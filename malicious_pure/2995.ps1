
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
