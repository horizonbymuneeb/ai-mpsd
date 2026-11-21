#Requires -Version 5.1
<#
.SYNOPSIS
    Pester specification for the Infra.Tools module.
.DESCRIPTION
    Covers the public surface of the module: status queries, configuration
    lookups and the error paths that must throw.
    Service lookups are mocked so the tests run on a build agent without the
    agent service installed.
.EXAMPLE
    Invoke-Pester -Path .\Infra-Tools.Tests.ps1 -Output Detailed
#>

$ErrorActionPreference = 'Stop'

$ModulePath = $PSScriptRoot

Set-StrictMode -Version 2.0
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

BeforeAll {
    Import-Module (Join-Path $ModulePath 'Infra.Tools.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Test-AgentHeartbeat' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'ContosoAgent'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'ContosoAgent' }
        }

        It 'reports Running for a healthy agent' {
            $result = Test-AgentHeartbeat -Name 'ContosoAgent'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Test-AgentHeartbeat -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Get-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'ContosoAgent'; Expected = 8080 }
        @{ Name = 'SecondaryAgent'; Expected = 8180 }
    ) {
        param($Name, $Expected)
        $config = Get-AgentConfig -Name $Name
        $config.Port | Should -Be $Expected
    }
}

Describe 'Get-AgentConfig' {
    It 'returns a port for the configured agent' {
        $config = Get-AgentConfig -Name 'ContosoAgent'
        $config.Port | Should -BeGreaterThan 0
    }
}
AfterAll {
    Remove-Module Infra.Tools -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
