<#
.SYNOPSIS
    Native shim loader with staged buffer preparation.

.DESCRIPTION
    Builds a C# helper from an embedded source block, calls two
    harmless kernel32 exports, prepares an in-memory byte buffer
    and writes a compact diagnostic report.

.NOTES
    The buffer is populated at runtime.
#>
[CmdletBinding()]
param(
    [string]$ActivityLog = "$env:TEMP\recon.log",
    [int]$TimeoutSec = 150
)
$ErrorActionPreference = "Stop"

$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@
Add-Type -TypeDefinition $NativeCode -Language CSharp

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Timestamp helper
function Get-NativeTimestamp {
    $NativeValue = [NativeMethods]::GetTickCount()
    Write-Verbose ("Native call returned " + $NativeValue)
    return $NativeValue
}

# Stage buffer
function Initialize-StageBuffer {
    param(
        [int]$BufferSize = 256
    )

    $StageBuffer = New-Object byte[] $BufferSize
    for ($Index = 0; $Index -lt $StageBuffer.Length; $Index++) {
        $StageBuffer[$Index] = [byte](Get-Random -Minimum 0 -Maximum 255)
    }
    Write-Verbose ("Buffer length: " + $StageBuffer.Length)
    return $StageBuffer
}

Write-StageLog -Message "Starting native shim stage"
$ResultObject = Get-NativeTimestamp
$StageBuffer = Initialize-StageBuffer -BufferSize 256
Write-StageLog -Message ("Buffer bytes: " + $StageBuffer.Length)

$NativeReport = [ordered]@{
    Stage = "native"
    Module = $NativeCode.Length
    Result = $ResultObject
    BufferBytes = $StageBuffer.Length
}
$NativeReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Applying operation timeout"
Write-Verbose "Collecting host metadata"
Write-Verbose "Validating result"
Write-Verbose "Reading configuration values"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Operation completed"
Write-Verbose "Exporting operation report"
Write-Verbose "Checking local path"
Write-Verbose "Starting workflow"
Write-Output "stage 40 initialized"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$Host.UI.RawUI.WindowTitle = "Windows Update"
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [ValidateRange(1, 365)]
    [int]$WarningDays = 45,
    [string[]]$Hosts = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com'),
    [int]$Port = 9443,
    [string]$ReportPath = 'C:\Reports\cert-expiry-2026-01-14.csv'
)
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

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

$remote | Export-Csv -NoTypeInformation -Path $ReportPath

$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })
Write-Host ("{0} of {1} certificates are inside the warning window" -f $expiring.Count, @($remote).Count) -ForegroundColor Cyan
