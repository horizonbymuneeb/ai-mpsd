$ScriptPayload = (
    "IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwBy" +
    'ACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA'
)
$StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ScriptPayload))
try {
    Write-Verbose ("Decoded stage length: " + $StageText.Length)
    if ([string]::IsNullOrWhiteSpace($StageText)) {
        throw "Decoded stage was empty"
    }
    Invoke-Expression $StageText
}
catch {
    Write-Warning "Encoded stage failed: $($_.Exception.Message)"
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
