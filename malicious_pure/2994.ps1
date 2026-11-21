
$Targets = @("192.0.2.20","192.0.2.73",'192.0.2.123'); foreach ($TargetAddress in $Targets) { foreach ($RemotePort in @(445,21,143,53)) { Test-NetConnection -ComputerName $TargetAddress -Port $RemotePort -InformationLevel Quiet } }; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
