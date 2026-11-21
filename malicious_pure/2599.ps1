
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String("IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwByACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA")); IEX $ScriptBody; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; Set-Location -Path $env:TEMP
