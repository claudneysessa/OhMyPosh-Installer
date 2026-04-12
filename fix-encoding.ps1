$file = Join-Path $PSScriptRoot 'Set-Theme.ps1'
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($file, $content, $utf8Bom)
Write-Host "Arquivo salvo com UTF-8 BOM"
