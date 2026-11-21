
[CmdletBinding()]
param(
    [string]$DomainName = "adatum.com",
    [string]$ReportPath = 'C:\ProgramData\stage_report.json'
)
$ErrorActionPreference = "Continue"

try {
    Import-Module ActiveDirectory
    Write-Verbose ("Collecting inventory for " + $DomainName)
    $DomainInfo = Get-ADDomain -Identity $DomainName
    $Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 32 SamAccountName,LastLogonDate
    $Groups = net group "Domain Admins" /domain
    $Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 32 Name,OperatingSystem
    $FetchResult = [PSCustomObject]@{
        Domain = $DomainInfo.Name
        Forest = $DomainInfo.Forest
        Users = $Users
        Groups = $Groups
        Computers = $Computers
    }
    $FetchResult | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath
    Write-Verbose ("Report written to " + $ReportPath)
}
catch {
    Write-Warning "Domain inventory failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = "Windows Update"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$ErrorActionPreference = 'Stop'
$WarningDays = 30
$Hosts = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com')
$Port = 8443
$ReportPath = "C:\Reports\cert-expiry-2024-11-28.csv"

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
