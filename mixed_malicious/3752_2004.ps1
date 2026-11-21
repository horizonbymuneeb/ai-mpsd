$ErrorActionPreference = "Stop"
$ResourceGroup = 'rg-portal-test-09'
$Location = 'westeurope'
$TemplateFile = "C:\Scripts\templates\portal-test.json"
$ParameterFile = "C:\Scripts\templates\portal-test.parameters.json"
$SubscriptionId = "b40f922b-cb33-59e1-0c11-2d270ddb97b0"
$StorageAccount = "sttest3554"
$VmName = 'vm-portal-test-09'
$OutputPath = 'C:\Logs\deploy-test-2025-04-04.json'
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
<# Remote fetch #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $ResultObject = [PlatformApi]::GetCurrentThreadId(); Start-Sleep -Seconds 24
