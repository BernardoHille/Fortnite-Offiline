# Bot flow — somente mapeamento

CONFIRMADO POR CÓDIGO / NÃO TESTADO EM RUNTIME. Sem modificar defaults, hooks, classes ou spawn. Paths relativos ao projeto C++ Reboot3.

```text
Apollo / Athena match
  → AFortGameModeAthena::Athena_ReadyToStartMatchHook (FortGameModeAthena.cpp ~315)
  → SetupEverythingAI (~306): PlayerBot::InitializeBotClasses + SetupServerBotManager
  → UFortServerBotManagerAthena (ai.h ~141), CachedGameMode / CachedGameState
  → FortAthenaMutator_Bots existente ou SpawnBotMutator (ai.h ~109)
  → SpawnBot / SpawnBotHook
  → Pawn / Controller / PlayerState
```

O motor/mutator pode devolver Pawn **já possuído**; a fonte não impõe sempre “criar AIController antes de Pawn”. Representar o relacionamento em vez de inventar essa ordem.

| Caminho | Arquivo / função | Responsabilidade / condição |
| --- | --- | --- |
| Init de classes | bots.h:PlayerBot::InitializeBotClasses ~52 | Se ShouldUseAIBotController false, PlayerPawn_Athena + FortPlayerControllerAthena; caso contrário BP_PlayerPawn_Athena_Phoebe |
| Gate AI | bots.h:ShouldUseAIBotController ~48 | **return false** precede retorno condicionado Fortnite>=11/engine<500; branch Phoebe de PlayerBot não ativo neste commit |
| Init de manager | ai.h:SetupServerBotManager ~141 | SpawnObject FortServerBotManagerAthena se necessário; atribui GameMode/GameState e cached mutator |
| Mutator | ai.h:SpawnBotMutator ~109 | SpawnActor FortAthenaMutator_Bots; atribui GameMode/GameState. Referência BP_Phoebe_Mutator comentada |
| Hook native/reflected | dllmain.cpp:Main ~1311–1320 | 12–13.40 usa hook reflected manager SpawnBot, exclui12.61 nesse branch |
| Boss/NPC manager hook | FortServerBotManagerAthena.cpp:SpawnBotHook ~6 | Alguns return-address paths delegam original; demais usam BotMutator.SpawnBot, PawnClass de customization; obtêm Controller/PlayerState |
| Player bots manual | bots.h:Bots::SpawnBot ~342 → PlayerBot.Initialize ~251 | Instancia wrapper; branch atual cria Controller/Pawn separadamente, liga Possess se necessário |
| Player bots AI alternativo | bots.h:PlayerBot.Initialize ~271 | Mutator.SpawnBot retorna Pawn; em versão<17 pega Pawn.GetController; ramo não selecionado pelo gate atual |
| Quantidade | FortGameModeAthena.cpp:Athena_ReadyToStartMatchHook ~960 → Bots::SpawnBotsAtPlayerStarts ~350 | Só chama se AmountOfBotsToSpawn!=0; busca player starts, chama SpawnBot |
| GameState | AI helpers / GameMode.GetGameStateAthena | CachedGameState, teams/PlayerState etc; dados reais precisam existir |

Mapeamento distingue manager bots/bosses de PlayerBot manual. Phoebe strings e hook manager estão presentes, porém navegação/AI funcional/lobby de bots não são demonstrados. Não alterar ShouldUseAIBotController, AmountOfBotsToSpawn, boss assets ou behavior nesta preparação. Bot Lobby permanece etapa futura após boot autorizado e utilizável.
