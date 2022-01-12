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

Run server as scheduled task
```
$port = 80;
$dir = "C:\PowershellWebServer"
New-Item -ItemType Directory -Force -Path $dir
New-NetFirewallRule -DisplayName 'PowershellWebServer' -Profile @('Domain', 'Private', 'Public') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @($port);
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/iarovyi/PowershellWebServer/master/Run-WebServer.ps1' -OutFile "$dir\Run-WebServer.ps1"
@"
if (`$(Test-NetConnection -ComputerName $env:computername -Port $port).TcpTestSucceeded){
  Write-Host 'skipping because port $port is occupied'
  "skipped at `$(Get-Date)" >> $dir\task.log
} else {
  "starting at `$(Get-Date)" >> $dir\task.log
  Start-Process powershell -argument '$dir\Run-WebServer.ps1 http://+:$port/' -WindowStyle Normal #Hidden
  "started" >> $dir\task.log
}
"@ > $dir\Task.ps1
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-executionpolicy bypass -noprofile -file $dir\Task.ps1" 
Register-ScheduledTask -TaskName "PowershellWebServer" -Trigger $trigger -Action $action
```