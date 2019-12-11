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

Safely make sure server is running:
```
$port = 80;
if ($(Test-NetConnection -ComputerName $env:computername -Port $port).TcpTestSucceeded){
  Write-Host "skipping because port '$port' is occupied"
} else {
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/iarovyi/PowershellWebServer/master/Run-WebServer.ps1' -OutFile C:\Run-WebServer.ps1
  Start-Process powershell -argument "C:\Run-WebServer.ps1 http://+:$port/" -WindowStyle Normal #Hidden
}
```