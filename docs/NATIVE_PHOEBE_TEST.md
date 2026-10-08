# Native Phoebe — ensaio manual

**PHOEBE PARTIAL. A opção ON deste build faz somente preflight e recusa o spawn.** Não é um teste de bot autônomo de 60 segundos nesta revisão. OFF mantém BOT-0 funcional. Nenhum Launcher/host/cliente foi iniciado pelo Codex.

## Resultado do preflight — 08/10/2026, 09:55:28

Executado pelo usuário, **DLL native-phoebe-ai confirmada** na linha 14203 do launcher.log. Uma requisição ON foi consumida no tick do host e chegou ao final. Recorte privado: `reboot/audit/native-phoebe-test-20261008-0955.local.txt`, 57 eventos técnicos com números de linha originais. **PHOEBE PARTIAL, spawned=0, AI-0 a AI-7 NOT_TESTED.**

| Dependência/consulta | Evidência da sessão |
| --- | --- |
| Manager / mutator | Objetos existentes válidos; guards de caches/contexto passaram |
| Playlist efetiva | Playlist_DefaultSolo |
| Playlist.AISettings | Phoebe_Default_AISettings válido |
| bAllowAIGoalManager / bAllowAIDirector | Properties presentes; valores dos flags não lidos |
| GoalManager / Director | Não obtidos como objetos válidos nas properties consultadas |
| Controller | Apenas CDO inspecionado, nenhum Controller novo criado |
| BotData / BehaviorTree / Blackboard / PerceptionComponent | Properties presentes no Controller CDO; conteúdos/storage não lidos |
| Brain do CDO | Nenhum objeto válido obtido; não é observação de Brain de um bot novo |
| BT_Phoebe / BB_Phoebe / CurveTables | Assets existentes válidos |
| NavDataSet | available=true, count=0; registered_AthenaNavMesh=false |
| Agente default | Phoebe |
| Construção/bloqueio | building=false, building_or_locked=true; origem do bloqueio desconhecida |

O FAIL de `PHOEBE native_spawn_contract` é **uma recusa programada pelo preflight**, não um retorno de erro do SpawnAI/SpawnBot: essas funções não foram chamadas. A ausência de entidade é o resultado esperado desta revisão. Nenhuma mudança de source/DLL ou inicialização automática foi feita durante a análise do log.

### Metadados nativos obtidos

| Objeto refletido | PropertiesSize | Fields e offsets registrados |
| --- | --- | --- |
| Manager.SpawnAI | 40 | InSpawnLocation=0, InSpawnRotation=12, AISpawnerComponentList=24, ReturnValue=32 |
| Manager.SpawnBot | 56 | InSpawnLocation=0, InSpawnRotation=12, InBotData=24, InRuntimeBotData=32, ReturnValue=48 |
| RuntimeCustomizationData | 16 | PredefinedCosmeticSetTag=0, CullDistanceSquared=8, bCheckForOverlaps=12, bHasCustomSquadId=13, CustomSquadId=14 |
| AIController.RunBehaviorTree | 16 | BTAsset=0, ReturnValue=8 |

Todos os field lists terminaram com incomplete=false. **Nomes/offsets/tamanhos não validam tipos, defaults, direção dos parâmetros ou ownership.** A struct nativa tem 16 bytes; a declaração vazia continua sendo uma limitação do SDK do Reboot, não ausência de dados na build.

O ObjectsDump atualizado dessa sessão contém FortAthenaAISpawnerDataComponentList, CreateComponentList/CreateComponentListFromClass, GetBehaviorComponent/GetSpawnParamsComponent e classes nativas de behavior, skillset e inventory. Isso fornece um candidato de investigação para a entrada SpawnAI por componentes. Não comprova que haja um perfil genérico preenchido/carregado, que a lista correta tenha sido identificada ou que behavior funcione sem restaurar navegação. Detalhes no [pipeline](NATIVE_PHOEBE_PIPELINE.md).

## Seleção da DLL

Selecionar, com sessão anterior encerrada normalmente, **Settings → Internal files → Game server → Game server type = Custom**, primeiro campo Game server (antes da Season20):

`D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\native-phoebe-ai\Project Reboot 3.0.dll`

PDB no mesmo diretório. Manter configuração funcional: Backend Embedded, 127.0.0.1, Detached Off; Host 13.40 CL14113327, Headless On, porta7777, players required1, restart Off, argumentos vazios, Private IPs operator e No MCP marcados. Internet totalmente desconectada continua não validada. Não alterar auxiliares ou playlist.

## OFF — comparação com BOT-0

1. Host novo → Apollo listening :7777 → cliente → lobby → partida.
2. Start Bus → saltar → pousar em chão terrestre aberto.
3. **Game → Bots**, Native Phoebe AI **OFF**, Spawn 1 Bot uma vez.
4. Conferir visual/replicação. Não usar MoveTo como prova de autonomia. O comportamento é o BOT-0 anterior; não esperamos que esta revisão tenha corrigido AI.
5. Encerrar cliente/host normalmente. Manter DLL anterior para rollback.

## ON — coleta de requisitos

1. Iniciar outro host novo, sem bot/tentativa anterior.
2. Cliente entra → Start Bus → salto → pouso.
3. **Game → Bots → Native Phoebe AI ON → Spawn 1 Bot**, uma vez.
4. Aguardar [PHOEBE] preflight complete ou FAIL de guard. **Nenhum bot deve ser criado.** Registrar os objetos, playlist, metadata do manager/runtime struct e NavDataSet.
5. Não enviar MoveTo, target, armas, teleporte, StartLogic ou chamadas manuais de setup. Não esperar 60s de comportamento de uma entidade que não foi criada.
6. Entregar eventos [PHOEBE], [BOT], [NAV] da sessão e apenas a linha técnica do caminho da DLL. Não publicar launcher.log bruto com AUTH/conta.

```powershell
$phoebeSourceLog = 'D:\Games\Fortnite-Local-C2S3\reboot\artifacts\launcher\Release\launcher.log'
$phoebeEvents = 'D:\Games\Fortnite-Local-C2S3\reboot\audit\native-phoebe-test-events.local.txt'
Get-Content -LiteralPath $phoebeSourceLog |
  Where-Object { $_ -match '\[(PHOEBE|BOT|NAV)\]' -and $_ -notmatch '(?i)AUTH_|password|exchange|token' } |
  Set-Content -LiteralPath $phoebeEvents -Encoding utf8
```

ON não ativa a entrada Epic original. [PHOEBE] preflight complete não significa bootstrap complete. É esperado stage=native_spawn_contract até a validação/adaptação desse caminho. Se NavDataSet vazio, também haverá stage=registered_nav; não liberar bloqueio/recriar sistema por tentativa.

## Observação futura — somente quando bootstrap estiver validado

Com ON e exatamente um bot criado pelo fluxo nativo, pousar em área aberta, não enviar MoveTo/target nem conceder arma. Observar ~60s e registrar separadamente:

| Nível | Critério | Estado nesta revisão |
| --- | --- | --- |
| AI-0 | Brain nativo válido/running e vínculo com BT observado | NOT_TESTED |
| AI-1 | Movimento espontâneo visível | NOT_TESTED |
| AI-2 | Navegação/caminho comprovados | NOT_TESTED |
| AI-3 | Percepção/reação ao player | NOT_TESTED |
| AI-4 | Loot/interação/coleta | NOT_TESTED |
| AI-5 | Equipa arma sozinho | NOT_TESTED |
| AI-6 | Combate espontâneo | NOT_TESTED |
| AI-7 | Construção espontânea | NOT_TESTED |

Não inferir capacidades a partir dos nomes dos assets. Um Brain running não comprova combate. Não introduzir bosses, henchmen, Marauders, sharks ou mais bots.

## Build, reprodução e rollback

Build Release x64 com MSBuild/SDK do baseline, OutDir e IntDir exclusivos native-phoebe-ai. Source base: **ab39364a3c3644c7169752c6dcb2de4e70f9f5f9**, tag baseline/bot2-navdiag-empty-navdata, nova branch bot-ai/native-phoebe-bootstrap. Patch `reboot/patches/native-phoebe-bootstrap.patch`, relativo ao BOT-2.

Checkout novo: upstream fixado → reboot3-build-compat.patch → bot0-single-bot.patch → bot1-manual-move.patch → bot2-nav-diagnostics.patch → native-phoebe-bootstrap.patch, cada um somente após git apply --check. Não reaplicar no checkout local modificado nem usar outputs padrão do build script do baseline.

Build final: **exit code 0**, Release x64; manifesto privado `reboot/audit/native-phoebe-build.local.json`.

| Artefato | Identidade final |
| --- | --- |
| DLL | 3127296 bytes, AMD64; SHA-256 f1a441fb07732f98633f75c4bb5ac1354a7695e9fa38376be7f40ff41c995f10 |
| PDB | 27168768 bytes; SHA-256 f44d11ddc76c5442d7c9372a406e7f861bcc69628b42f5074096a76400a2c735 |
| CodeView/PDB | GUID dd40169e-fede-4826-bc4f-def31dfbf5cf, age 2; correspondência verificada |
| Patch | SHA-256 62185304001a590b5aad88e502952444470f51e5abdae0c494c342b4606770c2; base ab39364a3c3644c7169752c6dcb2de4e70f9f5f9 |

15 hashes de artefatos preservados e três patches anteriores intactos. Build/artefatos/source verificados, **runtime Native Phoebe não executado**. A classificação continua PARTIAL porque ON ainda não ativa bootstrap.

Rollback com sessão encerrada: selecionar a DLL bot2-navdiag, bot1 ou bot0-working. OFF no build novo também preserva o spawn BOT-0, mas trocar modo após um preflight/attempt no mesmo host requer host novo. Nenhuma configuração do Launcher é escrita automaticamente.

Mapeamento: [NATIVE_PHOEBE_PIPELINE.md](NATIVE_PHOEBE_PIPELINE.md). Implementação e limites: [NATIVE_PHOEBE_IMPLEMENTATION.md](NATIVE_PHOEBE_IMPLEMENTATION.md).
