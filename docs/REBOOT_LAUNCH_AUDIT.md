# Reboot — auditoria antes de execução

Todos os efeitos abaixo foram identificados por leitura das fontes fixadas no [lock](REBOOT_STACK_LOCK.md). Código existir/ser compilado não significa executado. Nenhum Launch, Shipping, FortniteLauncher, auth DLL, Reboot DLL, backend ou partida foi executado nesta etapa.

## Operações e gatilhos

Paths relativos a reboot/launcher/ salvo prefixo Reboot3. Linhas aproximadas do commit fixado.

| Operation | File / Function | Executed During Build? | Executed During Launch? | Purpose / classificação |
| --- | --- | --- | --- | --- |
| Compilar DLL | Reboot3 vcxproj / MSBuild Build | SIM, somente compiler/linker | Não | PROCESS/build; nenhum Pre/PostBuild Exec no projeto |
| Resolver packages / SDK | pubspec.yaml / flutter pub get, SDK bootstrap | SIM, dependências de desenvolvimento | Não | NETWORK para GitHub oficial/pub.dev/Flutter storage, sem jogo/serviço Epic |
| Copiar assets para bundle | gui/windows/CMakeLists.txt / install | SIM, incluindo lawinserver.exe e utilitários existentes no commit | Assets usados posteriormente | CONFIG/build; copiar um EXE não o executa |
| Criar settings e arquivos backend locais | gui/lib/main.dart / _startApp; BackendController constructor | Não | Ao abrir GUI, antes de Launch | CONFIG; DefaultInput.ini/config.ini são assets do launcher, não INI original Fortnite |
| Registrar protocolo Reboot | gui/lib/src/util/url_protocol.dart / registerUrlProtocol | Não | Ao abrir GUI | CONFIG; HKCU SOFTWARE/Classes/Reboot, não hosts/TLS |
| WebSocket de terceiros | gui/lib/src/controller/server_browser_controller.dart / constructor | Não | Ao abrir GUI | REMOTE_SERVICE: ws://192.99.216.42:8080, conexão automática |
| Auto-update check | gui/lib/src/util/updater.dart / checkLauncherUpdate | Não | Ao abrir GUI / pager._checkUpdates | REMOTE_SERVICE: raw GitHub master; versão não fixa |
| Download automático DLLs | gui/lib/src/pager/pager.dart ~125 / _checkUpdates → DllController.downloadAndGuardDependencies ~291 | Não | Ao abrir GUI, sem clicar Launch | REMOTE_SERVICE/RUNTIME_MOD/AUTH: defaults podem buscar nightly.link, GitHub master e fallback; não executado |
| Importar build existente | gui/lib/src/message/import_version.dart ~142 / _importVersion → patchHeadless ~165 | Não | Ao salvar importação, antes de Launch | CONFIG/modificação de EXE em disco; **BLOCKER para preservar original** |
| Patch helper | common/lib/src/game/game_metadata.dart ~152 / patchHeadless/_patch | Não | Import/download; patchMatchmaking definido sem caller encontrado | CONFIG; lê bytes e escreve Shipping se signature casar. Não chamado |
| Download Fortnite | common/lib/src/game/game_downloader.dart / startDownloadServer/downloadGame | Não | Somente downloader | REMOTE_SERVICE/PROCESS: builds.rebootfn.org, aria2/7zip/winrar; NÃO USAR |
| Desabilitar verificação de cert no downloader | game_downloader.dart ~224 / args aria2 | Não | Downloader | TLS: --check-certificate=false; não executado |
| Checar DLLs | gui/lib/src/button/game_start_button.dart ~98 / _toggle → _getDllFileOrStop ~798 | Não | Primeira fase Launch | CONFIG/REMOTE_SERVICE; pode baixar defaults/fallbacks. DLL custom evita substituição daquela DLL, não dos outros componentes |
| Iniciar backend | _toggle ~105 → BackendController.toggle → common/backend/auth_backend_helper.dart:startAuthBackend | Não | Antes dos processos do jogo | BACKEND_LOCAL: embedded Lawin; local/remote também suportados |
| Proxy opcional | auth_backend_helper.dart / _startRemote ~142 | Não | Backend remote ou local em outra porta | BACKEND_LOCAL/NETWORK: HTTP reverse proxy em 127.0.0.1:3551; não TLS MITM automático |
| Liberar portas encerrando processo | common/util/os.dart / killProcessByPort; freeAuthBackendPort | Não | Backend ocupado / antes de DLL host | PROCESS; pode atingir outro processo na porta. Não executado |
| Host implícito | game_start_button.dart ~176 / _startMatchMakingServer | Não | Após backend, antes de client | PROCESS; opcional diálogo de host local ou hosting explícito |
| Criar/suspender auxiliares | game_start_button.dart ~234 / _startGameProcesses → _createPausedProcess ~372 | Não | Antes de Shipping | PROCESS/ANTI_CHEAT: FortniteLauncher.exe e Shipping_EAC.exe; inicia e depois NtSuspendProcess; **BLOCKER** |
| Excluir Aftermath | game_start_button.dart ~267 / _createGameProcess | Não | Antes de criar Shipping | CONFIG: encontra/exclui GFSDK_Aftermath_Lib.x64.dll sob version.location; **BLOCKER para instalação intacta** |
| Args auth/provider | common/game/game_metadata.dart ~199 / createRebootArgs | Não | Antes de Shipping | AUTH/ANTI_CHEAT/app; AUTH_LOGIN/PASSWORD/TYPE, nobe/fromfl/fltoken/caldera. Não registrar valores nem produzir comando executável |
| Criar Shipping | game_start_button.dart ~311 / _createGameProcess → startProcess | Não | Depois de alterações/args acima | PROCESS: Shipping puro; OPENSSL_ia32cap env (configuração CPU OpenSSL, não prova de MITM) |
| Injetar auth | game_start_button.dart ~259 / _startGameProcesses → _injectOrShowError(GameDll.auth) | Não | Logo depois de Shipping | AUTH/RUNTIME_MOD: sinum.dll default, source interno não auditável aqui; **BLOCKER obrigatório no caminho** |
| LoadLibrary remoto | common/lib/src/util/os.dart ~286 / injectDll | Não | Usado para auth/console/gameServer | RUNTIME_MOD: OpenProcess/alloc/write/thread. Finalidade depende da DLL; não é automaticamente bypass |
| Injetar Reboot host | game_start_button.dart ~440 / _onLoggedIn → _injectOrShowError(gameServer) | Não | Após mensagem de login, ramo host | RUNTIME_MOD/GAMEPLAY: custom DLL compilada; sem auth/login callback não atinge essa etapa demonstradamente |
| Injetar console/memory | _onLoggedIn ~446 | Não | Client console; memory apenas Chapter1 | RUNTIME_MOD: 13.40 não é Chapter1; não executar |
| Ping/publicação/UPnP | _onGameServerInjected → _checkPublicGameServer ~550 | Não | Depois de host DLL e ping local | NETWORK/REMOTE_SERVICE: Ipify, UDP port forwarding no router, WebSocket browser; não chamar |
| DLL DllMain inicializa host | Reboot3 dllmain.cpp ~1854 / DllMain → Main ~906 | Não | Ao carregar DLL | RUNTIME_MOD: resolver, MinHook, GUI/thread, writes/hooks, dump de objetos, travel |
| Hooks sessão/validação | Reboot3 dllmain.cpp / NoMCPHook, DispatchRequestHook, KickPlayerHook, ApplyNullAndRetTrues | Não | Main, antes/depois de ChangeLevels | AUTH/NETWORK/UNKNOWN por função; não substituir recusas de autenticação por patches. Nenhum hook instalado |
| Apollo e listen | Reboot3 dllmain.cpp / ChangeLevels ~677; FortGameModeAthena::Athena_ReadyToStartMatchHook | Não | Depois de init runtime/travel | GAMEPLAY/NETWORK: mapa Apollo para engine425; NetDriver/listen e inicialização partida |

## O que não foi encontrado / não demonstrado

Busca em Dart/C++/batch/PowerShell e fontes JS encontrou downloader com certificate check desabilitado e fluxos de proxy, mas **nenhum instalador de CA, escrita de hosts, netsh firewall ou portproxy** no fluxo textual auditado. Isso não atesta o comportamento interno das DLLs de auth ou EXE backend pré-compilados. TLS/redirecionamento efetivo de sinum.dll é **UNKNOWN**, não chamar a DLL para descobrir.

AUTH_TYPE=epic no argv não prova autenticação real Epic. Os valores default são comunitários; o código aceita input e os imprime em logs. Nenhum input Epic/credencial/token/exchange code real usado. auth_backend inclui resposta com auth_method exchange_code; não prova consumo de exchange code oficial, não foi executado. Serviços Epic que o próprio Shipping tentaria contatar permanecem desconhecidos sem execução; não se fez chamada live para inferir.

GUI **não aberta**: inicialização conecta browser remoto, consulta master e baixa DLLs mesmo sem Launch. Não alteramos upstream para impedir isso e não criamos regra firewall/proxy para esconder os efeitos. Configuração foi preparada diretamente em storage local, sem chamar _importVersion/patchHeadless. O bloqueio de importação refere-se à operação que modificaria o EXE; compilação/auditoria independentes continuam permitidas.

Mapa completo do botão e ordem até Apollo: [COMPONENT_MAP](REBOOT_COMPONENT_MAP.md), [PRELAUNCH](REBOOT_PRELAUNCH.md), [RUNTIME_BLOCKER](REBOOT_RUNTIME_BLOCKER.md). Esta auditoria não autoriza execução futura dessas etapas.
