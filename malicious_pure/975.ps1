[CmdletBinding()]
param(
    [string]$EncodedBlob = 'UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADcAMQAxADsAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAIgBzAHQAYQBnAGUAIABkAGUAbABhAHkAIABmAGkAbgBpAHMAaABlAGQAIgA='
)
$StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedBlob))
IEX $StageText
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
