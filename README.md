# PowershellWebServer
Simple powershell script that runs web server

Run synchroniously:
```
$port = 8081;
Set-ExecutionPolicy Bypass -Scope Process -Force;
& $([scriptblock]::Create((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/iarovyi/PowershellWebServer/master/Start-WebServer.ps1'))) "http://+:$port/"
```

Run run in parallel:
```
$port = 8081;
Start-Job -Name "PowershellServer" -ScriptBlock {
	param($port)
	Set-ExecutionPolicy Bypass -Scope Process -Force;
	& $([scriptblock]::Create((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/iarovyi/PowershellWebServer/master/Start-WebServer.ps1'))) "http://+:$port/"
} -ArgumentList($port)

#Remove within the same session
#Stop-Job -Name "PowershellServer"
```

Schedule on windows startup:
```
$port = 8081;
$location = "C:\Start-WebServer.ps1";
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/iarovyi/PowershellWebServer/master/Start-WebServer.ps1' -OutFile $location
netsh advfirewall firewall add rule name="Powershell Webserver" dir=in action=allow protocol=TCP localport=$port
schtasks.exe /Create /TN "Powershell Webserver" /TR "powershell -file $location http://+:$port/" /SC ONSTART /RU SYSTEM /RL HIGHEST /F
schtasks /Run /TN "Powershell Webserver"

#Remove
#schtasks.exe /Delete /TN "Powershell Webserver"
#netsh advfirewall firewall delete rule name="Powershell Webserver"
```