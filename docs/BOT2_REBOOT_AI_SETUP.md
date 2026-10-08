# BOT-2 — auditoria do setup AI do Reboot

Somente leitura do Project Reboot fixado no upstream **10c659028ad9d6816f78226483f11a884bf81f57**, com baselines locais BOT-0/BOT-1. Alvo **13.40 / CL14113327**, Engine_Version detectado **426**. Nenhuma função descrita abaixo foi ativada nesta etapa.

## Setup atualmente chamado

Resultado posterior do usuário em 07/10/2026: NavDataSet available=true/count=0, DefaultAgentName=Phoebe, PreferredNavData do bot=AthenaNavMesh; não foi enumerado ator AthenaNavMesh no World. Isso fortalece a investigação da inicialização/registro/streaming de navegação, sem tornar seguro descomentar SetupNavConfig("MANG"). A estratégia de pipeline nativo de 08/10 está mapeada em [NATIVE_PHOEBE_PIPELINE.md](NATIVE_PHOEBE_PIPELINE.md); os helpers aqui auditados continuam sem ativação.

`Project Reboot 3.0/FortGameModeAthena.cpp:SetupEverythingAI` chama PlayerBot.InitializeBotClasses e SetupServerBotManager. Permanecem comentados SetupAIGoalManager, SetupAIDirector e SetupNavConfig(Conv_StringToName("MANG")). Os diagnósticos BOT-2 não alteram esse bloco, os helpers ai.h ou os finders/addresses.

InitializeBotClasses resolve classes existentes; SetupServerBotManager obtém/cria FortServerBotManagerAthena, preenche CachedGameMode/State e obtém/cria FortAthenaMutator_Bots com caches. Foi esse mutator que retornou Pawn/Controller Phoebe no BOT-0. Não reinicializar/substituir esse caminho para consultar navegação.

## SetupNavConfig("MANG") — o que o source realmente faz

`ai.h:SetupNavConfig` recebe FName AgentName. **"MANG" é o valor passado para DefaultAgentName da configuração de navegação**, quando a property existe. Não é um caminho de asset nem um identificador de função. O source não define a expansão da sigla. Há paths /Game/Athena/AI/MANG/BotData em outros pontos e classes FortMang no dump, mas isso não prova o significado da sigla ou que seja o agente certo para Phoebe.

Sequência estática do helper:

1. Resolve **AthenaNavSystemConfigOverride** e spawna um actor dessa classe.
2. Resolve **AthenaNavSystemConfig** e cria um objeto de configuração com o override como outer.
3. Escreve flags de configuração: building grid=false; streamed nav level=true se disponível; auto rebuild=true; create on client=true; auto spawn missing NavData=true; spawn in nav bounds level=true; navigation invokers=false se disponível.
4. Escreve DefaultAgentName=AgentName, se disponível.
5. Associa o config à property NavigationSystemConfig do override.
6. Chama **SetNavigationSystem(override)**.

Não há LoadObject de asset/config customizado nesse helper: classes nativas são resolvidas e config criado. Não há edição explícita de SupportedAgents, registro manual de cada agente, SpawnActor de NavData, criação de bounds ou chamada explícita GenerateNavigation. As flags solicitam políticas ao sistema; criação/registro/geração eventualmente feita dentro do motor **não foi demonstrada**. Constructors dos objetos/actor também podem ter efeitos internos não reconstruídos aqui.

## SetNavigationSystem e compatibilidade

`ai.h:SetNavigationSystem` lê World.NavigationSystem. Se ele já existe, **retorna false imediatamente**. As linhas de CleanUp e de zerar World.NavigationSystem que seguem o return são inalcançáveis nessa branch. O BOT-1 confirmou AthenaNavSystem presente: logo não se pode tratar o helper como um reparo automático de um sistema existente. SetupNavConfig já criou actor/config antes dessa chamada, por isso também não se deve afirmar que o helper inteiro seria inofensivo.

Se o sistema não existir, a sequência posterior pretende:

- obter WorldSettings;
- definir OverridePolicy=Append quando refletido;
- associar NavigationSystemConfigOverride em WorldSettings e marcar bIsOverriden no config existente;
- obter NavigationSystemClass pelo SoftObjectPath do config;
- chamar o endereço encontrado **AddNavigationSystemToWorld(World, GameMode, Config, true, false)**.

Há limitações estáticas materiais, sem correção nesta etapa:

- O log inicial chama NavSystem.IsValidLowLevel antes do teste de null. WorldSettings também é logado antes de seu guard; isso merece revisão antes de usar o helper em cenário de ponteiro ausente.
- As escritas de flags usam Get<bool> e o source marca algumas como BITFIELD, sem codificar masks específicas nesses call sites. Não afirmar que todas estão corretamente validadas para 13.40.
- `addresses.cpp` preenche AddNavigationSystemToWorld via FindAddNavigationSystemToWorld e inicializa NavSystemCleanUpOriginal pelo finder próprio. **finder.h:FindAddNavigationSystemToWorld contém branches somente para Engine_Version 421, 423 e 425. Para 426, retorna o addr inicial zero.** O helper posterior não valida esse ponteiro antes de chamar. Não acrescentamos pattern/endereço nesta etapa.
- As classes de config/override existem no dump 13.40, mas isso não valida as flags/ABI/efeitos do helper nessa build.

**Season 13:** não existe branch específica 13.40 nesse setup. O call site está em SetupEverythingAI genérico e comentado; o finder contempla engines antigos, sem branch para o 426 observado. Isso não demonstra funcionamento do helper em outra season: demonstra somente que esse código foi escrito para mais de um engine e ficou sem a variante necessária ao alvo atual. Não há ensaio de outra season nesta auditoria.

## SetupAIGoalManager

Lê GameMode.AIGoalManager; tenta resolver FortAIGoalManager; quando ausente no GameMode, spawna actor e atribui a property. O lookup no source usa **/Script.FortniteGame.FortAIGoalManager**, diferente do formato **/Script/FortniteGame.FortAIGoalManager** listado no dump. Sem executar, não afirmamos que essa grafia resolve; fica como limitação a validar em trabalho separado.

O helper não consulta NavData, não projeta pontos, não faz path query e não associa MovementComp ao PathFollowing. Parece a camada de objetivos/comportamento, não a implementação de pathfinding básico. Isso é inferência do escopo visível do helper, não prova de independência de todos os sistemas nativos Fortnite.

## SetupAIDirector

Resolve AthenaAIDirector (o comentário upstream diz que a classe pode estar errada), lê GameMode.AIDirector, spawna e associa o actor se ausente. Depois define BaseEncounterClass=FortAIEncounterInfo e chama FortAIDirector.Activate por ProcessEvent, se a função foi encontrada. O source reconhece que faltam dados/tabelas para completar o setup. Uma variável GameState é obtida, sem uso adicional nesse corpo.

Não registra NavData/agentes/bounds nem executa projeção/pathfinding nesse helper. Parece camada de encounters/comportamento autônomo. A necessidade disso para AIController.MoveToLocation básico **não está demonstrada**; ativá-lo não é uma correção fundamentada do retorno Failed atual.

## BrainComponent null

O teste BOT-1 confirmou null na instância. O dump local lista no CDO BP_PhoebePlayerController: PathFollowingComponent, ActionsComp, AircraftComponent, MarkerComponent, TelemetryComp e inventário. Não aparece um subobjeto Brain/BehaviorTree nessa lista, o que não prova a inexistência da property herdada nem de criação posterior pelo motor.

A busca no source Reboot auditado não encontrou chamadas RunBehaviorTree ou StartLogic; a UFunction AIController.RunBehaviorTree existe no dump. Quando o motor Fortnite normalmente cria/associa Brain/BehaviorTree ao Phoebe não foi determinado. O mutator retorna classes Phoebe, mas o conteúdo BotData e a inicialização comportamental nativa continuam opacos. Nada disso será sintetizado nesta etapa.

## Comparação com FortExternalServer

Referência somente leitura: **season-13**, commit **e42ecddbce59163c6a60ab7506766c2a0adfe580**, checkout gameserver/vendor/FortExternalServer. Fonte principal: Source/FortniteGame/Private/AI/FortAthenaAI.cpp e Private/Versioning/Season13BuildProfile.cpp. Source FES intacto. Não copiar essa arquitetura nem apresentar declarações de suporte como ensaio funcional de navegação.

| Subsystem | Reboot deste baseline | FES fixado | Relevância Season 13 / diferença |
| --- | --- | --- | --- |
| Pawn/Controller | Mutator nativo SpawnBot retorna Pawn/Controller Phoebe | Profile declara as mesmas classes; SpawnAI faz deferred Pawn spawn e lê Controller após FinishSpawning | Names compatíveis; pipelines distintos. FES não demonstra MoveTo funcionando por essa declaração |
| BotManager/mutator | Caches GameMode/State e CachedBotMutator, usa existentes quando válidos | SetupSubsystems cria manager/mutator e preenche caches/ServerBotManager | Inicialização adicional existe no FES, mas nosso manager/mutator já estão presentes |
| AIDirector | SetupAIDirector comentado | Cria AthenaAIDirector, Activate e associa ao GameMode antes de bots | Diferença comportamental; não prova dependência de nav/movimento |
| AIGoalManager | Helper existe, comentado | Nenhum setup equivalente encontrado na busca auditada | Sem evidência para ativar como conserto do Failed |
| Nav config/NavData | Helper comentado, com limitações 426; AthenaNavSystem já existe | Nenhuma inicialização/query adicional de NavData/navmesh/pathfinding encontrada nos source pesquisados | FES não oferece receita comprovada de nav para copiar |
| Brain/BT/MoveTo | Sem RunBehaviorTree/StartLogic no source; BOT-1 adicionou Move explícito | Sem esses mecanismos encontrados na busca source auditada | Não comprova movimentação autônoma ou BT indispensável |
| Registro/atributos/loadout | BOT-0 não aplica overrides manuais | FES altera teams, atributos/abilities/loadout e ForceNetUpdate via director | Fora do escopo; não importar para o diagnóstico |

## Decisão desta etapa

SetupNavConfig é o helper ligado diretamente à configuração de navegação, mas não está validado para o 426 observado e não é ativado. GoalManager/AIDirector parecem camadas de comportamento e não apresentam operações de pathfinding nesses corpos. Não há evidência suficiente para escolher qualquer um como correção do Failed.

Primeiro obter [NAV] NavDataSet/SupportedAgents, projeção e caminho para o Controller. Mesmo NavData vazio, projeção falsa, Brain null ou um erro de helper não autoriza uma inicialização automática no BOT-2. Resultado e próximo milestone serão decididos após o teste do usuário, conforme [BOT2_TEST.md](BOT2_TEST.md).
