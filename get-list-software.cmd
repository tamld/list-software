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
::Method 1: using Sysinternal - psinfo.exe
::Method 2: using winget utilities 
:main
Title Main
echo off
cls
pushd "%CD%"
CD /D "%~dp0"
set _cd=%CD%
call :func_check-winget
call :func_export
call :func_check-WO-licenses
call :func_clean-up
goto :eof

::Install winget
::Check Winget if installed
:func_check-winget
cls
winget -v >nul
if ERRORLEVEL 1 (cls
				echo.
				echo Installing Winget
				call :func_install-winget) else (cls
												echo.
												echo  Winget Already Installed 
												timeout 2
												)
goto :eof

::function install winget
:func_install-winget
Title Install Winget
cd /d %temp%
cls
echo.
curl -O -#fSL https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
curl -o Microsoft.DesktopAppInstaller.msixbundle -#fSL https://github.com/microsoft/winget-cli/releases/download/v1.1.12653/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
start /wait powershell Add-AppPackage -ForceUpdateFromAnyVersion ./Microsoft.VCLibs.x64.14.00.Desktop.appx
start /wait powershell Add-AppPackage -ForceUpdateFromAnyVersion ./Microsoft.DesktopAppInstaller.msixbundle
cls
goto :eof

:: function obtain app installed
:func_export
Title Export all installed apps
cls
echo ------------------------------------------------------------------------------- > \\AD01\audit\%computername%_winget-audit.csv
echo Hostname: %computername% >> \\AD01\audit\%computername%_winget-audit.csv
echo Username: %username% >> \\AD01\audit\%computername%_winget-audit.csv
echo ------------------------------------------------------------------------------- >> \\AD01\audit\%computername%_winget-audit.csv
echo . >> \\AD01\audit\%computername%_winget-audit.csv
echo y | winget list --accept-source-agreements >> \\AD01\audit\%computername%_winget-audit.csv
wmic /output:"\\AD01\audit\%computername%_wmic-audit.csv" product get name,version
"\\AD01\audit\PSTools\PsInfo.exe" -s -nobanner /accepteula > \\AD01\audit\%computername%_psinfo-audit.csv
"\\AD01\audit\PSTools\PsInfo64.exe" -s -d -nobanner /accepteula >> \\AD01\audit\%computername%_psinfo-audit.csv
goto :eof

::Clean up all temporay files, folders in %temp%
:func_clean-up
REM cd /d %temp%
REM rd /s /q . 2>nul
REM del "%_cd%\get-list-software.cmd"
del %temp%\Microsoft.VCLibs.x64.14.00.Desktop.appx
del %temp%\Microsoft.DesktopAppInstaller.msixbundle
goto :eof

::Check Windows - Office licenses
:func_check-WO-licenses
::Show windows license
cd %windir%\system32
cscript slmgr.vbs /dli > \\AD01\audit\%computername%_WindowsOffce-audit.csv
cscript slmgr.vbs /xpr >> \\AD01\audit\%computername%_WindowsOffce-audit.csv
::Show office license
for %%a in (4,5,6) do (if exist "%ProgramFiles%\Microsoft Office\Office1%%a\ospp.vbs" (cd /d "%ProgramFiles%\Microsoft Office\Office1%%a")
if exist "%ProgramFiles% (x86)\Microsoft Office\Office1%%a\ospp.vbs" (cd /d "%ProgramFiles% (x86)\Microsoft Office\Office1%%a"))
cls
cscript ospp.vbs /dstatus >>\\AD01\audit\%computername%_WindowsOffce-audit.csv
goto :eof

:eof
