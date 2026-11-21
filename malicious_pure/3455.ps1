<# Host profiling #> $TargetAddress = "127.0.0.1"; Test-NetConnection -ComputerName $TargetAddress -Port 5985 -InformationLevel Quiet; Set-Location -Path $env:TEMP
