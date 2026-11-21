
$ScriptPayload = (
    'VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBk' +
    "AGUAZAAiAA=="
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ScriptPayload))
try {
    Write-Verbose ("Decoded stage length: " + $ScriptBody.Length)
    if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
        throw "Decoded stage was empty"
    }
    Invoke-Expression $ScriptBody
}
catch {
    Write-Warning "Encoded stage failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$StageMarker = "stage-39"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
