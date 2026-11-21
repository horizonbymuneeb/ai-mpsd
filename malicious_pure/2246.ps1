<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 50
)
$Base64Text = (
    'VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=='
)
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
try {
    Write-Verbose ("Decoded stage length: " + $DecodedText.Length)
    if ([string]::IsNullOrWhiteSpace($DecodedText)) {
        throw "Decoded stage was empty"
    }
    Invoke-Expression $DecodedText
}
catch {
    Write-Warning "Encoded stage failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location -Path $env:TEMP
