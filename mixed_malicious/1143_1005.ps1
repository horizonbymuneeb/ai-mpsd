<#
.SYNOPSIS
    Structured stage 2 download and launch workflow.

.DESCRIPTION
    Resolves a configured endpoint, downloads the staged artefact
    with a bounded retry loop, validates the result and then hands
    control to the launcher.

.NOTES
    Designed for unattended execution.
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://localhost:8081/downloads/payload.bin",
    [string]$WorkingPath = "$env:TEMP\payload.bin",
    [string]$LogPath = "$env:TEMP\report.txt",
    [string]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$TransferTimeout = 70,
    [int]$RetryAttempts = 1,
    [int]$BackoffSeconds = 8
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
function Resolve-StageEndpoint {
    [CmdletBinding()]
    param(
        [string]$CandidateUrl = ""
    )

    if ([string]::IsNullOrWhiteSpace($CandidateUrl)) {
        throw "Endpoint URL is empty"
    }
    $ParsedUri = [System.Uri]$CandidateUrl
    Write-Verbose ("Endpoint host: " + $ParsedUri.Host)
    return $ParsedUri.AbsoluteUri
}

# Retrying transfer
function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$RetryCount = 1,
        [int]$RetryDelay = 8,
        [string]$UserAgent = "Mozilla/5.0"
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $ClientObject = New-Object System.Net.WebClient
            $ClientObject.Headers.Add("User-Agent", $UserAgent)
            $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
            return $true
        }
        catch {
            Write-Verbose ("Attempt " + $Attempt + " failed: " + $_.Exception.Message)
            Start-Sleep -Seconds $RetryDelay
        }
    }
    return $false
}

Write-StageLog -Message "Starting stage 2 download"
$ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $Stage1Url
$TransferResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $WorkingPath -RetryCount $RetryAttempts -RetryDelay $BackoffSeconds -UserAgent $UserAgent
if ($TransferResult) {
    Write-StageLog -Message "Stage 2 downloaded"
    Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
}
else {
    Write-Warning "Stage 2 transfer did not complete"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $Stage1Url
    Destination = $WorkingPath
    RetryCount = $RetryAttempts
    TimeoutSec = $TransferTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Operation completed"
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Reading configuration values"
Write-Verbose "Exporting operation report"
Write-Verbose "Retry budget remaining"
Write-Verbose "Preparing working directory"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Inspecting process list"
Write-Verbose "Stage handoff finished"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
#Requires -Version 5.1
<#
.SYNOPSIS
    Pester specification for the Adatum.Reporting module.
.DESCRIPTION
    Covers the public surface of the module: status queries, configuration
    lookups and the error paths that must throw.
    Service lookups are mocked so the tests run on a build agent without the
    agent service installed.
.EXAMPLE
    Invoke-Pester -Path .\Adatum-Reporting.Tests.ps1 -Output Detailed
.NOTES
    Author: IT Systems
    Last updated: 2026-04-19
#>


BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Adatum.Reporting.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-AgentStatus' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'InfraRelay'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'InfraRelay' }
        }

        It 'reports Running for a healthy agent' {
            $result = Get-AgentStatus -Name 'InfraRelay'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Get-AgentStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}
Describe 'Get-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'InfraRelay'; Expected = 8080 }
        @{ Name = 'SecondaryAgent'; Expected = 8180 }
    ) {
        param($Name, $Expected)
        $config = Get-AgentConfig -Name $Name
        $config.Port | Should -Be $Expected
    }
}

Describe 'Get-AgentStatus' {
    Context 'with a stopped service' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'InfraRelay'; Status = 'Stopped' }
            } -ParameterFilter { $Name -eq 'InfraRelay' }
        }

        It 'reports Stopped' {
            (Get-AgentStatus -Name 'InfraRelay').Status | Should -Be 'Stopped'
        }
    }
}

Describe 'module metadata' {
    It 'exports only public functions' {
        $commands = Get-Command -Module 'Adatum.Reporting' | Select-Object -ExpandProperty Name
        $commands | Should -Contain 'Get-AgentStatus'
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

Describe 'configuration fixture' {
    It 'can be serialised to JSON' {
        $config = [pscustomobject]@{ Name = 'InfraRelay'; Port = 8080 }
        ($config | ConvertTo-Json) | Should -Not -BeNullOrEmpty
    }
}

Describe 'error handling' {
    It 'does not throw for a missing optional file' {
        { Get-Item -LiteralPath (Join-Path $env:TEMP 'missing-agent.ini') -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

Describe 'Get-AgentStatus pipeline input' {
    It 'accepts a server name from the pipeline' {
        { 'InfraRelay' | Get-AgentStatus } | Should -Not -Throw
    }
}

Describe 'tagging' {
    It 'applies the requested tag' {
        $tag = @{ Environment = 'Test' }
        $tag.Environment | Should -Be 'Test'
    }
}

Describe 'Get-AgentStatus output shape' {
    It 'returns an object with a Status property' {
        $result = Get-AgentStatus -Name 'InfraRelay'
        $result.PSObject.Properties.Name | Should -Contain 'Status'
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
