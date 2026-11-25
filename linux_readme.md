# printer laknat for linux

**english** | [bahasa indonesia](linux_readme.id.md)

`printer-laknat.sh` checks a windows 10/11 pc that shares a printer, from a linux pc on the same lan. it tells you what is wrong and which option of `printer-laknat.bat` to run on which pc.

it is **read-only**. it does not change anything on the windows pc or on your linux pc. it only saves a report next to itself.

for the windows tool, see [README.md](README.md).

## what it checks

1. the host name resolves (dns, then netbios)
2. the host answers ping (a warning only, windows often blocks ping)
3. tcp 445 (smb) is open
4. tcp 135 (rpc) is open. win11 22H2+ clients need it
5. smb signing: if it is required, guest logons fail (win11 24H2 default)
6. guest can list shares
7. your account can log in (only with `-u USER`)
8. which printers are shared
9. the print spooler answers over rpc

at the end it prints a **verdict**: what to fix and where.

## needs

- `smbclient` and `rpcclient`: debian/ubuntu `smbclient`, fedora `samba-client`, arch `smbclient`
- `nmap` (optional, for the smb signing test)
- `nmblookup` (optional): debian/ubuntu `samba-common-bin`

run `./printer-laknat.sh --deps` to check. missing tools are skipped, not failed.

no root needed.

## how to use

```sh
chmod +x printer-laknat.sh
./printer-laknat.sh                          # menu
./printer-laknat.sh --diag 192.168.1.20      # guest only
./printer-laknat.sh --diag PC-ADMIN -u budi  # with an account on the host (asks for the password)
./printer-laknat.sh --code 0x709             # look up an error code
```

`DOMAIN\user` also works for `-u`. quote it: `-u 'KANTOR\budi'`.

## reports

saved in `printer-laknat.reports/linux-HOST-DATE.txt`. passwords are never written to the report. the password is kept only in a temp file (chmod 600) while the test runs, then deleted.

## limits

- it checks the host only. problems on a windows **client** (driver, point and print, rpc over tcp settings) can't be seen from linux. run C2 / C4 on that client.
- the spooler test uses rpc over named pipes (port 445). windows 11 22H2+ clients use rpc over tcp by default, so the port 135 check matters for them.
- tested only on linux without a real windows host so far. please report results.

## planned

printing from linux to a windows shared printer: see [backlog.md](backlog.md).
