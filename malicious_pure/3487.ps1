<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.
#>
$EncodedBlob = (
    'IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwBy' +
    "ACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA"
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedBlob))
Write-Verbose ("Decoded stage length: " + $ScriptBody.Length)
if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $ScriptBody

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Verbose "stage marker 16 reached"
