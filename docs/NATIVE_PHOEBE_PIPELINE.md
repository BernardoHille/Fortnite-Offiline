# Pipeline nativo Phoebe — 13.40 CL 14113327

**PHOEBE PARTIAL.** Há assets e entradas nativas reutilizáveis, mas ainda não há bootstrap completo validado. Mapeamento feito antes de editar o source desta etapa, usando Reboot upstream 10c659028ad9d6816f78226483f11a884bf81f57, baselines BOT-0/1/2, ObjectsDump da build alvo e FES season-13 e42ecddbce59163c6a60ab7506766c2a0adfe580. Não foram iniciados Launcher/host/cliente pelo Codex. Data de revisão: 08/10/2026.

**Atualização V1: NAV-BLOCKED confirmado no teste do usuário de 08/10/2026 às 10:46:38; zero bots ON.** A meta de uma primeira tentativa real não pôde ser habilitada: não há reparo NavData demonstrado para 13.40/426 nem contrato/profile BR validado. O preflight está congelado em `baseline/native-phoebe-preflight` (`0e252cd76d066ab5caea98c358c2b6b11dbccd3c`), nova branch `bot-ai/native-phoebe-bootstrap-v1`. Auditoria/limites em [NATIVE_PHOEBE_BOOTSTRAP_V1.md](NATIVE_PHOEBE_BOOTSTRAP_V1.md); ensaio da nova DLL em [NATIVE_PHOEBE_BOOTSTRAP_V1_TEST.md](NATIVE_PHOEBE_BOOTSTRAP_V1_TEST.md). Os trechos abaixo sobre PARTIAL/preflight descrevem a revisão histórica.

Leituras novas: AISettings.bAllowAIGoalManager=true e bAllowAIDirector=true; initial lock available=true/**false**, embora bInitialBuildingLocked configurado=true; building=false/building_or_locked=true. NavDataSet0 antes/depois. WorldSettings possui override AthenaNavSystemConfig nativo do nível **Apollo_Nav_Gameplay**, carregado/visível; **WaterLevel_0..7 não carregados/visíveis** na amostra. Uso de streamed nav=true, autocriação/rebuild=false. Hipótese atual: seleção/carregamento da variante nav de água não consumida; qual variante e seu conteúdo/contrato ainda desconhecidos. Não tratar o nível base como ausente ou inferir lock inicial ativo.

V1 lê os valores de bAllowAIGoalManager/bAllowAIDirector com ByteOffset/FieldMask, schemas dos component creators, initial-lock getter condicionado à assinatura/receptor, config e streaming. Com NavDataSet vazio aborta imediatamente em `navigation_bootstrap`, sem bot. Não chama MANG nem desbloqueia nav. Se houver dados, consultas restritas de agente/projeção/path precedem a recusa ainda necessária do contrato/profile. **SpawnAI/SpawnBot/RunBehaviorTree ON continuam sem chamada habilitada**; não há observação de60s porque não há bot nativo criado. OFF preserva o corpo BOT-0.

## Evidência de runtime

BOT-0 cria Pawn/Controller Phoebe, posse bidirecional, PlayerState, Movement e PathFollowing válidos. BrainComponent é null. BOT-1 falha no MoveTo. No ensaio BOT-2 de 07/10 às 23:49–23:50, NavDataSet disponível/count=0, World tem somente AbstractNavData-Default como NavigationData, e ambas as projeções false. FindPathToLocationSynchronously submetida retorna null. DefaultAgentName=Phoebe; agente do bot radius=42, height=150, PreferredNavData=/Script/FortniteGame.AthenaNavMesh. building=false/building_or_locked=true sugere bloqueio; initial lock unavailable. Detalhes em [BOT2_TEST.md](BOT2_TEST.md).

A playlist daquela sessão foi **Playlist_DefaultSolo**, confirmada no launcher.log às 23:46:46. Isso não comprova que todos os settings de AI da playlist tenham sido consumidos pelo host customizado.

## Caminhos encontrados

Atualização após o ensaio do usuário de 08/10/2026 às 09:55:28: **DefaultSolo.AISettings resolve Phoebe_Default_AISettings**. Manager/mutator e BT/BB/CurveTables existentes são válidos. NavDataSet novamente disponível/count=0, agente default Phoebe e building=false/building_or_locked=true. Properties BotData e BehaviorTree existem no CDO, mas seu conteúdo não foi lido. Nenhum bot novo foi criado pelo ON.

O metadata de **Manager.SpawnAI tem quatro fields**: InSpawnLocation (0), InSpawnRotation (12), **AISpawnerComponentList (24)** e ReturnValue (32), PropertiesSize=40. SpawnBot tem o caminho distinto de InBotData/InRuntimeBotData, PropertiesSize=56. RuntimeCustomizationData nativo foi enumerado com **16 bytes e cinco fields**, apesar da declaração vazia do wrapper Reboot. Tipos/defaults/ownership e caminho através do hook continuam sem validação; essas funções não foram invocadas.

O ObjectsDump da sessão (atualizado 09:53:16) acrescenta à investigação as entradas **FortAthenaAISpawnerData.CreateComponentList/CreateComponentListFromClass**, GetBehaviorComponent/GetSpawnParamsComponent e a classe **FortAthenaAISpawnerDataComponentList**, além de componentes Behavior, AIBotSkillset, PlayerBotSkillset e AIBotInventory. A cadeia candidata agora é **SpawnerData correto → CreateComponentList → Manager.SpawnAI → inicialização nativa**, em vez de assumir que SpawnAI recebe diretamente PawnClass. A relação é inferida pelos nomes/interfaces encontrados; assinaturas desses criadores e lista preenchida do BR genérico ainda precisam ser validadas. No recorte pesquisado do dump, as instâncias desses tipos são CDOs, que não devem ser usados como perfil preenchido. Não criar componentes manualmente nem usar dados DangerGrape para preencher essa lacuna.

Procedimento e tabela de metadados reais em [NATIVE_PHOEBE_TEST.md](NATIVE_PHOEBE_TEST.md). O preflight cumpriu a coleta, e a classificação permanece PARTIAL. O contrato é deliberadamente bloqueado no código; seu FAIL não representa falha de uma chamada ao spawn nativo.

```text
Reboot ReadyToStartMatch -> SetupEverythingAI
  -> PlayerBot.InitializeBotClasses (caminho PlayerBot usa controller humano)
  -> SetupServerBotManager -> CachedGameMode/State + CachedBotMutator

BOT-0 explícito
  -> FortAthenaMutator_Bots.SpawnBot(PawnClass, locator humano, transform, snap=false)
  -> Pawn Phoebe + Controller Phoebe + PlayerState
  -> Brain null; navegação sem AthenaNavMesh registrada no ensaio

Candidato nativo completo, ainda não comprovado ponta a ponta
  -> FortServerBotManagerAthena.SpawnAI / SpawnBot
  -> criação/consumo de FortAthenaAIBotCustomizationData + RuntimeCustomizationData
  -> inicialização de Controller, skill/config, inventário/cosmetic/name e behavior
  -> BT_Phoebe -> árvores/serviços/evaluators nativos
  -> Brain/Blackboard/Perception + NavData compatível -> comportamento
```

Os primeiros dois blocos são confirmados por source/runtime. O terceiro une entradas/assets encontrados com dependências inferidas: **a ordem interna Epic e o vínculo exato BotData → BehaviorTree não foram reconstruídos**. Existência de um nome no dump não demonstra que a função foi chamada ou que o asset pertence à instância do bot.

## Manager versus mutator e interceptação do Reboot

`FortAthenaMutator_Bots.h` expõe SpawnBot com PawnClass, locator, transform e snap. Não recebe BotCustomizationData, RuntimeCustomizationData ou BehaviorTree. BOT-0 utiliza esse wrapper existente e não atribui esses dados, não executa RunBehaviorTree, StartLogic, SetupNavConfig, Director ou GoalManager. Isso descreve o que BOT-0 não chama; efeitos internos do mutator não estão inteiramente conhecidos.

`FortServerBotManagerAthena.h` declara SpawnBotOriginal com CustomizationData e RuntimeCustomizationData. Porém **FFortAthenaAIBotRunTimeCustomizationData está vazia no SDK local**. O helper BotManagerSetupStuffIdk recebe BehaviorTree/skill/inventory/name e outros argumentos desconhecidos, em módulo+0x19D93F0, sem branch/validação 13.40. Nenhum call site foi encontrado para esse helper. Não é uma API utilizável demonstrada.

`dllmain.cpp` instala o hook de SpawnBot nas builds 12.00–13.40. Em 13.40 usa o caminho UFunction/native-function. `SpawnBotHook` compara return address com SpawnBotRet; somente um caller identificado pelo scanner segue SpawnBotOriginal. Para os demais, substitui o fluxo por mutator SpawnBot, teleporte e customização manual de skin/nome. Não inicia BehaviorTree. `finder.h:SpawnBotRet` procura a string de erro “Unable to create UFortAthenaAIBotCustomizationData object…” e uma sequência de bytes; o scanner não prova que SpawnAI usa esse caller na build alvo.

Portanto invocar SpawnBot por ProcessEvent não garante atingir o corpo nativo completo. Bypassar esse hook com a assinatura C++ incompleta também não é validado. Esta etapa não altera hook, não chama o endereço fixo nem fabrica a struct vazia.

`bots.h:ShouldUseAIBotController` retorna false antes da condição de versão. InitializeBotClasses seleciona PlayerPawn_Athena/FortPlayerControllerAthena para o sistema PlayerBot desse arquivo. Esse sistema é distinto do BOT-0, que resolve diretamente o asset Phoebe; ativá-lo não restaura automaticamente o pipeline Epic.

## Dependências e ordem

| Função/camada | Cria/associa | Momento/dependências | Compatibilidade e saída |
| --- | --- | --- | --- |
| SetupServerBotManager | Manager no GameMode; mutator existente ou novo; caches | SetupEverythingAI no fluxo ReadyToStartMatch; World/GameMode/GameState válidos | Já funcionou em 13.40; função void; leitura pelo GameMode; não configura BT/Nav |
| SetupNavConfig | Override actor + AthenaNavSystemConfig; política de streaming/autospawn | Concebida para setup do World antes do uso de nav; timing Epic desconhecido | Sistema já presente causa early return; finder AddNavigationSystemToWorld sem variante 426; não ativar |
| SetupAIGoalManager | FortAIGoalManager associado ao GameMode | Source comenta GameData e AISettings.bAllowAIGoalManager | Path de classe com grafia suspeita; não há setup de nav/BT neste corpo |
| SetupAIDirector | AthenaAIDirector; BaseEncounterClass; Activate | Source comenta AISettings.bAllowAIDirector; tabelas adicionais faltantes | Pode gerir encounters/população, inclusive NPCs fora de escopo; não ativar só para tentar |
| SpawnAI / SpawnBot do Manager | Entrada nativa; CustomizationData/runtime data no wrapper | Config da partida, dados do bot, nav e contexto do manager | UFunctions presentes; assinatura/ownership e original hook não validados para nova chamada |
| RunBehaviorTree | Executa um BT existente pelo AIController | Asset correto + blackboard/contexto/serviços inicializados | UFunction presente; não comprova substituir inicialização do manager |

Ordem sustentada para investigação: contexto/playlist → manager/mutator e dados → navegação utilizável → entrada de spawn nativa que fornece esses dados → inspeção de Brain/BT → observação. Não é uma ordem Epic comprovada para GoalManager/Director; não adicionar chamadas com base nessa inferência.

## MANG

CONFIRMADO: argumento FName de SetupNavConfig, escrito em DefaultAgentName. O helper cria config nativo; não resolve um asset chamado MANG, não escreve SupportedAgents explicitamente nem registra manualmente NavData. Políticas de auto-spawn/streaming podem provocar efeitos internos, ainda não validados. SetNavigationSystem retorna false se AthenaNavSystem já existir e tem riscos de null/flags/ABI. Auditoria completa em [BOT2_REBOOT_AI_SETUP.md](BOT2_REBOOT_AI_SETUP.md).

Referências locais a MANG incluem BotData_MANG_POI_HDP em um trecho condicionado a 12.30–12.61 e nomes/classes/som de NPCs no dump 13.40. Isso não define a sigla nem sua exigência para bot BR genérico. **O runtime alvo já tem agente default Phoebe; SupportedAgents observado não contém MANG.** Não substituir Phoebe por MANG. Uso do helper em outras seasons não foi demonstrado por teste; ausência da branch 426 é confirmada no finder.

## Dados e assets nativos

| Encontrado no ObjectsDump 13.40 | O que comprova / limite |
| --- | --- |
| FortAthenaAIBotCustomizationData e CDO | Classe de customização existe; CDO não é perfil BR genérico preenchido |
| BD_DangerGrape_Default / No_Starting_Weapons | São os únicos assets carregados dessa classe neste dump além do CDO; não usar como substituto Phoebe |
| FortAthenaAIBotRunTimeCustomizationData | Dump comprova existência; log preflight posterior enumera16bytes/cinco fields. Tipos/defaults/ownership ainda não validados; não construída. |
| Phoebe_ControllerData / Phoebe_ManagerData | **CurveTables**, não objetos FortAthenaAIBotCustomizationData; conteúdo de linhas ainda não lido |
| Phoebe_Default_AISettings | AthenaAISettings nativo; vínculo e flags efetivas da playlist precisam de leitura da instância |
| BT_Phoebe, BB_Phoebe | Árvore raiz/blackboard encontrados; vínculo exato com BotData e execução não comprovados |
| BT_Phoebe_Gameplay, Loot, Storm, Revive, PatrolAround, DBNO, Warmup | Capacidades têm assets nativos; existência não equivale a comportamento observado |
| Skillsets movement, inventory, looting, perception, attacking, aiming, building etc. | Config/infraestrutura nativa disponível; digest/init não reconstruído |

Property BotData do Controller foi detectada em BOT-1, mas **storage kind/tipo e conteúdo permanecem opacos**. Não tratá-la como UObject*, copiar bytes, preencher struct, confundir com o parâmetro InBotData ou usar defaults zerados. Não foi identificado o asset de customização genérico Season13 nem quem atribui esse campo em todos os caminhos. SpawnAI é um candidato importante porque o scanner referencia criação nativa de CustomizationData, ainda uma inferência.

## Brain, percepção e cosmetic

CDO Phoebe enumera PathFollowing, Actions, Aircraft, Marker, Telemetry e InventoryItems. A Blueprint class enumera AIPerception_GEN_VARIABLE com Sight/Hearing/Damage e Blackboard1_GEN_VARIABLE (templates, não instâncias ativas). Nenhum BrainComponent filho do CDO foi listado. BOT-0 runtime Brain=null. O dump inclui AIController.RunBehaviorTree, BrainComponent.StartLogic/IsRunning/IsPaused e FortAthenaAIBotController.BlueprintOnBehaviorTreeStarted. Callback não é inicializador. Não foi encontrado call site de RunBehaviorTree/StartLogic no Reboot/FES auditados.

RunBehaviorTree pode iniciar um asset existente segundo a [API oficial UE4.27](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/AIController?application_version=4.27). Não executamos a árvore isoladamente: inicialização de skillsets/evaluators/blackboard/inventário ainda não foi comprovada. Não criar Brain manualmente.

A skin igual ao player foi relatada pelo usuário. BOT-0 usa humano como spawn locator e não fornece perfil cosmetic; herança/cópia de defaults é uma **hipótese**, não um mecanismo nativo demonstrado. A correção deve vir do caminho/data nativo correto; não copiar loadout do humano ou substituir cosmetic isoladamente.

## Playlist

Source default e último runtime: DefaultSolo. Funções de setup comentam AISettings.bAllowAIGoalManager/bAllowAIDirector. Assets de configurações e structs de população/MMR existem no dump, mas população/bot settings/modifiers/mutators efetivos ainda não foram extraídos. O preflight registra playlist efetiva via struct PlaylistPropertyArray, property AISettings e presença de campos candidatos, sem escrever. Nada de alterar playlist/população, criar NPCs ou ativar encounters.

## FES Season13

| Subsystem | Reboot | FES fixado | Diferença e limite |
| --- | --- | --- | --- |
| Manager/mutator | Configurados no ReadyToStartMatch | SetupSubsystems cria objetos/caches | Padrão semelhante; não prova behavior |
| Controller/Pawn | BOT-0 mutator nativo, Phoebe confirmado | Deferred spawn do Pawn Phoebe, controller obtido depois | ResolveBotControllerClass existe, não usado por SpawnAI nesse source |
| Director | Setup comentado | Spawn AthenaAIDirector + Activate | Sem reconstrução completa de tabelas/init Phoebe |
| GoalManager/Nav | Setup comentado; NavData vazio no teste | Nenhum setup Nav/GoalManager encontrado | FES não fornece solução demonstrada para este bloqueio |
| BotData/BT/Brain | Wrapper de manager incompleto; nenhum início BT | Nenhum profile BotCustomizationData/RunBT/StartLogic encontrado | Não copiar como pipeline completo |
| Skill/loot/inventory | BOT-0 não concede manualmente | Abilities, teams, saúde e loadout manuais | Fora da estratégia native-only; não portado |

FES descreve suporte no README, mas o código fixado não comprova autonomia nem navegação BR. RegisterWithDirector apenas ForceNetUpdate no Director; isso não é registro de Pawn demonstrado. Não usar bosses ou coordenadas-placeholder do profile.

## Decisão

Decisão histórica preflight: seleção A/B e coleta sem spawn/AI parcial/hook antigo. Detalhes em [NATIVE_PHOEBE_IMPLEMENTATION.md](NATIVE_PHOEBE_IMPLEMENTATION.md), procedimento em [NATIVE_PHOEBE_TEST.md](NATIVE_PHOEBE_TEST.md).

Decisão V1: aplicar o bloqueio de navegação exigido no novo pedido. A auditoria não forneceu evidência forte para SetupNavConfig(MANG), Goal/Director ou contrato/component profile BR. Foram ampliadas as leituras que faltavam e os guards, sem inventar essas dependências. A restauração completa permanece pendente. Resultado NAV-BLOCKED agora confirmado na DLL V1 pelo usuário. Origem exata do lock e da ausência inicial de NavData: DESCONHECIDAS; dados de streaming WaterLevel são pista específica, não causa comprovada. Nenhuma mutation de navegação ou AI foi acrescentada após analisar esse ensaio.
