@echo off
REM ==========================================================
REM  Printer Laknat
REM  by IT Indoguna Makassar with Sonnet 5.5
REM ==========================================================
setlocal EnableExtensions
title Printer Laknat
color 0B

:: ---------- Admin check ----------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [!] This script must be run as Administrator.
    echo     Right-click the file ^> Run as administrator.
    echo.
    pause
    exit /b 1
)

:: Backup of the original settings, saved next to this script
:: (not %CD%: "Run as administrator" starts in C:\Windows\System32)
set "BK=%~dp0printer-laknat.backup"
set "PL_SELF=%~f0"

:menu
cls
echo.
echo   ####  ####  ### #   # ##### ##### ####     #      ###  #   # #   #  ###  #####
echo   #   # #   #  #  ##  #   #   #     #   #    #     #   # #  #  ##  # #   #   #
echo   ####  ####   #  # # #   #   ####  ####     #     ##### ###   # # # #####   #
echo   #     #  #   #  #  ##   #   #     #  #     #     #   # #  #  #  ## #   #   #
echo   #     #   # ### #   #   #   ##### #   #    ##### #   # #   # #   # #   #   #
echo.
echo ==========================================================
echo   PRINTER LAKNAT  (Windows 10 / 11)
echo   by IT Indoguna Makassar with Sonnet 5.5
echo ==========================================================
echo.
echo  FIXES  (each one explains itself and asks before applying)
echo   [1] Fix 0x0000011b  (RPC privacy auth level)
echo   [2] Reset Print Spooler + clear stuck jobs
echo   [3] Enable File/Printer Sharing + Network Discovery
echo   [4] Start/enable required services
echo   [5] Allow insecure guest logons (SMB)
echo   [6] Relax Point and Print driver restrictions (0x00000bcb / 0x0000007c)
echo   [7] Add shared printer via local port (fallback, bypasses RPC)
echo   [8] Store network credentials for a host (cmdkey)
echo   [B] Fix 0x00000079 / 0x00000709 on Win11 22H2+ clients (RPC over named pipes)
echo.
echo  COMMON FIXES  (pick this PC's role)
echo   [C1] Windows 10 as SERVER  (shares the printer)         (1 + 2 + 3 + 4 + firewall RPC)
echo   [C2] Windows 10 as CLIENT  (connects to shared printer) (2 + 3 + 4 + 8, optional 5 / 6)
echo   [C3] Windows 11 as SERVER  (shares the printer)         (1 + 2 + 3 + 4 + firewall RPC)
echo   [C4] Windows 11 as CLIENT  (connects to shared printer) (B + 2 + 3 + 4 + 8, optional 6)
echo.
echo   [9] Diagnostics   [R] Restore settings   [0] Exit
echo.
set "choice="
set /p "choice=Select an option: "

if /i "%choice%"=="1"  call :opt1      & goto done
if /i "%choice%"=="2"  call :opt2      & goto done
if /i "%choice%"=="3"  call :opt3      & goto done
if /i "%choice%"=="4"  call :opt4      & goto done
if /i "%choice%"=="5"  call :opt5      & goto done
if /i "%choice%"=="6"  call :opt6      & goto done
if /i "%choice%"=="7"  call :opt7      & goto done
if /i "%choice%"=="8"  call :opt8      & goto done
if /i "%choice%"=="B"  call :optB      & goto done
if /i "%choice%"=="C1" call :preset_w10server & goto done
if /i "%choice%"=="C2" call :preset_w10client & goto done
if /i "%choice%"=="C3" call :preset_w11server & goto done
if /i "%choice%"=="C4" call :preset_w11client & goto done
if /i "%choice%"=="9"  call :diag      & goto done
if /i "%choice%"=="R"  call :restore   & goto done
if "%choice%"=="0" exit /b 0
goto menu

:done
echo.
pause
goto menu


:: ==========================================================
:: Helpers
:: ==========================================================
:confirm
:: Asks Y/N. Returns errorlevel 1 when the user says no.
echo.
set "ok="
set /p "ok=Apply? (Y/N): "
if /i "%ok%"=="Y" exit /b 0
echo [-] Skipped.
exit /b 1

:header
echo.
echo ----------------------------------------------------------
echo  %~1
echo ----------------------------------------------------------
goto :eof


:: ==========================================================
:: Fixes (explanation + confirm + apply)
:: ==========================================================
:opt1
call :header "[1] Fix 0x0000011b - RPC privacy auth level"
echo  WHAT : Sets RpcAuthnLevelPrivacyEnabled = 0, then restarts the spooler.
echo  WHY  : Since the Jan 2022 update the print server demands encrypted RPC.
echo         Clients that can't do it fail with 0x11b. 0 lets them connect.
echo  RISK : Printer RPC traffic is no longer forced to be encrypted. Microsoft
echo         is phasing this override out; on fully patched builds it may be
echo         ignored. If so, use [B] on the client or [7].
echo  WHERE: The SERVER (sharing PC). Some setups need it on the client too.
echo  UNDO : [R] Restore.
call :confirm || goto :eof
call :backup
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f
call :spooler
echo [+] Done. Retry connecting to the printer.
goto :eof

:opt2
call :header "[2] Reset Print Spooler + clear stuck jobs"
echo  WHAT : Stops the spooler, deletes queued jobs, starts it again (auto start).
echo  WHY  : A stuck job or hung spooler blocks every print and connection.
echo  RISK : Pending print jobs on THIS PC are deleted.
echo  UNDO : Nothing to undo.
call :confirm || goto :eof
call :spooler
goto :eof

:opt3
call :header "[3] Enable File/Printer Sharing + Network Discovery"
echo  WHAT : Enables the "File and Printer Sharing" and "Network Discovery"
echo         firewall rules and switches Public networks to Private.
echo  WHY  : On a Public profile Windows blocks SMB (445) and printer RPC, so
echo         the host is invisible and connections time out.
echo  RISK : Other devices on this LAN can see this PC. Trusted networks only.
echo  UNDO : [R] Restore.
call :confirm || goto :eof
call :sharing
goto :eof

:opt4
call :header "[4] Start/enable required services"
echo  WHAT : Sets Spooler, Server, Workstation and discovery services to
echo         automatic and starts them.
echo  WHY  : If Server/Workstation are stopped there is no SMB; without the
echo         discovery services the PC doesn't show up in Network.
echo  RISK : Low. Slightly more network exposure.
echo  UNDO : [R] Restore.
call :confirm || goto :eof
call :services
goto :eof

:opt5
call :header "[5] Allow insecure guest logons (SMB)"
echo  WHAT : Sets AllowInsecureGuestAuth = 1 so this PC may open shares
echo         without a username/password.
echo  WHY  : Hosts shared "to everyone" use guest access, which newer Windows
echo         blocks by default.
echo  RISK : Guest sessions can't be signed or verified, so anyone on the LAN
echo         can impersonate the host. That's why it's off by default now.
echo         On Win11 24H2 SMB signing is required and guest still FAILS -
echo         use [8] with a real account instead.
echo  UNDO : [R] Restore.
call :confirm || goto :eof
call :backup
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f
echo [+] AllowInsecureGuestAuth = 1. Reboot may be needed.
goto :eof

:opt6
call :header "[6] Relax Point and Print driver restrictions"
echo  WHAT : Lets non-admins install printer drivers from the server without
echo         prompts (RestrictDriverInstallationToAdministrators = 0, etc.).
echo  WHY  : Fixes 0x00000bcb / 0x0000007c when the client can't fetch the
echo         driver from the print server.
echo  RISK : Off by default since PrintNightmare (2021): a malicious or hacked
echo         server could push a "driver" that runs as SYSTEM. Trusted
echo         servers only. Alternative: install the driver locally, use [7].
echo  WHERE: The CLIENT.
echo  UNDO : [R] Restore.
call :confirm || goto :eof
call :backup
set "PP=HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
reg add "%PP%" /v RestrictDriverInstallationToAdministrators /t REG_DWORD /d 0 /f
reg add "%PP%" /v NoWarningNoElevationOnInstall /t REG_DWORD /d 1 /f
reg add "%PP%" /v UpdatePromptSettings /t REG_DWORD /d 2 /f
call :spooler
echo [+] Point and Print restrictions relaxed.
goto :eof

:opt7
call :header "[7] Add shared printer via local port (fallback)"
echo  WHAT : Creates a LOCAL port named \\HOST\Share and adds a printer on it
echo         using a driver already installed on this PC.
echo  WHY  : Jobs are written to the share as plain SMB file writes. There is
echo         no RPC printer connection, so the 0x11b / 0x709 / 0x79 RPC checks
echo         never run.
echo  WHY NOT THE NORMAL WAY: you must install the right driver yourself, no
echo         automatic driver updates or queue status from the server, and it
echo         has to be set up by hand on every client. A workaround, not a fix.
echo  WHERE: The CLIENT. Needs SMB access to the host ([8] if it asks for a password).
echo  UNDO : [R] Restore removes these printers and ports.
call :confirm || goto :eof
call :localport
goto :eof

:opt8
call :header "[8] Store network credentials for a host"
echo  WHAT : Saves HOST + username + password in Credential Manager (cmdkey).
echo  WHY  : SMB then logs in with a real, signed account instead of guest.
echo         Recommended replacement for [5], required on Win11 24H2.
echo         Use an account that exists on the HOST (HOST\user).
echo  RISK : The password is visible while typing. Avoid shared screens.
echo  UNDO : [R] Restore can delete it.
call :confirm || goto :eof
call :creds
goto :eof

:optB
call :header "[B] Fix 0x00000079 / 0x00000709 / 0x00000bc4 - RPC over named pipes"
echo  WHAT : Sets RpcUseNamedPipeProtocol = 1 and RpcAuthentication = 0 under
echo         Policies\...\Windows NT\Printers\RPC, then restarts the spooler.
echo  WHY  : Since 22H2, Windows 11 connects to printers with RPC over TCP. A
echo         Windows 10 host (or a firewall blocking port 135 + dynamic ports)
echo         doesn't answer, so it times out (0x79). This goes back to the old
echo         path: RPC over named pipes inside SMB (port 445).
echo  RISK : Low, it's the pre-22H2 behaviour. Microsoft may remove it later.
echo  WHERE: The Windows 11 CLIENT. Run [8] afterwards if the host needs a login.
echo  UNDO : [R] Restore.
call :confirm || goto :eof
call :backup
set "RK=HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC"
reg add "%RK%" /v RpcUseNamedPipeProtocol /t REG_DWORD /d 1 /f
reg add "%RK%" /v RpcAuthentication /t REG_DWORD /d 0 /f
call :spooler
echo [+] RPC over named pipes enabled. Retry connecting to the printer.
goto :eof

:optFW
call :header "[firewall RPC] Allow printer RPC through the firewall"
echo  WHAT : Enables the "Spooler Service - RPC" and "RPC-EPMAP" (port 135)
echo         rules on all profiles and lists the printers this PC shares.
echo  WHY  : Windows 11 clients talk to the server with RPC over TCP. If these
echo         rules are off they time out with 0x79 even when SMB works.
echo  RISK : Low. Only the spooler's RPC endpoint is exposed.
echo  WHERE: The SERVER.
echo  UNDO : [R] Restore.
call :confirm || goto :eof
call :backup
powershell -NoProfile -Command "Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'RPC' } | Enable-NetFirewallRule -PassThru | Format-Table DisplayName,Profile,Enabled -AutoSize"
echo Printers shared from this PC:
powershell -NoProfile -Command "$s=@(Get-Printer | Where-Object Shared); if ($s.Count) { $s | Format-Table Name,ShareName,DriverName -AutoSize } else { Write-Host '    [!!] None. Share the printer: Printer properties > Sharing.' }"
goto :eof


:: ==========================================================
:: Common fixes per role
:: ==========================================================
:preset_w10server
call :header "C1: Windows 10 as SERVER (shares the printer)"
call :opt1
call :opt2
call :opt3
call :opt4
call :optFW
echo.
echo [+] C1 complete. Now run C2 or C4 on each client. Reboot if needed.
goto :eof

:preset_w11server
call :header "C3: Windows 11 as SERVER (shares the printer)"
echo  Note: Windows 11 clients reach this PC with RPC over TCP, so the
echo        firewall RPC step at the end matters more here.
call :opt1
call :opt2
call :opt3
call :opt4
call :optFW
echo.
echo [+] C3 complete. Now run C2 or C4 on each client. Reboot if needed.
goto :eof

:preset_w10client
call :header "C2: Windows 10 as CLIENT (connects to a shared printer)"
call :opt2
call :opt3
call :opt4
call :opt8
echo.
echo  Optional steps (only if the error persists):
call :opt5
call :opt6
echo.
echo [+] C2 complete. Connect to \\HOST\Printer, or use [7] as fallback.
goto :eof

:preset_w11client
call :header "C4: Windows 11 as CLIENT (connects to a shared printer)"
call :optB
call :opt2
call :opt3
call :opt4
echo.
echo  Win11 24H2 requires SMB signing, so guest logon [5] is skipped.
echo  Store a real account of the HOST instead:
call :opt8
echo.
echo  Optional step (only for driver errors 0x bcb / 7c):
call :opt6
echo.
echo [+] C4 complete. Connect to \\HOST\Printer, or use [7] as fallback.
goto :eof


:: ==========================================================
:: Actions (no prompts, used by the fixes above)
:: ==========================================================
:spooler
echo.
echo [*] Stopping Print Spooler...
net stop spooler /y >nul 2>&1
echo [*] Clearing spool folder...
del /q /f /s "%systemroot%\System32\spool\PRINTERS\*" >nul 2>&1
echo [*] Starting Print Spooler...
net start spooler
sc config spooler start= auto >nul
echo [+] Spooler reset.
goto :eof

:sharing
echo.
call :backup
echo [*] Enabling File and Printer Sharing firewall rules...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
echo [*] Enabling Network Discovery firewall rules...
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
echo [*] Setting active network profile(s) to Private...
powershell -NoProfile -Command "Get-NetConnectionProfile | Where-Object {$_.NetworkCategory -eq 'Public'} | Set-NetConnectionProfile -NetworkCategory Private"
echo [+] Sharing and discovery enabled.
goto :eof

:services
echo.
call :backup
echo [*] Configuring services (auto start + start now)...
for %%S in (Spooler LanmanServer LanmanWorkstation fdPHost FDResPub SSDPSRV upnphost) do (
    sc config %%S start= auto >nul 2>&1
    net start %%S >nul 2>&1
    echo     %%S : done
)
echo [+] Services configured.
goto :eof

:localport
echo.
set "HOSTNAME_="
set "SHARE="
set "DRV="
set /p "HOSTNAME_=Host name or IP (e.g. PC01 or 192.168.1.10): "
set /p "SHARE=Share name of the printer: "
echo.
echo Installed drivers on this PC:
powershell -NoProfile -Command "Get-PrinterDriver | Select-Object -ExpandProperty Name"
echo.
set /p "DRV=Exact driver name to use (from list above): "
echo.
echo [*] Creating port \\%HOSTNAME_%\%SHARE% ...
powershell -NoProfile -Command "try { Add-PrinterPort -Name '\\%HOSTNAME_%\%SHARE%' -ErrorAction Stop; Add-Printer -Name '%SHARE% (%HOSTNAME_%)' -DriverName '%DRV%' -PortName '\\%HOSTNAME_%\%SHARE%' -ErrorAction Stop; Write-Host '[+] Printer added.' } catch { Write-Host ('[-] Failed: ' + $_.Exception.Message) }"
goto :eof

:creds
echo.
set "CH="
set "CU="
set "CP="
set /p "CH=Host name or IP: "
set /p "CU=Username (HOST\user or user): "
set /p "CP=Password (visible while typing): "
cmdkey /add:%CH% /user:%CU% /pass:%CP%
echo [+] Credential stored in Windows Credential Manager.
goto :eof


:: ==========================================================
:diag
:: Read-only. Checks run in the PowerShell section at the end of this file.
:: Reports are kept outside the backup folder so a restore doesn't delete them.
set "RPTDIR=%~dp0printer-laknat.reports"
if not exist "%RPTDIR%" mkdir "%RPTDIR%"
set "STAMP="
for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%D"
set "RPT=%RPTDIR%\diag-%COMPUTERNAME%-%STAMP%.txt"
echo.
echo [*] Checking this PC...
set "PL_MODE=local"
call :ps > "%RPT%" 2>&1
type "%RPT%"
echo.
set "PL_HOST="
set /p "PL_HOST=Target host/IP to test (the PC sharing the printer, blank to skip): "
if not "%PL_HOST%"=="" (
    echo [*] Testing %PL_HOST% ... this can take up to a minute.
    set "PL_MODE=host"
    call :ps > "%TEMP%\printer-laknat-diag.txt" 2>&1
    type "%TEMP%\printer-laknat-diag.txt"
    type "%TEMP%\printer-laknat-diag.txt" >> "%RPT%"
    del "%TEMP%\printer-laknat-diag.txt" >nul 2>&1
)
echo.
set "PL_CODE="
set /p "PL_CODE=Error code you saw (e.g. 79 or 0x0000011b, blank to skip): "
if not "%PL_CODE%"=="" (
    set "PL_MODE=code"
    call :ps > "%TEMP%\printer-laknat-diag.txt" 2>&1
    type "%TEMP%\printer-laknat-diag.txt"
    type "%TEMP%\printer-laknat-diag.txt" >> "%RPT%"
    del "%TEMP%\printer-laknat-diag.txt" >nul 2>&1
)
echo.
echo [+] Report saved: %RPT%
goto :eof

:ps
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (((Get-Content -Raw -LiteralPath $env:PL_SELF) -split ('#'+'PSDIAG'+'#'))[1])"
goto :eof


:: ==========================================================
:backup
:: Snapshot every setting this tool touches. Registry values already in the
:: backup are never overwritten, so it always holds the state from before
:: the first fix; values added by newer versions of this tool are appended.
if not exist "%BK%" mkdir "%BK%"
powershell -NoProfile -Command "$f=Join-Path $env:BK 'registry.csv'; $old=@(); if (Test-Path $f) { $old=@(Import-Csv $f) }; $l=@(@('HKLM:\SYSTEM\CurrentControlSet\Control\Print','RpcAuthnLevelPrivacyEnabled'),@('HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation','AllowInsecureGuestAuth'),@('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint','RestrictDriverInstallationToAdministrators'),@('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint','NoWarningNoElevationOnInstall'),@('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint','UpdatePromptSettings'),@('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC','RpcUseNamedPipeProtocol'),@('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC','RpcAuthentication')); $new=@($l | Where-Object { $k=$_; -not ($old | Where-Object { $_.Path -eq $k[0] -and $_.Name -eq $k[1] }) } | ForEach-Object { $v=(Get-ItemProperty -Path $_[0] -Name $_[1] -ErrorAction SilentlyContinue).($_[1]); [pscustomobject]@{Path=$_[0];Name=$_[1];Exists=($null -ne $v);Value=$v} }); if ($new.Count) { if (-not $old.Count) { Write-Host ('[*] Saving original settings to ' + $env:BK) }; @($old) + $new | Export-Csv -NoTypeInformation -Path $f }"
if exist "%BK%\firewall.csv" goto :eof
powershell -NoProfile -Command "Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing','Network Discovery' -ErrorAction SilentlyContinue | Select-Object Name,Enabled | Export-Csv -NoTypeInformation -Path (Join-Path $env:BK 'firewall.csv')"
powershell -NoProfile -Command "Get-NetConnectionProfile | Select-Object Name,InterfaceIndex,NetworkCategory | Export-Csv -NoTypeInformation -Path (Join-Path $env:BK 'network.csv')"
powershell -NoProfile -Command "Get-Service Spooler,LanmanServer,LanmanWorkstation,fdPHost,FDResPub,SSDPSRV,upnphost -ErrorAction SilentlyContinue | Select-Object Name,StartType | Export-Csv -NoTypeInformation -Path (Join-Path $env:BK 'services.csv')"
echo [+] Backup saved.
goto :eof


:: ==========================================================
:restore
echo.
set "mode="
if exist "%BK%\registry.csv" (
    echo   Backup found: %BK%
    echo.
    echo   [1] Restore from backup  ^(settings from before the first fix^)
    echo   [2] Restore Windows defaults  ^(clean install state^)
    echo.
    set /p "mode=Select an option: "
) else (
    echo   No backup found. Only Windows defaults can be restored.
    set "mode=2"
)
if "%mode%"=="1" goto restore_backup
if "%mode%"=="2" goto restore_defaults
goto :eof

:restore_backup
echo.
echo [!] This puts every setting back to how it was before the first fix.
set "ok="
set /p "ok=Continue? (Y/N): "
if /i not "%ok%"=="Y" goto :eof
echo.
echo [*] Restoring registry values...
powershell -NoProfile -Command "Import-Csv (Join-Path $env:BK 'registry.csv') | ForEach-Object { if ($_.Exists -eq 'True') { if (-not (Test-Path $_.Path)) { New-Item -Path $_.Path -Force | Out-Null }; New-ItemProperty -Path $_.Path -Name $_.Name -Value ([int]$_.Value) -PropertyType DWord -Force | Out-Null } else { Remove-ItemProperty -Path $_.Path -Name $_.Name -ErrorAction SilentlyContinue } }"
echo [*] Restoring firewall rules...
powershell -NoProfile -Command "Import-Csv (Join-Path $env:BK 'firewall.csv') | ForEach-Object { Set-NetFirewallRule -Name $_.Name -Enabled $_.Enabled -ErrorAction SilentlyContinue }"
echo [*] Restoring network profile(s)...
powershell -NoProfile -Command "Import-Csv (Join-Path $env:BK 'network.csv') | Where-Object { $_.NetworkCategory -ne 'DomainAuthenticated' } | ForEach-Object { Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory $_.NetworkCategory -ErrorAction SilentlyContinue }"
echo [*] Restoring service startup types...
powershell -NoProfile -Command "Import-Csv (Join-Path $env:BK 'services.csv') | ForEach-Object { Set-Service -Name $_.Name -StartupType $_.StartType -ErrorAction SilentlyContinue }"
call :restore_extras
:: Remove the used backup so the next fix takes a fresh snapshot
rmdir /s /q "%BK%"
call :spooler
echo [+] Original settings restored. Reboot recommended.
goto :eof

:restore_defaults
echo.
echo [!] WARNING: This puts every setting this tool changes back to the
echo     Windows defaults. Printer sharing will likely STOP working, network
echo     profiles become Public, and security hardening is re-enabled.
set "ok="
set /p "ok=Continue? (Y/N): "
if /i not "%ok%"=="Y" goto :eof
echo.
echo [*] Removing RpcAuthnLevelPrivacyEnabled (option 1)...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /f >nul 2>&1
echo [*] Removing AllowInsecureGuestAuth (option 5)...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" /v AllowInsecureGuestAuth /f >nul 2>&1
echo [*] Removing Point and Print overrides (option 6)...
set "PP=HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
for %%V in (RestrictDriverInstallationToAdministrators NoWarningNoElevationOnInstall UpdatePromptSettings) do (
    reg delete "%PP%" /v %%V /f >nul 2>&1
)
echo [*] Removing RPC over named pipes overrides (option B)...
set "RK=HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC"
for %%V in (RpcUseNamedPipeProtocol RpcAuthentication) do (
    reg delete "%RK%" /v %%V /f >nul 2>&1
)
echo [*] Disabling File and Printer Sharing + Network Discovery rules (option 3)...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=No >nul
netsh advfirewall firewall set rule group="Network Discovery" new enable=No >nul
echo [*] Setting network profile(s) back to Public (option 3)...
powershell -NoProfile -Command "Get-NetConnectionProfile | Where-Object {$_.NetworkCategory -eq 'Private'} | Set-NetConnectionProfile -NetworkCategory Public"
echo [*] Restoring service startup types (option 4)...
for %%S in (Spooler LanmanServer LanmanWorkstation) do sc config %%S start= auto >nul 2>&1
for %%S in (fdPHost FDResPub SSDPSRV upnphost) do sc config %%S start= demand >nul 2>&1
call :restore_extras
call :spooler
echo [+] Windows defaults restored. Reboot recommended.
goto :eof

:restore_extras
echo.
echo Printers added through a UNC local port (option 7):
powershell -NoProfile -Command "Get-Printer | Where-Object {$_.PortName -like '\\\\*'} | Format-Table Name,PortName -AutoSize"
set "ok="
set /p "ok=Remove ALL printers listed above and their ports? (Y/N): "
if /i "%ok%"=="Y" powershell -NoProfile -Command "Get-Printer | Where-Object {$_.PortName -like '\\\\*'} | ForEach-Object { $p=$_.PortName; Remove-Printer -Name $_.Name; Remove-PrinterPort -Name $p -ErrorAction SilentlyContinue; Write-Host ('    removed ' + $_.Name) }"
echo.
echo Stored credentials (option 8):
cmdkey /list | findstr /i "Target"
set "CH="
set /p "CH=Host to delete credential for (blank to skip): "
if not "%CH%"=="" cmdkey /delete:%CH%
goto :eof

exit /b
#PSDIAG#
# ---- Diagnostics (PowerShell). Run by :ps with PL_MODE = local / host / code.
function S($st, $msg, $fix) {
    $t = switch ($st) { 'ok' { '[OK]' } 'bad' { '[!!]' } default { '[--]' } }
    if ($fix) { "$t $msg   -> $fix" } else { "$t $msg" }
}
function RV($p, $n) { (Get-ItemProperty -Path $p -Name $n -ErrorAction SilentlyContinue).$n }
$mode = $env:PL_MODE

if ($mode -eq 'local') {
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $b = [int]$cv.CurrentBuild
    $w11 = $b -ge 22000
    $os = if ($w11) { 'Windows 11' } else { 'Windows 10' }
    "===== Printer Laknat diagnostics  $(Get-Date -Format 'yyyy-MM-dd HH:mm') ====="
    ""
    "----- This PC -----"
    "$env:COMPUTERNAME : $os $($cv.DisplayVersion) (build $b)"
    if ($w11) { "Suggested preset: C4 if this PC is a client, C3 if it shares the printer" }
    else      { "Suggested preset: C2 if this PC is a client, C1 if it shares the printer" }
    ""
    "----- Local checks -----"
    $sp = Get-Service Spooler
    if ($sp.Status -eq 'Running') { S ok "Spooler running ($($sp.StartType))" } else { S bad "Spooler $($sp.Status)" 'option 2' }
    foreach ($n in 'LanmanServer', 'LanmanWorkstation', 'FDResPub') {
        $x = Get-Service $n -ErrorAction SilentlyContinue
        if ($x.Status -eq 'Running') { S ok "$n running" } else { S bad "$n $($x.Status)" 'option 4' }
    }
    $pub = @(Get-NetConnectionProfile | Where-Object NetworkCategory -eq 'Public')
    if ($pub.Count) { S bad "Network profile Public: $($pub.Name -join ', ')" 'option 3' } else { S ok 'Network profile not Public' }
    $fw = @(Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing' -ErrorAction SilentlyContinue | Where-Object Enabled -eq 'True')
    if ($fw.Count) { S ok "File and Printer Sharing rules enabled ($($fw.Count))" } else { S bad 'File and Printer Sharing rules disabled' 'option 3' }
    $rpc = @($fw | Where-Object { $_.DisplayName -match 'RPC' })
    if ($rpc.Count) { S ok 'Printer RPC firewall rules enabled' } else { S na 'Printer RPC firewall rules off (matters on a server)' 'firewall RPC step in C1/C3' }
    $v = RV 'HKLM:\SYSTEM\CurrentControlSet\Control\Print' 'RpcAuthnLevelPrivacyEnabled'
    if ($v -eq 0) { S ok 'RpcAuthnLevelPrivacyEnabled = 0' } else { S na 'RpcAuthnLevelPrivacyEnabled default (encrypted RPC required)' 'option 1 if this is the server and clients get 0x11b' }
    $v = RV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC' 'RpcUseNamedPipeProtocol'
    if ($v -eq 1) { S ok 'Client uses RPC over named pipes (RpcUseNamedPipeProtocol = 1)' }
    elseif ($b -ge 22621) { S bad 'Client uses RPC over TCP (Win11 22H2+ default)' 'option B if you get 0x79 / 0x709 / 0xbc4' }
    else { S ok 'Client uses RPC over named pipes (pre-22H2 default)' }
    $sig = RV 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters' 'RequireSecuritySignature'
    if ($sig -eq 1 -or ($null -eq $sig -and $b -ge 26100)) { S bad 'SMB signing required: guest logons will fail' 'use option 8, not 5' } else { S ok 'SMB signing not required' }
    $g = RV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation' 'AllowInsecureGuestAuth'
    if ($g -eq 1) { S na 'Insecure guest logons allowed (option 5 applied)' } else { S na 'Insecure guest logons: default (blocked)' }
    $pp = RV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint' 'RestrictDriverInstallationToAdministrators'
    if ($pp -eq 0) { S na 'Point and Print relaxed (option 6 applied)' } else { S na 'Point and Print: default (admins only)' }
    $sh = @(Get-Printer -ErrorAction SilentlyContinue | Where-Object Shared)
    if ($sh.Count) { S ok "Shared from this PC: $(($sh | ForEach-Object { $_.Name + ' [' + $_.ShareName + ']' }) -join ', ')" }
    else { S na 'No printers shared from this PC (fine on a client)' }
    ""
    "----- Installed printers -----"
    Get-Printer | Format-Table Name, DriverName, PortName, Shared -AutoSize | Out-String -Width 200
    "----- Stored credentials -----"
    cmdkey /list | Select-String 'Target'
}

if ($mode -eq 'host') {
    $h = $env:PL_HOST
    ""
    "----- Target host: $h -----"
    if (Test-Connection $h -Count 2 -Quiet -ErrorAction SilentlyContinue) { S ok "Ping $h" }
    else { S na "Ping $h failed (ICMP may be blocked, continuing)" }
    $t = Test-NetConnection $h -Port 445 -WarningAction SilentlyContinue
    if (-not $t.RemoteAddress) { S bad "Cannot resolve $h" 'check the name or use the IP'; return }
    if ($t.TcpTestSucceeded) { S ok "SMB port 445 open ($($t.RemoteAddress))" }
    else { S bad 'SMB port 445 closed: nothing else can work' 'run C1/C3 on the host (option 3 + 4)'; return }
    $r = Test-NetConnection $h -Port 135 -WarningAction SilentlyContinue
    if ($r.TcpTestSucceeded) { S ok 'RPC port 135 open' }
    else { S bad 'RPC port 135 closed: Win11 clients (RPC over TCP) will time out' 'C1/C3 on the host, or option B on this client' }
    $nv = net view "\\$h" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $pr = @($nv | Where-Object { $_ -match '\s(Print|Printer|Drucker|Imprimante)\s' })
        if ($pr.Count) { S ok 'Printer shares visible:'; $pr | ForEach-Object { "       $_" } }
        else { S bad 'Host answers but shares no printer' 'share it on the host: Printer properties > Sharing' }
    }
    else { S bad "Cannot list shares: $((($nv | Out-String).Trim() -split "`n")[0])" 'option 8 with a host account (or 5 on Win10)' }
    if (cmdkey /list | Select-String -SimpleMatch $h) { S ok "Credential stored for $h" } else { S na "No stored credential for $h" 'option 8' }
}

if ($mode -eq 'code') {
    $c = ($env:PL_CODE.Trim().ToLower() -replace '^0x', '') -replace '^0+', ''
    $m = @{
        '11b' = 'RPC privacy level mismatch. Option 1 on the SERVER (C1/C3). Fallback: option 7.'
        '709' = 'Cannot connect to / set the printer. Win11 22H2+ client: option B. Also option 1 on the server, try the IP instead of the name, or option 7.'
        '79'  = 'Timeout: Win11 22H2+ client using RPC over TCP. Option B on the client, then option 8. Server: firewall RPC step (C1/C3). Fallback: option 7.'
        'bc4' = 'No printers found: Win11 22H2 RPC over TCP. Option B on the client.'
        '6d1' = 'Procedure not found (RPC). Option B on the client.'
        'bcb' = 'Driver install blocked by Point and Print. Option 6 on the client, or install the driver locally and use option 7.'
        '7c'  = 'Driver install blocked or wrong driver. Option 6, or option 7 with a local driver.'
        '5'   = 'Access denied. Option 8 with an account that exists on the host; check share permissions.'
        '35'  = 'Network path not found. Options 3 + 4 on both PCs; run the target host test.'
        '43'  = 'Network name not found. Check the share name; option 3 on the host.'
        '3e3' = 'Operation aborted. Option 2 on both PCs, then option 6.'
    }
    ""
    if ($m.ContainsKey($c)) { "----- 0x$($c.PadLeft(8, '0')) -----"; $m[$c] }
    else { "No entry for '$env:PL_CODE'. Known: 11b, 709, 79, bc4, 6d1, bcb, 7c, 5, 35, 43, 3e3. Run the target host test." }
}
