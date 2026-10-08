# BOT-1 — movimento manual do bot BOT-0

**BOT1 PARTIAL:** MoveTo implementado e DLL compilada Release x64; o teste manual posterior retornou **Failed nas três chamadas efetivas**, classificação BOT1-C. Caminhada não foi demonstrada. Alvo único: Fortnite **13.40 / CL 14113327**, Apollo, com **Engine_Version=426 detectado pelo Reboot**. Escopo: enviar um destino ao último bot criado pelo BOT-0 e diagnosticar o resultado. Evidências e procedimento em [BOT1_TEST.md](BOT1_TEST.md). O Codex não iniciou Launcher, host ou cliente.

## Baseline preservado antes da edição

O usuário confirmou bot visível no cliente, servidor estável e bot parado, aparentemente com a mesma skin do jogador. O log correspondente registra Pawn Phoebe, Controller Phoebe, PlayerState e posse válidos no retorno do spawn. Isso comprova BOT-0, sem comprovar navegação ou comportamento.

| Registro local em reboot/reboot3 | Valor |
| --- | --- |
| Upstream fixado | 10c659028ad9d6816f78226483f11a884bf81f57 |
| Baseline anterior de gameplay | ac95df9bc4a00e75ba414277d63bcca8e7fcabd1 |
| Commit que congela o BOT-0 funcional | **36915dbee72affd1b6ca51e591b297e3e4a30971** |
| Tag criada antes de editar | **baseline/bot0-spawn-working** |
| Branch de implementação | **bot1/reboot-13.40-manual-move** |
| Cópia da DLL funcional | reboot/artifacts/reboot3/bot0-working/Project Reboot 3.0.dll |
| SHA-256 dessa DLL | ffd76cb452d5ef1ff9d6252d9141491c6b7cee122a4e2f8e0b29d327ca144465 |
| PDB preservado junto da DLL | SHA-256 f07a6b6d6e0063e84a96f442aaafd12d550638edabbdc828859db25c24cff282 |

DLL/PDB de bot0 e os baselines anteriores continuam em seus diretórios. A tag e a branch são locais ao checkout upstream ignorado, sem publicação automática. Trechos técnicos do teste anterior estão em `reboot/audit/bot0-working-events.local.txt`; não incluem AUTH ou dados de conta.

## Alterações

Somente três arquivos de `reboot/reboot3/Project Reboot 3.0/` mudam em relação a esse commit:

| Arquivo | Alteração |
| --- | --- |
| Bot0.h | RequestDump e RequestMove |
| Bot0.cpp | Referências de debug ao retorno do spawn, diagnóstico, reflexão do MoveToLocation e observação limitada |
| gui.h | Dump Bot State e Move Bot To Player na seção Bots da aba Game do menu dev do host |

O botão Spawn 1 Bot permanece. A única adição dentro de seu caminho de spawn é guardar World, GameState, BotManager, Controller, Pawn e PlayerState retornados. Classe Phoebe, mutator, argumentos, guards e limite de uma tentativa nativa por host permanecem como no BOT-0. NetDriver.cpp e o projeto/configuração de build não recebem alterações BOT-1.

O patch `reboot/patches/bot1-manual-move.patch` é relativo ao commit **36915dbee72affd1b6ca51e591b297e3e4a30971**. O patch BOT-0 anterior permanece separado e intacto.

Launcher, Lawin, backend, auth, matchmaker, sinum/console/memory, Fortnite, PAKs, EAC/BE, lifecycle da partida, Battle Bus, storm e loot não foram editados. Sem ajustes de skin, inventário, armas, combate ou Behavior Tree.

## Referências e contexto de execução

RequestDump/RequestMove apenas enfileiram uma ação atômica na thread de UI. `ProcessPending`, já chamado pelo TickFlushHook BOT-0, executa a ação no tick do **World.NetDriver**. Drivers secundários não consomem a fila. Uma ação de debug pendente impede enfileirar outra até seu consumo; cliques recusados são registrados.

DebugBotState usa o FWeakObjectPtr existente como armazenamento de índice/serial, mais identidade do ponteiro e FName completo. Como o Get() upstream não verifica serial e a igualdade FName upstream ignora Number, Resolve faz essas verificações explicitamente, além de object array, classe legível e PendingKill. Não fixa objetos no GC, não altera serial e não modifica o helper global. São verificações pontuais de identidade, não uma garantia absoluta contra alterações internas do motor.

Referências de outro World/GameState são descartadas. Dump/Move antes de um spawn neste host são recusados. Não procura outro bot como fallback, não faz novo SpawnBot nem Possess.

## Diagnóstico

Dump Bot State apenas lê/reflete e registra:

- Controller/Pawn/PlayerState, endereço, nome e nome completo da classe;
- Controller.Pawn e Pawn.Controller, com `possession_match` bidirecional;
- Pawn.GetMovementComponent, CharacterMovement, BrainComponent e PathFollowing;
- validade dos componentes, ActorComponent.IsActive quando resolvível e MovementMode bruto quando disponível;
- BotManager, World e World.NavigationSystem;
- presença da property BotData no Controller, sem interpretar sua struct;
- AIController.GetMoveStatus quando disponível.

MovementComponent vem de `/Script/Engine.Pawn.GetMovementComponent`. PathFollowing vem de `/Script/AIModule.AIController.GetPathFollowingComponent`, com leitura da property conhecida como alternativa somente de diagnóstico. A leitura de CharacterMovement/BrainComponent usa properties conhecidas. Getters só são chamados quando o objeto deriva da classe proprietária da UFunction.

BotData tem layout opaco neste wrapper: o spawn usado não recebe BotData. A existência de uma property não comprova conteúdo, manager registration ou AI configurada. Não fabricamos esse conteúdo. Ver [BOT1_PHOEBE_STATE.md](BOT1_PHOEBE_STATE.md).

## Mecanismo nativo escolhido

Não existe helper MoveTo pronto em AIController.h deste Reboot. O ObjectsDump.txt da instalação alvo lista **AIController.MoveToLocation**, MoveToActor, GetMoveStatus e GetPathFollowingComponent. Foi escolhido **MoveToLocation via UFunction/ProcessEvent existente**:

```text
HOST / Game / Bots / Move Bot To Player
  → RequestMove
  → ProcessPending / ProcessDebugBody, no tick existente
  → referências do último SpawnBot
  → validação de posse/componentes/nav/humano
  → localização do humano naquele instante
  → AIController.MoveToLocation, uma chamada
  → resultado real e observação t=0…~5 s
```

A assinatura de referência é documentada para UE **4.27**, não tomada como prova isolada de compatibilidade 13.40: [AIController UE4](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/AIController?application_version=4.27). A função existe no dump local da 13.40; o formato dos parâmetros é conferido na UFunction em runtime antes de enviar o pedido.

ReflectedCall exige o conjunto exato de nove nomes abaixo, lê o tamanho do buffer e offsets pelos helpers/Offsets já existentes, verifica limites e regiões sem sobreposição e exige bools nativos (FieldMask=0xff). Não usa uma struct C++ presumida com padding nem endereço absoluto novo. Os tipos escalares/FVector são os tipos UE4 do wrapper e da assinatura de referência; a validação não é um verificador completo de tipos FProperty. Divergências nos campos/tamanho/bools recusam a chamada, sem tentar outra ABI. Getters usam o mesmo mecanismo para funções com apenas ReturnValue.

| Parâmetro | Valor |
| --- | --- |
| Dest | Snapshot da localização do Pawn humano |
| AcceptanceRadius | **400 Unreal units**, aproximadamente 4 m |
| bStopOnOverlap | false |
| bUsePathfinding | true |
| bProjectDestinationToNavigation | true |
| bCanStrafe | false |
| FilterClass | null, filtro padrão nativo |
| bAllowPartialPath | false |
| ReturnValue | Resultado byte lido após ProcessEvent |

Os valores de Failed, AlreadyAtGoal e RequestSuccessful são resolvidos no **UEnum runtime EPathFollowingRequestResult**, com validação de disponibilidade/faixa/distinção. Logs sempre mostram o valor bruto e seu nome. GetMoveStatus resolve Idle/Waiting/Paused/Moving via enum runtime. [RequestResult UE4](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/PathFollowingRequestResult?application_version=4.27), [Status UE4](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/PathFollowingStatus?application_version=4.27).

Não há MoveToActor, tracking contínuo, retry automático, BT, teleport, SetActorLocation ou escrita de velocidade. Outro clique explícito pode enviar outro pedido normal ao mesmo Controller; observação anterior é encerrada antes de avaliar esse clique. Stop Bot opcional não foi adicionado.

## Pré-condições do Move

1. World atual do game NetDriver, host listening, Apollo_Terrain, Athena GameMode/GameState, Fortnite 13.40, engine detectado 426 e GamePhase SafeZones. Pousar em chão aberto continua requisito manual: SafeZones não comprova pouso.
2. Bot salvo válido, Controller derivado de AAIController e Pawn Athena, com posse **em ambas as direções**. Recusa BOT1-D/BOT1-E se inadequado.
3. MovementComponent derivado de PawnMovementComponent, PathFollowing derivado de PathFollowingComponent e NavigationSystem derivado de NavigationSystemV1, já existentes. A atividade/mode dos componentes é registrada, sem forçar estados. Presença desses objetos não comprova navmesh utilizável para aquela área.
4. Humano escolhido entre ClientConnections: primeiro PlayerController Athena com PlayerState válido, property bIsABot disponível e false, Pawn Athena válido diferente do bot. Sem fallback para host. Transform finito.
5. Distância euclidiana ao humano: se ≤400 UU, registra que já está perto, sem emitir MoveTo e sem considerar falha. Para avaliar caminhada, distanciar o humano 20–50 m.
6. Função, parâmetros e enum compatíveis. Uma única chamada efetiva se todos os guards passam. O pedido só é marcado como submetido imediatamente antes da chamada.

O baseline chama InitializeBotClasses e SetupServerBotManager, mas SetupAIGoalManager, SetupAIDirector e SetupNavConfig("MANG") estão comentados em FortGameModeAthena.cpp. Permanecem assim. Se nav estiver ausente, registrar BOT1-F e investigar em outra etapa, sem inicialização automática nesta.

## Logs e observação limitada

Categoria LogBots, marcador `[BOT]`, logger já existente:

```text
[BOT] Dump Bot State requested ...
[BOT] ============================== BOT STATE
[BOT] ControllerClass = ...
[BOT] PawnClass = ...
[BOT] possession_match=...
[BOT] MovementComponent valid=... active_available=... active=... movement_mode_available=... movement_mode=...
[BOT] PathFollowingComponentClass = ...
[BOT] NavigationSystemClass = ...
[BOT] Move Bot To Player requested ...
[BOT] CurrentLocation=(...) TargetLocation=(...) Distance=... AcceptanceRadius=400
[BOT] reflected param ... offset=... bytes=...
[BOT] Move request submitted function=...
[BOT] Move result=... name=RequestSuccessful/AlreadyAtGoal/Failed/Unknown
[BOT] observation elapsed_ms=... location=(...) velocity=(...) status_name=... displacement=... distance_to_snapshot=...
[BOT] observation ended (5-second window); no follow/retry
```

Somente RequestSuccessful ativa amostras t=0 e aproximadamente uma por segundo até ~5 s. A observação lê o estado; não envia novos pedidos nem segue a localização atual do humano. Tick atrasado não gera rajada de amostras e, após 5,5 s, encerra sem amostra tardia. Objeto destruído, troca de mundo ou de posse encerra a observação. Failed registra BOT1-C; AlreadyAtGoal é retorno normal, mas não prova caminhada.

Dump durante uma observação não a cancela. Não há log por frame. O filtro SEH diagnóstico BOT-0 permanece: registra estágio/exception/módulo/RVA e devolve EXCEPTION_CONTINUE_SEARCH, sem ocultar falha ou retomar um motor possivelmente corrompido. Não resolve símbolos.

## Compilação e reprodução

Mesma configuração funcional: **Release x64**, VS2022 v143 **14.44.35207**, SDK **10.0.26100.0**, sem ABOVE_S20, runtime /MT. OutDir e IntDir exclusivos de bot1. Resultado/identidade do binário em [BOT1_TEST.md](BOT1_TEST.md). Log privado: `reboot/logs/reboot3-bot1-Release.log`.

```powershell
Set-Location 'D:\Games\Fortnite-Local-C2S3'
$bot1MsBuild = 'C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe'
& $bot1MsBuild 'reboot/reboot3/Project Reboot 3.0.sln' /t:Build /m:2 `
  /p:Configuration=Release /p:Platform=x64 /p:PlatformToolset=v143 `
  /p:VCToolsVersion=14.44.35207 /p:WindowsTargetPlatformVersion=10.0.26100.0 `
  /p:CL_MPCount=2 `
  /p:OutDir='D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\bot1\' `
  /p:IntDir='D:\Games\Fortnite-Local-C2S3\reboot\artifacts\intermediate\reboot3\bot1\' `
  /v:minimal /nologo
```

No checkout atual, não reaplicar patches. Em checkout novo: restaurar upstream fixado; aplicar o ajuste reboot3-build-compat.patch do restore; depois bot0-single-bot.patch; por último bot1-manual-move.patch, uma vez e com `git apply --check` antes de cada aplicação. Os dois patches BOT são relativos às etapas anteriores, não ao upstream limpo. Não usar build-reboot3.ps1 para este ensaio: exige HEAD upstream e tem saída padrão do baseline.

## Rollback

Fechar normalmente host e cliente. Em Settings → Internal files → Game server, tipo **Custom**, selecionar no primeiro campo Game server a cópia preservada:

`D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\bot0-working\Project Reboot 3.0.dll`

Reiniciar o host para carregar BOT-0. Não há cópia automática sobre DLL selecionada/Release, edição de configuração do launcher ou cleanup do jogo. Para revisão do source, usar a tag local baseline/bot0-spawn-working em checkout separado; não resetar trabalho pendente. Depois do teste BOT-1, parar e decidir o próximo milestone com o usuário.
