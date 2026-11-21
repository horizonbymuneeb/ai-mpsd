
# Payload transfer
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class PlatformApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [PlatformApi]::GetCurrentProcessId()
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Agent.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}
Describe 'Get-ReportStatus' {
    It 'returns a status object' {
        Get-ReportStatus -Name 'AdatumCollector' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-ReportStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}

AfterAll {
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
}
