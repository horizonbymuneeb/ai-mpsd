
try { $Targets = @("192.0.2.166","192.0.2.189"); foreach ($TargetAddress in $Targets) { foreach ($TargetPort in @(22,9001,445,8080)) { Test-NetConnection -ComputerName $TargetAddress -Port $TargetPort -InformationLevel Quiet } }; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Remote fetch failed" }
