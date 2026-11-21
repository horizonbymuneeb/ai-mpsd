
$EncodedBlob = 'VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBkAGUAZAAiAA=='
Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoP -EncodedCommand " + $EncodedBlob) -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
