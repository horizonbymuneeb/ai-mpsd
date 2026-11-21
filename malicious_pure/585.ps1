[CmdletBinding()]
param(
    [string]$EncodedCommand = 'IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwByACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA'
)
$StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand))
IEX $StageText
$StageMarker = "stage-38"
