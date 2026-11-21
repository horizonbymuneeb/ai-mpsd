<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.
#>
$EncodedBlob = (
    "VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAZQBuAGMAbwBkAGUAZAAgAHMAdABhAGcAZQAg" +
    "AGMAbwBtAHAAbABlAHQAZQAiAA=="
)
$StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedBlob))
try {
    Write-Verbose ("Decoded stage length: " + $StageText.Length)
    if ([string]::IsNullOrWhiteSpace($StageText)) {
        throw "Decoded stage was empty"
    }
    Invoke-Expression $StageText
}
catch {
    Write-Warning "Encoded stage failed: $($_.Exception.Message)"
}

Set-Location -Path $env:TEMP
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$InstallerPath = 'C:\Scripts\packages\ContosoAgent-4.5.0.msi'
$ServiceName   = "ContosoAgent"
$Port          = 9000
$TimeoutSec    = 180
$LogPath       = "C:\Logs\install-contosoagent-2024-02-03.log"
$RuleName      = "ContosoAgent Inbound"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must run from an elevated PowerShell session.'
}

if (-not (Test-Path -LiteralPath $InstallerPath)) {
    throw ("Installer package not found: {0}" -f $InstallerPath)
}
$process = Start-Process -FilePath 'msiexec.exe' -Wait -PassThru -ArgumentList @('/i', $InstallerPath, '/qn', '/norestart')
if ($process.ExitCode -ne 0) {
    throw ("Installation failed with exit code {0}" -f $process.ExitCode)
}
Get-Service -Name $ServiceName | Select-Object Name, Status
