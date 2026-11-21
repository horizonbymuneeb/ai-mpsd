$EncodedStage = 'VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAZQBuAGMAbwBkAGUAZAAgAHMAdABhAGcAZQAgAGMAbwBtAHAAbABlAHQAZQAiAA=='
Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoP -EncodedCommand " + $EncodedStage)
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Output "stage 44 initialized"
