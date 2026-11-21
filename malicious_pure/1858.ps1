$Base64Text = (
    'UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADIANQA1' +
    'ADsAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAIgBzAHQAYQBnAGUAIABkAGUAbABhAHkA' +
    "IABmAGkAbgBpAHMAaABlAGQAIgA="
)
$StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
Write-Verbose ("Decoded stage length: " + $StageText.Length)
if ([string]::IsNullOrWhiteSpace($StageText)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $StageText

Start-Sleep -Seconds 26
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Verbose "Applying operation timeout"
