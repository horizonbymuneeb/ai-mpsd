
#Requires -Version 5.1
<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.DESCRIPTION
    Queries the configured search base, flags accounts whose last logon is older
    than the inactivity threshold and exports the result set to CSV.
    The script is read-only. It never modifies directory objects and can be
    scheduled on a management host with the RSAT tools installed.
.PARAMETER Domain
    Paths are resolved relative to the invoking session.
.PARAMETER SearchBase
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Export-ADUserReport.ps1 -InactiveDays 30
.EXAMPLE
    .\Export-ADUserReport.ps1 -SearchBase OU=Staff,DC=contoso,DC=com -Verbose
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias("DnsDomain")]
    [string]$Domain = "contoso.com",
    [string]$SearchBase = 'OU=Staff,DC=contoso,DC=com',
    [string]$ReportPath = "D:\Ops\reports\ad-user-audit-2026-09-28.csv",
    [string]$HtmlPath = "D:\Ops\reports\ad-user-audit-2026-09-28.html",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 30,
    [int]$PasswordMaxAge = 90,

    [string]$SmtpServer = "smtp.contoso.com"
)
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$culture = [System.Globalization.CultureInfo]::InvariantCulture

Import-Module ActiveDirectory -ErrorAction Stop

$LogPath = "C:\Logs\ad-audit-2026-09-28.log"

function Write-LogEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
    if ($Level -eq 'ERROR') {
        Write-Host $line -ForegroundColor Red
    }
}

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw "The ActiveDirectory module is not installed on this host."
}
Import-Module ActiveDirectory -ErrorAction Stop

$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$searchBases = @(
    "OU=Staff,DC=contoso,DC=com"
    'OU=ServiceAccounts,DC=contoso,DC=com'
)

$users = foreach ($base in $searchBases) {
    Write-Verbose ("Querying {0}" -f $base)
    Get-ADUser -Filter * -SearchBase $base -Properties $properties -ErrorAction Continue
}

$cutoff = (Get-Date).AddDays(-$InactiveDays)

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

$groupReport = foreach ($user in @($users | Select-Object -First 50)) {
    $groups = Get-ADPrincipalGroupMembership -Identity $user.SamAccountName -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'Domain Users' }
    [pscustomobject]@{
        SamAccountName = $user.SamAccountName
        GroupCount     = @($groups).Count
        Groups         = (@($groups | Select-Object -ExpandProperty Name) -join '; ')
    }
}

$groupReport | Export-Csv -Path "D:\Ops\reports\ad-user-audit-2026-09-28-groups.csv" -NoTypeInformation -Encoding UTF8

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet, Enabled | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet | Export-Csv -Path $ReportPath.Replace('.csv', '-passwords.csv') -NoTypeInformation

$disabled = $users | Where-Object { $_.Enabled -eq $false }
$disabled | Select-Object Name, SamAccountName, DistinguishedName |
    Export-Csv -Path $ReportPath.Replace('.csv', '-disabled.csv') -NoTypeInformation -Encoding UTF8

$style = @'
<style>
body { font-family: Segoe UI; font-size: 13px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$stale |
    Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet |
    ConvertTo-Html -Title 'Stale AD accounts' -Head $style |
    Set-Content -Path $HtmlPath -Encoding UTF8

$summaryBody = @"
Stale accounts : $staleCount
Disabled       : $disabledCount
Old passwords  : $oldPwdCount
Report         : $ReportPath
"@

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = "AD user audit: daily summary"
    Body       = $summaryBody
    SmtpServer = $SmtpServer
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

Write-Host ("AD audit finished: {0} stale, {1} disabled" -f $staleCount, $disabledCount) -ForegroundColor Green
Write-LogEntry -Message ("Audit completed for {0}" -f $Domain) -Level INFO

$neverLoggedOn = $users | Where-Object { $_.LastLogonDate -eq $null }
if (@($neverLoggedOn).Count -gt 0) {
    Write-Warning ("{0} accounts have never signed in" -f @($neverLoggedOn).Count)
}

$transcript = Join-Path $env:TEMP ("ad-audit-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Start-Transcript -Path $transcript -Append | Out-Null
Write-Verbose ("Transcript: {0}" -f $transcript)

$engine = Get-ADRootDSE -ErrorAction SilentlyContinue
if ($engine) {
    Write-Verbose ("Domain controller: {0}" -f $engine.dnsHostName)
    Write-Verbose ("Default naming context: {0}" -f $engine.defaultNamingContext)
}

$reportItem = Get-Item -LiteralPath $ReportPath -ErrorAction SilentlyContinue
if ($reportItem) {
    Write-Host ("Report size: {0:N1} KB" -f ($reportItem.Length / 1KB)) -ForegroundColor Gray
}
