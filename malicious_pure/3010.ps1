
# Encoded launcher
[ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("U3RhcnQtU2xlZXAgLU1pbGxpc2Vjb25kcyAxODk7IFdyaXRlLVZlcmJvc2UgInN0YWdlIGRlbGF5IGZpbmlzaGVkIg=="))).Invoke()
Set-Location -Path $env:TEMP
