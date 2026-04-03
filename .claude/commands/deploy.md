# Deploy Oh My Posh

Executa a implantação completa do Oh My Posh em todos os terminais compatíveis da máquina.

## O que faz

1. Instala Oh My Posh via winget
2. Instala a fonte FiraCode Nerd Font
3. Instala Clink para suporte ao CMD
4. Configura o tema M365Princess em:
   - PowerShell 5.1
   - PowerShell 7+
   - Git Bash (.bashrc)
   - CMD (via Clink)
5. Configura autocomplete (PSReadLine) no PowerShell
6. Configura a fonte Nerd Font em:
   - Windows Terminal
   - VSCode

## Execução

Execute o script de setup como administrador:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "e:/Powershell/OhMyPosh/Setup-OhMyPosh.ps1"
```

Se o usuário pedir para usar um tema diferente, passe o parâmetro `-Theme`:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "e:/Powershell/OhMyPosh/Setup-OhMyPosh.ps1" -Theme "nome-do-tema"
```

Se o usuário pedir para trocar apenas o tema (sem reinstalar tudo), execute:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "e:/Powershell/OhMyPosh/Set-Theme.ps1"
```

Após a execução, informe ao usuário que ele precisa reiniciar todos os terminais para ver as mudanças.
