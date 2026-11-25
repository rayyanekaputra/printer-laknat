```text

░▒▓███████▓▒░░▒▓███████▓▒░░▒▓█▓▒░▒▓███████▓▒░▒▓████████▓▒░▒▓████████▓▒░▒▓███████▓▒░  
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓███████▓▒░░▒▓███████▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓██████▓▒░ ░▒▓███████▓▒░  
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░ 
                                                                                     
                                                                                     
░▒▓█▓▒░       ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░ ░▒▓██████▓▒░▒▓████████▓▒░       
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░           
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░           
░▒▓█▓▒░      ░▒▓████████▓▒░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░ ░▒▓█▓▒░           
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░           
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░           
░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░           
                                                                                     
                                                                                                                                                               
```
                                

**english** | [bahasa indonesia](README.id.md)

a simple menu-driven batch script that fixes the most common printer sharing problems on Windows 10 and Windows 11. made to save time on repetitive IT support tickets.

by IT Indoguna Makassar with Sonnet 5.5

## what it fixes

- error 0x0000011b (RPC authentication level)
- error 0x00000709 (cannot connect to the shared printer)
- error 0x00000079 (timeout: Windows 11 22H2+ client connecting to a Windows 10 host)
- error 0x00000bcb and 0x0000007c (driver not available)
- stuck print jobs and a crashing print spooler
- host pc not showing up on the network
- network profile set to public instead of private
- SMB guest logon problems, including Windows 11 24H2 where SMB signing makes guest logons fail

## how to use

1. copy `printer-laknat.bat` to the affected pc
2. right-click the file and choose **run as administrator**
3. pick an option from the menu. every fix explains what it does and asks before applying

## which preset to use

the **server** is the pc the printer is plugged into and shared from. the **client** is the pc that connects to it.

| key | role | steps |
|-----|------|-------|
| C1 | windows 10 as server (shares the printer) | 1 + 2 + 3 + 4 + firewall RPC |
| C2 | windows 10 as client (connects to shared printer) | 2 + 3 + 4 + 8, optional 5 / 6 |
| C3 | windows 11 as server (shares the printer) | 1 + 2 + 3 + 4 + firewall RPC |
| C4 | windows 11 as client (connects to shared printer) | B + 2 + 3 + 4 + 8, optional 6 |

run the server preset on the host first, then the client preset on each client. every step inside a preset still asks Y/N, so you can skip any of them.

## menu options

| key | what it does |
|-----|--------------|
| 1 | fix 0x0000011b by setting `RpcAuthnLevelPrivacyEnabled` to 0, then restart the spooler |
| 2 | reset the print spooler and clear stuck jobs |
| 3 | enable file and printer sharing and network discovery, set public networks to private |
| 4 | set the required services to automatic and start them |
| 5 | allow insecure SMB guest logons |
| 6 | relax Point and Print restrictions for driver installation |
| 7 | add a shared printer through a local port pointing at `\\HOST\Share` (fallback) |
| 8 | store network credentials for a host in credential manager |
| B | fix 0x00000079 / 0x00000709 / 0x00000bc4 on windows 11 22H2+ clients by forcing RPC over named pipes (`RpcUseNamedPipeProtocol` = 1) |
| C1-C4 | common fixes per role, see above |
| 9 | diagnostics, see below |
| R | restore settings. if `printer-laknat.backup` exists next to the script, you can restore the exact settings from before the first fix. otherwise, or if you choose to, restore Windows defaults: remove the registry changes from 1, 5, 6 and B, disable the sharing and discovery firewall rules, set networks back to public, reset service startup types, and optionally remove printers from 7 and credentials from 8 |
| 0 | exit |

## what each option does

- **1 RPC privacy (0x11b):** since the january 2022 update the print server demands encrypted RPC and some clients fail the handshake. 0 lets them connect. *risk:* printer RPC is no longer forced to be encrypted, and Microsoft is phasing this override out. run it on the server.
- **2 spooler reset:** a stuck job or hung spooler blocks everything. *risk:* pending jobs on that pc are deleted.
- **3 sharing:** on a public profile Windows blocks SMB (445) and printer RPC, so the host is invisible. *risk:* other devices on the LAN can see the pc.
- **4 services:** without the server/workstation services there is no SMB, without the discovery services the pc doesn't show up. *risk:* low.
- **5 guest logon:** lets the client open shares without a password. *why it's off by default now:* guest sessions can't be signed or verified, so anyone on the LAN can impersonate the host. windows 11 24H2 requires SMB signing, so guest fails anyway. use 8 instead.
- **6 Point and Print:** lets non-admins install drivers from the server (0xbcb / 0x7c). *why it's off by default now:* since PrintNightmare (2021) a malicious server could push a "driver" that runs as SYSTEM.
- **7 local port:** creates a local port named `\\HOST\Share` and uses a driver installed on the client. *why it works:* jobs go to the share as plain SMB file writes, with no RPC printer connection, so the 0x11b / 0x709 / 0x79 RPC checks never run. *why it's not the normal way:* you install the driver yourself, there are no automatic driver updates or queue status from the server, and it has to be set up by hand on every client. a workaround, not a fix.
- **8 credentials:** SMB logs in with a real, signed account instead of guest. the recommended replacement for 5, required on windows 11 24H2. use an account that exists on the host.
- **B named pipes (0x79):** since 22H2, windows 11 talks to printers with RPC over TCP. a windows 10 host, or a firewall blocking port 135, doesn't answer, so the connection times out. B goes back to RPC over named pipes inside SMB (port 445). *risk:* low, it's the pre-22H2 behaviour. run it on the windows 11 client.
- **firewall RPC (in C1 / C3):** enables the "Spooler Service - RPC" and "RPC-EPMAP" (port 135) rules so windows 11 clients can reach the server over TCP, and lists the printers the pc shares.

## diagnostics

option 9 changes nothing. it shows:

- this pc's Windows version and build, and the preset that matches it
- a checklist with `[OK]`, `[!!]` or `[--]` per item and the option that fixes it: spooler, services, network profile, firewall rules, RPC settings, SMB signing, guest logon, Point and Print, shared printers
- **target host test:** enter the server's name or IP. it tests ping, SMB port 445, RPC port 135, visible printer shares and stored credentials, in order, so you can see which layer breaks
- **error code lookup:** type the code you saw (for example `79` or `0x0000011b`) to get the likely cause and the option to run
- a report saved to `printer-laknat.reports\` next to the script, so you can compare the client and the server

## troubleshooting flow

1. on the client, run 9 and test the target host
2. fix the server with C1 or C3
3. fix the client with C2 or C4
4. still failing? use 7 as the fallback

## notes

- the script needs administrator rights and will exit if it does not have them
- options 1, 5, 6 and B lower some security hardening, so use them on trusted networks only. every option explains its risk and asks before applying
- 0x0000011b is usually fixed on the host, but some setups need option 1 on the client too
- 7 is a fallback, not the normal method: it needs a local driver on every client and loses automatic driver updates
- on windows 11 24H2, use option 8 instead of 5: SMB signing is required and guest logons fail
- option 8 shows the password while you type, so avoid it on shared screens
- diagnostics reports are saved in `printer-laknat.reports\` and are kept when you restore settings
- a `.bat` file cannot be code-signed. to control trust, deploy it through Intune, GPO or your RMM tool, or convert it to a signed `.ps1`
- test on a spare pc before using it widely. use at your own risk

## requirements

- Windows 10 or Windows 11
- an administrator account
- PowerShell (included with Windows)
