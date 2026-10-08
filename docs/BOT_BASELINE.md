# Baseline funcional congelado para BOT-0

Data de referência: **2026-10-07**, America/Sao_Paulo. O marco manual existente é lobby Lawin, host Apollo/listen 7777, Battle Bus, salto/Pawn e movimentação. Headless On no teste definitivo; internet conectada. Não repetir o boot pelo Codex.

| Item | Registro |
| --- | --- |
| Upstream Project Reboot 3.0 | 10c659028ad9d6816f78226483f11a884bf81f57 |
| Commit local que congela o source efetivamente compilado | **ac95df9bc4a00e75ba414277d63bcca8e7fcabd1** |
| Tag local no checkout reboot/reboot3 | **baseline/reboot-13.40-playable** |
| Branch de trabalho separada | **bot0/reboot-13.40-single-bot** |
| Configuração funcional | Release x64, v143 14.44.35207, Windows SDK 10.0.26100.0 |
| DLL funcional SHA-256 | **2f6acb349a942f086a453596d0fd10c65682563b12ee25d27a7d2abdfec35c3c** |
| DLL original preservada | reboot/artifacts/reboot3/Release/Project Reboot 3.0.dll |
| Cópia congelada | **reboot/artifacts/reboot3/baseline/Project Reboot 3.0.dll** |
| PDB congelado | Mesmo diretório baseline, Project Reboot 3.0.pdb |
| Snapshot privado | reboot/audit/bot0-baseline.local.json |

O checkout upstream estava detached com **apenas o ajuste Debug CRT/iterator já documentado** no vcxproj. Esse ajuste preexistente foi registrado no commit local antes de editar BOT-0; não mudou Release, gameplay ou o arquivo DLL. A tag guarda essa combinação real de source + patch de build, evitando apresentar o SHA upstream limpo como se contivesse o ajuste.

O snapshot guarda também hashes de Launcher EXE, sinum/console/memory e Shipping. Não contém credenciais. Backend/launcher/settings/jogo não são editados nesta etapa. Runtime próprio Season13Runtime e FES permanecem separados.

A DLL BOT-0 será compilada em **reboot/artifacts/reboot3/bot0/**, com intermediários/PDB próprios. Nenhuma cópia automática para Release, nenhuma alteração automática da DLL selecionada no launcher. Rollback: selecionar a DLL **baseline** acima; não restaurar/extrair Fortnite nem atualizar backend.

Verificação após o build BOT-0: os sete hashes do snapshot continuam idênticos. DLL nova/PDB gerados em bot0; resultado e instruções em [BOT0_TEST.md](BOT0_TEST.md).

As refs Git mencionadas são **locais do checkout upstream ignorado**, não branches/tags publicadas no repositório do projeto. Patches/documentação preservam a alteração para revisão sem redistribuir DLLs/game/SDK.
