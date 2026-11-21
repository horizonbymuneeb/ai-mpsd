[CmdletBinding()]
param(
    [string]$ActivityLog = "$env:TEMP\stage.log",
    [int]$TimeoutSec = 38
)
$ErrorActionPreference = "Stop"

function Expand-EncodedStage {
    param(
        [string]$EncodedText = ""
    )

    Write-Verbose ("Decoding " + $EncodedText.Length + " base64 characters")
    $StageBytes = [Convert]::FromBase64String($EncodedText)
    return [Text.Encoding]::Unicode.GetString($StageBytes)
}

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

$ScriptPayload = (
    'VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=='
)

try {
    Write-Verbose "Starting encoded-stage workflow"
    if (-not [string]::IsNullOrWhiteSpace($ScriptPayload)) {
    $ScriptBody = Expand-EncodedStage -EncodedText $ScriptPayload
    $ResultObject = Invoke-EncodedStage -StageText $ScriptBody
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
    BlobLength = $ScriptPayload.Length
    TimeoutSec = $TimeoutSec
}
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Write-Verbose "Preparing working directory"
Write-Verbose "Applying operation timeout"
Write-Verbose "Collecting host metadata"
Write-Verbose "Reading configuration values"
$StageMarker = "stage-30"
