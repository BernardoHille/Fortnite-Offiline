# Evidência Season13 / 13.40 / CL14113327

**CONFIRMADO POR CÓDIGO**, em commits fixados, **NÃO TESTADO EM RUNTIME**. Branch/version strings não comprovam estabilidade da build.

| Elemento | Arquivo / função / linha aproximada | Condição / uso | Resultado |
| --- | --- | --- | --- |
| 13.40 exato no launcher | common/lib/src/game/game_metadata.dart:_buildToGameVersion ~116 | Map 14113327 → 13.40 | RECOGNIZED por tabela; CL não é campo persistido em GameVersion |
| Descoberta versão | mesmo arquivo:extractGameVersion ~305 | Procura CrashReportClient, Shell property store; Cert/Next usa map por CL; outros Release usam suffix; fallback basename | Sem executar jogo; método nem sempre extrai CL, retorno é String gameVersion |
| Build path/Shipping | GameVersion.location; GUI import_version.dart:_importVersion ~142; LaunchButton._createGameProcess ~284 | Procura Shipping recursivo, exige match único; import guarda parent de Shipping | Configuração manual pode usar raiz existente: busca recursiva alcança Shipping. Import GUI tentaria patch, não usado |
| Identidade alvo | Arquivo Shipping já auditado | CL14113327/build13.40/hash integral fixo | BUILD PATH VALID; não confundir com guard estrito do runtime Reboot |
| Engine425 | Reboot3 addresses.cpp:Offsets::FindAll ~427; Addresses::Init ~655 | Engine_Version==425 | Layout/func pointers específicos, NÃO TESTADOS |
| Season13 | addresses.cpp:Offsets::FindAll ~443 | floor(Fortnite_Version)==12 ou13 | Offsets de runtime, não prova suporte de todos os CLs |
| 13.40 específico | dllmain.cpp:Main ~1392 | Fortnite_Version==13.40 | Ajuste de gameplay nessa versão, fonte localizada |
| Bots Season12–13.40 | dllmain.cpp:Main ~1311–1320 | >=12 && <=13.40, !=12.61 no branch de hook reflected SpawnBot | Hook UFortServerBotManagerAthena.SpawnBot; não executado |
| Apollo | dllmain.cpp:ChangeLevels ~677–704 | engine>=424 && <500, não Creative | open Apollo_Terrain; engine425 seleciona Apollo por código |
| S13 foundations | FortGameModeAthena.cpp:Athena_ReadyToStartMatchHook ~471–521 | Season13 world setup | Coral/Slurpy/farm/lobby foundations Apollo citadas |
| Phoebe | bots.h:PlayerBot::InitializeBotClasses ~66; ai.h:SpawnBotMutator ~109 | BP_PlayerPawn_Athena_Phoebe no branch AI; mutator/controller/nome | Código FOUND; o branch de PlayerBot AI está desativado por return false em ShouldUseAIBotController ~48 |
| Bot manager | ai.h:SetupServerBotManager ~141 | FortServerBotManagerAthena + CachedGameMode/GameState/BotMutator | Código FOUND; reflection runtime não validada |
| SpawnBot | FortServerBotManagerAthena.cpp:SpawnBotHook ~6; bots.h:SpawnBot ~342 | Mutator retorna pawn/controller ou PlayerBot manual | Código FOUND; não concluir Phoebe funcional no lobby só pela presença |

Reboot3 `Addresses::SetupVersion` (~22) parseia versão/engine e tem **TODO Fortnite_CL** no ramo Release usual. Busca por literal 14113327 na fonte Reboot3 não identifica um guard desse CL. O mapa exato está no launcher, e a identidade real do arquivo foi verificada separadamente; CL recognized não significa rejeição automática de outra build pelo Reboot.

CrashReportClient local não expôs FileVersion/ProductVersion por FileVersionInfo na leitura inicial. Teste do **extractGameVersion real**, em Dart sem GUI/Launch, retornou **13.40 pelo fallback do basename** (`[VERSION] Using default value`), e findFiles confirmou Shipping único/caminho correto. O teste verificou separadamente a presença do mapa CL14113327. Não afirmar que o CL foi extraído pelo Shell ou mostrado na GUI. Evidência em reboot/audit/build-recognition.local.json e reboot/logs/launcher-build-recognition-final.log.

Não se baixou Fortnite 13.40, Apollo asset ou DLL de origem alternativa. Nenhuma mudança de offset/gameplay para forçar suporte foi aplicada.
