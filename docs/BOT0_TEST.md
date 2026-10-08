# BOT-0 — teste manual do usuário

A DLL fica separada do baseline. **Não iniciar processos pelo Codex.** A base anterior foi comprovada com internet conectada e Headless On; repetir essas condições evita misturar teste offline com bot. Não executar scripts de preparação/cleanup de fases antigas.

## Procedimento exato

1. No Reboot Launcher existente, abrir **Settings → Internal files → Game server**. Em **Game server type**, escolher **Custom**. No primeiro campo **Game server** (o usado antes da Season 20), colar `D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\bot0\Project Reboot 3.0.dll`, sem aspas, ou usar o botão com ícone de pasta para selecionar esse arquivo. O controller salva a alteração automaticamente. Não é em Host → Information/Options nem em Backend; não selecionar no lugar de sinum/console/memory ou no campo after Season 20. Fechar/reiniciar host e cliente já abertos normalmente para carregar a nova DLL. Manter Backend Embedded, Game server address 127.0.0.1, Detached Off; host 13.40 CL 14113327, **Headless On**, Automatic restart Off, porta 7777, Custom launch arguments vazio, Players required=1, Private IPs are operator marcado, No MCP marcado.
2. **Start Hosting**, como no teste funcional. Aguardar Apollo_Terrain / Listening on port 7777; Lawin Embedded permanece no localhost:3551.
3. Abrir **Play** no mesmo Launcher para iniciar o cliente normalmente. Aguardar o lobby existente.
4. Entrar na partida como no teste anterior e conectar ao host local.
5. No painel dev do **HOST**, aba **Game**, usar **Start Bus** já existente.
6. No **cliente**, saltar normalmente e **pousar em área plana, ampla e segura**, com espaço à direita do personagem. Permanecer vivo. Nada de clicar durante lobby/loading/ônibus/voo. O teste também exige GamePhase SafeZones; se o ônibus ainda mantiver a fase Aircraft, aguardar a mudança e repetir o clique após recusa.
7. Voltar ao painel dev **do HOST** (janela Project Reboot), aba **Game**. Localizar a nova seção **Bots**, abaixo das opções gerais. Não é uma nova opção da GUI Flutter do Launcher.
8. Clicar **Spawn 1 Bot** **uma vez**. O status passa pela fila/tick; existe no máximo uma chamada nativa por sessão. Após tentativa real, outro clique é recusado, inclusive em retorno parcial. Somente uma recusa anterior ao spawn permite novo clique sem reiniciar.
9. Observar host vivo e entidade no cliente, aproximadamente 3 m à direita e 1 m acima da posição do humano no instante do pedido. Conferir logs **[BOT]**, especialmente World/Mode/State/Manager/Mutator, SpawnBot begin, Pawn/Controller/PlayerState, counts before/after, result e Spawn completed ou [BOT][FAIL]. Esses logs vão ao console e ao **reboot.log** no diretório de trabalho do host pelo logger existente; o console capturado também pode aparecer em launcher.log. Se não souber a localização exata do reboot.log, devolver primeiro as linhas do console/launcher.log que contenham [BOT].
10. Se falhar, devolver todos os eventos **[BOT] dessa tentativa**, última mensagem/etapa, se existiu SpawnBot begin, estado de host/cliente e uma captura da entidade/ausência no cliente e do painel do host. Em crash, incluir exception code, módulo, endereço/RVA, RIP/RSP, stack quando disponível e crash log/dump existentes; não repetir com outros patches ou mudar várias opções. Preservar a cópia local dos logs antes de reiniciar, pois reboot.log é aberto com truncamento. Compartilhar trechos de bot/crash sanitizados: logs completos do launcher podem conter AUTH/senha/conta.

## Como classificar o ensaio

Conferência da primeira tentativa enviada após o build: launcher.log registrou o host carregando **reboot/artifacts/reboot3/Release/Project Reboot 3.0.dll**, não bot0, e nenhum evento [BOT]. Portanto o teste BOT-0 ainda não foi realizado nessa execução. O log também registra EXCEPTION_ACCESS_VIOLATION reading 0x00000130, com PickLootDropsHook/FortKismetLibrary.cpp:650 na stack da DLL baseline; não atribuir esse crash ao botão novo nem aplicar patches de bot para corrigi-lo. Primeiro selecionar a DLL correta. Confirmação após novo boot: painel do HOST deve mostrar Game → Bots → Spawn 1 Bot e a linha File to inject for gameServer deve apontar para o diretório bot0.

**Tentativa seguinte, 22:20–22:22:** DLL bot0 corretamente carregada, botão e passagem UI → tick confirmados em Apollo. Os 14 cliques foram recusados por `requires Fortnite 13.40 / UE 4.25`, antes da fase/manager/spawn; zero SpawnBot begin. Causa confirmada: Reboot detecta **Fortnite_Version=13.4 / Engine_Version=426**, enquanto o guard inicial exigia 425. Revisão corrigiu somente esse valor e acrescentou log version; DLL antiga do ensaio preservada em bot0/revisions/guard425. **Reiniciar host/cliente normalmente para carregar a DLL corrigida no mesmo caminho bot0.** Sala de espera continua fora do teste; pousar e aguardar SafeZones. Spawn nativo ainda não foi avaliado por esses cliques.

**BOT-0 SUCCESS:** clique processado, chamada SpawnBot registrada, host continua vivo, Pawn/AIController válidos e entidade existe/aparece no mundo. Confirmar manualmente no cliente; log de retorno completo sozinho não basta.

**BOT-0 PARTIAL:** Pawn ou Controller ausente; entidade sem comportamento/parada; existe só no servidor; não replica; replica sem cosmetic. São resultados úteis. Não corrigir AI/replicação/inventário/contadores nesta etapa. Ausência de PlayerState/posse também é registrada como retorno incompleto, sem fallback.

**Recusa de pré-condição:** não houve tentativa nativa. Devolver reason e etapa; se estiver apenas antes de SafeZones, esperar e clicar novamente. Manager/mutator/classe ausentes precisam de análise, não de múltiplos cliques automáticos.

**Crash:** devolver evidências da tentativa e interromper o ensaio. O filtro diagnóstico não impede fatal nativo nem todo crash tardio. Não confundir stack do filtro sem símbolos com stack original do jogo.

## Build e preservação

**BOT0 READY — revisão do guard compilada e pronta para novo teste manual.** Build revisado concluído em 2026-10-07, **22:24 America/Sao_Paulo**, MSBuild exit code 0; Release x64, v143 14.44.35207, SDK 10.0.26100.0. O usuário testou a revisão anterior e comprovou UI/tick/recusa; o spawn nativo e a revisão corrigida ainda não foram executados. Mantidos os warnings preexistentes dos headers/upstream, incluindo C4172/C4715; nenhum ajuste de gameplay foi feito para silenciá-los.

| Artefato | Tamanho | SHA-256 |
| --- | ---: | --- |
| bot0/Project Reboot 3.0.dll | 3.011.584 bytes | **ffd76cb452d5ef1ff9d6252d9141491c6b7cee122a4e2f8e0b29d327ca144465** |
| bot0/Project Reboot 3.0.pdb | 26.546.176 bytes | f07a6b6d6e0063e84a96f442aaafd12d550638edabbdc828859db25c24cff282 |
| reboot/patches/bot0-single-bot.patch | 19.087 bytes | 8a351fe42c83ccca584f7a338493b3e37b7ebdf70cb1303e1326970761661a9d |

Verificado: DLL PE AMD64 com flag DLL; CodeView GUID/age corresponde ao PDB; strings do botão/log presentes; propriedades de compilação/link Release x64 iguais ao baseline; diff limitado aos cinco arquivos previstos; patch passa git apply --reverse --check no checkout alterado. Os sete hashes congelados — DLL baseline/cópia Release, Launcher, três DLLs auxiliares e Shipping — continuam idênticos após a revisão. A revisão inicial também verificou metadados dos arquivos protegidos e hashes dos quatro executáveis originais Shipping/BE/EAC/FortniteLauncher sem mudança. Evidência privada da revisão em reboot/audit/bot0-guard426-build.local.json; log de build em reboot/logs/reboot3-bot0-guard426-Release.log. O Codex não iniciou host/cliente/launcher para validar.

Rollback: fechar host/cliente normalmente, selecionar **`D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\baseline\Project Reboot 3.0.dll`**, iniciar pelo fluxo habitual. SHA-256 baseline **2f6acb349a942f086a453596d0fd10c65682563b12ee25d27a7d2abdfec35c3c**. Não trocar arquivos do Fortnite nem as DLLs auxiliares.

[Implementação, riscos e compilação](BOT0_IMPLEMENTATION.md) · [Baseline congelado](BOT_BASELINE.md) · [Menu dev](DEBUG_MENU_MAP.md) · [Infraestrutura de bots](BOT_RUNTIME_MAP.md)
