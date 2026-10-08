# Teste manual — Native Phoebe V1

**PHOEBE-V1 NAV-BLOCKED confirmado no teste do usuário em 08/10/2026 às 10:46:38.** Codex apenas analisou o log. A DLL V1 valida navegação/config/streaming e não habilita spawn nativo ON; nenhum bot autônomo foi criado nesta revisão.

## Resultado registrado — 08/10/2026, 10:46:38

A última seção de host começa na linha21959 do launcher.log e confirma a DLL `native-phoebe-bootstrap-v1/Project Reboot 3.0.dll`. Há uma requisição ON nesse host, consumida no TickFlush. Manager/mutator, DefaultSolo e Phoebe_Default_AISettings válidos. O fluxo termina na linha29734 com `result=PHOEBE-V1 NAV-BLOCKED spawned=0`; a linha29733 identifica `stage=navigation_bootstrap`. Não há evento técnico de exceção `[BOT/PHOEBE][FAIL] exception=` nessa seção. Isso não comprova ausência de falhas em toda a aplicação.

| Leitura efetiva | Resultado |
| --- | --- |
| AISettings.bAllowAIGoalManager | true; offset48, ByteOffset0, mask2 |
| AISettings.bAllowAIDirector | true; offset48, ByteOffset0, mask1 |
| Objetos GoalManager/Director existentes | Não obtidos como objetos válidos; V1 não os criou |
| NavDataSet antes/depois | available=true, count0 / count0 |
| AthenaNavMesh registrado / Phoebe NavData | false / false |
| DefaultAgentName | Phoebe |
| IsNavigationBeingBuilt / BeingBuiltOrLocked | false / true, ambos available=true |
| IsInitialNavigationLockActive | available=true, **false**; contrato WorldContextObject@0/ReturnValue@8, size16 |
| AthenaNavSystem.bInitialBuildingLocked | **true** (configuração); não equivale ao getter de lock ativo |
| AthenaNavSystem.bAutoCreateNavigationData | false |
| AthenaNavSystem.bUsesStreamedInNavLevel / bAllowAutoRebuild | true / false |
| AthenaNavSystem.bSpawnNavDataInNavBoundsLevel / bShouldDiscardSubLevelNavData | true / false |
| AthenaNavSystem.bUseBuildingGridAsNavigableSpace | true |
| WorldSettings.NavigationSystemConfig | NullNavSysConfig, DefaultAgentName=None, bIsOverriden=true |
| WorldSettings.NavigationSystemConfigOverride | AthenaNavSystemConfig do nível `/Game/Maps/Apollo_Nav_Gameplay`, DefaultAgentName=Phoebe |
| Override.bAutoSpawnMissingNavData / bAllowAutoRebuild | false / false |
| Override.bUsesStreamedInNavLevel / bSpawnNavDataInNavBoundsLevel | true / true |
| World.StreamingLevels | count679; amostra limitada aos primeiros64 |
| `/Game/Maps/Apollo_Nav_Gameplay` | loaded=true, visible=true |
| `/Game/Maps/Apollo_Nav_Gameplay_WaterLevel_0` até `_7` | **Todos loaded=false, visible=false**, encontrados nos índices1–8 |
| Projeção/path/spawn/Brain/BT/AI-0..7 | Não alcançados; zero bot ON |

**CONFIRMADO:** o nível base de navegação e seu override nativo estão presentes; a criação automática/rebuild estão desativados e o uso de nav carregada de subníveis está habilitado. **INFERIDO:** a seleção/carregamento de uma variante WaterLevel pode ser a ligação ausente para os dados Phoebe. **DESCONHECIDO:** qual variante deveria estar ativa, se seus assets contêm a NavData necessária, como é selecionada e por que o outro getter ainda indica building_or_locked. Não classificar o nível base como descarregado nem o lock inicial como ativo; não habilitar geração/unlock por tentativa.

Os três níveis server-only MANG aparecem na playlist, mas isso não demonstra que substituam as variantes de navegação. A leitura `AISettings.NavigationSystemConfig` candidata não resolveu objeto válido; não concluir ausência de config de AI sob outra property.

Metadados adicionais coletados, sem chamadas aos creators ou ao getter FortKismet:

| Função | PropertiesSize / fields |
| --- | --- |
| CreateComponentList | 16; OuterObject@0, ReturnValue@8 |
| CreateComponentListFromClass | 24; AISpawnerDataClass@0, OuterObject@8, ReturnValue@16 |
| GetBehaviorComponent / GetSpawnParamsComponent | 8 cada; ReturnValue@0 |
| ComponentList.GetList | 16; ReturnValue@0; tipo/ownership ainda não demonstrados |
| FortKismetLibrary.GetNavigationDataForActor | 16; Actor@0, ReturnValue@8 |

Manager.SpawnAI/SpawnBot, RuntimeCustomizationData e RunBehaviorTree repetem os sizes/offsets anteriores. Existência/offsets continuam sem comprovar contrato completo ou perfil BR preenchido. O getter initial-lock **foi chamado** após validar a assinatura; a frase “not invoked” na linha de schema descreve somente a enumeração anterior.

Evidência privada: `reboot/audit/native-phoebe-v1-test-20261008-1046.local.txt`, 203 eventos técnicos com numeração original, e JSON local correspondente. Log bruto de autenticação/conta não publicado. Código/DLL/PDB/patch não foram alterados nesta análise.

O procedimento abaixo fica como referência de reprodução; o ensaio acima já foi executado pelo usuário.

DLL copiável, sem aspas no seletor:

```text
D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\native-phoebe-bootstrap-v1\Project Reboot 3.0.dll
```

Selecionar no Reboot Launcher: **Settings → Internal files → Game server → Game server type: Custom → primeiro campo Game server, antes de Season 20**. Não selecionar o campo pós-Season20. Confirmar no novo log que essa pasta foi usada. A DLL/PDB anterior em native-phoebe-ai permanece separada.

DLL final SHA-256: `9010a6ef53c3ef705b6f567948a8bf21d1f7d82b06aef9ff4f15b3e2cf41c824`, 3155968bytes, Release x64. PDB preservado no mesmo diretório, GUID/age correspondentes verificados. Compilação final exit0; nenhuma execução do jogo pelo Codex.

Perfil comprovado anteriormente: Backend Embedded, address127.0.0.1, Detached Off; host13.40 CL14113327, Headless On, Automatic restart Off, port7777, custom arguments vazio, players required1, Private IPs are operator marcado, No MCP marcado. Não alterar a playlist. Internet estava conectada no teste de gameplay; funcionamento totalmente offline não foi comprovado.

## Execução pelo usuário

1. Encerrar a sessão antiga e iniciar **host novo** com a DLL V1. Uma tentativa ON por host.
2. Abrir cliente pelo Play do Reboot, entrar no lobby e na partida.
3. Start Bus no host; saltar e pousar em terreno aberto. Aguardar Pawn humano/partida SafeZones.
4. No menu Bots do host, marcar **Native Phoebe AI** e clicar **Spawn 1 Bot** uma vez.
5. Não usar Move, comandos de target, armas, teleporte ou segundo spawn. Ler o resultado do estágio.
6. Se NAV-BLOCKED: nenhum bot novo deve aparecer. O ensaio termina aí; não é necessário esperar 60s para uma entidade que não foi criada.
7. Se SPAWN-BLOCKED: queries de nav passaram, mas o contrato continua ausente. Também nenhum bot novo deve aparecer.

A sequência de 60s/AI-0..7 solicitada só é aplicável depois de uma revisão criar bot com Brain ativo. Nesta V1 ela está **NOT_TESTED**, e não há sampler automático. Não confundir um BOT-0 de outro host com entidade V1.

## Evidência a conferir

```text
[PHOEBE] ... revision=native-phoebe-bootstrap-v1
[PHOEBE] bAllowAIGoalManager=... available=...
[PHOEBE] bAllowAIDirector=... available=...
[PHOEBE] AthenaNavSystem.IsInitialNavigationLockActive field=...
[PHOEBE] initial_lock available=... value=... route=...
[PHOEBE] bInitialBuildingLocked=... (ou UNKNOWN)
[PHOEBE] ... config/default_agent/flags ...
[PHOEBE] playlist server_level[...] asset=...
[PHOEBE] World.StreamingLevels available=... count=...
[PHOEBE] streaming[...] package=... loaded=... visible=...
[PHOEBE] nav data before count=...
[PHOEBE] SetupNavConfig result=NOT_CALLED reason=...
[PHOEBE] nav data after count=... available=...
[PHOEBE] AthenaNavMesh registered=... Phoebe agent NavData=...
[PHOEBE][FAIL] stage=navigation_bootstrap reason=...
[PHOEBE] result=PHOEBE-V1 NAV-BLOCKED spawned=0 ...
```

`available=false`, `UNKNOWN` e count=-1 são indisponibilidade da leitura, não false/zero reais. As linhas before/after são duas leituras na mesma ação sem mutation/helper; não demonstram resultado de geração. `Config.Name=Phoebe` indica candidato; só nav queries/agent guards acrescentam evidência de usabilidade. Flag de initial lock configurada e lock ativo são leituras diferentes. Streaming sample é limitado a64 itens; ausência na amostra não prova ausência no World inteiro.

A assinatura dos component creators e `FortKismetLibrary.GetNavigationDataForActor` é enumerada. Esses creators/getter FortKismet não são chamados; nome/offset não comprova tipo/ownership. O initial-lock getter só é chamado se um dos dois contratos exatos e receptor coincidirem. Se outra assinatura surgir, a linha metadata permite corrigir sem adivinhar.

Se houver exception/crash, preservar log da sessão e parar. Guard de pré-condição não garante segurança de uma chamada interna Epic. O filtro SEH não recupera uma falha desconhecida.

## A/B e critérios

Para verificar OFF, iniciar **outro host novo** com a mesma DLL e deixar a checkbox desmarcada. Spawn1Bot deve seguir BOT-0 antigo; comportamento de navegação/Brain não foi restaurado nesse caminho. Não misturar OFF e ON no mesmo host.

| Classificação do pedido | Evidência necessária |
| --- | --- |
| NAV-BLOCKED | Dados Phoebe ausentes/inutilizáveis ou sua validação indisponível; zero spawn ON. |
| SPAWN-BLOCKED | Registro/agente/projeções/path passam; contrato/profile nativo não validado; zero spawn ON. |
| BRAIN-BLOCKED | Bot nasce pelo pipeline nativo, mas Brain/BT não inicia. Impossível produzir por esta V1. |
| PARTIAL | Bot nativo criado e algum estágio funciona. Impossível produzir por esta V1. |
| SUCCESS | Bot nativo criado, Brain/BT ativos e autonomia observada. Impossível produzir por esta V1. |

Não conceder AI-0 por existência de BT_Phoebe no dump, AI-1 por teleporte/spawn, AI-2 por um Move antigo, AI-3 por olhar ao acaso ou AI-6 pela presença de uma arma. Quando o caminho nativo existir, observar movimento/percepção/loot/equipar/combate/construção separadamente; nenhuma capacidade foi medida nesta revisão.

O `launcher.log` completo pode conter credenciais/contexto de conta. Ele permanece privado. Relatório publicável deve usar somente eventos técnicos da nova sessão; não commitar o arquivo bruto. Build/identidade/testes e limites em [NATIVE_PHOEBE_BOOTSTRAP_V1.md](NATIVE_PHOEBE_BOOTSTRAP_V1.md).
