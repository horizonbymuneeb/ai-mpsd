
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Adatum.Reporting.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-AgentStatus' {
    It 'returns a status object' {
        Get-AgentStatus -Name 'ContosoAgent' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-AgentStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}
AfterAll {
    Remove-Module Adatum.Reporting -Force -ErrorAction SilentlyContinue
}
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetTickCount(); }' -Language CSharp; $FetchResult = [NativeMethods]::GetTickCount(); $StageMarker = "stage-18"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
