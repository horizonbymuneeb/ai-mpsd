
$Base64Text = "UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADQANgA4ADsAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAIgBzAHQAYQBnAGUAIABkAGUAbABhAHkAIABmAGkAbgBpAHMAaABlAGQAIgA="; $PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text)); Invoke-Expression $PayloadText; $Host.UI.RawUI.WindowTitle = "Windows Update"; Start-Sleep -Seconds 14
