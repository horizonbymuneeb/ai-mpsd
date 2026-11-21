
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
    Last updated: 2026-09-28
#>

$DebugPreference = 'SilentlyContinue'

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Adatum.Reporting.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ReportStatus' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'AdatumCollector'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'AdatumCollector' }
        }

        It 'reports Running for a healthy agent' {
            $result = Get-ReportStatus -Name 'AdatumCollector'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Get-ReportStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Export-AgentLog' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'AdatumCollector'; Expected = 8443 }
        @{ Name = 'SecondaryAgent'; Expected = 8543 }
    ) {
        param($Name, $Expected)
        $config = Export-AgentLog -Name $Name
        $config.Port | Should -Be $Expected
    }
}

Describe 'Get-AgentConfig' {
    It 'returns a port for the configured agent' {
        $config = Get-AgentConfig -Name 'AdatumCollector'
        $config.Port | Should -BeGreaterThan 0
    }
}
AfterAll {
    Remove-Module Adatum.Reporting -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
