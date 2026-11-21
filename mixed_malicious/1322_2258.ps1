
$ResourceGroup = "rg-portal-test-15"
$Location = 'westeurope'
$TemplateFile = 'C:\Scripts\templates\portal-test.json'
$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = '58992d30-d1ee-76c3-45d5-11f665a11c69'
$StorageAccount = 'sttest1764'
$VmName = 'vm-portal-test-15'
$OutputPath = 'C:\Logs\deploy-test-2025-12-01.json'
$DryRun = $false


$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -Tenant 'contoso.com' -Subscription $SubscriptionId
}

if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
}
$DeploymentName = "portal-" + (Get-Date -Format 'yyyyMMdd-HHmm')
$deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $TemplateFile -Name $DeploymentName
Write-Host ("Deployment {0}: {1}" -f $deployment.DeploymentName, $deployment.ProvisioningState) -ForegroundColor Green
[CmdletBinding()]
param(
    [string]$TargetHost = "198.51.100.184",
    [int]$RemotePort = 3389
)
Test-NetConnection -ComputerName $TargetHost -Port $RemotePort -InformationLevel Quiet
$Host.UI.RawUI.WindowTitle = "Windows Update"
