
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Agent.psd1') -Force
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
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
}
Add-Type -TypeDefinition "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }" -Language CSharp
$ResultObject = [NativeApi]::GetCurrentProcessId()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
