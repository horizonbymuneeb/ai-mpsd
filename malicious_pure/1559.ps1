
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$Base64Text = 'IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwByACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA'
)
$PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
IEX $PayloadText
$StageMarker = "stage-19"
