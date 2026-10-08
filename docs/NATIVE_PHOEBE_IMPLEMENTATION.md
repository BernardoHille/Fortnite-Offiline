# Native Phoebe — implementação e limites

**PHOEBE PARTIAL: seleção A/B e preflight implementados; bootstrap nativo completo não ativado.** Este build não produz bot autônomo com a opção ON. O checkbox existe para coletar os requisitos que faltam, e recusa antes de spawn/AI. Não confundir DLL compilada com restauração de comportamento.

Mapeamento anterior às edições em [NATIVE_PHOEBE_PIPELINE.md](NATIVE_PHOEBE_PIPELINE.md). Os bloqueios são concretos: NavDataSet vazio no ensaio BOT-2, contrato incompleto de RuntimeCustomizationData no SDK e interceptação existente do SpawnBot do manager. Não foi demonstrado que executar BT_Phoebe isoladamente inicializa todos os dados nativos. Não fabricar layout/defaults nem descomentar os três helpers.

## Preservação

Ensaio ON executado pelo usuário em 08/10/2026 às 09:55:28 confirmou o funcionamento do preflight e seu bloqueio explícito, com spawned=0. DLL correta, playlist/AISettings e metadata obtidos; navegação continuou sem AthenaNavMesh registrada. **Este resultado não ativa o bootstrap nem valida behavior.** Os dados completos estão em [NATIVE_PHOEBE_TEST.md](NATIVE_PHOEBE_TEST.md). Durante a leitura desse log, source, patch e DLL/PDB não foram alterados.

- Baseline BOT-1: commit 0bbf1c5cdff5bd3a92309140930e86ff3906cac5, tag baseline/bot1-moveto-failed.
- BOT-2 congelado: commit **ab39364a3c3644c7169752c6dcb2de4e70f9f5f9**, tag **baseline/bot2-navdiag-empty-navdata**; branch bot2/reboot-13.40-nav-diagnostics preservada nessa ref.
- Nova branch local **bot-ai/native-phoebe-bootstrap**, derivada desse BOT-2.
- DLLs/PDBs antigos mantidos em Release, baseline, bot0, bot0-working, bot1 e bot2-navdiag. Patches anteriores mantidos sem alteração.
- Source novo limitado a Bot0.cpp/h, gui.h, NativePhoebe.inl e inclusão no vcxproj. Reboot Launcher/Lawin/FES/auxiliares/Shipping/PAKs permanecem fora da edição.

## Comportamento e concorrência

**Game → Bots → Native Phoebe AI**, default OFF em cada processo. Alterar o checkbox apenas seleciona o modo; não executa ações. Spawn 1 Bot captura o valor num estado atômico Queued ou QueuedNative. Trocar a opção depois do clique não troca a requisição já enfileirada. Nenhuma configuração persistente ou auto-spawn é adicionada.

OFF usa ProcessBody do BOT-0 **textualmente preservado**. Mantém sua única tentativa nativa por host, mesma função do mutator e mesma inspeção. BOT-1/BOT-2 continuam disponíveis. ON despacha ProcessNativePhoebe no TickFlush já existente, somente no NetDriver principal do World. Guards de 13.40/426, Apollo listening, Athena SafeZones, manager/mutator/caches, humano e ausência de tentativa/bot anterior. Não aplicar ON após um spawn OFF no mesmo host; reiniciar normalmente para A/B.

## Preflight ON

1. Inspeciona objetos existentes de manager/mutator/GoalManager/Director, sem criar ou substituir.
2. Lê playlist efetiva via offsets refletidos de PlaylistPropertyArray.BasePlaylist; fallback CurrentPlaylistData só se disponível, validando classe.
3. Inspeciona AISettings e presença de propriedades candidatas. Ausência é UNKNOWN; não força flags de playlist.
4. Inspeciona CDO do Controller Phoebe (explicitamente rotulado como CDO), presença de BotData/BT/blackboard/perception/skill e assets já carregados BT_Phoebe, BB_Phoebe e CurveTables. Não usa CDO como perfil BotData preenchido.
5. Enumera **somente metadados** de Manager.SpawnAI, Manager.SpawnBot, RuntimeCustomizationData e AIController.RunBehaviorTree: tamanho do objeto refletido, nomes/offsets, máximo 32 fields por objeto. Tipos/defaults/ownership permanecem UNKNOWN. Não chama essas funções.
6. Lê NavDataSet emprestado, limitado a 1000 entradas e logs de até dez; procura classe AthenaNavMesh. Membership não comprova tiles/cobertura/compatibilidade de agente. Consulta somente getters nativos de building/locked.
7. Emite [PHOEBE][FAIL] stage=registered_nav se necessário e stage=native_spawn_contract. Estado NativeBlocked, spawned=0; sem fallback BOT-0, BT isolada ou retry. Novo ensaio requer reiniciar host.

Não há chamada de SpawnAI/SpawnBotOriginal, BotManagerSetupStuffIdk, RunBehaviorTree/StartLogic, SetupNavConfig/MANG, Director/GoalManager. Não há novos offsets, hooks, AI loop, targeting, loot/shooting logic, concessão de armas, teleporte, skin do player ou Boss AI. Os getters utilizados são os já validados/refletidos do BOT-2. O preflight produz metadados úteis para validar uma adaptação futura, sem se apresentar como essa adaptação.

## Falhas

Valores/classes/pointers e buffers são guardados com os mecanismos existentes. Componentes obrigatórios ausentes recusam a requisição. A ausência de getters não é convertida em null comprovado. BotData não é reinterpretado como UObject ou struct fabricada. Arrays de navegação são emprestados e não são liberados.

Erro nativo inesperado é registrado com [PHOEBE][FAIL] e continua até o handler normal existente (SEH do BOT-0). Isso não garante impossibilidade de crash ao consultar o motor; não engole exceção e não tenta continuar estado corrompido. Nenhuma nova chamada de inicialização nativa não validada foi introduzida.

## Build e validação

Release x64, v143 14.44.35207 / SDK 10.0.26100.0 / sem ABOVE_S20, diretório exclusivo `reboot/artifacts/reboot3/native-phoebe-ai/`. PDB e intermediários separados. Identidades e resultado de build registrados no manifesto privado `reboot/audit/native-phoebe-build.local.json` e no [procedimento de teste](NATIVE_PHOEBE_TEST.md).

**Build final confirmado: exit code 0**, DLL AMD64 3127296 bytes e PDB correspondente. Log privado `reboot/logs/reboot3-native-phoebe-verified-Release.log`. A primeira compilação falhou por nome incorreto do helper NavArray; corrigido para o helper existente. A revisão final também remove a conversão implícita no offset de lista de fields, com limite de int antes do cast. Não há erro nem aviso apontado para NativePhoebe.inl no build final; permanecem avisos upstream conhecidos, incluindo World.h C4172/Map.h C4715.

Verificação final passou: **15 hashes de artefatos anteriores preservados**, três patches antigos intactos, FES no commit fixado/sem mudanças, OFF body idêntico, escopo de cinco arquivos, configuração Release preservada, patch completo com check reverso, seis botões anteriores mais checkbox, DLL/PDB CodeView GUID/age correspondentes e links/fences. Não executa jogo nem comprova ausência absoluta de efeitos internos de getters; bootstrap/behavior permanecem NOT_TESTED.

Verificação necessária: build sem erros; DLL/PDB correspondentes; hashes dos artefatos/patches antigos preservados; OFF spawn body idêntico; apenas cinco source files no escopo; propriedades de build preservadas; preflight sem chamadas que criem/controlem AI; patch completo aplicável; links/fences. O Codex não executa jogo. AI-0 a AI-7 continuam **NOT_TESTED**, não Failed nem Success.

## Para concluir a restauração

Ainda falta validar como a navegação Athena da build é criada/registrada/streamed e quem detém o bloqueio. Depois, validar parâmetros, tipos, defaults e ownership do entrypoint nativo SpawnAI/SpawnBot e como ele atravessa a interceptação do Reboot; identificar o dado genérico correto e seu vínculo com BT/skillsets/perception. Só então adaptar o mínimo native-only. Ativar RunBehaviorTree isoladamente não comprova esse contrato completo.
