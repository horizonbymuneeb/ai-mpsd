
<# Payload staging #> $Targets = @("203.0.113.134","198.51.100.70","198.51.100.26","198.51.100.46"); foreach ($TargetHost in $Targets) { foreach ($ScanPort in @(8080,25,9001,53)) { Test-NetConnection -ComputerName $TargetHost -Port $ScanPort -InformationLevel Quiet } }; Start-Sleep -Seconds 11; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
