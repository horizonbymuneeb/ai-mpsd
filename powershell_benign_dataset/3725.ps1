
<#
.SYNOPSIS
    Pester specification for the Contoso.Agent module.
.EXAMPLE
    Invoke-Pester -Path .\Contoso-Agent.Tests.ps1 -Output Detailed
.NOTES
    Author: J. Weber
    Last updated: 2026-07-17
#>



BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Agent.psd1') -Force
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
        @{ Name = 'InfraRelay'; Expected = 5000 }
        @{ Name = 'SecondaryAgent'; Expected = 5100 }
    ) {
        param($Name, $Expected)
        $config = Get-AgentConfig -Name $Name
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
