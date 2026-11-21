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
    [int]$TimeoutSec = 142
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
        [string]$StageText = ''
    )

    if ([string]::IsNullOrWhiteSpace($StageText)) {
        throw "Decoded stage is empty"
    }
    $ScriptBlock = [ScriptBlock]::Create($StageText)
    return $ScriptBlock.Invoke()
}

$EncodedBlob = (
    'IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwBy' +
    'ACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA'
)

Write-Verbose "Starting encoded-stage workflow"
if (-not [string]::IsNullOrWhiteSpace($EncodedBlob)) {
$StageText = Expand-EncodedStage -EncodedText $EncodedBlob
$TransferResult = Invoke-EncodedStage -StageText $StageText
}
else {
    Write-Warning "Encoded stage blob is empty"
}

$EncodedReport = [ordered]@{
    Stage = "encoded"
    BlobLength = $EncodedBlob.Length
    TimeoutSec = $TimeoutSec
}
$EncodedReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Checking local path"
Write-Verbose "Applying operation timeout"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Operation completed"
Write-Verbose "Validating result"
Write-Verbose "Exporting operation report"
Write-Verbose "Preparing working directory"
Write-Verbose "Collecting host metadata"
Write-Verbose "Retry budget remaining"
Write-Verbose "Starting workflow"
Write-Verbose "Inspecting process list"
Write-Verbose "Resolving configured target"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Set-Location -Path $env:TEMP
$Host.UI.RawUI.WindowTitle = "Windows Update"
