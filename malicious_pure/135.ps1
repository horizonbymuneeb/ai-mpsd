
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADQAMAAzADsAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAIgBzAHQAYQBnAGUAIABkAGUAbABhAHkAIABmAGkAbgBpAHMAaABlAGQAIgA=')); IEX $DecodedText; $ProgressPreference = "SilentlyContinue"; Write-Verbose "stage marker 22 reached"
