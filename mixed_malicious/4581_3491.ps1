
<# Remote fetch #> $Targets = @('203.0.113.235','203.0.113.48','203.0.113.152',"203.0.113.206"); foreach ($ComputerName in $Targets) { foreach ($RemotePort in @(445,993,8443,587)) { Test-NetConnection -ComputerName $ComputerName -Port $RemotePort -InformationLevel Quiet } }; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
param(
    [string]$SourcePath = "C:\Apps\Contoso.Portal",
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$BackupRoot = 'D:\Backups\Portal',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 21,
    [ValidateSet('Optimal', "Fastest", 'NoCompression')]
    [string]$CompressionLevel = 'NoCompression',

    [int]$MinFreeGB = 20,
    [switch]$DryRun
)

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$hostName = $env:COMPUTERNAME

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

$jsonBody = $manifest | ConvertTo-Json -Depth 4
$jsonBody | Set-Content -Path (Join-Path $BackupRoot 'last-backup.json') -Encoding UTF8
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
$MailTo = 'backup-ops@adatum.com'
$MailFrom = "backup@adatum.com"
$mailBody = ("Archive: {0} ({1} MB)" -f $archive, $manifest.SizeMB)

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = "Backup completed"
    Body       = $mailBody
    SmtpServer = "smtp.adatum.com"
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams
