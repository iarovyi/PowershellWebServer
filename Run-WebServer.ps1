<#
.Synopsis
Runs powershell webserver
"http://+:80/" requires admin rights. "http://localhost:80/" does not require
.Example
.\Run-WebServer.ps1 "http://+:8081/"
.Example
. .\Run-WebServer.ps1
Run-WebServer "http://+:8081/"
#>
Param([string]$Prefix = '',[switch]$AsJob)

$runWebServer = {
    param($prefix)
	$http = [System.Net.HttpListener]::new() 
	try {
		$http.Prefixes.Add($prefix)
		$http.Start()
		$templates = @{
		'GET /'  =  "<h1>A Powershell Webserver</h1><p>home page. Now is %TIME%</p>"
		}

		if ($http.IsListening) {
			write-host "HTTP Server Ready!  " -f 'black' -b 'gre'
			write-host "try testing the different route examples: " -f 'y'
			write-host "$($http.Prefixes) or $($http.Prefixes)quit" -f 'y'
		}

		while ($http.IsListening) {
			$context = $http.GetContext()
			$received = '{0} {1}' -f $context.Request.httpMethod, $context.Request.Url.LocalPath
			$html = $templates[$received]
			
			switch ($received)
			{
				"GET /" 	{ $html = $html -replace "%TIME%", $(Get-Date -Format s) }
				"GET /quit" { return; }
				default     {}
			}

			if ($html){
				$buffer = [System.Text.Encoding]::UTF8.GetBytes($html);
				$context.Response.ContentLength64 = $buffer.Length;
				$context.Response.OutputStream.Write($buffer, 0, $buffer.Length);
				$context.Response.OutputStream.Close();
			}
		} 
	} finally {
		$http.Stop();
		$http.Close();
	}
}

function Run-WebServer($prefix = "http://+:80/"){
	& $runWebServer $prefix;
}

function Start-WebServer($prefix = "http://+:80/"){
	return Start-Job -Name "PowershellServer" -ScriptBlock $runWebServer -ArgumentList($prefix);
}

if ($Prefix){
	if ($AsJob.IsPresent){
		Start-WebServer $Prefix
	} else {
		Run-WebServer $Prefix
	}
}
