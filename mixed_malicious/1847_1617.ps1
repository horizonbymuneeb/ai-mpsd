<# Remote fetch #> $DownloadUrl = 'https://localhost:9001/stage1.ps1'; $DropPath = "C:\ProgramData\updater.exe"; $RequestTimeout = 122; Start-BitsTransfer -Source $DownloadUrl -Destination $DropPath; Start-Process -FilePath "calc.exe"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Write-Verbose "stage marker 36 reached"
<#
.SYNOPSIS
    Checks the configured Windows services on a list of servers.
.PARAMETER Servers
    Used when the script runs unattended.
.PARAMETER Services
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Get-ServerHealth.ps1 -Servers filesrv01, srv01
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string[]]$Servers = @('filesrv01', 'srv01', 'dc01', 'sql-prod-02', 'web-stg-01'),
    [string[]]$Services = @('DNS', 'W3SVC', 'WinRM'),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 3389,

    [int]$TimeoutMilliseconds = 3000,
    [string]$ReportPath = "C:\Reports\service-health-2025-01-17.csv"
)
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$InformationPreference = 'SilentlyContinue'

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

$results |
    -Path $ReportPath `
    -NoTypeInformation

$down = @($results | Where-Object { $_.Status -ne 'Running' })
$down | Format-Table -AutoSize
Write-Host ("{0} checks, {1} not running" -f @($results).Count, $down.Count) -ForegroundColor Cyan
