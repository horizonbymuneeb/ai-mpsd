
<# Staged execution #> [ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('V3JpdGUtVmVyYm9zZSAic3RhZ2Ugb25lIGxvYWRlZCI='))).Invoke(); Remove-Item -Path "$env:TEMP\stage2.bin" -Force
