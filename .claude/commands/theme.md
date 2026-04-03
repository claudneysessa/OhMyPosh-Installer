# Trocar Tema Oh My Posh

Troca o tema do Oh My Posh em todos os terminais configurados.

## Execução

Se o usuário especificou um nome de tema, execute o script Set-Theme.ps1 passando o nome:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "e:/Powershell/OhMyPosh/Set-Theme.ps1" -Name "$ARGUMENTS"
```

Se o usuário não especificou um tema, execute o script interativamente para listar opções:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "e:/Powershell/OhMyPosh/Set-Theme.ps1"
```

Para apenas pré-visualizar um tema sem aplicar:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "e:/Powershell/OhMyPosh/Set-Theme.ps1" -Preview "nome-do-tema"
```

Após a troca, lembre ao usuário de reiniciar os terminais ou rodar `. $PROFILE` no PowerShell.
