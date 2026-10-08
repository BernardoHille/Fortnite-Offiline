# Reboot — bloqueios do primeiro boot

**Relatório histórico dos limites da preparação sem execução.** Houve depois um teste manual bem-sucedido pelo usuário ([evidências](REBOOT_MANUAL_VALIDATION.md)). Os efeitos que motivaram os bloqueios não foram removidos do upstream e a execução totalmente offline ainda não foi validada. Procedimento atual: [COMO_RODAR_REBOOT](COMO_RODAR_REBOOT.md).

Os bloqueios são operações concretas do código fixado que conflitam com preservar a instalação e com não executar auth/anti-cheat/TLS nesta etapa. Eles não foram removidos ou contornados. Compilação/configuração é independente de boot utilizável.

| Bloqueio | Arquivo / função | Momento / antes → depois | Dependência / impacto |
| --- | --- | --- | --- |
| Importação modifica Shipping | gui/lib/src/message/import_version.dart:_importVersion ~165 → common/game_metadata.dart:patchHeadless | Save Import: encontra Shipping → patchHeadless → extractGameVersion/persist | Importação não é somente leitura. PARE antes da alteração; não usamos esse caminho. Configuração em JSON separado evita tocar o EXE. |
| Suspensão de EAC | gui/lib/src/button/game_start_button.dart:_startGameProcesses ~234 → _createPausedProcess ~372; common/util/os.dart:suspend | Backend pronto → inicia FortniteLauncher/EAC → suspende ambos → Shipping | Executado sem toggle alternativo nesse método; BLOCKER ao primeiro Launch sob as restrições. |
| Exclusão de arquivo original | _createGameProcess ~267 | Auxiliares → findFiles/delete GFSDK_Aftermath_Lib.x64.dll → Shipping | Pode excluir arquivos sob location mesmo no launch sem headless; BLOCKER de instalação original. Nenhuma exclusão foi feita. |
| Parâmetros auth/provider | common/game_metadata.dart:createRebootArgs ~199 | Preparar processo → argv auth/anti-cheat → Process.start | Argumentos comunitários e flags de provedor não são boot independente stock comprovado; não usar credenciais/contexto live. |
| Injeção auth obrigatória | _startGameProcesses ~259 → _injectOrShowError(GameDll.auth) | Shipping criado → sinum.dll default → esperar login | Fonte interna da DLL não é auditada pelo Dart. Declarada auth redirect; efeitos TLS internos UNKNOWN. Não carregar para descobrir nem substituir para contornar. |
| Host depende do callback login | _onLoggedIn ~440 → GameDll.gameServer | auth/network output → callback → Reboot DLL | A simples compilação de Reboot não prova que essa pré-condição ocorrerá no CL alvo. |
| GUI já tem rede/downloads | main:_startApp → ServerBrowserController; pager:_checkUpdates → downloadAndGuardDependencies | Antes de qualquer Launch | ws terceiros, GitHub master/nightly e download DLL automático. A GUI não foi aberta; não usar mirrors/default downloads para testar origem. |
| Runtime Reboot mistura runtime e alterações de sessão | dllmain.cpp:Main, NoMCPHook/DispatchRequestHook/KickPlayerHook/ApplyNullAndRetTrues | Load DLL → init/MinHook → hooks/patches e ChangeLevels | Não é R0 passivo; não se testou auth/session removal. Classificação por finalidade; o detalhe de cada alvo não é inferido como neutralização EAC só por ser patch. |

Paths relativos a reboot/launcher, salvo último row Reboot3. Código desses ramos permanece upstream. Correções de build documentadas não implementam bypass, não alteram AUTH/EAC/BE/Launch nem autorizam sua execução.

O que já foi preparado: fontes oficiais fixadas, SDK/dependências de compilação, DLL/GUI conforme seus relatórios, recognition read-only e storage com build existente. O que não foi provado: Shipping iniciado pelo stack, callback login, Reboot carregado, Apollo utilizável, portas/listen ou bots.

Próximo passo é revisão desta cadeia e decisão sobre um contexto de execução compatível com a fronteira definida. Não recomendar simplesmente remover auth/suspend/TLS checks para desbloquear. Se não houver caminho elegível, manter boot bloqueado; não apertar Launch e não integrar Season13Runtime automaticamente.
