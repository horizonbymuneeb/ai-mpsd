
[CmdletBinding()]
param(
    [string]$DomainName = "contoso.com",
    [string]$ReportPath = 'C:\ProgramData\recon.json'
)
$ErrorActionPreference = "Continue"

Import-Module ActiveDirectory
Write-Verbose ("Collecting inventory for " + $DomainName)
$DomainInfo = Get-ADDomain -Identity $DomainName
$Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 37 SamAccountName,LastLogonDate
$Groups = net group "Domain Admins" /domain
$Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 37 Name,OperatingSystem
$OperationResult = [PSCustomObject]@{
    Domain = $DomainInfo.Name
    Forest = $DomainInfo.Forest
    Users = $Users
    Groups = $Groups
    Computers = $Computers
}
$OperationResult | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath
Write-Verbose ("Report written to " + $ReportPath)

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Output "stage 6 initialized"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
