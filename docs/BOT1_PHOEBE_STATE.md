# BOT-1 — estado da infraestrutura Phoebe

**Resposta: PARTIAL.** Controller e Pawn Phoebe estão comprovados no spawn BOT-0 e no teste BOT-1. A infraestrutura completa de comportamento, BotData e navegação funcional ainda não foi demonstrada. PARTIAL não significa que o spawn falhou: o usuário viu o bot replicado e estável, mas imóvel.

## Atualização após teste BOT-1 — 2026-10-07, 23:13

Os dois Dumps da sessão BOT-1 comprovam agora as classes completas dos objetos vivos, posse bidirecional e os componentes:

| Item | Evidência da instância |
| --- | --- |
| Controller | BlueprintGeneratedClass /Game/Athena/AI/Phoebe/BP_PhoebePlayerController.BP_PhoebePlayerController_C |
| Pawn | BlueprintGeneratedClass /Game/Athena/AI/Phoebe/BP_PlayerPawn_Athena_Phoebe.BP_PlayerPawn_Athena_Phoebe_C |
| Possession | Controller.Pawn == Pawn e Pawn.Controller == Controller; possession_match=true |
| Movement/CharacterMovement | Class /Script/FortniteGame.FortMovementComp_CharacterAthena; mesmo objeto, válido/ativo, MovementMode bruto 1 |
| PathFollowing | Class /Script/FortniteGame.FortAthenaAIBotPathFollowingComponent; válido/ativo |
| NavigationSystem | Class /Script/FortniteGame.AthenaNavSystem; presente no World Apollo |
| BrainComponent | null no diagnóstico |
| BotData | Property presente; conteúdo não interpretado |
| GetMoveStatus após pedidos | 0 / Idle |

MoveToLocation foi efetivamente chamado três vezes, com retorno **0 / Failed** em todas. Não houve RequestSuccessful nem caminhada comprovada; resultado **BOT1-C**, não BOT1-F. A existência de AthenaNavSystem e PathFollowing não comprova NavData/navmesh aptos ao agente ou um caminho utilizável. Brain null também não estabelece a causa do retorno. Não foi inicializado Brain/Nav, não foi alterado spawn e nenhuma DLL mudou na análise posterior.

Evidências e linhas do log em [BOT1_TEST.md](BOT1_TEST.md). As seções abaixo preservam a distinção entre o que havia sido observado no BOT-0 e o que era desconhecido **antes** deste teste; esta atualização supersede os itens já comprovados.

## Confirmado pelo último log BOT-0

No ensaio do usuário de **2026-10-07**, carregando a DLL bot0, o guard detectou Fortnite_Version=13.4 e Engine_Version=426. Após pouso/fase adequada, SpawnBot retornou:

| Item | Objeto observado / evidência |
| --- | --- |
| World | Apollo_Terrain |
| Pawn | BP_PlayerPawn_Athena_Phoebe_C_2147456469 |
| Controller | BP_PhoebePlayerController_C_2147456459 |
| PlayerState | FortPlayerStateAthena_2147456458 |
| BotManager | FortServerBotManagerAthena_2147480528 |
| Mutator | FortAthenaMutator_Bots_2147480527 |
| Validações pós-spawn | pawn_valid=true, ai_controller_valid=true, possessed=true, player_state_valid=true |

O guard `ai_controller_valid` testa derivação de **FortAthenaAIBotController**, não só o nome do objeto. `possessed` do BOT-0 valida Controller.Pawn == Pawn. BOT-1 adiciona também a direção Pawn.Controller == Controller antes do Move.

A classe de Pawn selecionada é:

`/Game/Athena/AI/Phoebe/BP_PlayerPawn_Athena_Phoebe.BP_PlayerPawn_Athena_Phoebe_C`

O ObjectsDump.txt local contém a classe do Controller:

`/Game/Athena/AI/Phoebe/BP_PhoebePlayerController.BP_PhoebePlayerController_C`

Isso sustenta uso de classes Phoebe reais. BOT-1 registra o GetFullName da classe dos objetos **vivos** para confirmar a identidade completa durante o novo ensaio.

PlayersLeft/AlivePlayers/NumPlayers eram 1/1/1 antes e depois; PlayerArray passou 41 → 42. Esses contadores foram apenas lidos. Não se conclui, desse incremento isolado, que o bot entrou em todos os sistemas de partida/AI. BOT-1 não muda registro, time, inventário ou skin.

## Evidências do dump disponíveis antes do teste BOT-1

- O CDO de BP_PhoebePlayerController possui um **FortAthenaAIBotPathFollowingComponent** com nome PathFollowingComponent. Um componente no objeto default não comprova que a instância retornada tem o componente correto/ativo.
- O dump lista AIController.MoveToLocation, MoveToActor, GetMoveStatus e GetPathFollowingComponent, Pawn.GetMovementComponent, Actor.GetVelocity e ActorComponent.IsActive. Disponibilidade da função não demonstra que navmesh/pathfinding da partida funciona.
- A classe **FortniteGame.AthenaNavSystem** existe no dump. Isso não comprova World.NavigationSystem criado no World Apollo da sessão.

Fonte local somente leitura: `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64\ObjectsDump.txt`. A dumpagem é evidência de nomes/classes/funções da build, não de comportamento runtime do pedido novo.

## Questões inicialmente desconhecidas, antes do teste BOT-1

| Questão | Estado / como obter evidência |
| --- | --- |
| Posse reversa Pawn.Controller | Não registrada pelo BOT-0; BOT-1 imprime as duas direções |
| MovementComponent/CharacterMovement | GetMovementComponent e property CharacterMovement, classe/validade/atividade/mode no Dump |
| BrainComponent | Property, classe e atividade no Dump; não inicia Brain/Behavior Tree |
| PathFollowing da instância | Getter nativo/property, classe e atividade no Dump |
| World.NavigationSystem | Property, classe/validade no Dump; existência não prova navmesh para o destino |
| BotData associada | Layout opaco; só presença de property no Controller será registrada; sem leitura/síntese da struct |
| Behavior Tree/Behavior | Nenhuma árvore ou execução comportamental comprovada; bot parado não demonstra uma árvore configurada |
| Aceite e caminhada nativa | Move result, GetMoveStatus, posição/velocidade por ~5 s e visual do cliente |

## Setup preservado

Em Project Reboot 3.0/FortGameModeAthena.cpp, SetupEverythingAI chama InitializeBotClasses e SetupServerBotManager. SetupAIGoalManager, SetupAIDirector e SetupNavConfig("MANG") estão comentados. Isso é evidência de um setup de Reboot parcial; **não prova por si só** que a navegação do motor esteja ausente, pois pode ter sido criada por outro caminho da build/mapa.

Esses métodos não foram ativados. Spawn usa o mutator existente, sem carregar boss/spawner/data customizada. BOT-1 usa MoveToLocation nativo por reflexão, sem BT novo. Não foi demonstrado que uma Behavior Tree seja estritamente necessária para esse pedido básico; não será adicionada como tentativa.

Para classificar movimento, usar [BOT1_TEST.md](BOT1_TEST.md). Para a decisão técnica e guards, ver [BOT1_IMPLEMENTATION.md](BOT1_IMPLEMENTATION.md). Mesmo BOT1-A demonstraria movimento/path following do ensaio, sem comprovar toda a AI Phoebe, combate ou comportamento autônomo.
