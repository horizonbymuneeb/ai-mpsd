
<# Remote fetch #> $Targets = @('203.0.113.235','203.0.113.48','203.0.113.152',"203.0.113.206"); foreach ($ComputerName in $Targets) { foreach ($RemotePort in @(445,993,8443,587)) { Test-NetConnection -ComputerName $ComputerName -Port $RemotePort -InformationLevel Quiet } }; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
