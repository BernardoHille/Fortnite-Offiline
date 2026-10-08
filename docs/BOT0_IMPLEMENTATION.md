# BOT-0 — implementação isolada

**BOT0 READY:** implementação compilada Release x64 e pronta para teste manual. Alvo único: **Fortnite 13.40 / CL 14113327**. O teste do usuário confirmou que **Reboot detecta Engine_Version=426** nessa instalação; o guard inicial que exigia 425 foi corrigido. Baseline congelado em [BOT_BASELINE.md](BOT_BASELINE.md); leitura anterior à alteração em [DEBUG_MENU_MAP.md](DEBUG_MENU_MAP.md) e [BOT_RUNTIME_MAP.md](BOT_RUNTIME_MAP.md). Esta etapa prepara o spawn, não afirma que um bot já funcionou em runtime. O Codex não iniciou processos de jogo.

## Arquivos e funções

Paths relativos a `reboot/reboot3/Project Reboot 3.0/`:

| Arquivo | Alteração |
| --- | --- |
| Bot0.h (novo) | Interface RequestSpawn, Status, ProcessPending |
| Bot0.cpp (novo) | Pedido atômico, validações, uma chamada nativa, inspeção dos retornos, logs e diagnóstico SEH |
| gui.h | MainUI, aba Game: seção Bots, botão **Spawn 1 Bot**, texto de status; include Bot0.h |
| NetDriver.cpp | TickFlushHook chama Bot0::ProcessPending antes do corpo preexistente; retorno TickFlushOriginal preservado |
| Project Reboot 3.0.vcxproj | Registra Bot0.cpp/h; não altera propriedades de compilação/link/configuração |

O patch revisável fica em `reboot/patches/bot0-single-bot.patch`. É relativo ao baseline local ac95df9bc4a00e75ba414277d63bcca8e7fcabd1; não inclui novamente o ajuste Debug CRT preexistente. O checkout upstream é ignorado pelo Git principal, por isso o patch preserva também os dois arquivos novos.

## Caminho usado

```text
HOST / Game / Bots / Spawn 1 Bot
  → Bot0::RequestSpawn (GuiThread, apenas pedido)
  → Bot0::ProcessPending (TickFlushHook já instalado)
  → World Apollo_Terrain / Athena GameMode / Athena GameState
  → ServerBotManager existente / CachedBotMutator existente
  → AFortAthenaMutator_Bots::SpawnBot
  → Pawn retornado / Controller / PlayerState / posse observados
```

Reutiliza **o wrapper original** de `FortAthenaMutator_Bots.h`, via UFunction `/Script/FortniteGame.FortAthenaMutator_Bots.SpawnBot`. A assinatura e o preenchimento de params permanecem do Reboot. A alternativa Phoebe de `bots.h:PlayerBot::Initialize` já usa esse caminho e consulta Controller após receber Pawn em versões <17.

Argumentos: classe genérica `/Game/Athena/AI/Phoebe/BP_PlayerPawn_Athena_Phoebe.BP_PlayerPawn_Athena_Phoebe_C`, carregada pelo padrão LoadObject/BlueprintGeneratedClass já presente; locator = Pawn Athena de um cliente conectado; posição = localização desse Pawn + **3 m à direita e 1 m acima**; rotação = a do Pawn; `bSnapToGround=false`, igual ao call site Phoebe existente. Nenhuma coordenada absoluta do mapa, spawner adicional ou classe de boss.

## Pré-condições e isolamento

- Fortnite_Version 13.40 e **Engine_Version 426**, valor detectado pelo próprio Addresses::SetupVersion e registrado no teste manual. A documentação anterior rotulava o alvo como UE 4.25; esse rótulo não substitui o valor runtime do Reboot. Não alterar a detecção global ou os offsets do baseline. CL exato não tem guard confiável disponível nesse ramo; usar a build/hash congelados, não outra instalação.
- NetDriver e World registrados no object array e sem PendingKill; o driver deve ser o World.NetDriver. Ticks de outros drivers não consomem o pedido do mundo ativo.
- Host já listening, nome do mundo **Apollo_Terrain**, tipos FortGameModeAthena/FortGameStateAthena.
- GamePhase **SafeZones (4)**. Aircraft/Warmup/EndGame recusados. SafeZones não verifica fisicamente que o humano pousou: pousar em área plana e segura é pré-condição manual.
- ServerBotManager e CachedBotMutator válidos, dos tipos nativos corretos, CachedGameMode coincidente; CachedGameState coincidente quando a property existe. Não chamar SetupServerBotManager novamente ou criar substitutos.
- Pawn Athena válido associado a PlayerController de um cliente conectado. Não usar o Pawn do host como fallback nem criar um player start artificial.
- UFunction SpawnBot, getters de transform, ProcessEventOriginal, BlueprintGeneratedClass, StaticLoadObject e classe Phoebe válidos. Classe derivada de FortPlayerPawnAthena e transform finito.

Validações usam properties/offsets e getters já disponíveis no Reboot. Se property/objeto estiver ausente, recusar e logar. IsBadReadPtr e registro no object array são verificações pontuais; não garantem a vida útil de objetos nem a segurança interna do motor.

Pedido Idle → Queued → Running. Recusa **antes da chamada nativa** retorna a Idle, permitindo um novo clique quando a condição melhorar. Tick de beacon/driver secundário mantém o pedido na fila para o game driver. **Uma chamada real por sessão do host/DLL**; retorno nulo/incompleto também consome essa única tentativa. Cliques posteriores são recusados. Reiniciar o host normalmente é necessário para outro ensaio; nenhum spawn automático em reinício/mapa/tick.

Nenhum novo hook/thread de gameplay, tick AI, team, inventário, cosmetic, navegação ou registro manual. `ShouldUseAIBotController` continua com return false; `SpawnBotsAtPlayerStarts` continua com return imediato; AmountOfBotsToSpawn=0 e Bots::Tick comentado preservados. Não chama o wrapper PlayerBot.Initialize que altera contadores.

## Logs e avaliação

Categoria LogBots, logger existente com flush em info:

```text
[BOT] Spawn 1 Bot requested ui_thread=...
[BOT] consuming request tick_thread=...
[BOT] World: ... name=Apollo_Terrain
[BOT] version Fortnite_Version=13.4 Engine_Version=426 (expected 13.40 / 426)
[BOT] GameMode: ...
[BOT] GameState: ...
[BOT] BotManager: ...
[BOT] BotMutator: ...
[BOT] HumanPawn: ...
[BOT] PhoebePawnClass: ...
[BOT] counts before PlayersLeft=... AlivePlayers=... NumPlayers=... PlayerArray=...
[BOT] SpawnBot begin function=... locator=... location=(...) snap=false
[BOT] Pawn: ...
[BOT] Controller: ...
[BOT] PlayerState: ...
[BOT] counts after ...
[BOT] result pawn_valid=... ai_controller_valid=... possessed=... player_state_valid=...
[BOT] Spawn completed; verify entity/replication manually ...
```

Ou `[BOT][FAIL] Spawn refused: ... stage=...`, ou `reason=native return incomplete; PARTIAL`. Ausência de contagem refletida é -1. **PlayersLeft, AlivePlayers, NumPlayers e PlayerArray são somente lidos**; diferenças vêm do motor, sem simular registro.

`Spawn completed` significa Pawn/Controller/PlayerState/posse válidos no retorno imediato. Não comprova entidade visível, replicação, comportamento, estabilidade posterior ou BOT-0 SUCCESS. O cliente e os logs do usuário completam essa avaliação. Nenhum retorno incompleto gera Possess, spawn adicional ou cleanup destrutivo.

## Crash e limites

Filtro SEH local à ação registra exception code, endereço, módulo/RVA, RIP/RSP, última etapa e ponteiros World/GameMode/GameState/Manager. CaptureStackBackTrace registra endereços/módulos/RVAs da **pilha do filtro diagnóstico**, não um unwind simbolizado do contexto original. Não resolve símbolos nem acessa rede.

O filtro devolve EXCEPTION_CONTINUE_SEARCH: diagnostica, **não engole uma falha nativa nem retoma motor possivelmente corrompido**. Validações recusam contextos inválidos normalmente; ainda pode haver crash dentro da UFunction, asserts/fatal/abort, corrupção ou AI em tick posterior. Nesse caso o handler normal do jogo continua responsável pelo dump. Não há promessa de captura de todo crash; preservar log e dump/exception existentes sem adicionar patches de tentativa.

## Correção após primeiro teste manual BOT-0

O log do usuário de 2026-10-07 confirma o carregamento de bot0/Project Reboot 3.0.dll, World Apollo_Terrain e consumo do pedido em tick_thread=36704, separado de ui_thread=23948. Houve **14 pedidos**, todos recusados pelo guard de engine antes de GameMode/GameState/fase/manager/spawn; **zero SpawnBot begin**. O baseline e o BOT-0 registram Fortnite_Version=13.4 e Engine_Version=426. Logo essa execução não avalia a criação de bot nem demonstra falha do mutator.

Mudança única de comportamento nesta revisão: comparação Engine_Version **425 → 426**, sustentada por esse log e pela leitura de Addresses::SetupVersion. Adicionado log explícito dos dois valores. Não ampliar suporte, aceitar engines arbitrárias, remover o guard ou mudar qualquer outra pré-condição. O gate de SafeZones segue recusando a sala de espera e a fase Aircraft; pousar e aguardar SafeZones continua necessário.

Cópia da DLL/PDB do primeiro ensaio preservada em `reboot/artifacts/reboot3/bot0/revisions/guard425/`. Trechos técnicos sanitizados guardados em `reboot/audit/bot0-guard425-refusals.local.txt`. A DLL corrigida usa o mesmo caminho bot0 selecionado no launcher; exige novo host para carregar a revisão, sem substituir a DLL baseline. Hash atualizado em BOT0_TEST.md.

Posição relativa não faz raycast/navmesh/collision fix; escolher chão amplo evita iniciar o ensaio junto de parede/água/queda. Instanciar classe Phoebe não garante AI, cosmetic, inventário ou replicação. O guard exige infraestrutura que o setup do baseline tenta criar; a presença real será comprovada ou recusada no ensaio.

## Compilação e reprodução

Release x64, VS 2022/v143 **14.44.35207**, SDK **10.0.26100.0**, sem ABOVE_S20. OutDir/IntDir exclusivos. Resultado e hash final registrados em [BOT0_TEST.md](BOT0_TEST.md); log inicial privado `reboot/logs/reboot3-bot0-Release.log`, log da revisão `reboot/logs/reboot3-bot0-guard426-Release.log` e PDB ao lado da DLL nova.

Para recompilar este checkout local **sem sobrescrever Release**:

```powershell
Set-Location 'D:\Games\Fortnite-Local-C2S3'
$bot0MsBuild = 'C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe'
& $bot0MsBuild 'reboot/reboot3/Project Reboot 3.0.sln' /t:Build /m:2 `
  /p:Configuration=Release /p:Platform=x64 /p:PlatformToolset=v143 `
  /p:VCToolsVersion=14.44.35207 /p:WindowsTargetPlatformVersion=10.0.26100.0 `
  /p:CL_MPCount=2 `
  /p:OutDir='D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\bot0\' `
  /p:IntDir='D:\Games\Fortnite-Local-C2S3\reboot\artifacts\intermediate\reboot3\bot0\' `
  /v:minimal /nologo
```

Em checkout restaurado do Git principal: usar upstream fixado + `reboot3-build-compat.patch` como no restore; depois, dentro de reboot/reboot3, `git apply --check ../patches/bot0-single-bot.patch` e `git apply ../patches/bot0-single-bot.patch`, uma vez. Não aplicar de novo sobre o branch local já alterado. Ajustar só paths de saída caso a raiz seja outra. Não usar `scripts/build-reboot3.ps1` para esse ensaio: seus outputs padrão são o baseline e o script exige o HEAD upstream original.

## Rollback e milestones

Fechar host/cliente pelo procedimento normal e selecionar no Launcher **`D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\baseline\Project Reboot 3.0.dll`**. Reiniciar normalmente. Launcher, backend, configurações, DLLs auxiliares e Fortnite não precisam ser restaurados; não foram alterados. Source baseline está na tag local baseline/reboot-13.40-playable.

Somente documentados: BOT-0 = um bot existe; BOT-1 = replicação correta; BOT-2 = comportamento AI; BOT-3 = arma/inventário; BOT-4 = 10 bots; BOT-5 = 50+; BOT-6 = pregame/ônibus; BOT-7 = bosses Season 13. Apenas BOT-0 implementado.
