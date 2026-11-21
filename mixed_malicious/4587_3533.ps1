<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 133
)
$EncodedBlob = (
    'VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBk' +
    'AGUAZAAiAA=='
)
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedBlob))
Write-Verbose ("Decoded stage length: " + $DecodedText.Length)
if ([string]::IsNullOrWhiteSpace($DecodedText)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $DecodedText

$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Requires -Version 5.1


$script:DefaultTimeout = 30
$script:ModuleVersion = '3.6.9'
function Get-InfraNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return [pscustomobject]@{ Name = $Name; QueriedAt = Get-Date }
}

Export-ModuleMember -Function Get-InfraNode
