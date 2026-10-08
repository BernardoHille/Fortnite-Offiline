# Instalação e preparação Project Reboot — READY B

**Registro histórico da preparação, anterior à execução manual.** O usuário posteriormente validou lobby, Apollo, Battle Bus e salto/movimentação com internet conectada. Estado atual em [REBOOT_MANUAL_VALIDATION](REBOOT_MANUAL_VALIDATION.md); reprodução em [COMO_RODAR_REBOOT](COMO_RODAR_REBOOT.md). Os resultados abaixo descrevem o momento em que nenhuma execução havia sido feita.

2026-10-07. **GUI e DLL compiladas; configuração preparada para a instalação existente. O primeiro boot permanece bloqueado.** Nenhum Fortnite, wrapper, backend, DLL ou partida foi executado. A GUI também não foi aberta, pois sua inicialização já conecta a um servidor de terceiros e pode baixar DLLs automaticamente.

## Resultado solicitado

| Item | Resultado | Evidência e limite |
| --- | --- | --- |
| PROJECT REBOOT 3.0 | **COMPILED** | Debug x64 e Release x64, MSBuild exit 0. Debug usa CRT /MT compatível com as bibliotecas vendor, sem heap/iterator checks Debug. |
| REBOOT LAUNCHER | **COMPILED** | GUI Windows x64 Release, Flutter build exit 0. Bundle completo preparado; não iniciado. |
| FORTNITE 13.40 | **RECOGNIZED** | Método real `extractGameVersion` retornou 13.40 pelo fallback do nome da pasta. Não foi uma detecção em runtime. |
| CL 14113327 | **RECOGNIZED por código/identidade** | Tabela do launcher contém 14113327 → 13.40; identidade da instalação já auditada e hash do Shipping preservado. CL não foi extraído pelo Shell nem exibido pela GUI. Reboot3 não possui guard estrito desse CL demonstrado. |
| BUILD PATH | **VALID** | Busca somente leitura encontrou um único Shipping no caminho correto; seleção e storage foram validados. |
| APOLLO SUPPORT | **FOUND** | `ChangeLevels` seleciona Apollo_Terrain para UE 4.25 no ramo não Creative. NÃO TESTADO EM RUNTIME. |
| PHOEBE/BOT CODE | **FOUND** | BotManager, SpawnBot, Pawn e Controller localizados. PlayerBot AI tem `return false` antes do ramo Phoebe; presença de código não comprova bots funcionais. |
| LAUNCH FLOW | **MAPPED** | Backend, wrappers, Shipping, auth DLL, callback de login, Reboot host DLL, travel e Athena/listen mapeados. Não executados. |

## Fontes e instalação

Somente checkouts oficiais, separados da instalação Fortnite:

- `reboot/reboot3/`: Milxnor/Project-Reboot-3.0, commit **10c659028ad9d6816f78226483f11a884bf81f57**, detached HEAD, BSD-3-Clause.
- `reboot/launcher/`: Auties00/Reboot-Launcher, commit **c6f82298b167ef2076bb59dc621f13dc5bd8d390**, detached HEAD. Nenhuma licença raiz/GUI identificada; auth_backend possui GPL-3.0.
- `reboot/tools/flutter-sdk/`: Flutter oficial **3.29.3**, Dart **3.7.2**, framework ea121f8859e4b13e47a8f845e4586164519588bc. SDK portátil, sem alteração de PATH global.
- Packages declarados pelo launcher resolvidos no cache local `reboot/tools/pub-cache/`. O commit não tinha pubspec.lock; o lock inicial foi salvo, hashado e preservado nas builds `--no-pub`. Nenhum pubspec foi atualizado.

VS 2022, MSVC v143 e Windows SDK já estavam instalados. Foram utilizados MSVC **14.44.35207**, Windows SDK **10.0.26100.0** e CMake **3.31.6-msvc6**. Não foi necessário instalar VS, Node/npm, .NET, vcpkg ou empacotador de instalador. Flutter doctor confirmou o ambiente Windows; avisos de canal detached e licenças Android estão registrados, sem instalação Android adicional.

Correções mínimas para compilar: compatibilidade CRT/iterator do Debug Reboot3; geração l10n no caminho já importado; restauração de duas declarações ausentes de constantes do downloader a partir de commit histórico oficial. Nenhuma lógica de Launch/auth/EAC/hooks/bots foi alterada. Diffs e motivos nos relatórios de build.

## Artefatos e hashes

Todos sob **D:/Games/Fortnite-Local-C2S3/reboot/artifacts/**. Headers PE confirmam AMD64 por leitura. Nenhum artefato foi carregado no jogo.

| Artefato | Caminho relativo a reboot/artifacts/ | SHA-256 |
| --- | --- | --- |
| Reboot3 Debug DLL | reboot3/Debug/Project Reboot 3.0.dll | fd7fece04c4bb823b9215093b51786b3ba33ea1676b605e99c4c105c8d0bf272 |
| Reboot3 Release DLL | reboot3/Release/Project Reboot 3.0.dll | 2f6acb349a942f086a453596d0fd10c65682563b12ee25d27a7d2abdfec35c3c |
| Launcher Release EXE | launcher/Release/reboot_launcher.exe | 5b5f43d320091cdc9efafb5acb70c89ad0038fc9e0dbf7c42ffd59ac700dd1fb |

GUI entregue com DLLs/plugins/data e settings, total de **657 arquivos** hashados no manifesto. Manter o bundle completo; o EXE isolado não basta. PDBs, tamanhos e hashes individuais estão em `reboot/audit/evidence.local.json` e [REBOOT3_BUILD](REBOOT3_BUILD.md). Não executar a GUI stock apenas para verificar a tela nesta etapa.

Builds C++ finais: Debug **1140** e Release **1120** ocorrências de warnings, **zero erros**. Há warnings upstream de retorno de endereço de temporário/local (C4172) e caminho sem retorno (C4715), com risco real em runtime. Compilar não demonstra estabilidade, ABI ou compatibilidade de offsets. GUI final: zero warnings de compilador e zero erros encontrados no log.

## Configuração da instalação existente

Build configurada: **D:/Games/FortniteLocal/13.40-CL-14113327/13.40**.

Shipping encontrado: **D:/Games/FortniteLocal/13.40-CL-14113327/13.40/FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping.exe**.

Os arquivos `.gs` e respectivos `.bak` foram preparados em **D:/Games/Fortnite-Local-C2S3/reboot/artifacts/launcher/Release/settings/**:

- `v3_game_storage`: uma versão selecionada, nome Fortnite 13.40 CL 14113327, gameVersion 13.40, location apontando para a raiz existente. Conta, senha e custom args vazios.
- `v3_dll_storage`: custom_game_server=true, DLL apontando para **Project Reboot 3.0.dll Release compilada localmente**, porta 7777.
- `v3_hosting_storage`: headless=false e auto_restart=false; campos de conta/senha/custom args vazios.

Configuração foi validada em arquivos, **sem importar pela GUI**: `_importVersion` chama `patchHeadless` no Shipping antes de persistir a versão. Essa operação foi interrompida antes de qualquer alteração, conforme o escopo. Não houve downloader, cópia, substituição ou atualização de Fortnite. Configuração em storage não comprova que a GUI exibiu ou iniciou a build.

## Arquitetura mapeada

```text
Reboot Launcher / Flutter GUI
  → seleção de build / verificação de DLLs
  → backend Lawin embutido ou backend configurado
  → wrappers FortniteLauncher e Shipping_EAC iniciados/suspensos [BLOCKER]
  → tentativa de excluir Aftermath da instalação [BLOCKER]
  → Shipping puro com args auth/provider
  → auth DLL sinum [BLOCKER]
  → callback de login
  → host Shipping recebe Project Reboot 3.0.dll
  → DllMain / Main / resolvers / hooks
  → ChangeLevels: Apollo_Terrain
  → Athena GameMode / world / listen / partida [NÃO TESTADO]
```

O host é uma DLL carregada dentro de Shipping, não um gameserver EXE independente. Client e host podem ser processos separados. Lawin usado pelo launcher vem de `reboot/launcher/auth_backend` e de assets do bundle; não é o `backend/` preservado deste projeto. Season13Runtime não foi integrado.

Portas declaradas: Lawin REST 3551, XMPP/matchmaker WS 80; primeira listen UE425 game 7777/beacon 7776. GUI tem browser remoto na porta 8080 e caminhos de Ipify/UPnP após host. Nenhum serviço foi iniciado nem porta exposta por esta preparação. Detalhes e condições em [COMPONENT_MAP](REBOOT_COMPONENT_MAP.md) e [BOT_FLOW](REBOOT_BOT_FLOW.md).

## Preservação e provas

Conferência final contra o snapshot anterior à instalação:

- **1493 arquivos** em runtime-mod/, backend/ e gameserver/vendor/FortExternalServer/: mesma lista de arquivos, tamanhos e timestamps de modificação; nenhum adicionado, removido ou modificado detectado.
- **429 arquivos** da instalação Fortnite: mesmos caminhos, tamanhos e timestamps; nenhuma diferença detectada.
- **Quatro executáveis Win64 originais**: SHA-256 idênticos ao baseline. Shipping continua **fb348e9a239a52170f2b46e99c225d4ec2bded53e40f8e7ff9daec3ac39a9f21**.
- pubspec.lock atual e cópia auditada possuem SHA-256 **db2dff71e1934f97410096529a5a83be9c7217ec12c06cc2737ac875dec4b63d**.

Limite da verificação: hashes integrais dos PAKs e de todos os componentes preservados não foram recalculados; conferência completa desses arquivos foi por lista/tamanho/timestamp. Manifesto local: `reboot/audit/evidence.local.json`, baseline: `preservation-before.local.json`, logs: `reboot/logs/`. Evidências/configurações/binários ficam ignorados no Git principal.

## Por que READY B e próximo passo

Compilação e configuração estão concluídas, mas o caminho stock de Launch requer suspensão de EAC e injeção de auth; também tenta excluir Aftermath na instalação. Abrir a GUI já tem efeitos automáticos de rede/download. Essas etapas conflitam com a fronteira definida e não foram executadas, removidas ou contornadas. Os detalhes internos de TLS da auth DLL permanecem desconhecidos.

Próximo passo: revisar [REBOOT_RUNTIME_BLOCKER](REBOOT_RUNTIME_BLOCKER.md) para determinar se existe um contexto de execução compatível com as restrições. Nenhum primeiro teste real está autorizado ou preparado para execução automática por este relatório. Não foi criado plano READY A. Trabalho encerrado nesta preparação, sem iniciar Fortnite, bots, bosses ou Season13Runtime.

Documentação completa: [DEPENDENCIES](REBOOT_DEPENDENCIES.md), [STACK_LOCK](REBOOT_STACK_LOCK.md), [LAUNCH_AUDIT](REBOOT_LAUNCH_AUDIT.md), [REBOOT3_BUILD](REBOOT3_BUILD.md), [LAUNCHER_BUILD](REBOOT_LAUNCHER_BUILD.md), [BUILD_SUPPORT](REBOOT_BUILD_SUPPORT.md), [COMPONENT_MAP](REBOOT_COMPONENT_MAP.md), [BOT_FLOW](REBOOT_BOT_FLOW.md), [PRELAUNCH](REBOOT_PRELAUNCH.md), [RUNTIME_BLOCKER](REBOOT_RUNTIME_BLOCKER.md).
