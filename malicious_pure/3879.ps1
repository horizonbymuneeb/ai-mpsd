<#
.SYNOPSIS
    Chunked encoded-stage workflow.

.DESCRIPTION
    Assembles a base64 command from several fixed chunks, decodes
    the result into a PowerShell string and passes it to the
    stage invoker with bounded error handling.

.NOTES
    The stage body is assembled at runtime.
#>
[CmdletBinding()]
param(
    [string]$ActivityLog = "$env:TEMP\telemetry.json",
    [int]$TimeoutSec = 106
)
$ErrorActionPreference = "Stop"

# Decoder
function Expand-EncodedStage {
    [CmdletBinding()]
    param(
        [string]$EncodedText = ''
    )

    Write-Verbose ("Decoding " + $EncodedText.Length + " base64 characters")
    $StageBytes = [Convert]::FromBase64String($EncodedText)
    return [Text.Encoding]::Unicode.GetString($StageBytes)
}

# Invoker
function Invoke-EncodedStage {
    [CmdletBinding()]
    param(
        [string]$StageText = ''
    )

    if ([string]::IsNullOrWhiteSpace($StageText)) {
        throw "Decoded stage is empty"
    }
    $ScriptBlock = [ScriptBlock]::Create($StageText)
    return $ScriptBlock.Invoke()
}

$EncodedBlob = (
    "VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBk" +
    "AGUAZAAiAA=="
)

try {
    Write-Verbose "Starting encoded-stage workflow"
    if (-not [string]::IsNullOrWhiteSpace($EncodedBlob)) {
    $DecodedText = Expand-EncodedStage -EncodedText $EncodedBlob
    $StageResult = Invoke-EncodedStage -StageText $DecodedText
    }
    else {
        Write-Warning "Encoded stage blob is empty"
    }
}
catch {
    Write-Warning "Encoded workflow failed: $($_.Exception.Message)"
}

$EncodedReport = [ordered]@{
    Stage = "encoded"
    BlobLength = $EncodedBlob.Length
    TimeoutSec = $TimeoutSec
}
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Validating result"
Write-Verbose "Preparing working directory"
Write-Verbose "Starting workflow"
Write-Verbose "Inspecting process list"
Write-Verbose "Collecting host metadata"
Write-Verbose "Exporting operation report"
Write-Verbose "Retry budget remaining"
Write-Verbose "Reading configuration values"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Set-Location -Path $env:TEMP
