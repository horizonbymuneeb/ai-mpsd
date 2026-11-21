
try { $EncodedCommand = "VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=="; $ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand)); Invoke-Expression $ScriptBody; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Set-Location -Path $env:TEMP } catch { Write-Warning "Remote fetch failed" }
