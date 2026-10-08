# Reboot prelaunch — execução bloqueada nesta preparação

**Histórico da etapa de preparação sem execução.** Depois deste relatório o usuário realizou o teste manual descrito em [MANUAL_VALIDATION](REBOOT_MANUAL_VALIDATION.md). Use [COMO_RODAR_REBOOT](COMO_RODAR_REBOOT.md) para a configuração/ordem atual. As operações upstream identificadas abaixo continuam presentes.

Nenhum Launch/Shipping/DLL/backend executado. GUI também não aberta devido a efeitos automáticos. Leitura das fontes não é autorização de boot. [Cadeia completa](REBOOT_COMPONENT_MAP.md), [auditoria](REBOOT_LAUNCH_AUDIT.md), [bloqueios](REBOOT_RUNTIME_BLOCKER.md).

| Pergunta | Resposta com base no código fixado |
| --- | --- |
| 1. Qual EXE iniciamos? | EXE GUI gerado: reboot_launcher.exe, bundle Windows Release. **Não iniciado nesta etapa**. Não iniciar FortniteLauncher.exe para esse experimento. |
| 2. Qual processo ele cria? | Ao abrir: GUI já conecta browser/downloads; ao Launch: backend Lawin quando embedded, FortniteLauncher e Shipping_EAC, Shipping puro; pode duplicar fluxo para linked host. |
| 3. Quando Shipping inicia? | Depois de DLL checks, backend, auxiliares iniciados/suspensos e tentativa de excluir Aftermath; _createGameProcess via Process.start. |
| 4. Qual DLL Reboot entra? | Host usa GameDll.gameServer; configuração custom aponta Project Reboot 3.0.dll compilada em Release. Client usa console.dll; auth default sinum.dll entra antes de ambos. |
| 5. Quem inicia backend? | LaunchButton._toggle → BackendController.toggle → startAuthBackend; embedded executa lawinserver.exe do bundle, não backend/ do nosso projeto. Local/remote oferecem outros ramos. |
| 6. Quem inicia host? | Botão hosting ou prompt de linked hosting → _startGameProcesses(host=true). Callback de login injeta gameServer. DllMain → Main inicia runtime host e travel. |
| 7. Quais portas? | REST3551, WS80 no Lawin fonte; game7777/beacon7776 na primeira listen UE425; browser remoto8080; downloaderRPC6800 somente se usado. Nenhuma porta iniciada por nós. |
| 8. Argumentos normais? | Seleção app/environment: epicapp Fortnite, epicenv Prod, epiclocale en-us, epicportal. UE/game: log opcional; host nosplash/nosound e nullrhi se headless. Não tratar AUTH/provider como argumentos normais UE; nomes separados abaixo. |
| 9. Etapas que modificam runtime? | injectDll(auth/console/gameServer), DllMain/Main, MinHook/patches, ChangeLevels e Athena game initialization. Import GUI também escreve Shipping em disco, diferente de mod runtime. |
| 10. Autenticação? | createRebootArgs usa AUTH_LOGIN/PASSWORD/TYPE; default comunitário, aceita input e loga args. Auth DLL obrigatória logo após Shipping; backend simula endpoints. Não usar conta, tokens/exchange real ou live services. |
| 11. Anti-cheat? | _createPausedProcess inicia/suspende Shipping_EAC; args nobe/fromfl/fltoken/caldera. Nenhuma suspensão/manipulação executada. Não fornecer valores auth/provider como comando pronto. |
| 12. Rede/TLS? | Backend HTTP/proxy e WS; browser remoto; updater/downloads; Ipify e router UDP forwarding. Downloader usa certificate-check=false. Instalação de CA/hosts/firewall/portproxy não encontrada no source textual; efeito TLS da auth DLL UNKNOWN. |
| 13. Serviços remotos? | GitHub/raw (updates/default DLLs), nightly.link (DLL Reboot), IP browser192.99.216.42:8080, Ipify, builds.rebootfn.org só downloader. Serviços Epic tentados pelo Shipping são UNKNOWN sem execução, não consultados. Builds/tooling só acessaram fontes oficiais/registries declarados, não esse fluxo launch. |
| 14. Ordem até Apollo? | GUI/config → DLL checks → backend → host opcional → wrappers suspensos → tentativa de excluir Aftermath → Shipping+auth/provider → sinum → mensagem login → Reboot host DLL → DllMain/Main/resolvers/hooks → ChangeLevels(engine425, não Creative: Apollo_Terrain) → Athena_ReadyToStartMatchHook/listen/setup. Todos os ramos são NÃO TESTADOS EM RUNTIME. |

Configuração da build existente foi preparada no storage local do launcher, fora da instalação, sem Import GUI. JSON, seleção da versão e caminho da DLL Release foram validados sem abrir a GUI. A flag custom_game_server seleciona nosso **Project Reboot3** compilado, não Season13Runtime. Não significa que seja seguro apertar Launch: auth/anti-cheat/alteração de disco continuam no caminho. GUI não tem modo audit offline demonstrado que evite todos os downloads/conexões sem mudança de código; não executar automaticamente.

Não há plano de RUN real habilitado neste relatório. Enquanto os bloqueios de fronteira permanecerem, READY A não se aplica. Nenhum ajuste de rede/TLS/EAC/BE foi realizado para tornar o stack elegível.
