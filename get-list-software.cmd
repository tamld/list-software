::Get list installed software by batch scripts
::Support Windows 10, version greater than 1703
echo Getting list software installed in this computer
timeout 5
cls
\\live.sysinternals.com\tools\psinfo.exe -s /accepteula > %temp%\audit_%computername%.txt