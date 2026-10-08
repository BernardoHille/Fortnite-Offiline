# Fase 2 — infraestrutura preparada, lobby real pendente

Revisão de arquitetura em 2026-10-07: **STACK B**, conforme [COMMUNITY_STACK_DECISION](COMMUNITY_STACK_DECISION.md) e [ARCHITECTURE_V2](ARCHITECTURE_V2.md). Há módulos comunitários de referência, mas nenhum boot completo elegível demonstrado. A migração é somente proposta e aguarda aprovação; nenhum novo componente foi executado. Não repetir busca de flags stock.

A auditoria somente leitura da [cadeia de lançamento](PHASE2_LAUNCH_CHAIN.md) adotou C: nenhuma entrada independente demonstrada sob as restrições. FortniteLauncher.exe abriu Epic Games Launcher segundo o usuário; essa abertura não será repetida. BE/EAC apontam para o mesmo Shipping; seleção oficial e comando histórico completo permanecem desconhecidos. Nenhuma implementação de lançamento foi feita.

O objetivo final continua sendo iniciar 13.40, comunicar-se somente com infraestrutura local, exibir Bernardo e permanecer no lobby com PLAY visível. **A Fase 2 não está concluída.** Os testes REST sem cliente passaram; uma captura manual confirmou execução do Shipping, mas os critérios de isolamento, roteamento e lobby não foram demonstrados. Ver [PHASE2_RUNTIME_OBSERVATION](PHASE2_RUNTIME_OBSERVATION.md).

A auditoria com as chaves fornecidas foi concluída sem cliente: configurações MCP reais foram encontradas, os índices dos 43 PAKs do jogo foram validados e houve somente extração seletiva local. Resultado **ROUTE C**, pois nenhum override externo suportado foi demonstrado na Shipping. Revisão em [PHASE2_ROUTING_REPORT.md](PHASE2_ROUTING_REPORT.md), [PHASE2_ROUTING_FEASIBILITY.md](PHASE2_ROUTING_FEASIBILITY.md) e [PHASE2_PAK_AUDIT.md](PHASE2_PAK_AUDIT.md). As chaves ficam em configs/aes-keys.local.json ignorado; não são credenciais de autenticação.

## Implementação

`backend/phase2/server.cjs` é um adaptador seletivo dos schemas LawinServer, com as dependências já fixadas da Fase 1. O entrypoint upstream da Fase 1 conserva seus guards e não teve seus routers liberados indiscriminadamente. `phase=2` seleciona o novo entrypoint através de `start-backend.ps1`; o modo 1 permanece separado.

As rotas exatas estão em `PHASE2_CLIENT_BOOT.md`. Não há router wildcard de MCP nem proxy. Apenas QueryProfile lê athena/common_core/common_public. O fixture local inclui default pickaxe/glider/emote, loadout vazio/default, season 13, nível inicial e valores zero, sem concessão de XP, currency ou Battle Pass. Esses campos são placeholders do schema, não implementação de progressão.

Identidade: accountId `local-player`, displayName `Bernardo`. Snapshots ficam somente em `runtime/phase2/profiles.json`, ignorado. Sessões locais opacas são transitórias em memória e expiram; não há reutilização de tokens reais. A chave de encerramento do coordenador fica em `runtime/phase2/coordinator.private.json`, também ignorado.

## Testes efetuados

- Saúde, sessão fictícia, verificação, identidade, três envelopes MCP e repetição da revisão sem mudança.
- Timeline Season13/LobbySeason13, versão exata, NO_UPDATE, status local e lista de hotfixes vazia.
- Presença REST local e bootstrap consolidado, sem URLs externas e sem afirmar lobby/PLAY reais.
- 401 para sessões inválidas, 404 para conta/profile não suportado, 403 para encerramento sem chave e 503 para matchmaking, comando de alteração de loadout e rota não implementada.
- Rejeição de exchange_code e demais fluxos não locais.
- Contador de tentativas externas do backend igual a zero; uma única escuta em 127.0.0.1; encerramento normal.
- Oito probes sintéticos de guard em processo separado bloqueados antes do acesso; usam example.invalid, sem hosts/credenciais Epic.
- Coordenador Prepare/Stop, inclusive retomada de estado persistido e comparação do PID com horário de criação. Gate de lançamento sem aprovação rejeitou a solicitação, sem executar qualquer cliente.

As primeiras execuções dos testes do coordenador revelaram dois erros: leitura do ExitCode de um objeto Process recém-obtido e comparação de um timestamp que ConvertFrom-Json desserializa como DateTime. Foram corrigidos mantendo o handle apropriado e comparando ticks UTC; os ciclos passaram após a correção.

## Logs e alcance da prova

`logs/phase2-backend.log`: JSONL com timestamp UTC, PID/component, host, método, rota segura, tipo de payload, status, resultado e código de erro. Não contém headers Authorization, corpos, valores da query, tokens ou senhas. Rotas desconhecidas são redigidas para evitar segredos em segmentos de URL. `logs/phase2-launcher.log` registra lifecycle/PIDs; `logs/phase2-client.log` contém marcadores de cliente não iniciado, não logs fictícios de execução.

Evidências adicionais: `phase2-smoke.json`, `phase2-guard-test.log`, auditoria estática do Shipping e relatório de isolamento. O guard cobre APIs auditadas do processo Node; não é sandbox completa, não cobre o Fortnite e não exclui escapes por código nativo, workers ou APIs não auditadas. Ausência de chamadas nas rotas testadas não comprova o comportamento de um cliente ainda não executado.

## Bloqueios restantes

A auditoria estática não será reaberta nesta etapa. A preparação de uma única observação offline está em [PHASE2_RUNTIME_PRELAUNCH](PHASE2_RUNTIME_PRELAUNCH.md). Na tentativa manual, Prepare recusou interfaces virtuais ativas antes de criar regras; o usuário realizou várias aberturas, incluindo Shipping diretamente. O [relatório da captura](PHASE2_RUNTIME_OBSERVATION.md) registra três PIDs Shipping, sem INIs/Saved ou eventos Network observados. O resultado runtime é inconclusivo; não comprova ausência de tráfego ou suporte a override. Nenhum novo experimento foi preparado. Windows Sandbox não foi usado nessa observação.

1. Roteamento nativo integral dos serviços do cliente para loopback ainda não demonstrado.
2. Compatibilidade dos envelopes, comandos mínimos e sessão local com o cliente real ainda não observada; XMPP/party podem exigir trabalho adicional.
3. Pré-requisitos normais de autenticação e anti-cheat do cliente ainda não testados. Nenhuma alteração ou bypass será usado para contorná-los.
4. Isolamento e renderização do cliente no ambiente alternativo ainda não validados.

O Windows 11 Pro possui WindowsSandbox.exe, hypervisor presente e feature CIM Containers-DisposableClientVM habilitada (InstallState 1). A consulta inicial via Get-WindowsOptionalFeature não estava disponível com o contexto atual; a consulta CIM somente leitura confirmou o estado. Não houve instalação ou ativação de componentes.

Foi preparada uma configuração Sandbox sem rede, ProtectedClient habilitado, build mapeada somente leitura e sem comando automático. Um teste separado de backend em guest, sem mapear o Fortnite, expirou após 100 segundos sem prova do guest. O helper foi encerrado; a configuração não foi tratada como comprovação de isolamento em runtime. A causa ainda não foi identificada e nenhuma configuração de segurança foi reduzida para tentar fazê-lo funcionar. Essa alternativa, se validada, trataria isolamento de rede, não transformaria endpoints Epic em locais. Ver [configuração Sandbox Microsoft](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-configure-using-wsb-file) e [estados CIM](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-optionalfeature).
