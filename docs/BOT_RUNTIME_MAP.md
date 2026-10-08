# Infraestrutura de bot e caminho mínimo 13.40

Mapeamento realizado **antes da implementação**. Fonte primária: checkout Reboot3 congelado; busca em todo o source por SpawnBot/BotManager/FortServerBotManagerAthena/FortAthenaAIBotController/Phoebe/AIBot/AIController/BotPawn/BotCustomizationData/BotNameSettings/BotData/SpawnAI/SpawnPawn/CreateBot. Resultado bruto privado em reboot/audit/bot0-code-search.local.txt. Código existir não prova funcionamento do spawn nessa build.

| Caminho | Arquivo / função | Uso e decisão BOT-0 |
| --- | --- | --- |
| Setup AI existente | FortGameModeAthena.cpp:SetupEverythingAI ~306 | InitializeBotClasses + SetupServerBotManager; já integra lifecycle do baseline. Não modificar |
| Manager existente | ai.h:SetupServerBotManager ~141 | GameMode.ServerBotManager, CachedGameMode/GameState/CachedBotMutator; cria mutator se necessário. BOT-0 apenas verifica instâncias já existentes; não chama setup para esconder ausência |
| Mutator nativo reutilizável | FortAthenaMutator_Bots.h:AFortAthenaMutator_Bots::SpawnBot | ProcessEvent da UFunction /Script/FortniteGame.FortAthenaMutator_Bots.SpawnBot. Retorna Pawn; deixa criação/posse de Controller para o fluxo nativo |
| Uso Phoebe existente | bots.h:PlayerBot.Initialize ~270 | Manager→CachedBotMutator→SpawnBot(PawnClass, locator, location, rotation, false); em versão<17 obtém Controller do Pawn |
| Classe genérica Phoebe | bots.h:InitializeBotClasses ~66 | LoadObject BlueprintGeneratedClass de /Game/Athena/AI/Phoebe/BP_PlayerPawn_Athena_Phoebe.BP_PlayerPawn_Athena_Phoebe_C. Path usado na nova ação é este já existente, sem inventar assets |
| Controller genérico esperado | FortAthenaAIBotController.h:StaticClass | /Script/FortniteGame.FortAthenaAIBotController, base da infraestrutura Phoebe. Verificar tipo retornado; não criar Controller alternativo |
| Wrapper manual | bots.h:Bots::SpawnBot ~342 → PlayerBot.Initialize | Retorna Controller mas também aplica inventário/cosmetics/teams, PlayersLeft++ e AlivePlayers.Add no ramo atual. **Não usado**: mistura milestones e mascara registro natural |
| Spawn em massa/pregame | bots.h:SpawnBotsAtPlayerStarts ~350 | **return imediato** antes de todo o corpo. Não remover; AmountOfBotsToSpawn segue 0 |
| BotManager NPC hook | FortServerBotManagerAthena.cpp:SpawnBotHook ~6 | Usa InBotData/runtime customization; delega original ou cria locator/Pawn e aplica cosmetics de NPC/boss. Não chamar com dados inventados nem escolher henchmen/Ocean/Jules/Kit |
| Outros helpers | ai.h:SpawnAIFromSpawnerData/SpawnAIFromCustomizationData | Exigem dados/assets/inventário/cosmetics e podem destruir Pawn/Controller em falha. Não necessários ao menor teste |
| Tick dos bots manuais | NetDriver.cpp:TickFlushHook | Bots::Tick está comentado; bEnableBotTick false. Não habilitar como workaround |

## Gates preservados

`bots.h:PlayerBot::ShouldUseAIBotController` ~48 contém:

```cpp
return false;
return Fortnite_Version >= 11 && Engine_Version < 500;
```

O segundo return é inalcançável. **Razão original desconhecida:** não há justificativa junto ao gate. Chamadores incluem InitializeBotClasses, Initialize, SetupInventory e ramos de loadout/cosmetic; trocar o gate selecionaria de uma vez outra classe, spawn/Controller, inventário e registro. Seria uma mudança ampla no comportamento de todos os PlayerBots. O gate ficará intacto.

O hook manager em dllmain.cpp ~1311–1320 trata versões 12–13.40, excluindo 12.61 naquele ramo. Na 13.40 é o caminho reflected de UFortServerBotManagerAthena.SpawnBot; ele não é a UFunction do mutator. O teste escolherá o método do **mutator**, já usado pela alternativa Phoebe do próprio Reboot, sem ativar globalmente essa alternativa.

## Fluxo proposto e argumentos justificados

```text
Game / Spawn 1 Bot
  → pedido atômico, sem spawn na thread UI
  → TickFlushHook do game NetDriver
  → World Apollo_Terrain + Athena GameMode/GameState + SafeZones
  → GameMode.ServerBotManager já existente
  → CachedBotMutator já existente
  → AFortAthenaMutator_Bots::SpawnBot (uma chamada)
  → Pawn retornado
  → Controller do Pawn / PlayerState / posse observados
```

Não representar “criar AIController antes de Pawn”: o wrapper existente retorna Pawn e o chamador consulta seu Controller depois. Nenhum Controller/Pawn de fallback será forçado. Default cosmetics dependem da classe nativa; ausência/entidade parada é resultado parcial.

Argumentos: PawnClass é o path Phoebe genérico já presente; locator é o Pawn válido de um cliente conectado; localização/rotação derivadas desse Pawn, com deslocamento curto lateral e altura de segurança, sem coordenadas absolutas; bSnapToGround=false segue o call site Phoebe de PlayerBot.Initialize. Não passar BotCustomizationData/BotNameSettings/FFortAthenaAIBotRunTimeCustomizationData vazios a um hook que os dereferencia.

Não modificar PlayersLeft, AlivePlayers, NumPlayers ou PlayerArray. Registrar contagens antes/depois; alterações naturais dentro da UFunction nativa são evidência do teste. Não adicionar team/inventário/cosmetic/AI behavior.

## Referência secundária FES

Checkout FES season-13 e42ecddbce59163c6a60ab7506766c2a0adfe580, somente leitura: `Source/FortniteGame/Private/Versioning/Season13BuildProfile.cpp` ~62–65 também aponta o Pawn Phoebe genérico, controller BP_PhoebePlayerController e FortServerBotManagerAthena. `Private/AI/FortAthenaAI.cpp` resolve esses dados e possui sua própria arquitetura de spawn deferred. Nenhum código/arquitetura/helper FES será copiado ou executado; o path Pawn já tem evidência suficiente no Reboot.

Classificação nesta leitura: **caminho reutilizável encontrado**, pré-condições/retornos ainda precisam de teste manual. A ação não pode garantir navegação/ataque/replicação apenas por usar a classe Phoebe.

Após este mapeamento, o teste isolado foi implementado/compilado sem alterar os gates descritos. Ver [BOT0_IMPLEMENTATION.md](BOT0_IMPLEMENTATION.md) e [BOT0_TEST.md](BOT0_TEST.md). A classificação final é BOT0 READY para ensaio manual, não bot funcionando já confirmado.

Primeiro ensaio manual: o Reboot detectou Engine_Version **426** para Fortnite_Version 13.4. O guard exclusivo da nova ação exigia incorretamente 425 e recusou todos os 14 pedidos antes de SpawnBot. Corrigido somente esse guard para 426, com log dos valores; a função nativa e os gates originais acima permanecem intactos. A infraestrutura de spawn ainda aguarda teste que passe dessa validação.
