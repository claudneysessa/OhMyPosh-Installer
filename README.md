# Oh My Posh — Setup Automático

Kit de implantação do Oh My Posh para todos os terminais compatíveis do Windows.
Um comando configura tudo em qualquer máquina nova.

## O que é implantado

| Componente | Detalhe |
|---|---|
| Oh My Posh | Instalado via winget |
| FiraCode Nerd Font | Fonte com ícones para o prompt |
| PSReadLine | Autocomplete preditivo no PowerShell |
| Clink | Suporte ao Oh My Posh no CMD |
| Tema | bubbles (customizável) |

## Terminais configurados

- **PowerShell 5.1** — profile + autocomplete
- **PowerShell 7+** — profile + autocomplete
- **Git Bash** — .bashrc
- **CMD** — via Clink + script Lua
- **Windows Terminal** — fonte Nerd Font aplicada automaticamente
- **VSCode** — verifica/configura fonte do terminal integrado

## Como implantar

### 1. Clonar ou copiar esta pasta para a máquina

```
E:\Powershell\OhMyPosh\
```

### 2. Executar o setup como Administrador

Abra o PowerShell **como Administrador** e rode:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Setup-OhMyPosh.ps1
```

Pronto. Feche e reabra todos os terminais.

### 3. Parâmetros opcionais

```powershell
# Usar outro tema
.\Setup-OhMyPosh.ps1 -Theme "agnoster"

# Usar outra fonte
.\Setup-OhMyPosh.ps1 -Font "CascadiaCode"

# Pular instalação de fonte (se já tem)
.\Setup-OhMyPosh.ps1 -SkipFont

# Pular instalação do Clink (não precisa de CMD)
.\Setup-OhMyPosh.ps1 -SkipClink
```

## Trocar de tema

Aplicar um tema diretamente por nome (baixa do GitHub se necessário):

```powershell
.\Set-Theme.ps1 -Name "bubbles"
```

Listar todos os temas disponíveis (customizados + built-in) interativamente:

```powershell
.\Set-Theme.ps1
```

Para pré-visualizar sem aplicar:

```powershell
.\Set-Theme.ps1 -Preview "paradox"
```

## Estrutura da pasta

```
OhMyPosh/
├── Setup-OhMyPosh.ps1     # Instalação completa (rodar 1x por máquina)
├── Set-Theme.ps1           # Troca rápida de tema
├── README.md
├── themes/
│   ├── bubbles.omp.json        # Tema padrão
│   ├── clean-minimal.omp.json  # Tema minimalista
│   └── powerline-dark.omp.json # Tema powerline escuro
└── .claude/
    └── commands/
        ├── deploy.md       # Skill: /deploy
        └── theme.md        # Skill: /theme
```

## Autocomplete no PowerShell

O setup configura o PSReadLine com:

| Atalho | Função |
|---|---|
| `Tab` | Menu de completar comandos |
| `Seta cima` | Busca no histórico pelo que você digitou |
| `Seta baixo` | Busca no histórico (próximo resultado) |
| `Ctrl+D` | Sair do terminal |

No PowerShell 7+ também ativa sugestões preditivas em lista visual baseadas no histórico.

## Temas customizados

Para adicionar um tema customizado, coloque o arquivo `.omp.json` na pasta `themes/` e rode `.\Set-Theme.ps1` para aplicá-lo.

Temas podem ser baixados de: https://ohmyposh.dev/docs/themes
