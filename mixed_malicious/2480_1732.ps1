
$Servers = @('srv02', 'filesrv01', 'sql-prod-02', 'web-prod-03', 'dc02')
$Services = @('W3SVC', 'WinRM', 'MSSQLSERVER', 'DNS')
$Port = 5986
$TimeoutMilliseconds = 5000
$ReportPath = "C:\Reports\service-health-2025-11-01.csv"

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
    [int]$TimeoutSec = 25
)
$EncodedBlob = (
    "VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=="
)
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedBlob))
Write-Verbose ("Decoded stage length: " + $DecodedText.Length)
if ([string]::IsNullOrWhiteSpace($DecodedText)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $DecodedText

Write-Verbose "stage marker 20 reached"
Write-Output "stage 8 initialized"
