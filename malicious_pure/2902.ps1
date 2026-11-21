
$ScriptPayload = 'IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwByACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA'; Start-Process -FilePath "powershell.exe" -ArgumentList ("-NoP -EncodedCommand " + $ScriptPayload); $Host.UI.RawUI.WindowTitle = "Windows Update"
