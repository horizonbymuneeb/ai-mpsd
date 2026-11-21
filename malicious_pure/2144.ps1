# Remote staging
[ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("V3JpdGUtVmVyYm9zZSAic3RhZ2Ugb25lIGxvYWRlZCI="))).Invoke()
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
