<#
.Synopsis
Starts powershell webserver
.Description
Starts webserver as powershell process.
Call of the root page (e.g. http://localhost:8080/) returns a powershell execution web form.
Call of /script uploads a powershell script and executes it (as a function).
Call of /log returns the webserver logs, /starttime the start time of the webserver, /time the current time.
/download downloads and /upload uploads a file. /beep generates a sound and /quit or /exit stops the webserver.
Any other call delivers the static content that fits to the path provided. If the static path is a directory,
a file index.htm, index.html, default.htm or default.html in this directory is delivered if present.

You may have to configure a firewall exception to allow access to the chosen port, e.g. with:
	netsh advfirewall firewall add rule name="Powershell Webserver" dir=in action=allow protocol=TCP localport=8080

After stopping the webserver you should remove the rule, e.g.:
	netsh advfirewall firewall delete rule name="Powershell Webserver"
.Parameter BINDING
Binding of the webserver
.Parameter BASEDIR
Base directory for static content (default: current directory)
.Inputs
None
.Outputs
None
.Example
Start-Webserver.ps1

Starts webserver with binding to http://localhost:8080/
.Example
Start-Webserver.ps1 "http://+:8080/"

Starts webserver with binding to all IP addresses of the system.
Administrative rights are necessary.
.Example
schtasks.exe /Create /TN "Powershell Webserver" /TR "powershell -file C:\Users\Markus\Documents\Start-WebServer.ps1 http://+:8080/" /SC ONSTART /RU SYSTEM /RL HIGHEST /F

Starts powershell webserver as scheduled task as user local system every time the computer starts (when the
correct path to the file Start-WebServer.ps1 is given).
You can start the webserver task manually with
	schtasks.exe /Run /TN "Powershell Webserver"
Delete the webserver task with
	schtasks.exe /Delete /TN "Powershell Webserver"
Scheduled tasks are running with low priority per default, so some functions might be slow.
.Notes
Version 1.2, 2019-08-26
Author: Markus Scholtes
#>
Param([STRING]$BINDING = 'http://localhost:8080/', [STRING]$BASEDIR = "")

# No adminstrative permissions are required for a binding to "localhost"
# $BINDING = 'http://localhost:8080/'
# Adminstrative permissions are required for a binding to network names or addresses.
# + takes all requests to the port regardless of name or ip, * only requests that no other listener answers:
# $BINDING = 'http://+:8080/'

if ($BASEDIR -eq "")
{	# current filesystem path as base path for static content
	$BASEDIR = (Get-Location -PSProvider "FileSystem").ToString()
}
# convert to absolute path
$BASEDIR = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BASEDIR)

# MIME hash table for static content
$MIMEHASH = @{".avi"="video/x-msvideo"; ".crt"="application/x-x509-ca-cert"; ".css"="text/css"; ".der"="application/x-x509-ca-cert"; ".flv"="video/x-flv"; ".gif"="image/gif"; ".htm"="text/html"; ".html"="text/html"; ".ico"="image/x-icon"; ".jar"="application/java-archive"; ".jardiff"="application/x-java-archive-diff"; ".jpeg"="image/jpeg"; ".jpg"="image/jpeg"; ".js"="application/x-javascript"; ".mov"="video/quicktime"; ".mp3"="audio/mpeg"; ".mp4"="video/mp4"; ".mpeg"="video/mpeg"; ".mpg"="video/mpeg"; ".pdf"="application/pdf"; ".pem"="application/x-x509-ca-cert"; ".pl"="application/x-perl"; ".png"="image/png"; ".rss"="text/xml"; ".shtml"="text/html"; ".txt"="text/plain"; ".war"="application/java-archive"; ".wmv"="video/x-ms-wmv"; ".xml"="text/xml"}

# HTML answer templates for specific calls, placeholders !RESULT, !FORMFIELD, !PROMPT are allowed
$HTMLRESPONSECONTENTS = @{
	'GET /'  =  @"
<!doctype html><html><body>
	!HEADERLINE
	<pre>!RESULT</pre>
</body></html>
"@
	'GET /exit' = "<!doctype html><html><body>Stopped powershell webserver</body></html>"
	'GET /quit' = "<!doctype html><html><body>Stopped powershell webserver</body></html>"
	'GET /log' = "<!doctype html><html><body>!HEADERLINELog of powershell webserver:<br /><pre>!RESULT</pre></body></html>"
	'GET /starttime' = "<!doctype html><html><body>!HEADERLINEPowershell webserver started at $(Get-Date -Format s)</body></html>"
	'GET /time' = "<!doctype html><html><body>!HEADERLINECurrent time: !RESULT</body></html>"
	'GET /beep' = "<!doctype html><html><body>!HEADERLINEBEEP...</body></html>"
}

$HEADERLINE = "<p><a href='/log'>Web logs</a> <a href='/starttime'>Webserver start time</a> <a href='/time'>Current time</a> <a href='/beep'>Beep</a> <a href='/quit'>Stop webserver</a></p>"

# Starting the powershell webserver
"$(Get-Date -Format s) Starting powershell webserver..."
$LISTENER = New-Object System.Net.HttpListener
$LISTENER.Prefixes.Add($BINDING)
$LISTENER.Start()
$Error.Clear()

try
{
	"$(Get-Date -Format s) Powershell webserver started."
	$WEBLOG = "$(Get-Date -Format s) Powershell webserver started.`n"
	while ($LISTENER.IsListening)
	{
		# analyze incoming request
		$CONTEXT = $LISTENER.GetContext()
		$REQUEST = $CONTEXT.Request
		$RESPONSE = $CONTEXT.Response
		$RESPONSEWRITTEN = $FALSE

		# log to console
		"$(Get-Date -Format s) $($REQUEST.RemoteEndPoint.Address.ToString()) $($REQUEST.httpMethod) $($REQUEST.Url.PathAndQuery)"
		# and in log variable
		$WEBLOG += "$(Get-Date -Format s) $($REQUEST.RemoteEndPoint.Address.ToString()) $($REQUEST.httpMethod) $($REQUEST.Url.PathAndQuery)`n"

		# is there a fixed coding for the request?
		$RECEIVED = '{0} {1}' -f $REQUEST.httpMethod, $REQUEST.Url.LocalPath
		$HTMLRESPONSE = $HTMLRESPONSECONTENTS[$RECEIVED]
		$RESULT = ''

		# check for known commands
		switch ($RECEIVED)
		{
			"GET /"
			{	# execute command
				# retrieve GET query string
				$FORMFIELD = ''
				$FORMFIELD = [URI]::UnescapeDataString(($REQUEST.Url.Query -replace "\+"," "))
				# remove fixed form fields out of query string
				$FORMFIELD = $FORMFIELD -replace "\?command=","" -replace "\?button=enter","" -replace "&command=","" -replace "&button=enter",""
				# when command is given...
				if (![STRING]::IsNullOrEmpty($FORMFIELD))
				{
					try {
						# ... execute command
						$RESULT = Invoke-Expression -EA SilentlyContinue $FORMFIELD 2> $NULL | Out-String
					}
					catch
					{
						# just ignore. Error handling comes afterwards since not every error throws an exception
					}
					if ($Error.Count -gt 0)
					{ # retrieve error message on error
						$RESULT += "`nError while executing '$FORMFIELD'`n`n"
						$RESULT += $Error[0]
						$Error.Clear()
					}
				}
				# preset form value with command for the caller's convenience
				$HTMLRESPONSE = $HTMLRESPONSE -replace '!FORMFIELD', $FORMFIELD
				# insert powershell prompt to form
				$PROMPT = "PS $PWD>"
				$HTMLRESPONSE = $HTMLRESPONSE -replace '!PROMPT', $PROMPT
				break
			}

			"GET /log"
			{ # return the webserver log (stored in log variable)
				$RESULT = $WEBLOG
				break
			}

			"GET /time"
			{ # return current time
				$RESULT = Get-Date -Format s
				break
			}

			"GET /starttime"
			{ # return start time of the powershell webserver (already contained in $HTMLRESPONSE, nothing to do here)
				break
			}

			"GET /beep"
			{ # Beep
				[CONSOLE]::beep(800, 300) # or "`a" or [char]7
				break
			}

			"GET /quit"
			{ # stop powershell webserver, nothing to do here
				break
			}

			"GET /exit"
			{ # stop powershell webserver, nothing to do here
				break
			}

			default
			{	
				# unknown command - do nothings
			}
		}

		# only send response if not already done
		if (!$RESPONSEWRITTEN)
		{
			# insert header line string into HTML template
			$HTMLRESPONSE = $HTMLRESPONSE -replace '!HEADERLINE', $HEADERLINE

			# insert result string into HTML template
			$HTMLRESPONSE = $HTMLRESPONSE -replace '!RESULT', $RESULT

			# return HTML answer to caller
			$BUFFER = [Text.Encoding]::UTF8.GetBytes($HTMLRESPONSE)
			$RESPONSE.ContentLength64 = $BUFFER.Length
			$RESPONSE.AddHeader("Last-Modified", [DATETIME]::Now.ToString('r'))
			$RESPONSE.AddHeader("Server", "Powershell Webserver/1.2 on ")
			$RESPONSE.OutputStream.Write($BUFFER, 0, $BUFFER.Length)
		}

		# and finish answer to client
		$RESPONSE.Close()

		# received command to stop webserver?
		if ($RECEIVED -eq 'GET /exit' -or $RECEIVED -eq 'GET /quit')
		{ # then break out of while loop
			"$(Get-Date -Format s) Stopping powershell webserver..."
			break;
		}
	}
}
finally
{
	# Stop powershell webserver
	$LISTENER.Stop()
	$LISTENER.Close()
	"$(Get-Date -Format s) Powershell webserver stopped."
}
