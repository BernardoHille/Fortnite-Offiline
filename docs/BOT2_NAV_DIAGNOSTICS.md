# BOT-2 — diagnóstico de navegação 13.40

**BOT2 PARTIAL:** diagnósticos compilados Release x64 e suficientes para teste, com getters internos de seleção/associação/request id declarados UNKNOWN. Etapa estritamente diagnóstica para **Fortnite 13.40 / CL 14113327**, Reboot detectando **Engine_Version=426**. BOT-1 continua classificado BOT1-C: três chamadas MoveToLocation com retorno Failed, posse bidirecional correta e Movement/PathFollowing/NavSystem presentes. O motivo interno ainda não foi comprovado. O Codex não iniciou Launcher, host, cliente ou Fortnite.

## Preservação e escopo

Atualização de runtime, 07/10/2026 23:49–23:50: **NAV-A**. NavDataSet disponível/vazio; World enumera somente AbstractNavData-Default e um bounds volume. Ambas as projeções nativas false; query de caminho submetida retorna null; dois MoveTo retornam Failed. Agente do bot radius 42/height 150, PreferredNavData AthenaNavMesh; DefaultAgentName Phoebe. building=false/building_or_locked=true sugere bloqueio, mas seu proprietário/motivo e o getter de initial lock permanecem desconhecidos. Não afirmar ausência de arquivos de navegação no disco a partir desse snapshot. Resultado e limitações em [BOT2_TEST.md](BOT2_TEST.md).

Antes de editar, o source BOT-1 foi congelado no commit local **0bbf1c5cdff5bd3a92309140930e86ff3906cac5**, tag **baseline/bot1-moveto-failed**. Nova branch local: **bot2/reboot-13.40-nav-diagnostics**. Essas refs pertencem a reboot/reboot3, não ao Git principal publicado.

DLL BOT-1 preservada em `reboot/artifacts/reboot3/bot1/Project Reboot 3.0.dll`, SHA-256 **0aa15f81f7cbb0a047407915d87094788fccab10c4ff09e223d8ac0ecaf0c78b**, PDB ao lado. BOT-0 funcional segue em bot0 e bot0-working, SHA-256 **ffd76cb452d5ef1ff9d6252d9141491c6b7cee122a4e2f8e0b29d327ca144465**. Saídas BOT-2 são exclusivas de **bot2-navdiag**, inclusive intermediários/PDB.

Arquivos relativos a reboot/reboot3/Project Reboot 3.0:

| Arquivo | Alteração BOT-2 |
| --- | --- |
| Bot2Nav.inl, novo | Consultas e logs NAV, incluído no namespace interno de Bot0.cpp para reutilizar seus helpers/estado |
| Bot0.cpp | Ações NavDump/NavProjection/NavPath, acesso a outputs nomeados no buffer refletido, dispatcher e snapshots antes/depois do Move existente |
| Bot0.h | RequestNavDump, RequestNavProjection e RequestNavPath |
| gui.h | Três botões na seção Bots da aba Game do HOST |
| Project Reboot 3.0.vcxproj | Apenas registra o include Bot2Nav.inl; propriedades de build preservadas |

O spawn BOT-0 não foi editado. MoveToLocation mantém função/argumentos/guards e uma chamada por clique; ganhou somente snapshots de diagnóstico antes/depois. Nenhum setter de gameplay/nav, setup, BT, teleporte, velocity hack, A*, thread/hook novo ou retry automático. Launcher/Lawin/backend/auth/matchmaker, Fortnite/PAKs/EAC/BE, auxiliares e lifecycle/Battle Bus/storm/loot permanecem intactos.

## Arquitetura observada e limites

```text
World Apollo_Terrain
  └─ AthenaNavSystem (validado no teste BOT-1)
       ├─ MainNavData / DefaultNavData / NavDataSet, se refletidos
       ├─ SupportedAgents / DefaultAgentName, se refletidos
       └─ queries nativas de projeção/caminho

BP_PhoebePlayerController_C
  ├─ Pawn → BP_PlayerPawn_Athena_Phoebe_C
  │          └─ FortMovementComp_CharacterAthena → NavAgentProps, se refletido
  ├─ FortAthenaAIBotPathFollowingComponent
  │    └─ ligação MovementComp: ainda sem getter/storage validado
  └─ BrainComponent=null no teste BOT-1
```

ObjectsDump.txt local, somente leitura, datado 2026-10-07 23:10:44, lista NavigationData, RecastNavMesh, FortNavMesh, AthenaNavMesh, AthenaNavSystem, NavMeshBoundsVolume, NavAgentProperties, MovementProperties e NavDataConfig. A busca por instâncias Recast/Fort/AthenaNavMesh e bounds encontrou os CDOs, não atores de nav do World. Esse dump foi produzido antes do clique BOT-1 e **não comprova ausência de NavData na sessão posterior**. Dump Nav State consulta o World vivo justamente para resolver essa dúvida.

Fonte: `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64\ObjectsDump.txt`. Os nomes de UFunctions abaixo constam dessa build, não são assumidos a partir de UE5. Assinaturas de referência vêm da documentação oficial UE4.27; o buffer/nome de parâmetros é validado em runtime antes da chamada. A documentação não substitui essa validação 13.40.

## Execução e validações

Todos os botões apenas enfileiram uma ação atômica da UI. O dispatcher existente processa no tick do World.NetDriver, com prefixo **[NAV]**. Exige o último bot salvo na sessão atual, mesmo World/GameState, posse bidirecional, classes AI/Pawn corretas, host listening, Apollo Athena SafeZones, 13.40/426. Drivers secundários não consomem pedidos. Recusas são logadas, sem fallback para outro bot/host e sem criar objetos substitutos.

Queries usam CDOs **já existentes** de NavigationSystemV1, GameplayStatics e AIBlueprintHelperLibrary, encontrados no dump. Não criam CDO/classe nem carregam assets. Reutilizam lifetime/identity checks, seleção do primeiro humano conectado com bIsABot=false e reflexão BOT-1.

ReflectedCall exige conjunto exato de nomes, offsets de UFunction existentes, buffer de 1–512 bytes, escrita sem sobreposição e bools nativos. Não há structs de parâmetros com padding inventado. Structs de dados são lidas por tamanho/offsets de ScriptStruct, inclusive sua cadeia de superstruct; sem layouts/endereços absolutos novos. Tipos escalares são os UE4 conhecidos e as properties esperadas; o SDK não tem verificador completo de tipos FField para 13.40. Ausência de property/API/tipo esperado vira unavailable/UNKNOWN, não valor fabricado ou prova de null interno.

SEH apenas registra falha e continua até o handler normal do jogo. Estágio BOT2 acrescenta [NAV][FAIL], preservando o diagnóstico BOT existente. Não há tentativa de engolir crash ou retomar motor corrompido.

## Dump Nav State

Registra World/NavSystem/classes, bot, movimento, Brain e PathFollowing, além de:

- MainNavData e DefaultNavData quando as properties estiverem disponíveis;
- NavDataSet, quantidade e até 20 entradas com classe. Membership é evidência de presença nesse array, não validação completa de tiles/registro interno;
- atores NavigationData e NavMeshBoundsVolume do World via GetAllActorsOfClass, com contagem e até dez nomes/classes/posições por categoria. Ator carregado não comprova participação no NavDataSet; extensão real dos bounds/tiles não é inventada;
- SupportedAgents como array de NavDataConfig com stride obtido do ScriptStruct, até 16 descritores. Os índices logados são índices desse array, **não um índice nativo escolhido para o bot**;
- DefaultAgentName e estado building/building-or-locked por funções nativas, quando resolvíveis.

Também consulta **AthenaNavSystem.IsInitialNavigationLockActive** se o getter de apenas ReturnValue bool for validado. Não libera o bloqueio. A função específica **FortNavSystem.IsNavmeshInRadiusInitialized** existe no dump; como sua assinatura não foi comprovada, Dump Nav State registra apenas tamanho do buffer e nomes/offsets dos parâmetros (até 12), sem chamar a função. OnNavDataRegistered e os métodos de registro de observers encontrados no dump não são usados como queries.

Arrays emprestados de NavDataSet/SupportedAgents/PathPoints nunca são liberados. OutActors é o array temporário produzido pela query: cabeçalho validado e memória liberada pelo allocator do próprio Reboot, sem destruir atores. GetCurrentPath/FindPath criam wrappers transitórios de resultado administrados pelo motor; não se alteram seus paths nem se solicita atualização/recalculation contínua.

**GetNavDataForProps, GetNavDataForActor, GetMainNavData e GetDefaultNavDataInstance não aparecem como UFunctions nesse dump.** Não são chamados via endereço/virtual inventado. A ausência do getter refletido não significa que a função C++ não exista; também não é um retorno null. Exact selected NavData/native agent index permanecem UNKNOWN.

## Agente

NavAgentProps do MovementComponent é inspecionado pelo ScriptStruct Engine.NavAgentProperties. AgentRadius, AgentHeight, AgentStepHeight e NavWalkingSearchHeightScale são lidos quando refletidos e finitos. Capabilities bCanCrouch/Jump/Walk/Swim/Fly usam masks de bool do helper versionado existente, respeitando herança de MovementProperties. PreferredNavData tenta ler apenas AssetPathName pela reflexão de SoftClassPath; nenhuma classe é carregada. Se inacessível, registra opaque/unavailable.

NavData.Config e SupportedAgents usam NavDataConfig refletido: campos herdados do agente, Name e DefaultQueryExtent quando acessíveis. Não aplicam valores ao bot, não selecionam agente por comparação heurística de radius/height e não fabricam struct. Referências de campos: [NavAgentProperties UE4](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/NavAgentProperties?application_version=4.27), [NavMovementComponent UE4](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/NavMovementComponent?application_version=4.27).

## Test Nav Projection

Uma operação explícita realiza **uma projeção do bot e uma do humano**, ambas pelo mesmo extent. Usa a UFunction **NavigationSystemV1.K2_ProjectPointToNavigation** com WorldContextObject, Point, ProjectedLocation, NavData, FilterClass, QueryExtent e ReturnValue. Registra localização original, API available, success e output.

NavData de projeção é MainNavData/DefaultNavData válido se refletido; caso contrário, parâmetro null pede o default nativo. Isso é explicitamente uma consulta do **default**, sem provar correspondência com o agente do bot. Não usa o primeiro ator encontrado nem cria NavData. Controller.DefaultNavigationFilterClass é usado quando refletido e validado como classe derivada de NavigationQueryFilter; caso contrário null, com origem/limitação registradas.

Extent: primeiro consulta DefaultQueryExtent do NavData/property Config. Só aceita valores positivos/finitos e contidos em X/Y≤500, Z≤1000 UU, evitando ampliar arbitrariamente a busca. Sem config acessível nesse limite, usa **(50,50,250) UU**: default documentado de NavDataConfig UE4.27, explicitamente **fallback diagnóstico**, não valor observado do Fortnite. Não há segundo extent nem expansão automática. [NavDataConfig UE4](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/NavDataConfig?application_version=4.27).

A projeção usa localização do Actor. GetNavAgentLocation do bot é registrado separadamente com distância ao Actor, para identificar diferenças de origem. False nativo é falha de projeção; assinatura/API indisponível é UNKNOWN, não NAV-A/B automaticamente. Não move/teleporta nem corrige o ponto no jogo.

## Test Path To Player

Uma consulta **NavigationSystemV1.FindPathToLocationSynchronously**: WorldContextObject, PathStart, PathEnd, PathfindingContext, FilterClass, ReturnValue. Contexto = **BotController**, preservando a seleção de agente feita pelo motor. Start = Pawn.GetNavAgentLocation quando disponível/finito; fallback = ActorLocation com aviso. End = ActorLocation do humano, mesmo destino do Move BOT-1. O default filter do Controller é usado quando resolvido.

A função aceita os pontos diretamente; não força outputs projetados em NavData default sobre o contexto do bot. Test Nav Projection é um botão separado e deve preceder o path mantendo os personagens no mesmo lugar. A consulta de caminho não movimenta nem chama MoveTo. O NavData efetivo selecionado internamente não fica exposto; o log mostra essa limitação junto do candidato default. [NavigationSystemV1 UE4](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/NavigationSystemV1?application_version=4.27).

Resultado NavigationPath é examinado por IsValid, IsPartial e PathPoints, com contagem e **máximo dez pontos**. Success = válido e não parcial; Partial é registrado separadamente, sem contar como sucesso completo. Return nulo/incompatível, false válido ou API indisponível ficam diferenciados. Não habilita debug drawing/recalculation. [NavigationPath UE4](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/NavigationPath?application_version=4.27).

## PathFollowing antes/depois do Move

NavPathFollowing registra:

- classe/identidade de Movement e PathFollowing;
- ActorComponent.GetOwner do PathFollowing versus Controller, PawnMovementComponent.GetPawnOwner versus Pawn;
- GetMoveStatus, GetPathActionType, GetPathDestination quando resolvíveis;
- cópia do caminho atual via **AIBlueprintHelperLibrary.GetCurrentPath**, validade/partial/contagem, sem editar o path usado pelo Controller;
- presença de properties candidatas MovementComp, NavMovement, PathFollowingAgent, MovementComponent, CurrentRequestId, RequestID e Path.

GetCurrentPath consta do dump 13.40; a semântica de cópia é descrita em [AIHelperLibrary UE4](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/AIHelperLibrary?application_version=4.27). Os getters de status/destino e ownership são evidências reais. **Ownership correto não prova ligação interna MovementComp.** A storage kind dos campos candidatos e um getter de associação não foram validados pelo SDK; não reinterpretamos weak/interface/shared pointers como UObject. Associação exata e current request id são declarados UNKNOWN. As fotos antes/depois podem mostrar mudança de path/status, mas não identificam sozinhas a instrução nativa de criação/falha da request.

## Por que MoveTo retornou Failed?

**CONFIRMADO:** no teste BOT-1, função/params/enum resolvidos, três chamadas efetivas retornam Failed, Controller/Pawn/posse válidos, Movement/PathFollowing ativos, NavSystem presente, Brain null e status Idle após. Não houve fase/raio/seleção de DLL bloqueando essas chamadas.

**CANDIDATOS:** NavData sem cobertura/agente compatível; projeção do destino falhando; path inválido/parcial quando BOT-1 exige bAllowPartialPath=false; diferenças de filtro; associação ou aceitação da request pelo PathFollowing. São hipóteses, não ramos nativos já comprovados. O dump enumera UFunctions, sem implementação C++ do Fortnite; o corpo nativo 13.40 não foi reconstruído/desassemblado para afirmar a instrução exata do Failed. BOT-2 produz as consultas discriminantes, sem hookar/patchar essa função.

Brain null não estabelece causalidade. SetupNavConfig/AIDirector/GoalManager permanecem comentados. A auditoria e seus limites de Season 13 estão em [BOT2_REBOOT_AI_SETUP.md](BOT2_REBOOT_AI_SETUP.md). O ensaio e matriz estão em [BOT2_TEST.md](BOT2_TEST.md). A resposta exata depende das novas evidências; não será antecipada nem corrigida automaticamente.
