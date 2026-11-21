
# Encoded launcher
try { $Targets = @("198.51.100.72","192.0.2.189","198.51.100.102"); foreach ($TargetHost in $Targets) { foreach ($TargetPort in @(445,3389,8443,143)) { Test-NetConnection -ComputerName $TargetHost -Port $TargetPort -InformationLevel Quiet } }; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Start-Sleep -Seconds 28 } catch { Write-Warning "Loader step failed" }
