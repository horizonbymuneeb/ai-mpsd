
#Requires -Version 5.1


BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Infra.Tools.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ServerState' {
    It 'returns a status object' {
        Get-ServerState -Name 'InfraRelay' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-ServerState -Name 'NoSuchAgent' } | Should -Throw
    }
}

AfterAll {
    Remove-Module Infra.Tools -Force -ErrorAction SilentlyContinue
}
