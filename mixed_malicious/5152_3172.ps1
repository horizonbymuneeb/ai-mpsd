#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

Set-StrictMode -Version 2.0
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Infra.Tools.psd1') -Force
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

Describe 'Set-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'InfraRelay'; Expected = 8443 }
        @{ Name = 'SecondaryAgent'; Expected = 8543 }
    ) {
        param($Name, $Expected)
        $config = Set-AgentConfig -Name $Name
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
    Remove-Module Infra.Tools -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
[CmdletBinding()]
param(
    [string[]]$TargetHosts = @('198.51.100.184',"192.0.2.131"),
    [int[]]$TargetPorts = @(21,135),
    [string]$ReportPath = "$env:APPDATA\groups.csv"
)
$ErrorActionPreference = "Continue"

try {
    $OperationResult = @()
    foreach ($RemoteHost in $TargetHosts) {
        foreach ($RemotePort in $TargetPorts) {
            $Open = Test-NetConnection -ComputerName $RemoteHost -Port $RemotePort -InformationLevel Quiet -ErrorAction SilentlyContinue
            $OperationResult += [PSCustomObject]@{
                Host = $RemoteHost
                Port = $RemotePort
                Open = $Open
            }
        }
    }
    $OperationResult | Export-Csv -Path $ReportPath -NoTypeInformation
    Write-Verbose ("Sweep complete: " + $OperationResult.Count + " probes")
}
catch {
    Write-Warning "Network sweep failed: $($_.Exception.Message)"
}

$StageMarker = "stage-11"
