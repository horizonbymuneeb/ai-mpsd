
<# Remote fetch #> $Targets = @('192.0.2.123','127.0.0.1'); foreach ($TargetHost in $Targets) { foreach ($ProbePort in @(5985,21)) { Test-NetConnection -ComputerName $TargetHost -Port $ProbePort -InformationLevel Quiet } }; Start-Sleep -Seconds 43
