# printerfix

**english** | [bahasa indonesia](README.id.md)

a simple menu-driven batch script that fixes the most common printer sharing problems on Windows 10 and Windows 11. made to save time on repetitive IT support tickets.

by IT Indoguna Makassar with Sonnet 5.5

## what it fixes

- error 0x0000011b (RPC authentication level)
- error 0x00000709 (cannot connect to the shared printer)
- error 0x00000bcb and 0x0000007c (driver not available)
- stuck print jobs and a crashing print spooler
- host pc not showing up on the network
- network profile set to public instead of private
- SMB guest logon problems on newer Windows 11 builds

## how to use

1. copy `PrinterFix.bat` to the affected pc
2. right-click the file and choose **run as administrator**
3. pick an option from the menu and follow the prompts

## menu options

| key | what it does |
|-----|--------------|
| 1 | fix 0x0000011b by setting `RpcAuthnLevelPrivacyEnabled` to 0, then restart the spooler |
| 2 | reset the print spooler and clear stuck jobs |
| 3 | enable file and printer sharing and network discovery, set public networks to private |
| 4 | set the required services to automatic and start them |
| 5 | allow insecure SMB guest logons |
| 6 | relax Point and Print restrictions for driver installation |
| 7 | add a shared printer through a local port pointing at `\\HOST\Share` |
| 8 | store network credentials for a host in credential manager |
| 9 | diagnostics: spooler state, registry value, network profile, printers, credentials, port 445 test |
| A | run the common fixes (1 to 4) at once |
| 0 | exit |

## notes

- the script needs administrator rights and will exit if it does not have them
- options 1, 5 and 6 lower some security hardening, so use them on trusted networks only. options 5 and 6 ask for confirmation first
- 0x0000011b is usually fixed on the host, but some setups need option 1 on the client too
- option 7 often avoids 0x0000011b and 0x00000709 without any registry changes, so try it first when you can
- option 8 shows the password while you type, so avoid it on shared screens
- a `.bat` file cannot be code-signed. to control trust, deploy it through Intune, GPO or your RMM tool, or convert it to a signed `.ps1`
- test on a spare pc before using it widely. use at your own risk

## requirements

- Windows 10 or Windows 11
- an administrator account
- PowerShell (included with Windows)
