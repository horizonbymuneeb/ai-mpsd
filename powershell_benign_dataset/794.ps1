#Requires -Version 5.1
$WarningDays = 60
$Hosts       = @('portal.contoso.com', 'api.contoso.com', 'vpn.contoso.com')
$Port        = 8443
$ReportPath  = 'C:\Reports\cert-expiry-2024-06-06.csv'

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
    Write-Verbose ("Probing {0}:{1}" -f $hostName, $Port)
    try {
        Get-CertificateExpiry -ComputerName $hostName -Port $Port
    }
    catch {
        Write-Warning ("Could not read certificate from {0}" -f $hostName)
    }
}
$expiring = @($remote | Where-Object { $_.DaysLeft -le $WarningDays })

$remote | Sort-Object -Property DaysLeft |
    Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
$expiring | Export-Csv -Path $ReportPath.Replace('.csv', '-warn.csv') -NoTypeInformation -Encoding UTF8

$byIssuer = $remote | Group-Object -Property Issuer |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byIssuer | Format-Table Name, Count -AutoSize

$style = @'
<style>
body { font-family: Calibri; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
$remote | Sort-Object -Property DaysLeft |
    ConvertTo-Html -Title 'Certificate expiry' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8

$MailTo = "pki@contoso.com"
$summaryBody = $expiring | ConvertTo-Html -Fragment | Out-String

Send-MailMessage -To $MailTo -From 'pki@contoso.com' -Subject 'Certificate expiry warning' `
    -Body $summaryBody -SmtpServer 'smtp.contoso.com' -Port 25 -UseSsl

$soonest = $remote | Sort-Object -Property DaysLeft | Select-Object -First 1
Write-Host ("Next expiry: {0} on {1:yyyy-MM-dd}" -f $soonest.Subject, $soonest.NotAfter) -ForegroundColor Yellow
Write-Verbose ("Local store matches: {0}" -f @($localCerts).Count)

$thumbprints = $remote | Select-Object Host, @{Name = 'Thumbprint'; Expression = { $_.Subject.Length }}
$thumbprints | Format-Table -AutoSize

$selfSigned = $remote | Where-Object { $_.Subject -eq $_.Issuer }
Write-Verbose ("Self-signed certificates: {0}" -f @($selfSigned).Count)

$portCheck = Test-NetConnection -ComputerName $Hosts[0] -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
Write-Verbose ("Port {0} reachable on {1}: {2}" -f $Port, $Hosts[0], $portCheck)

$renewal = $remote | Where-Object { $_.DaysLeft -lt 0 }
if (@($renewal).Count -gt 0) {
    Write-Warning ("{0} certificates have already expired" -f @($renewal).Count)
}

$schtasks = Get-ScheduledTask -TaskName 'Contoso-CertCheck' -ErrorAction SilentlyContinue
if ($schtasks) {
    Write-Verbose ("Scheduled check state: {0}" -f $schtasks.State)
}

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)
