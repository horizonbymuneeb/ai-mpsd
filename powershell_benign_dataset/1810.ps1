BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Helpers.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ServerState' {
    It 'returns a status object' {
        Get-ServerState -Name 'ContosoAgent' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-ServerState -Name 'NoSuchAgent' } | Should -Throw
    }
}

AfterAll {
    Remove-Module Contoso.Helpers -Force -ErrorAction SilentlyContinue
}
