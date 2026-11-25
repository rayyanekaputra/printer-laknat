# AGENTS.md

Context for AI coding sessions working on **Printer Laknat**.

## What this is

A single menu-driven Windows batch script, `printer-laknat.bat`, that fixes shared-printer problems between Windows 10 and Windows 11 PCs on a LAN (errors 0x11b, 0x709, 0x79, 0xbcb, 0x7c, guest/SMB issues). It's used by IT support (IT Indoguna Makassar) and copied to the affected PC. It must be run as Administrator.

Files:
- `printer-laknat.bat`: the whole tool
- `README.md` (English) and `README.id.md` (Bahasa Indonesia): user docs, kept in sync
- `printer-laknat.sh`: linux companion, read-only diagnostics of a windows host (smbclient / rpcclient / nmap). Never changes the windows PC. Docs in `linux_readme.md` / `linux_readme.id.md`, kept in sync
- `backlog.md`: planned work (linux to windows printing via CUPS `smb://`)
- `.gitignore`: ignores `printer-laknat.backup/` and `printer-laknat.reports/`, which the script creates next to itself on the target PC

## Script layout (top to bottom)

1. Admin check, then `BK` (backup folder) and `PL_SELF` (path of the script)
2. `:menu`: banner, COMMON FIXES (C1–C4) first, then individual FIXES (1–8, B), then 9 / R / 0
3. Helpers: `:confirm` (Y/N, returns errorlevel 1 on no) and `:header`
4. `:optN` / `:optB` / `:optFW`: user-facing fixes. Each one prints WHAT / WHY / RISK / WHERE / UNDO, then runs `call :confirm || goto :eof`, then `call :backup`, then applies the fix
5. Presets `:preset_w10server` (C1), `:preset_w10client` (C2), `:preset_w11server` (C3), `:preset_w11client` (C4): just a list of `call :optX`, so every step still asks Y/N
6. Actions with no prompts (`:spooler`, `:sharing`, `:services`, `:localport`, `:creds`), used by the opt wrappers
7. `:diag` and `:ps`: diagnostics
8. `:backup`, `:restore`, `:restore_backup`, `:restore_defaults`, `:restore_extras`
9. After `exit /b`, a marker line `#PSDIAG#` followed by the diagnostics written in PowerShell. `:ps` loads it with `iex`, splitting the file on `'#'+'PSDIAG'+'#'`; the string is concatenated so the literal marker appears only once. The mode is passed in through the env vars `PL_MODE` (`local` / `host` / `code`), `PL_HOST` and `PL_CODE`

## Presets

| key | role | steps |
|-----|------|-------|
| C1 | Win10 server (shares the printer) | 1 + 2 + 3 + 4 + firewall RPC |
| C2 | Win10 client (connects to shared printer) | 2 + 3 + 4 + 8, optional 5 / 6 |
| C3 | Win11 server (shares the printer) | 1 + 2 + 3 + 4 + firewall RPC |
| C4 | Win11 client (connects to shared printer) | B + 2 + 3 + 4 + 8, optional 6 |

If you change a preset, update the menu label, the preset label in the script and both README tables.

## Technical facts this tool relies on

- 0x11b: `HKLM\SYSTEM\CurrentControlSet\Control\Print\RpcAuthnLevelPrivacyEnabled` = 0 on the server. Microsoft is phasing this override out.
- 0x79 / 0x709 / 0xbc4 on Win11 22H2+ clients: since 22H2 the client uses RPC over TCP. Fix B sets `HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC`: `RpcUseNamedPipeProtocol` = 1, `RpcAuthentication` = 0.
- Win11 24H2 requires SMB signing, so guest logons (option 5) fail. Use stored credentials (option 8) instead.
- Option 7 (a local port pointing at `\\HOST\Share`) bypasses printer RPC entirely. It's a fallback, not the normal method.

## Backup and restore rules

- `:backup` never overwrites registry values that are already saved. It only appends values that aren't in `registry.csv` yet, so values added in newer versions get backed up too. The firewall, network and services snapshots are taken once.
- Any new setting the tool changes must be added in **four** places: the `:backup` list, `:restore_defaults`, the diagnostics checklist and the READMEs.
- `:restore_backup` deletes the backup folder. That's why diagnostics reports live in a separate `printer-laknat.reports\` folder.

## Conventions

- `printer-laknat.sh` uses **LF** line endings, ASCII only, bash. Keep its error-code table in sync with the `.bat` one. Check with `bash -n` (shellcheck is not installed here)
- `printer-laknat.bat` uses **CRLF** line endings and **ASCII only**. After editing on Linux, run `sed -i 's/\r\?$/\r/' printer-laknat.bat`.
- No lines starting with `:` in the PowerShell section, because cmd's `goto` would treat them as labels.
- Escape `( )` inside `echo` lines that are within `if ( ... )` blocks as `^(` and `^)`.
- READMEs are written in lowercase, in a short and plain style. Update **both** languages in every docs change. Write the Bahasa version as natural Bahasa, not a word-for-word translation.
- **Commit every change** (the user's standing request), with conventional prefixes (`feat:`, `fix:`, `docs:`). Don't push unless asked.
- Development happens on Linux with no PowerShell or Windows available, so the script can't be run here. Say so honestly, and ask the user to test on a spare Windows PC.

## Possible next steps

- See `backlog.md`

- Real-world test results from Win11 24H2 client to Win10 host (not yet confirmed)
- Convert to a signed `.ps1` (mentioned in the README notes)
