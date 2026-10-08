# Menu dev do host — mapa antes da alteração BOT-0

Fonte primária: Project Reboot 3.0 upstream 10c659028ad9d6816f78226483f11a884bf81f57, com ajuste de build preexistente congelado. Paths abaixo relativos a `reboot/reboot3/Project Reboot 3.0/`; linhas aproximadas do baseline.

**UI:** Dear ImGui vendorizado, backend Win32 + Direct3D 9. Não é a GUI Flutter do Reboot Launcher. `dllmain.cpp:Main` ~979 inicia `GuiThread` com CreateThread; `gui.h:GuiThread` ~1563 cria a janela RebootClass/Project Reboot, device D3D9, contexto ImGui e loop de mensagens/renderização. Depois de bInitializedPlaylist usa MainUI; antes usa PregameUI.

| UI label | Arquivo / função | Callback / efeito | Dependências |
| --- | --- | --- | --- |
| Game | gui.h:MainTabs ~367; MainUI ~710 | Define Tab=GAME_TAB, PlayerTab=-1; MainUI renderiza conteúdo | Playlist inicializada; GuiThread |
| Calendar Events / Zone / Dump / Fun | gui.h:MainTabs ~404–428 | Seleciona tabs/flags existentes | Não alteradas |
| Enable Developer Mode | gui.h:StaticUI ~332 | ImGui::Checkbox escreve Globals::bDeveloperMode | Não é pré-condição do futuro botão Bots |
| Infinite Ammo / Materials | gui.h:StaticUI ~347 | Checkbox flags existentes | Não alteradas |
| Private IPs are operator / No MCP | gui.h:StaticUI ~351–353 | Checkbox flags existentes | Preservadas como no baseline |
| Lategame | gui.h:MainUI ~727 | Checkbox → SetIsLategame | Não alterar lifecycle |
| Players required to start the match | gui.h:MainUI ~736 / PregameUI ~1530 | Slider existente WarmupRequiredPlayerCount | Não alterar/duplicar |
| Execute console command | gui.h:MainUI ~743 | UKismetSystemLibrary.ExecuteConsoleCommand(GetWorld(),...) | Chamado diretamente da UI no baseline |
| Start Bus | gui.h:MainUI ~826 | bStartedBus=true; GetWorld→GameMode/GameState; StartAircraftPhase, ou LateGameThread no ramo lategame | Fortnite>=11 no ramo normal; callback roda na GuiThread |
| Start Bus Countdown | gui.h:MainUI ~847 | Modifica countdown no ramo antigo | Não usado como novo caminho BOT-0 |
| Bots / Spawn 1 Bot (proposto) | gui.h:MainUI/Game; Bot0 namespace | **Somente enfileirar pedido**, sem World/ProcessEvent/spawn na UI | Consumo no TickFlushHook já instalado |

## Contexto e acesso ao mundo

Os callbacks ImGui são síncronos no loop da **GuiThread**, distinta da thread de tick do servidor. O baseline chama GetWorld/ProcessEvent diretamente em alguns botões; isso não demonstra que spawn AI seja seguro nesse mesmo contexto. Não copiar esse risco para BOT-0 nem mudar os botões antigos.

Ponto de consumo existente: `NetDriver.cpp:UNetDriver::TickFlushHook` ~43, instalado pelo baseline em `dllmain.cpp:Main` ~1739. Ele já manipula mundo/atores e executa replicação. Nova ação pode consumir **somente pedido explícito**, no NetDriver do mundo atual; sem instalar novo hook ou alterar o retorno TickFlushOriginal.

`NetDriver.h:GetNetDriverWorld` ~156 usa property World; `World.h:GetGameMode/GetGameState/GetNetDriver` usam AuthorityGameMode/GameState/NetDriver. BOT-0 validará offsets/pointers/tipos por reflexão, mapa Apollo_Terrain e fase de Athena; não dependerá de callback UI que esteja no Frontend. IDs de thread UI/tick deverão constar no log do teste; afinidade em runtime ainda não foi medida por esta implementação.

Este documento preserva o mapeamento feito antes da edição. Implementação concluída: [BOT0_IMPLEMENTATION.md](BOT0_IMPLEMENTATION.md); teste manual: [BOT0_TEST.md](BOT0_TEST.md). O botão agora está em MainUI/Game, gui.h ~727–731; o callback chama somente Bot0::RequestSpawn, e o consumo foi adicionado ao início do TickFlushHook.
