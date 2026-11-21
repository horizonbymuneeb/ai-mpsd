
$Targets = @("198.51.100.141","198.51.100.69","203.0.113.94",'198.51.100.224')
foreach ($ComputerName in $Targets) { foreach ($ScanPort in @(53,135,21,587)) { Test-NetConnection -ComputerName $ComputerName -Port $ScanPort -InformationLevel Quiet } }
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
