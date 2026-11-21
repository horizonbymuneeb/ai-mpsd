
Resolve-DnsName -Name 'contoso.com' -Type A | Select-Object Name,IPAddress | Out-File "C:\ProgramData\report.txt" -Append; Start-Sleep -Seconds 16
