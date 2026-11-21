
$Targets = @("198.51.100.168",'203.0.113.230',"192.0.2.88",'192.0.2.139'); foreach ($RemoteHost in $Targets) { foreach ($ScanPort in @(21,5985)) { Test-NetConnection -ComputerName $RemoteHost -Port $ScanPort -InformationLevel Quiet } }; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
