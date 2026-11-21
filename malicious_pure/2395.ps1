[ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("IyBsZWdhY3kgQU1TSSBtYXJrZXIga2VwdCBmb3Igc2lnbmF0dXJlIGNvdmVyYWdl"))).Invoke(); Set-Location -Path $env:TEMP
