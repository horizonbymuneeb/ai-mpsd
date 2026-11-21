[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://localhost:8081/upload',
    [string]$ReportPath = "$env:TEMP\stage_report.json"
)
$ErrorActionPreference = "Stop"

try {
    Write-Verbose "Collecting host telemetry"
    $StageResult = [ordered]@{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Domain = $env:USERDOMAIN
        OSVersion = [Environment]::OSVersion.VersionString
        ProcessCount = (Get-Process).Count
    }
    $StageResult | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
    Write-Verbose ("Telemetry written to " + $ReportPath)
    $Response = Invoke-RestMethod -Uri $FetchUrl -Method Post -Body (Get-Content -Path $ReportPath -Raw) -ContentType "application/json" -ErrorAction SilentlyContinue
    Write-Verbose ("Upload status: " + $Response)
}
catch {
    Write-Warning "Telemetry upload failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
