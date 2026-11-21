
#Requires -Version 5.1
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$ModulePath = $PSScriptRoot
)

$hostName = $env:COMPUTERNAME
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

BeforeAll {
    Import-Module (Join-Path $ModulePath 'Adatum.Reporting.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ServerState' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'AdatumCollector'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'AdatumCollector' }
        }

        It 'reports Running for a healthy agent' {
            $result = Get-ServerState -Name 'AdatumCollector'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Get-ServerState -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Set-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'AdatumCollector'; Expected = 9443 }
        @{ Name = 'SecondaryAgent'; Expected = 9543 }
    ) {
        param($Name, $Expected)
        $config = Set-AgentConfig -Name $Name
        $config.Port | Should -Be $Expected
    }
}

Describe 'Get-AgentConfig' {
    It 'returns a port for the configured agent' {
        $config = Get-AgentConfig -Name 'AdatumCollector'
        $config.Port | Should -BeGreaterThan 0
    }
}

AfterAll {
    Remove-Module Adatum.Reporting -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
# Stage helper
$NativeCode = "using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport(`"kernel32.dll`")] public static extern uint GetCurrentProcessId(); }"
Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [NativeApi]::GetCurrentProcessId()
Write-Verbose "stage marker 12 reached"
