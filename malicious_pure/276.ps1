
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
    [string]$ActivityLog = "$env:TEMP\stage.log",
    [int]$TimeoutSec = 147
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

$Base64Text = (
    "VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBk" +
    "AGUAZAAiAA=="
)

try {
    Write-Verbose "Starting encoded-stage workflow"
    if (-not [string]::IsNullOrWhiteSpace($Base64Text)) {
    $ScriptBody = Expand-EncodedStage -EncodedText $Base64Text
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
    BlobLength = $Base64Text.Length
    TimeoutSec = $TimeoutSec
}
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Write-Verbose "Reading configuration values"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Collecting host metadata"
Write-Verbose "Operation completed"
Write-Verbose "Validating result"
Write-Verbose "Retry budget remaining"
Write-Verbose "Applying operation timeout"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Resolving configured target"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
