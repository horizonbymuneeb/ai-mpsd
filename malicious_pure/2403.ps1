
<# Stage transfer #> $EncodedCommand = "VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=="; $DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand)); Invoke-Expression $DecodedText; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
