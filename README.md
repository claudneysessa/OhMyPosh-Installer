# Oh My Posh - Setup Automatico para Windows

Kit de implantacao do [Oh My Posh](https://ohmyposh.dev/) para todos os terminais compativeis do Windows.
Um comando configura tudo em qualquer maquina nova.

---

## Pre-requisitos

| Requisito | Motivo |
|---|---|
| Windows 10/11 | Sistema operacional suportado |
| [winget](https://learn.microsoft.com/windows/package-manager/winget/) | Gerenciador de pacotes (vem com o Windows 11, no 10 instale pela Microsoft Store) |
| PowerShell **como Administrador** | Necessario para instalar fontes e pacotes |

---

## Instalacao Rapida

### 1. Clonar ou copiar esta pasta para a maquina

```
C:\tools\OhMyPosh-Installer\
```

### 2. Executar o setup como Administrador

Abra o PowerShell **como Administrador**, navegue ate a pasta e rode:

```powershell
cd C:\tools\OhMyPosh-Installer
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Setup-OhMyPosh.ps1
```

### 3. Reiniciar todos os terminais

Feche e reabra todos os terminais (PowerShell, CMD, Git Bash, VSCode, Windows Terminal).

Pronto. O Oh My Posh esta configurado em todos os terminais.

---

## Parametros do Setup

O script `Setup-OhMyPosh.ps1` aceita parametros para customizar a instalacao:

```powershell
.\Setup-OhMyPosh.ps1 [-Theme <nome>] [-Font <nome>] [-SkipFont] [-SkipClink]
```

| Parametro | Padrao | Descricao |
|---|---|---|
| `-Theme` | `bubbles` | Nome do tema (customizado, built-in ou do GitHub) |
| `-Font` | `FiraCode` | Nome da Nerd Font a instalar |
| `-SkipFont` | -- | Pula instalacao da fonte (se ja tem uma Nerd Font) |
| `-SkipClink` | -- | Pula instalacao do Clink (se nao usa CMD) |

### Exemplos

```powershell
# Setup padrao (tema bubbles, fonte FiraCode)
.\Setup-OhMyPosh.ps1

# Usar tema agnoster com fonte CascadiaCode
.\Setup-OhMyPosh.ps1 -Theme "agnoster" -Font "CascadiaCode"

# Usar tema customizado da pasta themes/
.\Setup-OhMyPosh.ps1 -Theme "lightgreen"

# Pular fonte e Clink (instalacao minima)
.\Setup-OhMyPosh.ps1 -SkipFont -SkipClink
```

---

## O que o Setup configura

O script faz tudo automaticamente. Abaixo esta o detalhamento de cada etapa para referencia ou configuracao manual.

### 1. Instalacao do Oh My Posh

```powershell
winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
```

Apos instalar, atualiza o `PATH` da sessao:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")
```

### 2. Instalacao da Nerd Font

```powershell
oh-my-posh font install FiraCode
```

> A Nerd Font e necessaria para que os icones e glifos do prompt aparecam corretamente.
> Sem ela, voce vera quadrados ou caracteres quebrados.

### 3. PSReadLine (Autocomplete)

O setup instala/atualiza o modulo PSReadLine e configura nos profiles:

```powershell
Install-Module PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser
```

Configuracao adicionada ao profile:

```powershell
if ($host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    $psrlVersion = (Get-Module PSReadLine).Version
    if ($psrlVersion -ge [version]'2.2.0') {
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
```

| Atalho | Funcao |
|---|---|
| `Tab` | Menu de completar comandos |
| `Seta cima` | Busca no historico pelo que voce digitou |
| `Seta baixo` | Busca no historico (proximo resultado) |
| `Ctrl+D` | Sair do terminal |

No PowerShell 7+ tambem ativa sugestoes preditivas em lista visual baseadas no historico.

### 4. Resolucao do tema

O setup procura o tema nesta ordem:

1. **Pasta `themes/` local** -- busca arquivo `*<nome>*.omp.*` dentro de `C:\tools\OhMyPosh-Installer\themes\`
2. **Temas built-in** -- busca em `%LOCALAPPDATA%\Programs\oh-my-posh\themes\`
3. **Download do GitHub** -- baixa de `https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/<nome>.omp.json` e salva na pasta `themes/`

### 5. PowerShell 5.1

O setup detecta o profile automaticamente:

```powershell
# Descobrir caminho do profile:
powershell.exe -NoProfile -Command '$PROFILE'
# Exemplo: D:\Documentos\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
```

Adiciona ao profile:

```powershell
oh-my-posh init pwsh --config 'C:\tools\OhMyPosh-Installer\themes\bubbles.omp.json' | Invoke-Expression
```

**Configuracao manual** -- se precisar editar o profile manualmente:

```powershell
# Abrir profile no editor
notepad $PROFILE

# Adicionar ou alterar a linha de init do Oh My Posh:
oh-my-posh init pwsh --config 'C:\caminho\para\tema.omp.json' | Invoke-Expression
```

### 6. PowerShell 7+

Mesmo processo do PowerShell 5.1, porem em profile separado:

```powershell
# Descobrir caminho do profile:
pwsh.exe -NoProfile -Command '$PROFILE'
# Exemplo: D:\Documentos\PowerShell\Microsoft.PowerShell_profile.ps1
```

> Os dois profiles (5.1 e 7+) sao configurados independentemente para que ambas as versoes funcionem.

### 7. Git Bash

O setup cria/atualiza o arquivo `%USERPROFILE%\.bashrc`:

```bash
eval "$(oh-my-posh init bash --config '/c/tools/OhMyPosh-Installer/themes/bubbles.omp.json')"
```

> Note que o caminho usa formato Unix (`/c/...` em vez de `C:\...`). O setup faz essa conversao automaticamente.

**Configuracao manual:**

```bash
# Abrir .bashrc
notepad ~/.bashrc

# Adicionar:
eval "$(oh-my-posh init bash --config '/c/tools/OhMyPosh-Installer/themes/seu-tema.omp.json')"
```

### 8. CMD (via Clink)

O setup instala o [Clink](https://chrisant996.github.io/clink/) e cria o script Lua:

```powershell
winget install chrisant996.Clink -s winget --accept-package-agreements --accept-source-agreements
```

Arquivo criado em `%LOCALAPPDATA%\clink\oh-my-posh.lua`:

```lua
-- Oh My Posh para CMD via Clink
load(io.popen('oh-my-posh init cmd --config "C:\\tools\\OhMyPosh-Installer\\themes\\bubbles.omp.json"'):read("*a"))()
```

> O CMD nao suporta Oh My Posh nativamente. O Clink adiciona essa capacidade.

**Configuracao manual:**

```
1. Instale o Clink: winget install chrisant996.Clink
2. Crie/edite: %LOCALAPPDATA%\clink\oh-my-posh.lua
3. Conteudo:
   load(io.popen('oh-my-posh init cmd --config "C:\\caminho\\para\\tema.omp.json"'):read("*a"))()
```

### 9. Windows Terminal -- Fonte

O setup configura a Nerd Font como fonte padrao no Windows Terminal:

```
Arquivo: %LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

Alteracao feita:

```json
{
  "profiles": {
    "defaults": {
      "font": {
        "face": "FiraCode Nerd Font"
      }
    }
  }
}
```

**Configuracao manual:**

1. Abra o Windows Terminal
2. `Ctrl+,` (Configuracoes)
3. Menu lateral: **Padrao** > **Aparencia**
4. **Tipo de fonte**: selecione a Nerd Font instalada (ex: `FiraCode Nerd Font`)
5. Salvar

### 10. VSCode -- Fonte do Terminal

O setup verifica e atualiza a fonte do terminal integrado do VSCode:

```
Arquivo: %APPDATA%\Code\User\settings.json
```

Configuracao adicionada/atualizada:

```json
{
  "terminal.integrated.fontFamily": "FiraCode Nerd Font Mono"
}
```

**Configuracao manual:**

1. Abra o VSCode
2. `Ctrl+,` (Configuracoes)
3. Pesquise: `terminal.integrated.fontFamily`
4. Defina: `FiraCode Nerd Font Mono`

---

## Trocar de Tema

### Modo interativo (lista todos os temas)

```powershell
cd C:\tools\OhMyPosh-Installer
.\Set-Theme.ps1
```

Exibe uma lista numerada com temas customizados `[C]` e built-in. Escolha o numero e o tema e aplicado em todos os profiles do PowerShell.

### Aplicar tema direto por nome

```powershell
.\Set-Theme.ps1 -Name "agnoster"
```

Se o tema nao existe localmente, ele e baixado automaticamente do GitHub.

### Pre-visualizar sem aplicar

```powershell
.\Set-Theme.ps1 -Preview "paradox"
```

Carrega o tema na sessao atual sem alterar os profiles. Ao reabrir o terminal, volta ao tema anterior.

### Ativacao basica (sem setup completo)

Para apenas adicionar a linha minima do Oh My Posh nos profiles, sem instalar nada:

```powershell
.\Activate-Basic-OhMyPosh.ps1

# Com tema especifico:
.\Activate-Basic-OhMyPosh.ps1 -Theme "C:\tools\OhMyPosh-Installer\themes\lightgreen.omp.json"
```

---

## Temas Customizados

Para adicionar um tema customizado:

1. Baixe ou crie um arquivo `.omp.json` (catalogo: https://ohmyposh.dev/docs/themes)
2. Coloque na pasta `C:\tools\OhMyPosh-Installer\themes\`
3. Aplique com `.\Set-Theme.ps1` ou `.\Set-Theme.ps1 -Name "nome-do-tema"`

### Temas incluidos

| Tema | Descricao |
|---|---|
| `M365Princess` | Colorido, estilo Microsoft 365 |
| `bubbles` | Tema padrao do setup, segmentos arredondados |
| `lightgreen` | Prompt verde claro, clean |
| `clean-minimal` | Minimalista, uma linha |
| `powerline-dark` | Powerline classico, fundo escuro |
| `atomicBit` | Moderno, com icones |
| `1_shell` | Simples, informativo |

---

## Estrutura do Projeto

```
C:\tools\OhMyPosh-Installer\
|-- Setup-OhMyPosh.ps1          # Instalacao completa (rodar 1x por maquina)
|-- Set-Theme.ps1                # Troca rapida de tema
|-- Activate-Basic-OhMyPosh.ps1 # Ativacao minima (sem instalar nada)
|-- fix-encoding.ps1             # Utilitario: corrige encoding para UTF-8 BOM
|-- check-encoding.ps1           # Utilitario: verifica encoding de arquivo
|-- README.md                    # Este documento
|-- themes/                      # Temas customizados (.omp.json)
|   |-- M365Princess.omp.json
|   |-- bubbles.omp.json
|   |-- lightgreen.omp.json
|   |-- clean-minimal.omp.json
|   |-- powerline-dark.omp.json
|   |-- atomicBit.omp.json
|   +-- 1_shell.omp.json
+-- .claude/
    +-- commands/
        |-- deploy.md            # Skill: /deploy
        +-- theme.md             # Skill: /theme
```

---

## Arquivos Modificados pelo Setup

O setup cria ou modifica os seguintes arquivos no sistema:

| Arquivo | Terminal |
|---|---|
| `$PROFILE` do PowerShell 5.1 | PowerShell 5.1 |
| `$PROFILE` do PowerShell 7+ | PowerShell 7+ (pwsh) |
| `%USERPROFILE%\.bashrc` | Git Bash |
| `%LOCALAPPDATA%\clink\oh-my-posh.lua` | CMD |
| Windows Terminal `settings.json` | Windows Terminal |
| VSCode `settings.json` | VSCode Terminal |

Para descobrir o caminho exato dos profiles do PowerShell:

```powershell
# PowerShell 5.1
powershell.exe -NoProfile -Command '$PROFILE'

# PowerShell 7+
pwsh.exe -NoProfile -Command '$PROFILE'
```

---

## Movendo a Pasta para Outro Local

Se voce mover a pasta `OhMyPosh-Installer` para outro diretorio, os terminais vao exibir **CONFIG NOT FOUND** porque os profiles ainda apontam para o caminho antigo.

Para corrigir, re-execute o setup a partir do novo local:

```powershell
cd C:\novo\caminho\OhMyPosh-Installer
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Setup-OhMyPosh.ps1
```

Ou corrija manualmente cada profile, substituindo o caminho antigo pelo novo em:

1. **PowerShell 5.1/7+** -- edite `$PROFILE` e atualize o `--config '...'`
2. **Git Bash** -- edite `~/.bashrc` e atualize o `--config '...'`
3. **CMD** -- edite `%LOCALAPPDATA%\clink\oh-my-posh.lua` e atualize o caminho

---

## Troubleshooting

### CONFIG NOT FOUND

O tema configurado no profile nao foi encontrado no caminho especificado.

**Causa:** a pasta foi movida ou o arquivo do tema foi deletado.

**Solucao:**

```powershell
# Re-executar o setup para reconfigurar tudo:
cd C:\tools\OhMyPosh-Installer
.\Setup-OhMyPosh.ps1

# Ou aplicar um tema manualmente:
.\Set-Theme.ps1 -Name "bubbles"
```

### Icones aparecem como quadrados

A fonte do terminal nao e uma Nerd Font.

**Solucao:**

```powershell
# Instalar Nerd Font:
oh-my-posh font install FiraCode

# Depois configure a fonte no terminal:
# - Windows Terminal: Configuracoes > Padrao > Aparencia > Tipo de fonte
# - VSCode: Configuracoes > terminal.integrated.fontFamily
```

### Oh My Posh nao carrega no CMD

O Clink precisa estar instalado para o CMD funcionar com Oh My Posh.

**Solucao:**

```powershell
winget install chrisant996.Clink
# Depois re-execute o setup ou crie o script Lua manualmente
```

### Sugestoes preditivas nao aparecem

O PSReadLine precisa ser versao 2.2.0 ou superior, e so funciona no PowerShell 7+.

**Solucao:**

```powershell
# Verificar versao:
Get-Module PSReadLine -ListAvailable | Select-Object Version

# Atualizar:
Install-Module PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser
```
