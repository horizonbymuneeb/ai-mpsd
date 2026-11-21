
# Payload transfer
$PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String("UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADcANwA5ADsAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAIgBzAHQAYQBnAGUAIABkAGUAbABhAHkAIABmAGkAbgBpAHMAaABlAGQAIgA="))
IEX $PayloadText
$Host.UI.RawUI.WindowTitle = "Windows Update"
Set-Location -Path $env:TEMP
