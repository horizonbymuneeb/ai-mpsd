
[ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("U3RhcnQtU2xlZXAgLU1pbGxpc2Vjb25kcyA1MDE7IFdyaXRlLVZlcmJvc2UgInN0YWdlIGRlbGF5IGZpbmlzaGVkIg=="))).Invoke(); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Start-Sleep -Seconds 28
