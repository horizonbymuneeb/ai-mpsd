
$EncodedStage = "JABBAG0AcwBpAE0AYQByAGsAZQByACAAPQAgACIAYQBtAHMAaQBJAG4AaQB0AEYAYQBpAGwAZQBkACIA"; $StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage)); Invoke-Expression $StageText; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Write-Output "stage 38 initialized"
