
$EncodedBlob = "VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=="
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedBlob))
Invoke-Expression $DecodedText
Write-Verbose "stage marker 31 reached"
