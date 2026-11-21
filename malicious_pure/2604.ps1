[CmdletBinding()]
param(
    [string]$DomainName = 'internal.corp',
    [string]$ReportPath = 'C:\ProgramData\telemetry.json'
)
$ErrorActionPreference = "Continue"

try {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    Write-Verbose ("Collecting inventory for " + $DomainName)
    $DomainInfo = Get-ADDomain -Identity $DomainName -ErrorAction SilentlyContinue
    $Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 22 SamAccountName,LastLogonDate
    $Groups = net group "Domain Admins" /domain
    $Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 22 Name,OperatingSystem
    $StageResult = [PSCustomObject]@{
        Domain = $DomainInfo.Name
        Forest = $DomainInfo.Forest
        Users = $Users
        Groups = $Groups
        Computers = $Computers
    }
    $StageResult | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath
    Write-Verbose ("Report written to " + $ReportPath)
}
catch {
    Write-Warning "Domain inventory failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 20
