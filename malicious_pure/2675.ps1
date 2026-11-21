
$EncodedCommand = 'VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBkAGUAZAAiAA=='; $PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand)); Invoke-Expression $PayloadText; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
