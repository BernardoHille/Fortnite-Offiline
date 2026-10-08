# Native Phoebe Bootstrap V1 — 13.40 CL 14113327

**Estado: PHOEBE-V1 NAV-BLOCKED confirmado no runtime V1 do usuário em 08/10/2026 às 10:46:38. A primeira tentativa real de spawn/Brain nativo não foi habilitada.** A auditoria não encontrou uma inicialização de navegação demonstrada para este host. Codex não executou o jogo. Resultado completo em [NATIVE_PHOEBE_BOOTSTRAP_V1_TEST.md](NATIVE_PHOEBE_BOOTSTRAP_V1_TEST.md).

O novo ensaio confirma NavDataSet0 antes/depois, flags de GoalManager/Director **true**, initial lock **inativo** e config Athena nativo vindo de **Apollo_Nav_Gameplay carregado/visível**. As variantes **Apollo_Nav_Gameplay_WaterLevel_0..7 estão descarregadas/invisíveis**. O sistema usa streamed nav, com criação automática/rebuild desativados. Seleção/carregamento das variantes é uma nova pista; causa exata e variante correta ainda não comprovadas. Não remover lock nem substituir o override Phoebe por MANG.

O pedido condiciona o spawn à navegação válida e permite `SetupNavConfig("MANG")` somente com evidência forte de compatibilidade. Essa evidência não existe. Continuar com criação de bot, trocar Phoebe por MANG ou remover um lock desconhecido violaria essas condições. O V1 avança as leituras de flags/config/streaming/contratos e aborta na primeira dependência não validada.

Data: 08/10/2026. Escopo de source: somente `Project Reboot 3.0/Bot0.cpp`, `NativePhoebe.inl` e `gui.h`. Launcher, Lawin, autenticação, backend, matchmaker, jogo/PAKs, DLLs auxiliares e anti-cheat não foram modificados. Codex não iniciou Launcher, host ou cliente.

## Preservação e reprodução

Preflight congelado no commit **0e252cd76d066ab5caea98c358c2b6b11dbccd3c**, tag **baseline/native-phoebe-preflight**. Branch V1: **bot-ai/native-phoebe-bootstrap-v1**. Upstream original: Milxnor/Project-Reboot-3.0, commit `10c659028ad9d6816f78226483f11a884bf81f57`.

DLL preflight preservada em `reboot/artifacts/reboot3/native-phoebe-ai/Project Reboot 3.0.dll`, SHA-256 `f1a441fb07732f98633f75c4bb5ac1354a7695e9fa38376be7f40ff41c995f10`; PDB `f44d11ddc76c5442d7c9372a406e7f861bcc69628b42f5074096a76400a2c735`. Os baselines de gameplay, BOT-0, BOT-1, BOT-2 e seus patches permanecem preservados.

O patch incremental V1 é `reboot/patches/native-phoebe-bootstrap-v1.patch`, relativo ao preflight acima. Para reproduzir de um checkout novo, seguir a cadeia já documentada em [NATIVE_PHOEBE_TEST.md](NATIVE_PHOEBE_TEST.md): compatibilidade de build → BOT-0 → BOT-1 → BOT-2 → preflight → V1. Não aplicar somente o último patch ao upstream original.

O script genérico `scripts/build-reboot3.ps1` valida o pin upstream e escreve na pasta do baseline. **Não foi usado para V1.** O build V1 usa MSBuild da instalação VS2022 Community, solução `reboot/reboot3/Project Reboot 3.0.sln`, com estes argumentos:

```text
/t:Build /m:2 /nologo /v:minimal
/p:Configuration=Release /p:Platform=x64 /p:CL_MPCount=2
/p:PlatformToolset=v143 /p:VCToolsVersion=14.44.35207
/p:WindowsTargetPlatformVersion=10.0.26100.0
/p:OutDir=D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\native-phoebe-bootstrap-v1\
/p:IntDir=D:\Games\Fortnite-Local-C2S3\reboot\artifacts\intermediate\reboot3\native-phoebe-bootstrap-v1\
```

## NavDataSet vazio: evidência e limites

**CONFIRMADO no ensaio anterior, 08/10 às 09:55:28:** sistema Athena válido; `NavDataSet available=true count=0`; nenhum AthenaNavMesh registrado; default agent Phoebe; `building=false`, `building_or_locked=true`. BOT-2 também havia observado somente AbstractNavData-Default como NavigationData no World, projeções false e caminho null. Isso demonstra ausência de dados utilizáveis, não sua causa inicial.

**CONFIRMADO no source Reboot:** `SetupEverythingAI` configura manager/mutator e classes PlayerBot. SetupNavConfig, GoalManager e Director estão comentados. `SetNavigationSystem` não repara um sistema existente: retorna false antes do cleanup e da substituição. `FindAddNavigationSystemToWorld` tem somente branches 421, 423 e 425; para 426 retorna zero. O helper chama esse ponteiro sem guard se alcançar esse trecho. Nenhuma alteração foi feita nesses helpers.

Outro ponto confirmado: ao atingir WarmupRequiredPlayerCount, o hook ReadyToStartMatch em Engine>=424 atribui Ret=true e deixa de chamar o original naquele ciclo. O original ainda pode ser chamado nos ciclos anteriores quando Ret=false. A mensagem `Athena_ReadyToStartMatchOriginal RET!` é emitida para qualquer Ret=true e **não prova que o original foi invocado**. O efeito sobre inicialização/lock de nav é hipótese, não causa demonstrada; nenhuma alteração desse hook foi feita no V1.

O log anterior imprime `AddNavigationSystemToWorld: 0xffff8009c44f0000`. O source imprime `Address - Base`; o valor é consistente com zero menos base, **não um RVA utilizável**. Não usar esse número como endereço ou procurar uma assinatura nova para chamar a função sem contrato validado.

**CONFIRMADO no streaming registrado:** DefaultSolo tem três `AdditionalLevelsServerOnly`, e o log informa sua solicitação:

```text
/Game/Athena/AI/MANG/Apollo_POI_Agency_MANG.Apollo_POI_Agency_MANG
/Game/Athena/AI/MANG/Apollo_POI_MANG_HMW.Apollo_POI_MANG_HMW
/Game/Athena/AI/MANG/Apollo_POI_Fortilla_MANG_Foundation.Apollo_POI_Fortilla_MANG_Foundation
```

Esses nomes não comprovam presença de NavData Phoebe. ReadyToStartMatch chama `AddToAdditionalPlaylistLevelsStreamed` e callbacks. O próprio source comenta que um array server-only de ULevelStreaming não é preenchido por esse caminho e que sua checagem de visibilidade pode passar porque está vazio. **INFERIDO:** streaming incompleto pode contribuir para a ausência de nav. **DESCONHECIDO:** se isso ocorreu aqui e qual pacote realmente contém os dados Phoebe. O V1 lê `World.StreamingLevels` e getters de loaded/visible, sem carregar níveis.

O ObjectsDump foi produzido antes do clique. Nele há classes/CDOs AthenaNavMesh/config, mas nenhuma instância carregada de AthenaNavMesh encontrada. Existência de CDO não significa malha de Apollo registrada. O V1 não cria um Recast/AthenaNavMesh vazio, não copia NavDataSet e não escreve SupportedAgents.

**Conclusão causal:** não foi demonstrado por que a build não criou/carregou/registrou nav originalmente. Foi demonstrado por que ativar o helper disponível não é um reparo válido. Faltam flags/config efetivos e origem do lock; o novo ensaio precisa fornecer essas leituras. Não afirmar que MANG é a inicialização ausente.

## SetupNavConfig("MANG") completo

Referências: `ai.h:SetNavigationSystem`, `SetupNavConfig`, `finder.h:FindAddNavigationSystemToWorld`, `FortGameModeAthena.cpp:ReadyToStartMatch` e [BOT2_REBOOT_AI_SETUP.md](BOT2_REBOOT_AI_SETUP.md).

| Pergunta | Resposta sustentada pelo source |
| --- | --- |
| Que objeto/asset MANG resolve? | Nenhum. O caller passa FName; o helper escreve `DefaultAgentName`. |
| É Phoebe? | Não demonstrado. Runtime default é Phoebe; SupportedAgents observado: Husk/Smasher/Graph/Phoebe/Deimos, sem MANG. |
| O que cria? | Actor AthenaNavSystemConfigOverride; objeto AthenaNavSystemConfig com outer nesse actor. |
| Flags alteradas? | BuildingGrid=false; streamed nav=true se property existir; auto-rebuild/client/autospawn/navbounds-level=true; invokers=false se existir. |
| Risco das flags? | Escreve `Get<bool>` em flags que podem ser bitfields; não respeita suas máscaras. V1 não reutiliza essas escritas. |
| Cria/registra NavData ou AthenaNavMesh? | Nenhuma chamada explícita. Config pode pedir autospawn ao sistema nativo; efeito não demonstrado. |
| Popula NavDataSet/SupportedAgents? | Não escreve esses arrays. |
| GamePhase/playlist? | Nenhum guard ou leitura desses dados no helper. O caller no match é comentado. Timing Epic desconhecido. |
| Guard por versão? | Helper não tem guard 13.40/426; finder não implementa 426. |
| Sistema existente? | SetNavigationSystem retorna false. Cleanup/substituição depois desse return são inalcançáveis nesse caso. |
| Sem sistema? | Altera WorldSettings/config; tenta chamar função nativa sem address guard e com assinatura de cinco argumentos não validada para 426. |

**Decisão V1: NOT_CALLED.** A condição de autorização técnica do pedido não foi atendida; nenhum override/config novo é criado.

## Flags, GoalManager e Director

O preflight só demonstrou presença de `bAllowAIGoalManager` e `bAllowAIDirector`, não valores. V1 lê a instância efetiva `Playlist_DefaultSolo.AISettings` usando property offset + **ByteOffset**, com FieldSize/ByteMask/FieldMask validados. Metadata ilegível/inconsistente produz `UNKNOWN`, nunca false presumido. O helper version-aware já existente documenta a ordem desses quatro bytes; o leitor fica restrito a 13.40/426. Não há escrita de flags.

A semântica de ByteOffset/FieldMask é descrita na [API oficial FBoolProperty](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/CoreUObject/UObject/FBoolProperty?application_version=4.27). Isso não substitui a validação das leituras na build alvo; o teste do usuário de08/10 às10:46:38 confirmou ambas as flags true (offset48, máscaras2 e1, ByteOffset0).

`SetupAIGoalManager` procura `/Script.FortniteGame.FortAIGoalManager` (grafia diferente do path usual `/Script/FortniteGame...`), cria actor se não existir e grava `GameMode.AIGoalManager`. O source comenta classe vinda de GameData e permissão AISettings, mas não lê a flag nem inicializa dados/BT/Nav. Dependência de um bot BR isolado: **DESCONHECIDA**. V1 não corrige/chama o helper por tentativa.

`SetupAIDirector` procura AthenaAIDirector, cria actor, grava `GameMode.AIDirector`, atribui FortAIEncounterInfo como BaseEncounterClass e chama Activate se encontrado. O source admite classe/tabelas incompletas. Relação direta com GameState, goals, skillsets, loot/combat e necessidade para um bot isolado: **não reconstruídas**. Activate pode envolver encounters/população; não foi chamado. Permissão true não comprova necessidade ou setup completo. Ambos: **created=0 pelo V1**, objetos existentes apenas inspecionados.

## Origem de building_or_locked

Não determinada exatamente. Os dois bools anteriores sugerem lock em vez de construção naquele instante, mas não revelam proprietário, razão/máscara, momento de aquisição ou dependência de streaming. No V1, `IsInitialNavigationLockActive=false` foi medido com getter válido. `bInitialBuildingLocked=true` é configuração distinta; não atribuir o resultado building_or_locked ao lock inicial. Outros locks, generation ou world lock continuam sem origem reconstruída.

V1 enumera os parâmetros de `AthenaNavSystem.IsInitialNavigationLockActive` e aceita somente `ReturnValue` em receptor Athena válido ou `WorldContextObject/ReturnValue` no CDO existente da classe dona. Outras assinaturas não são chamadas e ficam UNKNOWN. A seleção pelo conjunto exato de parâmetros corrige a limitação do getter anterior, que só admitia ReturnValue; **o teste V1 confirmou a segunda assinatura nesta build: PropertiesSize16, WorldContextObject@0 e ReturnValue@8; chamada retorna false para o lock inicial**.

Também lê flags candidatas na instância AthenaNavSystem e nos configs encontrados em WorldSettings/AISettings. Falta de property não é interpretada como flag desativada. Lê streaming e reconta NavDataSet no mesmo clique. É uma amostra imediata, não uma espera por construção. `bInitialBuildingLocked` é configuração, não prova isolada de lock ativo; a [documentação UE4.27 NavigationSystemV1](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/NavigationSystemV1?application_version=4.27) descreve seu efeito, autocriação/subníveis/agentes. Defaults documentados não foram impostos ao Fortnite.

A análise PE somente leitura encontrou nomes/tabelas de registro e candidatos de thunks, mas os bytes nos RVAs extraídos não permitiram reconstruir corpos coerentes suficientes para atribuir o lock. Não foi feita decriptação, patch ou execução do jogo. Evidência privada: `reboot/audit/inspect-phoebe-binary.local.py` e `.local.txt`. Nenhum endereço dessa análise é chamado pelo V1.

## SpawnAI, SpawnBot e component pipeline

| Entrada | Contrato observado anteriormente | Limite |
| --- | --- | --- |
| Manager.SpawnAI | 40 bytes; location@0, rotation@12, AISpawnerComponentList@24, ReturnValue@32 | Melhor candidato para componentes nativos; lista preenchida/asset genérico/types/ownership/caller interno não validados. |
| Manager.SpawnBot | 56 bytes; location@0, rotation@12, InBotData@24, InRuntimeBotData@32, ReturnValue@48 | CustomizationData/runtime; interceptado pelo Reboot; wrapper Runtime vazio. ProcessEvent não garante corpo Epic completo. |
| RuntimeCustomizationData | ScriptStruct 16 bytes; tag@0, cull@8, overlap@12, custom-squad flag@13, squad@14 | Tamanho/offset não demonstram defaults, tipo de cada campo ou inicialização/destruição. Não construído. |
| AIController.RunBehaviorTree | 16 bytes; BTAsset@0, ReturnValue@8 | Sem call site Epic genérico demonstrado. Não chamado isoladamente. |

O ObjectsDump comprova nomes/interfaces `FortAthenaAISpawnerData.CreateComponentList/CreateComponentListFromClass/GetBehaviorComponent/GetSpawnParamsComponent`, classe ComponentList e GetList/OverrideComponent*, além de componentes Behavior/skillset/inventory/cosmetic. V1 enumera assinatura desses criadores/getters, **sem chamá-los**. Ainda não é prova de uma lista completa de perception/skills/inventory nem de perfil BR genérico.

A opção preferida para investigação é **SpawnAI + lista criada nativamente a partir de perfil BR validado**. Não foi escolhida como função habilitada para execução. CDO vazio, CurveTable e DangerGrape não são substitutos demonstrados. Nenhuma BotData é lida como struct presumida, escrita, copiada ou fabricada. Nenhuma RuntimeCustomizationData é construída.

Reboot tem um helper `SpawnAIFromSpawnerData` que faz spawn/loadout manual; não é `Manager.SpawnAI`. `SpawnBotHook` permite original apenas para um return address detectado pelo scanner; outros callers seguem mutator, teleporte e cosmetic manual. Não foi demonstrado se o caller interno de SpawnAI segue o original. `BotManagerSetupStuffIdk` usa endereço fixo e assinatura opaca: não chamado. Nenhuma interceptação foi alterada.

## Gate implementado

```text
Native Phoebe OFF -> ProcessBody BOT-0 preservado
Native Phoebe ON -> request capturado -> TickFlush do NetDriver principal
  -> 13.40/426/Apollo/listening/Athena/SafeZones/humano/manager/mutator
  -> playlist efetiva + AISettings válidos; flags/metadata/config/streaming
  -> NavData antes -> SetupNavConfig NOT_CALLED -> NavData depois
  -> sem AthenaNavMesh Config.Name=Phoebe -> navigation_bootstrap / NAV-BLOCKED
  -> se houver candidato: dimensões do agente contra Movement do CDO Phoebe
     -> projeções humano/candidato 15m + caminho nativo completo
     -> falha/UNKNOWN: NAV-BLOCKED
     -> consultas válidas: spawn_contract_validation / SPAWN-BLOCKED
        (perfil BR/lista preenchida/types/ownership/original route ainda ausentes)
```

Igualdade conservadora de radius/height usa propriedades refletidas, sem constantes de agente. Não pretende reproduzir o algoritmo interno de seleção. Projeção usa nav explícito e extent limitado do helper BOT-2; o fallback 50/50/250 continua identificado como referência UE4.27, não valor observado na build. Distância humana deve permanecer entre 1000 e 2000cm. Uma query de caminho, sem MoveTo, exige NavigationPath válido, não parcial, com pelo menos dois pontos. São consultas de navegação; não comandos de AI.

**Nesta DLL não há SpawnAI/SpawnBot nativo ON habilitado, RunBehaviorTree, StartLogic, criação de Blackboard/Brain, configuração de senses ou concessão de arma.** O antigo FAIL final `native_spawn_contract` foi substituído por falha de estágio real de navegação, mantendo a recusa do contrato se a navegação passar. A condição pedida para remover a recusa do spawn não foi satisfeita. Não esconder esse limite como bootstrap funcional.

Uma requisição ON por host é consumida; não há fallback BOT-0, retries ou população automática. Para A/B, host novo. A flag começa OFF e o corpo de spawn BOT-0 permanece idêntico. Menu principal: checkbox, Spawn 1 Bot, Dump Bot State; comandos antigos ficam em Advanced/Diagnostics, com Move oculto quando ON. Observação automática de 60s não foi adicionada porque não existe caminho de criação/Brain ativado nesta revisão. AI-0 a AI-7: **NOT_TESTED**.

As consultas reutilizam ProcessEvent e guards de vida/reflection existentes. Falta de dado tratada por guard aborta o pedido; não é uma garantia contra todo fault nativo. SEH registra a exceção e deixa o crash handler normal continuar; não engole uma falha desconhecida para simular sucesso.

## FES season-13 fixado

Checkout somente leitura, commit `e42ecddbce59163c6a60ab7506766c2a0adfe580`. Arquivos principais: `Source/FortniteGame/Private/AI/FortAthenaAI.cpp` e `Private/Versioning/Season13BuildProfile.cpp`.

| Item | Encontrado no FES |
| --- | --- |
| Nav/setup/agente | Nenhuma inicialização/register NavData ou Phoebe agent demonstrada. |
| Lista nativa de componentes | Nenhum CreateComponentList/component profile nativo genérico identificado. |
| SpawnAI/SpawnBot | `FFortAIDirector::SpawnAI` é método C++ do FES; deferred Pawn spawn, não UFunction Manager.SpawnAI. |
| Controller | ResolveBotControllerClass existe; não utilizado pela função SpawnAI auditada. |
| BT/Brain/GoalManager | Nenhum RunBehaviorTree/StartLogic/setup GoalManager encontrado. |
| Director | Cria AthenaAIDirector/Activate; RegisterWithDirector apenas ForceNetUpdate, sem registro do Pawn demonstrado. |
| Inventory/skillset | Abilities/teams/saúde/loadout manuais; não digest nativo de skillset/component list comprovado. |

FES não fornece a ponte ausente. Não portado código de bosses/população/loadout; suporte descrito no README não demonstra autonomia nesta sessão.

## Validação e pendências

Build Release x64 compilado. Verificação: 17 hashes preservados (incluindo preflight DLL/PDB, Shipping, Launcher e auxiliares); corpo OFF idêntico; configuração/vcxproj inalterados; source limitado aos três arquivos; gate de navegação antes de queries/contrato; nenhuma chamada de mutation AI; patch incremental com reverse/apply-check; DLL AMD64 e PDB com GUID/age correspondentes; links/fences dos três documentos verificados. Detalhes privados em `reboot/audit/native-phoebe-v1-build.local.json`, verificador `verify-native-phoebe-v1.local.py`. Warnings antigos de conversão, World.h retornando endereço local e Map.h sem retorno permanecem; não corrigidos nesta etapa. Resultado runtime V1 confirmado pelo usuário: NAV-BLOCKED, zero bots ON, em08/10/2026 às10:46:38. Procedimento em [NATIVE_PHOEBE_BOOTSTRAP_V1_TEST.md](NATIVE_PHOEBE_BOOTSTRAP_V1_TEST.md).

| Artefato final | Identidade |
| --- | --- |
| DLL V1 | 3155968 bytes; SHA-256 `9010a6ef53c3ef705b6f567948a8bf21d1f7d82b06aef9ff4f15b3e2cf41c824` |
| PDB V1 | 27324416 bytes; SHA-256 `707810b30f7dbb8b988f41a2f578d5011b74731f7b549ba83edd6f664208ad70` |
| CodeView/PDB | GUID `98d93622-175e-4aac-a939-3edfc7d80551`, age2, correspondência verificada |
| Patch V1 | SHA-256 `353ccdb7582408fc688a8fd69cc84f7ed264d7878ced38c5b6e044776c4b8140` |
| Log de build final | `reboot/logs/reboot3-native-phoebe-bootstrap-v1-final-Release.log`, MSBuild exit0 |

O trabalho **não alcançou a meta de bot nativo autônomo**. Para habilitar a primeira tentativa real ainda é necessário demonstrar a origem/configuração de NavData/lock na build alvo e um perfil BR real com lista nativa/contrato validado. Não houve autorização técnica para inventar esses elementos. Esta revisão termina nesse bloqueio, sem escalada.

## Respostas finais solicitadas

1. **Por que NavDataSet estava vazio?** Causa inicial não comprovada. Ausência de registro foi medida; streaming e lock são candidatos. O helper existente não é reparo válido para esse sistema/426.
2. **MANG usado?** Não; condição de evidência forte não satisfeita.
3. **NavData depois?** V1 runtime:0 antes/0 depois; nenhuma geração foi chamada.
4. **AthenaNavMesh registrado?** Não no runtime V1.
5. **GoalManager criado?** Não pelo V1; objeto existente só inspecionado.
6. **Director criado?** Não pelo V1; Activate não chamado.
7. **Spawn escolhido?** SpawnAI + component pipeline é candidato preferido, sem habilitação. SpawnBot tem runtime struct incompleta e interceptação não validada para esse caller.
8. **Component list/BotData usados?** Nenhum; perfil BR preenchido não identificado. CDO/CurveTable/DangerGrape não substituídos.
9. **Brain inicializado?** Não; zero spawn ON.
10. **BT_Phoebe iniciado?** Não; nenhum RunBehaviorTree/StartLogic chamado.
11. **DLL?** `D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\native-phoebe-bootstrap-v1\Project Reboot 3.0.dll`.
12. **Observar?** Host novo, pousar, ON, um clique; registrar flags, assinatura/valor do initial lock, configs/streaming e counts before/after. NAV-BLOCKED encerra o teste sem bot/espera60s. Procedimento manual acima vinculado.
