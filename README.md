# PowershellWebServer
Simple powershell script that runs web server

Run synchroniously as admin:
```
$port = 80;
#netsh advfirewall firewall add rule name="Powershell Webserver" dir=in action=allow protocol=TCP localport=$port
Set-ExecutionPolicy Bypass -Scope Process -Force;
& $([scriptblock]::Create((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/iarovyi/PowershellWebServer/master/Run-WebServer.ps1'))) "http://+:$port/"
```

Run synchroniously as normal user:
```
$port = 80;
#netsh advfirewall firewall add rule name="Powershell Webserver" dir=in action=allow protocol=TCP localport=$port
Set-ExecutionPolicy Bypass -Scope Process -Force;
& $([scriptblock]::Create((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/iarovyi/PowershellWebServer/master/Run-WebServer.ps1'))) "http://localhost:$port/"
```