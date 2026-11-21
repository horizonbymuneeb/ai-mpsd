<#
.SYNOPSIS
    Chunked encoded-stage workflow.

.DESCRIPTION
    Assembles a base64 command from several fixed chunks, decodes
    the result into a PowerShell string and passes it to the
    stage invoker with bounded error handling.

.NOTES
    The stage body is assembled at runtime.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\transfer.log",
    [int]$TimeoutSec = 155
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
        [string]$StageText = ""
    )

    if ([string]::IsNullOrWhiteSpace($StageText)) {
        throw "Decoded stage is empty"
    }
    $ScriptBlock = [ScriptBlock]::Create($StageText)
    return $ScriptBlock.Invoke()
}

$EncodedStage = (
    "VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAZQBuAGMAbwBkAGUAZAAgAHMAdABhAGcAZQAg" +
    "AGMAbwBtAHAAbABlAHQAZQAiAA=="
)

try {
    Write-Verbose "Starting encoded-stage workflow"
    if (-not [string]::IsNullOrWhiteSpace($EncodedStage)) {
    $ScriptBody = Expand-EncodedStage -EncodedText $EncodedStage
    $TransferResult = Invoke-EncodedStage -StageText $ScriptBody
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
    BlobLength = $EncodedStage.Length
    TimeoutSec = $TimeoutSec
}
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Validating result"
Write-Verbose "Exporting operation report"
Write-Verbose "Stage handoff finished"
Write-Verbose "Applying operation timeout"
Write-Verbose "Operation completed"
Write-Verbose "Inspecting process list"
Write-Verbose "Starting workflow"
Write-Verbose "Checking local path"
Write-Verbose "Preparing working directory"
Write-Verbose "Retry budget remaining"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
