# Migração proposta — reutilização parcial STACK B

Data: 2026-10-07. Plano para revisão; **nenhuma migração de runtime executada e nenhum arquivo apagado**. Ver [decisão](COMMUNITY_STACK_DECISION.md) e [comparação](COMMUNITY_STACK_COMPARISON.md). A camada de compatibilidade do cliente continua sem implementação elegível.

## MANTER

| Arquivo / componente existente | Papel preservado |
| --- | --- |
| Build em `D:/Games/FortniteLocal/13.40-CL-14113327/13.40` | Instalação validada e íntegra; não copiar componentes comunitários para ela |
| `backend/phase2/server.cjs` | REST mínimo, identidade local, auth fictícia, timeline e envelopes MCP |
| `backend/phase2/profiles.cjs` e `runtime/phase2/profiles.json` | Schema e estado local athena/common_core/common_public; sem reset/grants/migração automática |
| `backend/offline-guard.cjs` | Proteção das APIs Node auditadas; não representa isolamento de Shipping |
| `backend/patches/` e `backend/vendor/LawinServer` | Proveniência, dependências e fontes GPL-3.0 já fixadas; vendor ignorado |
| `scripts/start-backend.ps1`, `scripts/start-phase2.ps1`, `scripts/phase2-common.ps1` e `launcher/README.md` | Lifecycle de backend/coordenador; gate de cliente continua fechado |
| `scripts/test-phase2-backend.ps1`, `scripts/test-phase2-guard.cjs`, `scripts/test-backend-isolation.cjs` | Baseline de verificação anterior; nenhuma repetição nesta etapa |
| `configs/stack.lock.json`, modelos de configuração e configuração privada existente | Commits fixados e valores locais; não promover auditoria de candidatos a dependências instaladas |
| `gameserver/vendor/FortExternalServer` | Checkout season-13 `e42ecddbce59163c6a60ab7506766c2a0adfe580`, sem clone/substituição |
| `gameserver/vendor/FortExternalServer/Binaries/Win64/FortExternalServer.exe` | Release x64 já compilado; preservar, sem execução |
| `scripts/build-gameserver.ps1`, `scripts/verify-build.ps1`, `scripts/check-environment.ps1`, `scripts/restore-stack.ps1` | Verificação/restauração/compilação existentes; não acionadas para migrar agora |
| `configs/aes-keys.local.json`, scripts de PAK/roteamento e resultados privados | Apenas auditoria, sem uso como auth nem divulgação de chaves/assets |
| `docs/`, `logs/` e `runtime/phase2/launch-chain-audit` | Histórico de evidência e limites, inclusive ROUTE C e captura inconclusiva |
| `progression/` | Reserva de fase futura; não criar XP/quests agora |

## SUBSTITUIR

| Premissa / peça | Substituição proposta | Estado |
| --- | --- | --- |
| Arquitetura orientada a descobrir override/flags no stock | Arquitetura por contratos locais e referências comunitárias, com boot explicitamente bloqueado | Desenho em ARCHITECTURE_V2; nenhuma alteração no cliente |
| Expectativa de “FortExternalServer EXE = host independente” | FES como controlador acoplado ao Shipping e referência técnica preservada | Documentado; runtime não selecionado |
| Presença REST tratada como XMPP/party | Contrato específico de mensagens/transporte, guiado por fontes Velocity | Futuro, NÃO TESTADO; endpoint existente não substituído |
| Ausência de especificação de sessão / resposta 503 de matchmaking | Especificação posterior de DTO/ticket/sessão e estado de readiness | Futuro; manter 503 até implementação autorizada e adequada |
| Schemas mínimos insuficientes para necessidades futuras | Avaliação seletiva de envelopes/estado Velocity, preservando identidade e revisões atuais | Futuro; nenhuma troca de snapshots ou entrypoint |

Não substituir integralmente Lawin adaptado por Anora, Velocity ou backend embarcado Reboot. Anora cobre mais funções no código, mas não comprovou vantagem operacional no CL/localidade e acrescenta conexão Discord/proveniência pendente. A escolha poderá ser revista com nova evidência; esta proposta contém uma única base principal.

## DESCARTAR

“Descartar” significa **não integrar ao caminho executável**; os arquivos de auditoria continuam guardados.

| Código / mecanismo excluído | Motivo |
| --- | --- |
| Reboot Launcher: startup/suspensão de auxiliares, injeção de auth/host | Incompatível com as restrições; metadados de versão continuam como evidência |
| Velocity: launcher, libcurl/TLS, setup de hosts/CA/portproxy, stub e bloqueio de anti-cheat | Boot/redirecionamento incompatíveis; não transplantar parcialmente para viabilizar Shipping |
| Velocity: `structs/gameserver.js`, controller de host e autostart chamado pelo matchmaker | Injeta DLL no caminho 13.40; não é adaptador FES |
| Receitas Fiddler/SSL redirect de Lawin | Interceptação/TLS excluídos pelo pedido |
| ggsplayz S13 Hybrid e fluxo de suspensão/substituição de DLL | Epic live e mecanismos proibidos |
| Era histórico launcher/injeção/redirecionamento; serviço Era atual não verificável como stack aberta local | Não demonstrado candidato elegível/autossuficiente para C2S3 |
| Uso runtime FES/Reboot como desbloqueio do cliente | Dependência de processo/memória/hooks, sem demonstração de bootstrap permitido |
| Migração integral para Anora e seu startup Discord | Nova dependência remota; licença/proveniência e CL sem resolução |

Preservar `OBSERVACAO-RUNTIME.bat` e scripts de preparação/cleanup como histórico operacional. Eles **não são o próximo passo** desta arquitetura e não devem ser usados para repetir lançamento stock ou iniciar a stack comunitária. Não remover automaticamente regras/configurações, processos ou arquivos antigos nesta etapa.

## ADICIONAR

| Item | Origem / finalidade | Estado |
| --- | --- | --- |
| Os quatro documentos desta revisão | Comparação, decisão, migração e arquitetura | Adicionados nesta etapa |
| Evidências textuais e metadados em `runtime/phase2/community-stack-audit` | Pequena seleção de fontes públicas fixadas, hashes e árvore de arquivos | Auditoria privada ignorada; não pacote de runtime |
| Contrato `CommunityProtocol13` | Futuro documento sobre MCP, identidade, XMPP/party, sessão e proveniência Velocity | Proposto, ainda não criado |
| Módulos locais seletivos de protocolo | Apenas após especificação/aprovação; sem entrypoints/redirecionamento/host autostart upstream | NOVO, NÃO TESTADO, não implementado |
| Interface de host/readiness independente do backend | Exigirá provedor executável elegível e sem mecanismos proibidos; nenhum escolhido | NOVO, bloqueado, não implementado |
| Contrato de resultados/progressão | Fase própria futura; eventos autoritativos, revisões e persistência | Reservado, não implementado; não avançar agora |

## Ordem e condições da migração

1. Entregar estes documentos e aguardar aprovação. Estado atual: **parada de revisão**.
2. Se aprovado, especificar estaticamente `CommunityProtocol13` e manifesto por arquivo/licença/dependência. Não importar upstream nessa primeira etapa.
3. Qualquer implementação posterior exige escopo autorizado e revisão do fechamento de dependências: sem side effects, spawn/attach, auth bypass, TLS/hosts/certificados, URLs que exigem interceptação ou serviços remotos. Isso é um critério técnico de seleção, não autorização para remover mecanismos do launcher.
4. Antes de cliente real, demonstrar boot/roteamento permitido. A ausência dessa prova mantém o gate fechado, mesmo com módulos de backend disponíveis.
5. Gameserver, Apollo, bots/bosses e progressão só podem ter implementação/testes nas fases autorizadas correspondentes e com provedor compatível. Nenhuma fase foi avançada aqui.

Compatibilidade de profiles será validada por contratos e preservação de revisões/saves antes de qualquer migração futura. Não há plano de instalar componentes incompatíveis e ajustá-los enquanto executam. Como nada foi migrado, não há rollback de runtime a executar.
