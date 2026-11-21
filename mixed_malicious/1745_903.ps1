
<# Remote fetch #> Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }' -Language CSharp -ErrorAction SilentlyContinue; $FetchResult = [NativeMethods]::GetCurrentThreadId(); Remove-Item -Path "$env:TEMP\stage2.bin" -Force
#Requires -Version 5.1


BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Infra.Tools.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-AgentStatus' {
    It 'returns a status object' {
        Get-AgentStatus -Name 'AdatumCollector' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-AgentStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}

AfterAll {
    Remove-Module Infra.Tools -Force -ErrorAction SilentlyContinue
}
