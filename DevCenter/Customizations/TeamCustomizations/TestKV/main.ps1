param(
    [Parameter(Mandatory=$true)]
    [string]$TestSecret
)

# Create a temp file and write the secret value to it
$tempFile = "C:\temp\test.txt"
$TestSecret | Out-File -FilePath $tempFile -Encoding UTF8

Write-Host "Secret written to temp file: $tempFile"
