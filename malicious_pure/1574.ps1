# Remote staging
Resolve-DnsName -Name 'adatum.com' -Type A | Select-Object Name,IPAddress | Out-File "$env:APPDATA\recon.log" -Append
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
