# Contribuição

Leia README.md, docs/ARCHITECTURE.md e docs/KNOWN_ISSUES.md. Preserve o ID do mod e a exigência >=0.3.93, sem teto de versão. Não reintroduza por acidente os menus KRS arquivados fora do mod.

Mantenha a lógica de comandos, input, mensagens, callbacks, inventário, boxes e saves na engine. Uma mudança gráfica não deve implementar transações paralelas. Não use package.loaded para obter módulos nativos em chunks do mod.

Não modifique KRS original, arquivos de outros mods, Gen1 ou Gen2. Integrações são opcionais e devem restaurar estados temporários em caso de erro. Não inclua ROMs, executáveis, launchers, saves, credenciais, backups ou cópias integrais das referências.

Ao alterar o payload, atualize manifesto/bootstrap, ARQUIVOS.json, documentação e baseline de upgrade da versão anterior. Preserve o baseline alpha.5 e os demais reconhecidos. Execute testes pertinentes; descreva separadamente o que foi simulado e o que foi observado no jogo.

Relatos devem conter passos de reprodução e contexto suficiente. Evite dados pessoais nos logs e imagens.
