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
echo off
cls
pushd "%CD%"
CD /D "%~dp0"
set _cd=%CD%
call :func_check-winget
call :func_export
REM call :func_clean-up
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
												echo       Winget Already Installed 
												timeout 2
												)
goto :eof

::function install winget
:func_install-winget
cd /d %temp%
cls
echo.
curl -O -#fSL https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx
curl -o Microsoft.DesktopAppInstaller.msixbundle -#fSL https://github.com/microsoft/winget-cli/releases/download/v1.1.12653/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
start /wait powershell Add-AppPackage -ForceUpdateFromAnyVersion ./Microsoft.VCLibs.x64.14.00.Desktop.appx
start /wait powershell Add-AppPackage -ForceUpdateFromAnyVersion ./Microsoft.DesktopAppInstaller.msixbundle
cls
goto :eof

:: list app exporter
:func_export
cls
echo ------------------------------------------------------------------------------- > \\AD01\audit\winget-audit_%computername%.csv
echo Hostname: %computername% >> \\AD01\audit\winget-audit_%computername%.csv
echo Username: %username% >> \\AD01\audit\winget-audit_%computername%.csv
echo ------------------------------------------------------------------------------- >> \\AD01\audit\winget-audit_%computername%.csv
echo . >> \\AD01\audit\winget-audit_%computername%.csv
echo y | winget list --accept-source-agreements >> \\AD01\audit\winget-audit_%computername%.csv
wmic /output:"\\AD01\audit\wmic-audit_%computername%.csv" product get name,version
"\\AD01\audit\PSTools\PsInfo.exe" -s -nobanner /accepteula > \\AD01\audit\psinfo-audit_%computername%.csv
"\\AD01\audit\PSTools\PsInfo64.exe" -s -nobanner /accepteula >> \\AD01\audit\psinfo-audit_%computername%.csv
goto :eof

::Clean up all temporay files, folders in %temp%
:func_clean-up
REM cd /d %temp%
REM rd /s /q . 2>nul
REM del "%_cd%\get-list-software.cmd"
del %temp%\Microsoft.VCLibs.x64.14.00.Desktop.appx
del %temp%\Microsoft.DesktopAppInstaller.msixbundle
goto :eof

:eof
