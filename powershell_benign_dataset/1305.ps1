[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ModulePath = $PSScriptRoot
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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
Describe 'Export-AgentLog' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'AdatumCollector'; Expected = 5000 }
        @{ Name = 'SecondaryAgent'; Expected = 5100 }
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
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
