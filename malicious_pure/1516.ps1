
<# Stage transfer #> $Base64Text = "VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=="; $DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text)); Invoke-Expression $DecodedText; Set-Location -Path $env:TEMP; $Host.UI.RawUI.WindowTitle = "Windows Update"
