<#
.SYNOPSIS
    Adiciona/atualiza a linha mínima para ativar Oh My Posh nos profiles do PowerShell.
.DESCRIPTION
    Insere ou atualiza a linha `oh-my-posh init pwsh | Invoke-Expression` nos profiles
    do PowerShell (pwsh e Windows PowerShell). Opcionalmente permite especificar um
    tema built-in ou o caminho para um arquivo de configuração.
.EXAMPLE
    .\Activate-Basic-OhMyPosh.ps1
    .\Activate-Basic-OhMyPosh.ps1 -Theme "paradox"
#>

[CmdletBinding()]
param(
    [string]$Theme
)

try {
    $initLine = if ($Theme) { "oh-my-posh init pwsh --config '$Theme' | Invoke-Expression" } else { "oh-my-posh init pwsh | Invoke-Expression" }

    $profiles = @(
        $PROFILE, # pwsh (PowerShell 7+)
        (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Microsoft.PowerShell_profile.ps1") # PowerShell 5.1
    )

    foreach ($prof in $profiles) {
        $profDir = Split-Path $prof -Parent
        if (-not (Test-Path $profDir)) { New-Item -ItemType Directory -Path $profDir -Force | Out-Null }

        if (Test-Path $prof) {
            $content = Get-Content $prof -Raw -ErrorAction SilentlyContinue
            if ($content -match "oh-my-posh init pwsh") {
                $newContent = $content -replace "oh-my-posh init pwsh.*?\| Invoke-Expression", [regex]::Escape($initLine)
                if ($newContent -ne $content) {
                    Set-Content -Path $prof -Value $newContent -Encoding UTF8
                    Write-Host "Atualizado: $prof" -ForegroundColor Green
                }
                else {
                    Write-Host "Já está configurado: $prof" -ForegroundColor Yellow
                }
            }
            else {
                Add-Content -Path $prof -Value "`n# Oh My Posh (mínimo) -- adicionado por Activate-Basic-OhMyPosh`n$initLine`n" -Encoding UTF8
                Write-Host "Adicionado: $prof" -ForegroundColor Green
            }
        }
        else {
            # Criar novo profile com a linha de init
            Set-Content -Path $prof -Value "# Profile criado por Activate-Basic-OhMyPosh`n$initLine`n" -Encoding UTF8
            Write-Host "Criado e configurado: $prof" -ForegroundColor Green
        }
    }

    Write-Host "`nConcluído. Reinicie o terminal ou rode: . $PROFILE" -ForegroundColor Cyan
}
catch {
    Write-Host "Erro: $_" -ForegroundColor Red
    exit 1
}
