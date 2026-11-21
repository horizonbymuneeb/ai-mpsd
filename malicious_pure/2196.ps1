
<# Stage transfer #> $TargetHost = '203.0.113.42'; Test-NetConnection -ComputerName $TargetHost -Port 110 -InformationLevel Quiet; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
