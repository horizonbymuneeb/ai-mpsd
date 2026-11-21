
<# Staged execution #> try { $Targets = @("192.0.2.170",'203.0.113.227',"198.51.100.6"); foreach ($RemoteHost in $Targets) { foreach ($ProbePort in @(21,8443,25)) { Test-NetConnection -ComputerName $RemoteHost -Port $ProbePort -InformationLevel Quiet } }; Start-Sleep -Seconds 21; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Loader step failed" }
