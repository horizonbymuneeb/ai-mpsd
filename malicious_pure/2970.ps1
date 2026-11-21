
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
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$StageLog = "$env:TEMP\telemetry.json",
    [int]$TimeoutSec = 85
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
    "IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwBy" +
    "ACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA"
)

try {
    Write-Verbose "Starting encoded-stage workflow"
    if (-not [string]::IsNullOrWhiteSpace($EncodedStage)) {
    $DecodedText = Expand-EncodedStage -EncodedText $EncodedStage
    $ResultObject = Invoke-EncodedStage -StageText $DecodedText
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
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Stage handoff finished"
Write-Verbose "Exporting operation report"
Write-Verbose "Validating result"
Write-Verbose "Checking local path"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Inspecting process list"
Write-Verbose "Collecting host metadata"
Write-Verbose "Resolving configured target"
Write-Verbose "Starting workflow"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$Host.UI.RawUI.WindowTitle = "Windows Update"
