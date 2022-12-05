:: Remote get list software

::Get list installed software by batch scripts
::Support Windows 10, version greater than 1703
Title Obtain a list of all installed software.
echo off
cls
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo  Run CMD as Administrator...
    goto :goUAC
) else (
 goto :main )

:goUAC
echo off
cls
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
set params = %*:"=""
echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs"
exit /B

::Main
:main
Title Main
echo off
cls
pushd "%CD%"
CD /D "%~dp0"
set _cd=%CD%
if not exist %temp%\audit mkdir %temp%\audit
call :func_check-winget
call :func_install-7zip
call :func_export
call :func_check-WO-licenses
call :func_zip-to-archive
call :func_clean-up
goto :eof

::Install winget
::Check Winget if installed
:func_check-winget
cls
winget -v >nul
if ERRORLEVEL 1 (echo Installing Winget
				call :func_install-winget) else (echo  Winget Already Installed
												timeout 1
												)
goto :eof

::function install winget
:func_install-winget
Title Install Winget
echo off
cd /d %temp%
cls
echo.
curl -O -#fSL https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
curl -o Microsoft.DesktopAppInstaller.msixbundle -#fSL https://github.com/microsoft/winget-cli/releases/download/v1.1.12653/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
start /wait powershell Add-AppPackage -ForceUpdateFromAnyVersion ./Microsoft.VCLibs.x64.14.00.Desktop.appx
start /wait powershell Add-AppPackage -ForceUpdateFromAnyVersion ./Microsoft.DesktopAppInstaller.msixbundle
cls
goto :eof

:func_export
:: function obtain app installed
Title Export software installed
echo off
call :func_get-list-software-winget
call :func_get-list-software-powershell
goto :eof


:func_get-list-software-winget
:: function
Title Export all installed apps by winget
echo off
cls
echo ------------------------------------------------------------------------------- > %temp%\audit\%computername%_winget-audit.csv
echo Hostname: %computername% >> %temp%\audit\%computername%_winget-audit.csv
echo Username: %username% >> %temp%\audit\%computername%_winget-audit.csv
echo ------------------------------------------------------------------------------- >> %temp%\audit\%computername%_winget-audit.csv
echo . >> %temp%\audit\%computername%_winget-audit.csv
echo y | winget list --accept-source-agreements >> %temp%\audit\%computername%_winget-audit.csv
goto :eof

:func_get-list-software-powershell
::Powershell get list software installed on the computer
::This function will return a list of software installed on the computer either x86 or x64
Title Export all installed apps by powershell
cls
::Export file powershell for audit
echo off
powershell -Command Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
echo ^$paths ^= 'HKLM:^\Software^\Microsoft^\Windows^\CurrentVersion^\Uninstall^\*', > %temp%\audit\%computername%_powershell-audit.ps1
echo         'HKLM:^\Software^\WOW6432Node^\Microsoft^\Windows^\CurrentVersion^\Uninstall^\*' >> %temp%\audit\%computername%_powershell-audit.ps1
REM echo ^$app^=Get-ItemProperty ^$paths ^| select DisplayName,Version,UninstallString >> %temp%\audit\%computername%_powershell-audit.ps1
echo ^$app^=Get-ItemProperty ^$paths ^| select DisplayName,Version >> %temp%\audit\%computername%_powershell-audit.ps1
echo echo ^$app ^> ^$env:temp^\audit^\^$env:computername'_powershell-audit.csv' >> %temp%\audit\%computername%_powershell-audit.ps1
powershell -Command %temp%\audit\%computername%_powershell-audit.ps1
goto :eof

:func_clean-up
::Clean up all temporay files, folders in %temp%
Title Clean up temp folder
echo off
cd /d %temp%
rd /s /q . 2>nul
del "%_cd%\get-list-*.cmd"
REM del %temp%\Microsoft.VCLibs.x64.14.00.Desktop.appx
REM del %temp%\Microsoft.DesktopAppInstaller.msixbundle
goto :eof


:func_check-WO-licenses
::Check Windows - Office licenses
cd %windir%\system32
cscript slmgr.vbs /dli > %temp%\audit\%computername%_WindowsOffce-audit.csv
cscript slmgr.vbs /xpr >> %temp%\audit\%computername%_WindowsOffce-audit.csv
::Show office license
for %%a in (4,5,6) do (if exist "%ProgramFiles%\Microsoft Office\Office1%%a\ospp.vbs" (cd /d "%ProgramFiles%\Microsoft Office\Office1%%a")
if exist "%ProgramFiles% (x86)\Microsoft Office\Office1%%a\ospp.vbs" (cd /d "%ProgramFiles% (x86)\Microsoft Office\Office1%%a"))
cls
cscript ospp.vbs /dstatus >>%temp%\audit\%computername%_WindowsOffce-audit.csv
goto :eof



:func_install-7zip
::Function install 7zip
::Check 7zip is exist
if exist "C:\Program Files\7-Zip" (goto :eof) else (call :func_install-winget
													echo y | winget install 7zip.7zip)
::associate files type with 7zip
assoc .zip=7-Zip
assoc .rar=7-Zip
assoc .tar=7-Zip
goto :eof

:func_zip-to-archive
::function create zip all audit files in the %temp%\audit
cls
"%ProgramFiles%\7-Zip\7z.exe" a %userprofile%\Desktop\%computername%_audit.zip %temp%\audit\*.csv
goto :eof

:eof