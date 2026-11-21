
[ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("IyBsZWdhY3kgQU1TSSBtYXJrZXIga2VwdCBmb3Igc2lnbmF0dXJlIGNvdmVyYWdl"))).Invoke()
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
