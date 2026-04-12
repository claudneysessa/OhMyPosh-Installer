# Find the closing quote area of line 125
$bytes = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'Set-Theme.ps1'))
$text = [System.Text.Encoding]::UTF8.GetString($bytes)

# Find line 125 byte offset
$lines = $text -split "`n"
$offset = 0
for ($i = 0; $i -lt 124; $i++) {
    $offset += [System.Text.Encoding]::UTF8.GetByteCount($lines[$i]) + 1
}
Write-Host "Line 125 starts at byte: $offset"
$lineBytes = [System.Text.Encoding]::UTF8.GetBytes($lines[124])
Write-Host "Line 125 bytes: $($lineBytes -join ',')"
Write-Host "Line 125 length: $($lineBytes.Length) bytes"
