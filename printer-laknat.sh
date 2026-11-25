#!/usr/bin/env bash
# printer-laknat.sh - read-only troubleshooting of a Windows 10/11 shared
# printer host, run from a Linux PC on the same LAN.
# It never changes anything on the Windows PC or on this Linux PC
# (except writing reports to printer-laknat.reports/ next to this script).
#
# usage:
#   ./printer-laknat.sh                       menu
#   ./printer-laknat.sh --diag HOST [-u USER]  test a host (asks for password)
#   ./printer-laknat.sh --code 0x11b           look up an error code
#   ./printer-laknat.sh --deps                 check required tools

set -u

PL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS="$PL_DIR/printer-laknat.reports"
TIMEOUT=3

# ---------- output helpers ----------
if [ -t 1 ]; then
    C_OK=$'\e[32m'; C_WARN=$'\e[33m'; C_BAD=$'\e[31m'; C_SKIP=$'\e[90m'; C_OFF=$'\e[0m'
else
    C_OK=''; C_WARN=''; C_BAD=''; C_SKIP=''; C_OFF=''
fi

# S status message [hint]   status: ok | warn | bad | skip
S() {
    local st="$1" msg="$2" hint="${3:-}" tag col
    case "$st" in
        ok)   tag='[ OK ]'; col="$C_OK" ;;
        warn) tag='[WARN]'; col="$C_WARN" ;;
        bad)  tag='[FAIL]'; col="$C_BAD" ;;
        *)    tag='[SKIP]'; col="$C_SKIP" ;;
    esac
    printf '%s%s%s %s\n' "$col" "$tag" "$C_OFF" "$msg"
    [ -n "$hint" ] && printf '       -> %s\n' "$hint"
    return 0
}

header() {
    echo
    echo "=============================================================="
    echo " $1"
    echo "=============================================================="
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- dependencies ----------
install_hint() {
    # $1 = debian pkg, $2 = fedora pkg, $3 = arch pkg
    echo "apt install $1  |  dnf install $2  |  pacman -S $3"
}

deps() {
    header "Required tools"
    have smbclient && S ok "smbclient" || S bad "smbclient missing (share and login tests)" "$(install_hint smbclient samba-client smbclient)"
    have rpcclient && S ok "rpcclient" || S warn "rpcclient missing (spooler test skipped)" "$(install_hint smbclient samba-client smbclient)"
    have nmap      && S ok "nmap"      || S warn "nmap missing (SMB signing test skipped)" "$(install_hint nmap nmap nmap)"
    have nmblookup && S ok "nmblookup" || S warn "nmblookup missing (NetBIOS name lookup skipped)" "$(install_hint samba-common-bin samba-client smbclient)"
    have timeout   && S ok "timeout"   || S bad "timeout missing (coreutils)" "install coreutils"
}

# ---------- checks ----------
port_open() { timeout "$TIMEOUT" bash -c "exec 3<>/dev/tcp/$1/$2" 2>/dev/null; }

# result flags used by the verdict
reset_flags() {
    F_RESOLVE=0; F_PING=0; F_445=0; F_135=0; F_139=0
    F_SIGNREQ=unknown; F_SMB1=unknown
    F_GUEST=unknown; F_AUTH=unknown; F_PRINTERS=0; F_RPC=unknown
    GUEST_ERR=''; AUTH_ERR=''; RPC_ERR=''
}

nt_status() { grep -o 'NT_STATUS_[A-Z_]*\|WERR_[A-Z_]*' <<<"$1" | head -n1; }

explain_status() {
    case "$1" in
        NT_STATUS_ACCESS_DENIED)       echo "access denied: account has no rights, or guest blocked" ;;
        NT_STATUS_LOGON_FAILURE)       echo "wrong user/password, or account does not exist on the host" ;;
        NT_STATUS_ACCOUNT_DISABLED)    echo "account disabled (on Windows usually the Guest account)" ;;
        NT_STATUS_ACCOUNT_RESTRICTION) echo "blank password not allowed over the network" ;;
        NT_STATUS_CONNECTION_REFUSED)  echo "port 445 closed" ;;
        NT_STATUS_IO_TIMEOUT|NT_STATUS_HOST_UNREACHABLE) echo "host not reachable" ;;
        NT_STATUS_BAD_NETWORK_NAME)    echo "share name not found" ;;
        WERR_ACCESS_DENIED)            echo "spooler refused the request" ;;
        '')                            echo "unknown error" ;;
        *)                             echo "$1" ;;
    esac
}

# list shares; $1 = host, $2 = authfile or empty for guest. sets LIST_OUT, returns rc
list_shares() {
    if [ -n "$2" ]; then
        LIST_OUT="$(timeout 15 smbclient -g -L "//$1" -A "$2" 2>&1)"
    else
        LIST_OUT="$(timeout 15 smbclient -g -L "//$1" -N 2>&1)"
    fi
}

diag() {
    local h="$1" user="${2:-}" pass='' authfile='' ip out st
    reset_flags

    if [ -n "$user" ]; then
        read -r -s -p "Password for $user on $h (not saved): " pass; echo
        authfile="$(mktemp)"; chmod 600 "$authfile"
        # DOMAIN\user or user
        if [[ "$user" == *\\* ]]; then
            printf 'username = %s\npassword = %s\ndomain = %s\n' "${user#*\\}" "$pass" "${user%%\\*}" >"$authfile"
        else
            printf 'username = %s\npassword = %s\n' "$user" "$pass" >"$authfile"
        fi
        pass=''
        trap 'rm -f "$authfile"' RETURN
    fi

    header "Target host test: $h  ($(date '+%Y-%m-%d %H:%M'))"

    # 1 name resolves
    if [[ "$h" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ip="$h"; F_RESOLVE=1; S ok "Using IP $ip"
    else
        ip="$(getent hosts "$h" | awk '{print $1; exit}')"
        if [ -z "$ip" ] && have nmblookup; then
            ip="$(timeout "$TIMEOUT" nmblookup "$h" 2>/dev/null | awk '/<00>/{print $1; exit}')"
            [ -n "$ip" ] && S warn "$h found only via NetBIOS: $ip" "DNS does not know it; use the IP if printing fails"
        fi
        if [ -n "$ip" ]; then F_RESOLVE=1; S ok "$h resolves to $ip"
        else S bad "Cannot resolve $h" "use the host IP (ipconfig on the host), or option 4 on the host (network discovery)"; ip="$h"
        fi
    fi
    if have nmblookup && [ "$F_RESOLVE" = 1 ]; then
        out="$(timeout "$TIMEOUT" nmblookup -A "$ip" 2>/dev/null | awk '/<00> -  *[BMH]/ && !/GROUP/{print $1; exit}')"
        [ -n "$out" ] && S ok "NetBIOS name: $out"
    fi

    # 2 ping
    if ping -c2 -W"$TIMEOUT" "$ip" >/dev/null 2>&1; then F_PING=1; S ok "Host answers ping"
    else S warn "No ping reply" "normal if the Windows firewall blocks ICMP; the port tests below matter more"
    fi

    # 3-4 ports
    if port_open "$ip" 445; then F_445=1; S ok "TCP 445 (SMB) open"
    else S bad "TCP 445 (SMB) closed or filtered" "on the host: option 2 (file and printer sharing) + option 4 (private network)"
    fi
    if port_open "$ip" 135; then F_135=1; S ok "TCP 135 (RPC endpoint mapper) open"
    else S warn "TCP 135 (RPC) closed" "Windows clients need it with RPC over TCP (Win11 22H2+): firewall RPC step of C1/C3 on the host, or option B on clients"
    fi
    if port_open "$ip" 139; then F_139=1; S ok "TCP 139 (NetBIOS session) open"
    else S skip "TCP 139 closed (not needed when 445 works)"
    fi

    # 5 SMB signing / dialects
    if [ "$F_445" = 1 ] && have nmap; then
        out="$(nmap -Pn -p445 --script smb2-security-mode,smb-protocols "$ip" 2>/dev/null)"
        if grep -qi 'enabled and required' <<<"$out"; then
            F_SIGNREQ=1; S warn "SMB signing REQUIRED" "guest logons fail (Win11 24H2 default). clients must use an account: option 8"
        elif grep -qi 'enabled but not required' <<<"$out"; then
            F_SIGNREQ=0; S ok "SMB signing enabled, not required (guest logons possible)"
        else
            S skip "Could not read SMB signing mode"
        fi
        if grep -q 'NT LM 0.12\|SMBv1' <<<"$out"; then F_SMB1=1; S warn "SMB1 enabled on host" "old and unsafe; not needed for printing"
        elif grep -q '2[:.]0[:.]2\|3[:.]' <<<"$out"; then F_SMB1=0; S ok "SMB2/3 only"
        fi
    elif [ "$F_445" = 1 ]; then S skip "SMB signing test (nmap missing)"
    fi

    # 6 guest share list
    if [ "$F_445" = 1 ] && have smbclient; then
        if list_shares "$ip" ''; then
            F_GUEST=1; S ok "Guest can list shares"
            GUEST_LIST="$LIST_OUT"
        else
            F_GUEST=0; GUEST_ERR="$(nt_status "$LIST_OUT")"
            S warn "Guest cannot list shares: $(explain_status "$GUEST_ERR")" "expected on Win11 24H2 / when guest is off. use an account (-u USER), option 8 on Windows clients"
        fi
    fi

    # 7 authenticated share list
    if [ -n "$authfile" ] && [ "$F_445" = 1 ] && have smbclient; then
        if list_shares "$ip" "$authfile"; then
            F_AUTH=1; S ok "Login as $user works"
            AUTH_LIST="$LIST_OUT"
        else
            F_AUTH=0; AUTH_ERR="$(nt_status "$LIST_OUT")"
            S bad "Login as $user failed: $(explain_status "$AUTH_ERR")" "the account must exist on the host (HOST\\user) and have a password"
        fi
    elif [ "$F_445" = 1 ]; then
        S skip "Account login test (run with -u USER)"
    fi

    # 8 printer shares
    local list=''
    [ "$F_AUTH" = 1 ] && list="$AUTH_LIST"
    [ -z "$list" ] && [ "$F_GUEST" = 1 ] && list="$GUEST_LIST"
    if [ -n "$list" ]; then
        out="$(awk -F'|' '$1=="Printer"{print $2 (length($3) ? "  ("$3")" : "")}' <<<"$list")"
        if [ -n "$out" ]; then
            F_PRINTERS=1; S ok "Printer shares:"
            sed 's/^/         /' <<<"$out"
        else
            S bad "Host answers but shares no printer" "share it on the host: printer properties > Sharing (option 1 / C1 / C3)"
        fi
    fi

    # 9 spooler over RPC (named pipe, same path as Win10 clients / option B)
    if [ "$F_445" = 1 ] && have rpcclient && { [ "$F_AUTH" = 1 ] || [ "$F_GUEST" = 1 ]; }; then
        if [ "$F_AUTH" = 1 ]; then out="$(timeout 15 rpcclient -A "$authfile" -c enumprinters "$ip" 2>&1)"
        else out="$(timeout 15 rpcclient -U% -N -c enumprinters "$ip" 2>&1)"
        fi
        if grep -q 'name:\[' <<<"$out"; then
            F_RPC=1; S ok "Print spooler answers over RPC (named pipe)"
        else
            F_RPC=0; RPC_ERR="$(nt_status "$out")"
            S bad "Spooler RPC failed: $(explain_status "$RPC_ERR")" "on the host: option 3 (restart spooler); access denied with a valid account can be the 0x11b side: option 1 on the host"
        fi
    elif [ "$F_445" = 1 ]; then
        S skip "Spooler RPC test (needs rpcclient and a working login)"
    fi

    verdict "$h"
}

verdict() {
    header "Verdict for $1"
    if [ "$F_445" = 0 ]; then
        echo " SMB is not reachable. On the HOST run C1 (Win10) or C3 (Win11),"
        echo " or at least options 2 + 4. Check that the host is on and on the same LAN."
        return
    fi
    if [ "$F_PRINTERS" = 0 ] && { [ "$F_AUTH" = 1 ] || [ "$F_GUEST" = 1 ]; }; then
        echo " The host is reachable but no printer is shared. Share the printer on the host."
    fi
    if [ "$F_GUEST" = 0 ] && [ "$F_AUTH" != 1 ]; then
        echo " Guest access is blocked. Re-run with -u USER (an account on the host)."
        echo " Windows clients: option 8 with that account."
    fi
    if [ "$F_SIGNREQ" = 1 ]; then
        echo " SMB signing is required: guest (option 5) will NOT work. Use option 8."
    fi
    if [ "$F_AUTH" = 0 ]; then
        echo " The account you gave is rejected. Create or fix it on the host."
    fi
    if [ "$F_135" = 0 ]; then
        echo " TCP 135 is closed. Win11 22H2+ clients will time out (0x79 / 0x709):"
        echo " firewall RPC step on the host (C1/C3), or option B on each Win11 client."
    fi
    if [ "$F_RPC" = 0 ]; then
        echo " The spooler does not answer RPC. Option 3 on the host; if clients get"
        echo " 0x11b, option 1 on the host. Fallback for clients: option 7."
    fi
    if [ "$F_PRINTERS" = 1 ] && [ "$F_RPC" = 1 ] && [ "$F_135" = 1 ]; then
        echo " Host looks fine from the network. If a Windows client still fails,"
        echo " the problem is on the client: run C2 (Win10) or C4 (Win11) there,"
        echo " and look up the error code (menu 2 / --code)."
    fi
}

# ---------- error codes (same table as the .bat) ----------
code_lookup() {
    local c
    c="$(tr '[:upper:]' '[:lower:]' <<<"${1// /}")"; c="${c#0x}"
    c="$(sed 's/^0*//' <<<"$c")"
    echo
    case "$c" in
        11b) m='RPC privacy level mismatch. Option 1 on the SERVER (C1/C3). Fallback: option 7.' ;;
        709) m='Cannot connect to / set the printer. Win11 22H2+ client: option B. Also option 1 on the server, try the IP instead of the name, or option 7.' ;;
        79)  m='Timeout: Win11 22H2+ client using RPC over TCP. Option B on the client, then option 8. Server: firewall RPC step (C1/C3). Fallback: option 7.' ;;
        bc4) m='No printers found: Win11 22H2 RPC over TCP. Option B on the client.' ;;
        6d1) m='Procedure not found (RPC). Option B on the client.' ;;
        bcb) m='Driver install blocked by Point and Print. Option 6 on the client, or install the driver locally and use option 7.' ;;
        7c)  m='Driver install blocked or wrong driver. Option 6, or option 7 with a local driver.' ;;
        5)   m='Access denied. Option 8 with an account that exists on the host; check share permissions.' ;;
        35)  m='Network path not found. Options 3 + 4 on both PCs; run the target host test.' ;;
        43)  m='Network name not found. Check the share name; option 3 on the host.' ;;
        3e3) m='Operation aborted. Option 2 on both PCs, then option 6.' ;;
        *)   echo "No entry for '$1'. Known: 11b, 709, 79, bc4, 6d1, bcb, 7c, 5, 35, 43, 3e3. Run the target host test."; return ;;
    esac
    local pad="00000000$c"
    echo "----- 0x${pad: -8} -----"
    echo "$m"
    echo "(option numbers refer to printer-laknat.bat on the Windows PC)"
}

# ---------- report ----------
run_diag_with_report() {
    local h="$1" user="${2:-}" f
    mkdir -p "$REPORTS"
    f="$REPORTS/linux-${h//[^A-Za-z0-9._-]/_}-$(date +%Y%m%d-%H%M).txt"
    # password prompt goes to the terminal, not the report (read -s writes to stderr)
    diag "$h" "$user" | tee >(sed 's/\x1b\[[0-9;]*m//g' >"$f")
    sleep 0.2
    echo
    echo "Report saved: $f"
}

# ---------- menu ----------
menu() {
    local k h u c
    while true; do
        echo
        echo "  PRINTER LAKNAT (linux, read-only troubleshooting)"
        echo
        echo "  [1] Test a Windows printer host"
        echo "  [2] Look up an error code"
        echo "  [3] Check required tools"
        echo "  [0] Exit"
        echo
        read -r -p "Choose: " k
        case "$k" in
            1) read -r -p "Host name or IP: " h
               [ -z "$h" ] && continue
               read -r -p "Account on the host (blank = guest only, DOMAIN\\user ok): " u
               run_diag_with_report "$h" "$u" ;;
            2) read -r -p "Error code (e.g. 79 or 0x0000011b): " c
               [ -n "$c" ] && code_lookup "$c" ;;
            3) deps ;;
            0|q|Q) exit 0 ;;
        esac
    done
}

case "${1:-}" in
    '') menu ;;
    --diag)
        [ -z "${2:-}" ] && { echo "usage: $0 --diag HOST [-u USER]"; exit 2; }
        h="$2"; u=''
        [ "${3:-}" = "-u" ] && u="${4:-}"
        run_diag_with_report "$h" "$u" ;;
    --code) code_lookup "${2:-}" ;;
    --deps) deps ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) echo "unknown option: $1 (try --help)"; exit 2 ;;
esac
