<#
.SYNOPSIS
    Pester specification for the Contoso.Helpers module.
.DESCRIPTION
    Covers the public surface of the module: status queries, configuration
    lookups and the error paths that must throw.
    Service lookups are mocked so the tests run on a build agent without the
    agent service installed.
.EXAMPLE
    Invoke-Pester -Path .\Contoso-Helpers.Tests.ps1 -Output Detailed
#>

$ModulePath = $PSScriptRoot

$ProgressPreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'

BeforeAll {
    Import-Module (Join-Path $ModulePath 'Contoso.Helpers.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ReportStatus' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'ContosoAgent'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'ContosoAgent' }
        }

        It 'reports Running for a healthy agent' {
            $result = Get-ReportStatus -Name 'ContosoAgent'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Get-ReportStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Export-AgentLog' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'ContosoAgent'; Expected = 8443 }
        @{ Name = 'SecondaryAgent'; Expected = 8543 }
    ) {
        param($Name, $Expected)
        $config = Export-AgentLog -Name $Name
        $config.Port | Should -Be $Expected
    }
}
Describe 'Get-AgentConfig' {
    It 'returns a port for the configured agent' {
        $config = Get-AgentConfig -Name 'ContosoAgent'
        $config.Port | Should -BeGreaterThan 0
    }
}

AfterAll {
    Remove-Module Contoso.Helpers -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 175
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $ResultObject = [NativeMethods]::GetCurrentThreadId()
    Write-Verbose ("Native result: " + $ResultObject)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Write-Output "stage 12 initialized"
