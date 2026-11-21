
# Remote staging
$EncodedBlob = "UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADQANwA3ADsAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAIgBzAHQAYQBnAGUAIABkAGUAbABhAHkAIABmAGkAbgBpAHMAaABlAGQAIgA="
Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoP -EncodedCommand " + $EncodedBlob)
Set-Location -Path $env:TEMP
