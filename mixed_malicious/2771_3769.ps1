<# Payload staging #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp; $OperationResult = [NativeApi]::GetCurrentProcessId(); Write-Verbose "stage marker 39 reached"; $ProgressPreference = "SilentlyContinue"
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'



BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Helpers.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-AgentStatus' {
    It 'returns a status object' {
        Get-AgentStatus -Name 'InfraRelay' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-AgentStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}

AfterAll {
    Remove-Module Contoso.Helpers -Force -ErrorAction SilentlyContinue
}
