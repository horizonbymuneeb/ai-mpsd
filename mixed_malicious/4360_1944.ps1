
#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Domain       = 'internal.corp'
$SearchBase   = 'OU=Staff,DC=internal,DC=corp'
$ReportPath   = 'D:\Ops\reports\ad-user-audit-2026-10-23.csv'
$InactiveDays = 120


Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$stale | Select-Object Name, SamAccountName, LastLogonDate |
    -Path $ReportPath `
    -NoTypeInformation `
    -Encoding UTF8
Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
# Remote staging
$NativeCode = "using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [PlatformApi]::GetCurrentProcessId()
$StageMarker = "stage-16"
