# Auditoria do boot — Fortnite 13.40 / CL 14113327

## Evidência e grau de certeza

Auditoria somente leitura do Shipping, dos PAKs/configurações locais e de projetos externos nos commits registrados. Nenhum PE da build foi carregado como código, nenhum arquivo original foi alterado e nenhum cliente foi iniciado. A sequência abaixo é uma hipótese de bootstrap baseada nos schemas upstream, não um trace real do Fortnite. A ordem exata e a obrigatoriedade de cada chamada ainda não foram observadas.

Resultado atual de roteamento: **ROUTE C — NATIVE ROUTING NOT FOUND**. Configurações MCP foram encontradas nos PAKs, mas sua existência não demonstrou um override externo utilizável nesta Shipping. Evidências detalhadas em [ROUTING_REPORT](PHASE2_ROUTING_REPORT.md), [ROUTING_FEASIBILITY](PHASE2_ROUTING_FEASIBILITY.md) e [PAK_AUDIT](PHASE2_PAK_AUDIT.md).

| Classificação solicitada | Evidência | Limite |
| --- | --- | --- |
| CONFIRMADO PELA BUILD | Identificação 13.40/CL14113327; referências de auth, MCP, URLs e configuração no Shipping; literal ini: | Referências não provam parser ativo, prioridade ou argumentos válidos |
| CONFIRMADO PELO BACKEND | Health, sessão local, três perfis, timeline/config e bootstrap sintético testados | Não prova autenticação do cliente ou lobby renderizado |
| CONFIRMADO PELO PAK | 43 índices cifrados listados; configs BaseEngine/DefaultEngine; Protocol/Domain/McpClientCommandUrl; perfil Localhost de GameServiceMcp | Localhost declara HTTP nesse serviço, sem Domain loopback ou modo offline global |
| CONFIRMADO POR PROJETO EXTERNO | Lawin recomenda redirecionador; FortExternal/Reboot usam controle de processo; ggsplayz S13 e Velocity usam mecanismos fora das restrições | Evidência de implementação desses projetos, não de suporte nativo nesta build |
| INFERÊNCIA | Hierarquia base/default/plataforma e Saved candidata; composição de URL por serviço | Não tratada como hierarquia efetiva observada do Fortnite |
| NÃO CONHECIDO | Aceitação de override MCP externo; seleção McpConfig; todos os destinos; HTTP local integral; auth/XMPP obrigatórios; ordem e estabilidade do lobby | Nenhum experimento de override ou cliente foi iniciado |

`logs/phase2-client-static-audit.json` contém offsets das referências ASCII/UTF-16 encontradas: `AUTH_LOGIN=`, `AUTH_PASSWORD=`, `AUTH_TYPE=`, `epicapp=`, `epicportal`, `OnlineSubsystemMcp`, `McpConfig`, `BaseUrl`, `QueryProfile`, `ClientQuestLogin`, `SetCosmeticLockerSlot`, `NO_UPDATE` e referência a fortnite-public-service. A busca restrita não encontrou vários nomes completos de endpoints; ausência de uma string não prova ausência da função. Nenhum segredo embutido ou payload proprietário foi exportado.

Uma leitura restrita de identificadores de configuração também encontrou `OnlineSubsystemMcp.AccountServiceMcp`, `OnlineSubsystemMcp.BaseServiceMcp`, `ClientBaseUrl`, `OnlineSubsystemMcp.OnlineAccessMcp`, `QueryServiceStatusUrl`, `OnlineSubsystemMcp.OnlineDiscoveryMcp`, `QueryEndpointsUrl`, `OnlineSubsystemMcp.XMPP`, `Domain`, `OnlineSubsystemMcp.McpProfile`, `McpClientCommandUrl` e `ClientUrlContext`. Isso sugere uma investigação de configuração nativa por serviço; não comprova que a build Shipping aceite substituí-los por linha de comando nem que todas as chamadas sejam cobertas.

## Fluxo candidato versus fluxo testado

```text
CLIENT real — não executado
  -> seleção de ambiente/serviços e preflight (ordem desconhecida)
  -> sessão local em /account/api/oauth/token, se roteamento nativo funcionar
  -> /account/api/oauth/verify e /account/api/public/account/local-player
  -> /fortnite/api/game/v2/profile/local-player/client/QueryProfile
       athena / common_core / common_public
  -> timeline + configuração + possíveis serviços adicionais
  -> lobby real + nome + PLAY — NÃO VALIDADOS

Smoke PowerShell — executado sem cliente
  -> /health
  -> sessão fictícia local e identidade
  -> QueryProfile + consulta da mesma revisão
  -> timeline / version / status / cloudstorage vazio / configuração local
  -> presença REST e /local/phase2/lobby-bootstrap
  -> respostas simuladas validadas -> encerramento normal
```

Os endpoints `/local/phase2/*` são instrumentos do coordenador/teste. O Fortnite não foi demonstrado solicitando esses endpoints. Passar no bootstrap REST não comprova carregamento do lobby, nome renderizado ou botão PLAY.

## Rotas habilitadas, estritamente

| Método e rota | Finalidade | Autorização / limite |
| --- | --- | --- |
| GET /health | Saúde da infraestrutura | Loopback e Host exato |
| POST /__local/shutdown | Encerramento do coordenador | Chave local de controle |
| POST /account/api/oauth/token | Sessão própria do backend local | Apenas par fictício local-player/local-only-not-epic e grant password; rejeita Authorization, exchange_code e demais campos |
| GET /account/api/oauth/verify | Verificar sessão local | Bearer opaco local válido |
| GET /account/api/public/account/:accountId | Identidade local | Bearer + somente local-player |
| GET /account/api/public/account?accountId=local-player | Forma em lista da mesma identidade | Bearer + uma conta local |
| POST /fortnite/api/game/v2/profile/:accountId/client/QueryProfile | Snapshot MCP somente leitura | Bearer + conta local + um dos três profiles; corpo vazio; limite 4 KiB |
| GET /fortnite/api/version | Metadados locais 13.40 / 14113327 | Loopback |
| GET /fortnite/api/v2/versioncheck | NO_UPDATE fictício local | Exatamente esse caminho, sem wildcard |
| GET /lightswitch/api/service/bulk/status | Status local do serviço | Sem URLs de manutenção/CDN |
| GET /fortnite/api/calendar/v1/timeline | Season13 / LobbySeason13, calendário local | Bearer; sem storefronts ou recompensas |
| GET /fortnite/api/cloudstorage/system | Lista vazia de hotfixes | Bearer; não envia INIs de segurança |
| GET /local/phase2/config | Diagnóstico da configuração | Bearer; sem caminhos pessoais |
| GET /local/phase2/presence | Presença local REST fictícia | Bearer; friends vazio; não é XMPP |
| GET /local/phase2/lobby-bootstrap | Consolidação dos snapshots para teste | Bearer; declara explicitamente lobby real não verificado |
| GET /local/phase2/network-report | Contadores do guard | Bearer; declara ausência de cobertura do cliente |

Qualquer outra rota/comando retorna 503 com código controlado e registro sem payloads/credenciais. Não há fallback ou encaminhamento externo. Outros perfis/contas retornam 404; sessão inválida retorna 401; encerramento sem chave retorna 403.

## O que foi excluído

Não foram carregados os routers genéricos upstream: o MCP genérico aceita comandos arbitrários como atualização completa e pode escrever perfis; outros módulos incluem loja, compras, currency elevada, URLs CDN, profiles modernos e autenticação permissiva. O adaptador seletivo usa Express instalado no checkout LawinServer e os envelopes/schemas auditados do projeto; não presume que todos os templates multiversão sirvam à 13.40.

XMPP/party, friends oficiais, EULA, conteúdo remoto, EOS `/auth/v1/*`, SDK, discovery de endpoints, telemetria e matchmaking não foram implementados sem evidência de necessidade. `ClientQuestLogin` aparece no Shipping, mas não está habilitado: presença de uma referência não prova que seja obrigatório para o lobby. Não existem XP, quests, Battle Pass, loja, compras, cloud save, rewards, bots ou partida.

## Argumentos e conexão

Os argumentos encontrados são apenas referências estáticas. `AUTH_*` seleciona material de autenticação, não determina sozinho o destino HTTP. `epicapp`/`epicportal` não comprova localhost. Os argumentos upstream com ambiente Prod não foram usados.

A documentação [Unreal 4.27 de argumentos](https://dev.epicgames.com/documentation/en-us/unreal-engine/command-line-arguments?application_version=4.27) e a [documentação de configuração](https://dev.epicgames.com/documentation/unreal-engine/configuration-files-in-unreal-engine) descrevem mecanismos de INI/linha de comando do engine. Essa documentação genérica, sobretudo a atual, não é prova de suporte pelo Fortnite Shipping 13.40. Não foi criado um pacote de overrides especulativos, não foram alterados TLS/certificados, e não se usaram flags para desabilitar anti-cheat, autenticação ou segurança.

Não há comando de execução aprovado ou argumentos finais definidos. Primeiro é necessário comprovar um mecanismo nativo de endpoints locais e um isolamento independente do processo cliente; se houver requisito de bypass ou alteração de segurança, a abordagem deve ser abandonada. O serviço local usa somente credenciais fictícias próprias e não aceita Basic oficial, senha Epic, refresh token ou exchange code. Sua compatibilidade com a autenticação do cliente real permanece desconhecida.
