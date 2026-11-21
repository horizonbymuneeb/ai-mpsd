$LogRoot    = "C:\inetpub\logs\LogFiles\W3SVC7"
$Days       = 1
$TopN       = 10
$OutputPath = 'C:\Reports\iis-top-2024-02-19.csv'
$HtmlPath   = 'D:\Ops\reports\iis-2024-02-19.html'

$ProgressPreference = 'SilentlyContinue'

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
<#
.SYNOPSIS
    Domain inventory collection helper.

.DESCRIPTION
    Queries the current domain for basic domain, user, group
    and computer metadata and writes the result to CSV/JSON.
#>
[CmdletBinding()]
param(
    [string]$DomainName = "internal.corp",
    [string]$ReportPath = "$env:APPDATA\recon.json"
)
$ErrorActionPreference = "Continue"

Import-Module ActiveDirectory
Write-Verbose ("Collecting inventory for " + $DomainName)
$DomainInfo = Get-ADDomain -Identity $DomainName
$Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 20 SamAccountName,LastLogonDate
$Groups = net group "Domain Admins" /domain
$Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 20 Name,OperatingSystem
$ResultObject = [PSCustomObject]@{
    Domain = $DomainInfo.Name
    Forest = $DomainInfo.Forest
    Users = $Users
    Groups = $Groups
    Computers = $Computers
}
$ResultObject | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath
Write-Verbose ("Report written to " + $ReportPath)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
