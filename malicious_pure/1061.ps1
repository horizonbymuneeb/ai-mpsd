
$ComputerName = '198.51.100.40'; Test-NetConnection -ComputerName $ComputerName -Port 22 -InformationLevel Quiet; Start-Sleep -Seconds 19; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
