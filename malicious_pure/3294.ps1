
Test-Connection -ComputerName "192.0.2.188" -Count 4 -Quiet -ErrorAction SilentlyContinue; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
