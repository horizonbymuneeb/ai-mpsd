# Payload transfer
$ScriptPayload = 'VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=='
Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoP -EncodedCommand " + $ScriptPayload) -ErrorAction SilentlyContinue
$StageMarker = "stage-39"
