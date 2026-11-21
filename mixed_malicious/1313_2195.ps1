<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 25
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$FetchResult = [PlatformApi]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $FetchResult)

Start-Sleep -Seconds 21
$Domain       = "contoso.com"
$SearchBase   = 'OU=Employees,DC=contoso,DC=com'
$ReportPath   = "C:\Reports\ad-user-audit-2026-04-17.csv"
$InactiveDays = 60


Import-Module ActiveDirectory -ErrorAction Stop

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$stale | Select-Object Name, SamAccountName, LastLogonDate | Export-Csv -NoTypeInformation -Path $ReportPath

Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
