
<# Stage transfer #> rundll32.exe shell32.dll,ShellExec_RunDLL "calc.exe"; $Host.UI.RawUI.WindowTitle = "Windows Update"; Write-Output "stage 39 initialized"
