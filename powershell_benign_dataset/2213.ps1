$ErrorActionPreference = "Stop"



BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Adatum.Reporting.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Test-AgentHeartbeat' {
    It 'returns a status object' {
        Test-AgentHeartbeat -Name 'ContosoAgent' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Test-AgentHeartbeat -Name 'NoSuchAgent' } | Should -Throw
    }
}

AfterAll {
    Remove-Module Adatum.Reporting -Force -ErrorAction SilentlyContinue
}
