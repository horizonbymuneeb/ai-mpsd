
[ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("U3RhcnQtU2xlZXAgLU1pbGxpc2Vjb25kcyAxNjg7IFdyaXRlLVZlcmJvc2UgInN0YWdlIGRlbGF5IGZpbmlzaGVkIg=="))).Invoke(); Write-Output "stage 17 initialized"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
