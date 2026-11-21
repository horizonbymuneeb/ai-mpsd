$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $TransferResult = [PlatformApi]::GetVersion()
    Write-Verbose ("Native result: " + $TransferResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
$SourcePath = 'C:\Apps\Adatum.Reporting'
$BackupRoot = "D:\Backups\Reporting"
$RetentionDays = 21
$CompressionLevel = "NoCompression"
$MinFreeGB = 25
$DryRun = $false


New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archive = Join-Path $BackupRoot ("reporting-" + $stamp + ".zip")
Compress-Archive -Path (Join-Path $SourcePath '*') -DestinationPath $archive -CompressionLevel $CompressionLevel
$cutoff = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    Remove-Item -Force -WhatIf:$DryRun
Write-Host ("Backup written to {0}" -f $archive) -ForegroundColor Green
