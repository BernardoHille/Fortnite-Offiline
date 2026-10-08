# Gameserver preparado, sem execução

Fonte principal: [FortExternalServer](https://github.com/OGFN-Open-sourceing/FortExternalServer/tree/season-13), licença MIT, branch season-13 e commit fixado em `configs/stack.lock.json`. O checkout fica em `vendor/FortExternalServer`, ignorado pelo Git; restaure com `scripts/restore-stack.ps1`.

`scripts/build-gameserver.ps1` compila Release x64 usando o override upstream v143 e SDK/MSVC definidos. O executável resultante fica em `vendor/FortExternalServer/Binaries/Win64/FortExternalServer.exe`, também ignorado. Não o execute nem copie para a instalação do jogo nesta fase: o upstream inicia o cliente e modifica memória do processo. Suporte de runtime e limites estão em `docs/STACK_AUDIT.md` e `docs/ARCHITECTURE.md`.
