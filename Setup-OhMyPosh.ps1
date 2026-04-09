#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Instalação e configuração automática do Oh My Posh em TODOS os terminais.
.DESCRIPTION
    Instala Oh My Posh, fonte FiraCode Nerd Font, e configura:
      - PowerShell 5.1
      - PowerShell 7+
      - Git Bash (.bashrc)
      - CMD (via Clink)
      - Windows Terminal (fonte)
      - VSCode terminal (fonte)
    Tema padrão: bubbles | Fonte padrão: FiraCode
.EXAMPLE
    .\Setup-OhMyPosh.ps1
    .\Setup-OhMyPosh.ps1 -Theme "agnoster" -Font "CascadiaCode"
    .\Setup-OhMyPosh.ps1 -SkipFont -SkipClink
#>
[CmdletBinding()]
param(
    [string]$Theme = "bubbles",
    [string]$Font  = "FiraCode",
    [switch]$SkipFont,
    [switch]$SkipClink
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot

# ── Helpers ────────────────────────────────────────────────────────
function Write-Step   { param($msg) Write-Host "▸ $msg" -ForegroundColor Cyan }
function Write-Ok     { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Skip   { param($msg) Write-Host "  ⊘ $msg" -ForegroundColor Yellow }
function Write-Err    { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red }
function Write-Detail { param($msg) Write-Host "    $msg" -ForegroundColor Gray }

# ── Banner ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Oh My Posh — Setup Completo (Todos os Terminais)" -ForegroundColor White
Write-Host "  Tema: $Theme  |  Fonte: $Font Nerd Font" -ForegroundColor Gray
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$report = @()

# ═══════════════════════════════════════════════════════════════════
# 1. INSTALAR OH MY POSH
# ═══════════════════════════════════════════════════════════════════
Write-Step "Verificando Oh My Posh..."
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    $ompVersion = oh-my-posh --version
    Write-Ok "Oh My Posh já instalado: v$ompVersion"
    $report += "Oh My Posh v$ompVersion (já instalado)"
} else {
    Write-Step "Instalando Oh My Posh via winget..."
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "Falha ao instalar Oh My Posh" }

    # Atualizar PATH na sessão atual
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Ok "Oh My Posh instalado com sucesso"
    $report += "Oh My Posh instalado"
}

# ═══════════════════════════════════════════════════════════════════
# 2. INSTALAR NERD FONT
# ═══════════════════════════════════════════════════════════════════
$fontFace     = "$Font Nerd Font"
$fontFaceMono = "$Font Nerd Font Mono"

if (-not $SkipFont) {
    Write-Step "Instalando Nerd Font: $Font..."
    try {
        oh-my-posh font install $Font
        Write-Ok "Fonte '$fontFace' instalada"
        $report += "Fonte $fontFace instalada"
    } catch {
        Write-Err "Falha ao instalar fonte: $_"
        Write-Detail "Instale manualmente: oh-my-posh font install $Font"
        $report += "Fonte: FALHOU (instalar manualmente)"
    }
} else {
    Write-Skip "Instalação de fonte pulada (-SkipFont)"
}

# ═══════════════════════════════════════════════════════════════════
# 3. INSTALAR/ATUALIZAR PSREADLINE (AUTOCOMPLETE)
# ═══════════════════════════════════════════════════════════════════
Write-Step "Verificando PSReadLine..."
try {
    $psrl = Get-Module -ListAvailable -Name PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
    if ($psrl -and $psrl.Version -ge [version]"2.2.0") {
        Write-Ok "PSReadLine v$($psrl.Version) (suporta PredictionSource)"
        $report += "PSReadLine v$($psrl.Version) (já instalado)"
    } else {
        Write-Step "Instalando/atualizando PSReadLine..."
        Install-Module PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser
        Write-Ok "PSReadLine atualizado"
        $report += "PSReadLine: atualizado"
    }
} catch {
    Write-Err "Falha ao verificar/instalar PSReadLine: $_"
    Write-Detail "Instale manualmente: Install-Module PSReadLine -Force -SkipPublisherCheck"
    $report += "PSReadLine: FALHOU"
}

# ═══════════════════════════════════════════════════════════════════
# 4. RESOLVER CAMINHO DO TEMA
# ═══════════════════════════════════════════════════════════════════
Write-Step "Resolvendo tema: $Theme..."

$themeConfigWin  = $null  # Caminho para PowerShell/CMD (Windows paths)
$themeConfigUnix = $null  # Caminho para Git Bash (Unix paths)

# Verificar tema customizado na pasta themes/
$themesDir = Join-Path $ScriptRoot "themes"
if (Test-Path $themesDir) {
    $customMatch = Get-ChildItem -Path $themesDir -Filter "*$Theme*.omp.*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($customMatch) {
        $themeConfigWin  = $customMatch.FullName
        Write-Ok "Tema encontrado localmente: $($customMatch.Name)"
    }
}

# Se não encontrou localmente, verificar nos built-in ou baixar do GitHub
if (-not $themeConfigWin) {
    # Tentar pasta de temas built-in (instalação non-MSIX)
    $ompThemesDir = Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes"
    $builtinPath  = Join-Path $ompThemesDir "$Theme.omp.json"

    if (Test-Path $builtinPath) {
        $themeConfigWin = $builtinPath
        Write-Ok "Tema built-in: $Theme"
    } else {
        # Instalação MSIX (winget): não tem temas locais, baixar do GitHub
        Write-Step "Baixando tema '$Theme' do repositório oficial..."
        $downloadPath = Join-Path $themesDir "$Theme.omp.json"
        if (-not (Test-Path $themesDir)) { New-Item -ItemType Directory -Path $themesDir -Force | Out-Null }
        try {
            $url = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$Theme.omp.json"
            Invoke-WebRequest -Uri $url -OutFile $downloadPath -UseBasicParsing
            $themeConfigWin = $downloadPath
            Write-Ok "Tema baixado: $downloadPath"
        } catch {
            Write-Err "Falha ao baixar tema: $_"
            Write-Detail "Baixe manualmente de: $url"
            $themeConfigWin = $url
            Write-Ok "Usando URL remota como fallback"
        }
    }
}

# Converter caminho Windows para Unix (Git Bash: C:\... → /c/...)
$themeConfigUnix = ($themeConfigWin -replace '\\','/') -replace '^([A-Za-z]):',{ '/' + $_.Groups[1].Value.ToLower() }

# ═══════════════════════════════════════════════════════════════════
# 4. POWERSHELL 5.1
# ═══════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "── PowerShell ──────────────────────────────────────────" -ForegroundColor Magenta

$ompInitBlock = @"

# ── Oh My Posh ──────────────────────────────────────────────────────
oh-my-posh init pwsh --config '$themeConfigWin' | Invoke-Expression
# ─────────────────────────────────────────────────────────────────────

# ── Autocomplete (PSReadLine) ────────────────────────────────────────
if (`$host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    `$psrlVersion = (Get-Module PSReadLine).Version
    if (`$psrlVersion -ge [version]'2.2.0') {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit
}
# ─────────────────────────────────────────────────────────────────────
"@

# Detectar TODAS as versões de PowerShell e seus profiles
$psProfiles = @()

# PowerShell 5.1 (Windows PowerShell)
$ps51 = Get-Command powershell.exe -ErrorAction SilentlyContinue
if ($ps51) {
    $ps5Profile = powershell.exe -NoProfile -Command '$PROFILE'
    if ($ps5Profile) {
        $psProfiles += @{ Version = "PowerShell 5.1"; Path = $ps5Profile.Trim() }
    }
}

# PowerShell 7+ (pwsh)
$ps7 = Get-Command pwsh.exe -ErrorAction SilentlyContinue
if ($ps7) {
    $ps7Profile = pwsh.exe -NoProfile -Command '$PROFILE'
    if ($ps7Profile) {
        $psProfiles += @{ Version = "PowerShell 7+"; Path = $ps7Profile.Trim() }
    }
}

foreach ($ps in $psProfiles) {
    Write-Step "$($ps.Version) → $($ps.Path)"
    $profPath = $ps.Path
    $profDir  = Split-Path $profPath -Parent

    if (-not (Test-Path $profDir)) {
        New-Item -ItemType Directory -Path $profDir -Force | Out-Null
    }

    $needsFullBlock = $true

    if (Test-Path $profPath) {
        $content = Get-Content $profPath -Raw -ErrorAction SilentlyContinue

        if ($content -and $content -match "oh-my-posh init pwsh") {
            # Atualizar tema se diferente
            $newContent = $content -replace "oh-my-posh init pwsh --config '.*?' \| Invoke-Expression",
                                            "oh-my-posh init pwsh --config '$themeConfigWin' | Invoke-Expression"
            if ($newContent -ne $content) {
                Set-Content -Path $profPath -Value $newContent -Encoding UTF8
                Write-Ok "Tema atualizado"
                $report += "$($ps.Version): tema atualizado"
            } else {
                Write-Skip "Tema já configurado"
                $report += "$($ps.Version): tema OK"
            }

            # Verificar se autocomplete já existe
            $currentContent = Get-Content $profPath -Raw
            if ($currentContent -match "PSReadLine") {
                Write-Skip "Autocomplete já configurado"
            } else {
                $autoCompleteBlock = @"

# ── Autocomplete (PSReadLine) ────────────────────────────────────────
if (`$host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    `$psrlVersion = (Get-Module PSReadLine).Version
    if (`$psrlVersion -ge [version]'2.2.0') {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit
}
# ─────────────────────────────────────────────────────────────────────
"@
                Add-Content -Path $profPath -Value $autoCompleteBlock -Encoding UTF8
                Write-Ok "Autocomplete adicionado"
                $report += "$($ps.Version): autocomplete adicionado"
            }
            $needsFullBlock = $false
        }
    }

    if ($needsFullBlock) {
        Add-Content -Path $profPath -Value $ompInitBlock -Encoding UTF8
        Write-Ok "Profile configurado (Oh My Posh + Autocomplete)"
        $report += "$($ps.Version): configurado"
    }
}

# ═══════════════════════════════════════════════════════════════════
# 5. GIT BASH
# ═══════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "── Git Bash ────────────────────────────────────────────" -ForegroundColor Magenta

$gitExe = Get-Command git.exe -ErrorAction SilentlyContinue
if ($gitExe) {
    Write-Step "Git detectado: $(git --version)"

    $bashrcPath = Join-Path $env:USERPROFILE ".bashrc"

    $bashOmpBlock = @"

# ── Oh My Posh ──────────────────────────────────────────────────────
eval "`$(oh-my-posh init bash --config '$themeConfigUnix')"
# ─────────────────────────────────────────────────────────────────────
"@

    if (Test-Path $bashrcPath) {
        $bashContent = Get-Content $bashrcPath -Raw -ErrorAction SilentlyContinue
        if ($bashContent -and $bashContent -match "oh-my-posh init bash") {
            $newBash = $bashContent -replace 'eval "\$\(oh-my-posh init bash --config ''.*?''\)"',
                                              "eval `"`$(oh-my-posh init bash --config '$themeConfigUnix')`""
            if ($newBash -ne $bashContent) {
                Set-Content -Path $bashrcPath -Value $newBash -Encoding UTF8NoBOM
                Write-Ok "Tema atualizado no .bashrc"
                $report += "Git Bash: tema atualizado"
            } else {
                Write-Skip ".bashrc já configurado"
                $report += "Git Bash: já configurado"
            }
        } else {
            Add-Content -Path $bashrcPath -Value $bashOmpBlock -Encoding UTF8NoBOM
            Write-Ok ".bashrc configurado"
            $report += "Git Bash: configurado"
        }
    } else {
        Set-Content -Path $bashrcPath -Value $bashOmpBlock -Encoding UTF8NoBOM
        Write-Ok ".bashrc criado e configurado"
        $report += "Git Bash: .bashrc criado"
    }
} else {
    Write-Skip "Git não encontrado — pulando Git Bash"
    $report += "Git Bash: não instalado"
}

# ═══════════════════════════════════════════════════════════════════
# 6. CMD (VIA CLINK)
# ═══════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "── CMD (Clink) ─────────────────────────────────────────" -ForegroundColor Magenta

if (-not $SkipClink) {
    $clinkExe = Get-Command clink.exe -ErrorAction SilentlyContinue
    if (-not $clinkExe) {
        Write-Step "Clink não instalado. Instalando via winget..."
        try {
            winget install chrisant996.Clink -s winget --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                            [System.Environment]::GetEnvironmentVariable("Path", "User")
                Write-Ok "Clink instalado"
            } else {
                Write-Err "Falha ao instalar Clink"
            }
        } catch {
            Write-Err "Falha ao instalar Clink: $_"
            Write-Detail "Instale manualmente: winget install chrisant996.Clink"
        }
    } else {
        Write-Ok "Clink já instalado: $(clink --version 2>$null)"
    }

    # Configurar oh-my-posh no Clink
    $clinkExe = Get-Command clink.exe -ErrorAction SilentlyContinue
    if ($clinkExe) {
        # Determinar pasta de scripts do Clink
        $clinkProfileDir = Join-Path $env:LOCALAPPDATA "clink"
        if (-not (Test-Path $clinkProfileDir)) {
            New-Item -ItemType Directory -Path $clinkProfileDir -Force | Out-Null
        }

        $clinkScriptPath = Join-Path $clinkProfileDir "oh-my-posh.lua"
        $themeConfigWinEscaped = $themeConfigWin -replace '\\','\\\\'

        $clinkLua = @"
-- Oh My Posh para CMD via Clink
load(io.popen('oh-my-posh init cmd --config "$themeConfigWinEscaped"'):read("*a"))()
"@

        Set-Content -Path $clinkScriptPath -Value $clinkLua -Encoding UTF8NoBOM
        Write-Ok "Clink configurado: $clinkScriptPath"
        $report += "CMD (Clink): configurado"
    } else {
        Write-Err "Clink não disponível após instalação — configure manualmente"
        $report += "CMD (Clink): falhou"
    }
} else {
    Write-Skip "Configuração do Clink pulada (-SkipClink)"
    $report += "CMD (Clink): pulado"
}

# ═══════════════════════════════════════════════════════════════════
# 7. WINDOWS TERMINAL — CONFIGURAR FONTE
# ═══════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "── Windows Terminal ────────────────────────────────────" -ForegroundColor Magenta

$wtPaths = @(
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json")
)

$wtConfigured = $false
foreach ($wtPath in $wtPaths) {
    if (Test-Path $wtPath) {
        $wtName = if ($wtPath -match "Preview") { "Windows Terminal Preview" } else { "Windows Terminal" }
        Write-Step "Configurando $wtName..."
        try {
            $wtRaw = Get-Content $wtPath -Raw

            # Remover comentários de linha (// ...) para JSON válido
            $wtClean = $wtRaw -replace '(?m)^\s*//.*$','' -replace '//[^"]*$',''
            $wt = $wtClean | ConvertFrom-Json

            # Garantir estrutura profiles.defaults.font
            if (-not $wt.profiles.defaults) {
                $wt.profiles | Add-Member -NotePropertyName "defaults" -NotePropertyValue ([PSCustomObject]@{}) -Force
            }
            if (-not $wt.profiles.defaults.font) {
                $wt.profiles.defaults | Add-Member -NotePropertyName "font" -NotePropertyValue ([PSCustomObject]@{}) -Force
            }

            $wt.profiles.defaults.font | Add-Member -NotePropertyName "face" -NotePropertyValue $fontFace -Force

            $wt | ConvertTo-Json -Depth 20 | Set-Content $wtPath -Encoding UTF8
            Write-Ok "$wtName: fonte '$fontFace' configurada no perfil padrão"
            $report += "$wtName`: fonte configurada"
            $wtConfigured = $true
        } catch {
            Write-Err "$wtName`: falha ao configurar — $_"
            Write-Detail "Configure manualmente: Configurações → Padrões → Aparência → Fonte → '$fontFace'"
            $report += "$wtName`: falhou (configurar manualmente)"
        }
    }
}

if (-not $wtConfigured) {
    Write-Skip "Windows Terminal não encontrado"
    $report += "Windows Terminal: não encontrado"
}

# ═══════════════════════════════════════════════════════════════════
# 8. VSCODE — CONFIGURAR FONTE DO TERMINAL
# ═══════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "── VSCode ──────────────────────────────────────────────" -ForegroundColor Magenta

$vscodePaths = @(
    (Join-Path $env:APPDATA "Code\User\settings.json"),
    (Join-Path $env:APPDATA "Code - Insiders\User\settings.json")
)

foreach ($vsPath in $vscodePaths) {
    if (Test-Path $vsPath) {
        $vsName = if ($vsPath -match "Insiders") { "VSCode Insiders" } else { "VSCode" }
        Write-Step "Verificando $vsName..."

        try {
            $vsRaw = Get-Content $vsPath -Raw

            # Verificar se já tem a fonte configurada
            if ($vsRaw -match "terminal\.integrated\.fontFamily.*$([regex]::Escape($fontFaceMono))") {
                Write-Skip "$vsName: fonte '$fontFaceMono' já configurada"
                $report += "$vsName`: já configurado"
            } elseif ($vsRaw -match '"terminal\.integrated\.fontFamily"') {
                # Atualizar fonte existente
                $vsNew = $vsRaw -replace '("terminal\.integrated\.fontFamily"\s*:\s*)"[^"]*"', "`$1`"$fontFaceMono`""
                Set-Content -Path $vsPath -Value $vsNew -Encoding UTF8
                Write-Ok "$vsName: fonte atualizada para '$fontFaceMono'"
                $report += "$vsName`: fonte atualizada"
            } else {
                Write-Detail "$vsName: adicione manualmente nas configurações:"
                Write-Detail "  `"terminal.integrated.fontFamily`": `"$fontFaceMono`""
                $report += "$vsName`: configurar manualmente"
            }
        } catch {
            Write-Err "$vsName: falha ao ler settings.json — $_"
            $report += "$vsName`: falhou"
        }
    }
}

# ═══════════════════════════════════════════════════════════════════
# 9. RELATÓRIO FINAL
# ═══════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Setup concluído!" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Resumo:" -ForegroundColor White
foreach ($line in $report) {
    $color = if ($line -match "falhou|manualmente") { "Yellow" } else { "Green" }
    Write-Host "    • $line" -ForegroundColor $color
}

Write-Host ""
Write-Host "  Próximos passos:" -ForegroundColor White
Write-Host "    1. Reinicie TODOS os terminais para aplicar" -ForegroundColor Gray
Write-Host "    2. Se ícones aparecem quebrados, confirme que a fonte" -ForegroundColor Gray
Write-Host "       '$fontFace' está selecionada no terminal" -ForegroundColor Gray
Write-Host "    3. Para trocar de tema: .\Set-Theme.ps1" -ForegroundColor Gray
Write-Host ""
