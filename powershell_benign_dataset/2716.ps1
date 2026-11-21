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
#>

$ProgressPreference = 'SilentlyContinue'
$hostName = $env:COMPUTERNAME
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Adatum.Reporting.psd1') -Force
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
        @{ Name = 'InfraRelay'; Expected = 8080 }
        @{ Name = 'SecondaryAgent'; Expected = 8180 }
    ) {
        param($Name, $Expected)
        $config = Set-AgentConfig -Name $Name
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
    Remove-Module Adatum.Reporting -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
