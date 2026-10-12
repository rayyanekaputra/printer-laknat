@echo off
REM ==========================================================
REM  Printer Sharing Fix Toolkit
REM  by IT Indoguna Makassar with Sonnet 5.5
REM ==========================================================
setlocal EnableExtensions
title Printer Sharing Fix Toolkit
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
set "BK=%~dp0PrinterFix.backup"

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
echo   PRINTER SHARING FIX TOOLKIT  (Windows 10 / 11)
echo   by IT Indoguna Makassar with Sonnet 5.5
echo ==========================================================
echo.
echo   [1] Fix 0x0000011b  (disable RPC privacy auth level)
echo   [2] Reset Print Spooler + clear stuck jobs
echo   [3] Enable File/Printer Sharing + Network Discovery
echo   [4] Start/enable required services
echo   [5] Allow insecure guest logons (SMB, 24H2 issues)
echo   [6] Relax Point and Print driver restrictions (0x00000bcb / 0x0000007c)
echo   [7] Add shared printer via local port (bypass 0x11b / 0x709)
echo   [8] Store network credentials for a host (cmdkey)
echo   [9] Diagnostics (spooler, printers, ports, connectivity test)
echo   [A] RUN COMMON FIXES (1 + 2 + 3 + 4)
echo   [R] Restore settings (from backup or Windows defaults)
echo   [0] Exit
echo.
set "choice="
set /p "choice=Select an option: "

if /i "%choice%"=="1" call :fix11b      & goto done
if /i "%choice%"=="2" call :spooler     & goto done
if /i "%choice%"=="3" call :sharing     & goto done
if /i "%choice%"=="4" call :services    & goto done
if /i "%choice%"=="5" call :guestauth   & goto done
if /i "%choice%"=="6" call :pointprint  & goto done
if /i "%choice%"=="7" call :localport   & goto done
if /i "%choice%"=="8" call :creds       & goto done
if /i "%choice%"=="9" call :diag        & goto done
if /i "%choice%"=="A" call :allfixes    & goto done
if /i "%choice%"=="R" call :restore     & goto done
if "%choice%"=="0" exit /b 0
goto menu

:done
echo.
pause
goto menu


:: ==========================================================
:fix11b
echo.
echo [*] Setting RpcAuthnLevelPrivacyEnabled = 0
echo     (Apply on the HOST/print server. Also needed on the client in some setups.)
call :backup
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f
call :spooler
echo [+] Done. Retry connecting to the printer.
goto :eof


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


:: ==========================================================
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


:: ==========================================================
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


:: ==========================================================
:guestauth
echo.
echo [!] WARNING: This allows unauthenticated SMB guest logons.
echo     It lowers security. Use only on trusted/isolated networks.
set "ok="
set /p "ok=Continue? (Y/N): "
if /i not "%ok%"=="Y" goto :eof
call :backup
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f
echo [+] AllowInsecureGuestAuth = 1. Reboot may be needed.
goto :eof


:: ==========================================================
:pointprint
echo.
echo [!] WARNING: This relaxes PrintNightmare protections (Point and Print).
echo     Use only if you trust the print server.
set "ok="
set /p "ok=Continue? (Y/N): "
if /i not "%ok%"=="Y" goto :eof
call :backup
set "PP=HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
reg add "%PP%" /v RestrictDriverInstallationToAdministrators /t REG_DWORD /d 0 /f
reg add "%PP%" /v NoWarningNoElevationOnInstall /t REG_DWORD /d 1 /f
reg add "%PP%" /v UpdatePromptSettings /t REG_DWORD /d 2 /f
call :spooler
echo [+] Point and Print restrictions relaxed.
goto :eof


:: ==========================================================
:localport
echo.
echo This installs the shared printer through a local port that points
echo at the UNC path. Often avoids 0x0000011b / 0x00000709 without registry changes.
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


:: ==========================================================
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
echo.
echo ----- Spooler status -----
sc query spooler | findstr /i "STATE"
echo.
echo ----- RPC privacy setting -----
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled 2>nul || echo Not set (default)
echo.
echo ----- SMB guest logon policy -----
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" /v AllowInsecureGuestAuth 2>nul || echo Not set (default)
echo.
echo ----- Point and Print policy -----
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" 2>nul || echo Not set (default)
echo.
echo ----- Network profile -----
powershell -NoProfile -Command "Get-NetConnectionProfile | Format-Table Name,NetworkCategory -AutoSize"
echo ----- Installed printers -----
powershell -NoProfile -Command "Get-Printer | Format-Table Name,DriverName,PortName,Shared -AutoSize"
echo ----- Stored credentials -----
cmdkey /list | findstr /i "Target"
echo.
set "T="
set /p "T=Host/IP to test SMB (port 445) - leave blank to skip: "
if not "%T%"=="" powershell -NoProfile -Command "Test-NetConnection -ComputerName '%T%' -Port 445 | Format-List ComputerName,RemoteAddress,TcpTestSucceeded"
goto :eof


:: ==========================================================
:allfixes
call :fix11b
call :sharing
call :services
echo.
echo [+] Common fixes complete. Reboot if the issue persists.
goto :eof


:: ==========================================================
:backup
:: Snapshot every setting this tool touches, once. An existing backup is
:: never overwritten, so it always holds the state from before the first fix.
if exist "%BK%\registry.csv" goto :eof
echo [*] Saving original settings to %BK%
if not exist "%BK%" mkdir "%BK%"
powershell -NoProfile -Command "$l=@(@('HKLM:\SYSTEM\CurrentControlSet\Control\Print','RpcAuthnLevelPrivacyEnabled'),@('HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation','AllowInsecureGuestAuth'),@('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint','RestrictDriverInstallationToAdministrators'),@('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint','NoWarningNoElevationOnInstall'),@('HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint','UpdatePromptSettings')); $l | ForEach-Object { $v=(Get-ItemProperty -Path $_[0] -Name $_[1] -ErrorAction SilentlyContinue).($_[1]); [pscustomobject]@{Path=$_[0];Name=$_[1];Exists=($null -ne $v);Value=$v} } | Export-Csv -NoTypeInformation -Path (Join-Path $env:BK 'registry.csv')"
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
