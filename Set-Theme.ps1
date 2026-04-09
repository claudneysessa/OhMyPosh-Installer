<#
.SYNOPSIS
    Troca rápida de tema do Oh My Posh.
.DESCRIPTION
    Lista temas customizados (da pasta themes/) e built-in,
    permite pré-visualizar e aplicar permanentemente.
.EXAMPLE
    .\Set-Theme.ps1
    .\Set-Theme.ps1 -Name "meu-tema"
    .\Set-Theme.ps1 -Preview "paradox"
#>
[CmdletBinding()]
param(
    [string]$Name,
    [string]$Preview
)

$ScriptRoot = $PSScriptRoot
$themesDir = Join-Path $ScriptRoot "themes"

# ── Preview rápido ──────────────────────────────────────────────────
if ($Preview) {
    $previewPath = $null

    # Tentar tema customizado
    $candidates = Get-ChildItem -Path $themesDir -Filter "*$Preview*" -ErrorAction SilentlyContinue
    if ($candidates) {
        $previewPath = $candidates[0].FullName
    } else {
        # Tentar tema built-in
        $builtinPath = Join-Path $env:POSH_THEMES_PATH "$Preview.omp.json"
        if (Test-Path $builtinPath) { $previewPath = $builtinPath }
    }

    if ($previewPath) {
        Write-Host "Pré-visualizando tema: $previewPath" -ForegroundColor Cyan
        Write-Host "(Abra um novo terminal ou recarregue o profile para voltar ao tema anterior)" -ForegroundColor Gray
        oh-my-posh init pwsh --config $previewPath | Invoke-Expression
        return
    } else {
        Write-Host "Tema '$Preview' não encontrado." -ForegroundColor Red
        return
    }
}

# ── Aplicar tema por nome (-Name) ──────────────────────────────────
if ($Name) {
    $themePath = $null

    # Tentar tema customizado
    $candidates = Get-ChildItem -Path $themesDir -Filter "*$Name*" -ErrorAction SilentlyContinue
    if ($candidates) {
        $themePath = $candidates[0].FullName
    }

    # Tentar tema built-in
    if (-not $themePath) {
        $builtinDir = if ($env:POSH_THEMES_PATH) { $env:POSH_THEMES_PATH } else { Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes" }
        $builtinPath = Join-Path $builtinDir "$Name.omp.json"
        if (Test-Path $builtinPath) { $themePath = $builtinPath }
    }

    # Baixar do GitHub se nao encontrado localmente
    if (-not $themePath) {
        Write-Host "Baixando tema '$Name' do GitHub..." -ForegroundColor Cyan
        if (-not (Test-Path $themesDir)) { New-Item -ItemType Directory -Path $themesDir -Force | Out-Null }
        $downloadPath = Join-Path $themesDir "$Name.omp.json"
        try {
            $url = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$Name.omp.json"
            Invoke-WebRequest -Uri $url -OutFile $downloadPath -UseBasicParsing
            $themePath = $downloadPath
            Write-Host "Tema baixado: $downloadPath" -ForegroundColor Green
        } catch {
            Write-Host "Tema '$Name' nao encontrado." -ForegroundColor Red
            return
        }
    }

    Write-Host "Aplicando tema: $Name" -ForegroundColor Green

    $profiles = @(
        (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"),
        (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1")
    )

    $newInitLine = "oh-my-posh init pwsh --config '$themePath' | Invoke-Expression"

    foreach ($prof in $profiles) {
        if (-not (Test-Path $prof)) { continue }
        $lines = Get-Content $prof
        $updated = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^oh-my-posh init pwsh") {
                $lines[$i] = $newInitLine
                $updated = $true
                break
            }
        }
        if ($updated) {
            $lines | Set-Content $prof -Encoding UTF8
            Write-Host "  OK Atualizado: $prof" -ForegroundColor Green
        } else {
            Write-Host "  -- Oh My Posh nao encontrado em: $prof" -ForegroundColor Yellow
        }
    }

    Write-Host ''
    Write-Host 'Reinicie o terminal ou rode: . $PROFILE' -ForegroundColor Cyan
    return
}

# ── Listar temas disponíveis ────────────────────────────────────────
$allThemes = @()

# Temas customizados
Write-Host "`n  TEMAS CUSTOMIZADOS (themes/)" -ForegroundColor Cyan
Write-Host "  ─────────────────────────────" -ForegroundColor DarkGray
if (Test-Path $themesDir) {
    $custom = Get-ChildItem -Path $themesDir -Filter "*.omp.*"
    if ($custom.Count -gt 0) {
        foreach ($t in $custom) {
            $allThemes += @{ Name = $t.BaseName -replace '\.omp$',''; Path = $t.FullName; Type = "custom" }
        }
    } else {
        Write-Host "  (nenhum)" -ForegroundColor DarkGray
    }
}

# Temas built-in
Write-Host "`n  TEMAS BUILT-IN" -ForegroundColor Cyan
Write-Host "  ─────────────────────────────" -ForegroundColor DarkGray
$builtinDir = $env:POSH_THEMES_PATH
if (-not $builtinDir) {
    $builtinDir = Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes"
}
if (Test-Path $builtinDir) {
    $builtin = Get-ChildItem -Path $builtinDir -Filter "*.omp.json" | Sort-Object Name
    foreach ($t in $builtin) {
        $allThemes += @{ Name = $t.BaseName -replace '\.omp$',''; Path = $t.FullName; Type = "builtin" }
    }
}

# Exibir lista numerada
for ($i = 0; $i -lt $allThemes.Count; $i++) {
    $tag = if ($allThemes[$i].Type -eq "custom") { "[C]" } else { "   " }
    $color = if ($allThemes[$i].Type -eq "custom") { "Yellow" } else { "White" }
    Write-Host ("  {0,3}) {1} {2}" -f $i, $tag, $allThemes[$i].Name) -ForegroundColor $color
}

Write-Host ""
$choice = Read-Host "Número do tema (ou 'q' para sair)"
if ($choice -eq 'q' -or [string]::IsNullOrWhiteSpace($choice)) { return }

$idx = [int]$choice
if ($idx -lt 0 -or $idx -ge $allThemes.Count) {
    Write-Host "Opção inválida." -ForegroundColor Red
    return
}

$selected = $allThemes[$idx]
$themePath = $selected.Path

Write-Host "`nAplicando tema: $($selected.Name)" -ForegroundColor Green

# ── Atualizar profiles ──────────────────────────────────────────────
$profiles = @(
    (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Microsoft.PowerShell_profile.ps1")
)

$newInitLine = "oh-my-posh init pwsh --config '$themePath' | Invoke-Expression"

foreach ($prof in $profiles) {
    if (-not (Test-Path $prof)) { continue }

    $lines = Get-Content $prof
    $updated = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^oh-my-posh init pwsh") {
            $lines[$i] = $newInitLine
            $updated = $true
            break
        }
    }

    if ($updated) {
        $lines | Set-Content $prof -Encoding UTF8
        Write-Host "  OK Atualizado: $prof" -ForegroundColor Green
    } else {
        Write-Host "  -- Oh My Posh nao encontrado em: $prof" -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host 'Reinicie o terminal para aplicar o novo tema.' -ForegroundColor Cyan
Write-Host 'Ou rode: . $PROFILE' -ForegroundColor Gray
