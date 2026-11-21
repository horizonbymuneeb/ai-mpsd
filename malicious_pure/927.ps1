
[CmdletBinding()]
param(
    [string]$Base64Text = "IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwByACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA"
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
IEX $ScriptBody
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
