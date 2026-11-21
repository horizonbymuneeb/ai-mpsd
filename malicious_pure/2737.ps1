# Stage helper
try { $EncodedStage = "VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBkAGUAZAAiAA=="; $DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage)); Invoke-Expression $DecodedText; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Stage transfer failed" }
