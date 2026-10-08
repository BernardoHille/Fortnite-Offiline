# PHASE 2 - PRE-LAUNCH REPORT — 2026-10-07

**Decisão atual: cliente NÃO liberado para execução.** Backend simulado passou, mas não existe ainda um caminho comprovado de roteamento/isolamento do Fortnite que satisfaça todas as restrições. Autorizar a primeira execução não remove esse bloqueio técnico. A Fase 2 permanece em andamento; não se afirma lobby funcional ou botão PLAY.

Auditoria posterior com AES/PAKs concluída em [PHASE2_ROUTING_REPORT.md](PHASE2_ROUTING_REPORT.md): ROUTE C. Foram encontradas configurações MCP reais, mas não um override externo demonstrado nesta Shipping. A leitura seletiva não executou o cliente nem alterou os originais; os detalhes estão em [PHASE2_PAK_AUDIT.md](PHASE2_PAK_AUDIT.md).

## 1. Rotas implementadas

Allowlist de 16 combinações método/caminho, descrita integralmente em `PHASE2_CLIENT_BOOT.md`: saúde/encerramento; sessão sintética e verificação; duas formas de identidade; somente QueryProfile; versão/versioncheck/status; timeline e listagem vazia de hotfixes; quatro endpoints locais de configuração, presença, bootstrap e relatório de rede. Contas/perfis/comandos fora da allowlist falham de forma controlada. XMPP, loja e matchmaking não estão habilitados.

## 2. Arquivos alterados/criados

| Área | Arquivos |
| --- | --- |
| Backend | `backend/offline-guard.cjs`, `backend/phase2/server.cjs`, `backend/phase2/profiles.cjs` |
| Configuração e Git | `.gitignore`, `configs/local.example.json`; configuração pessoal e readiness somente em arquivos ignorados |
| Diagnóstico/coordenação | `scripts/start-backend.ps1`, `scripts/phase2-common.ps1`, `scripts/start-phase2.ps1`, `scripts/test-phase2-backend.ps1`, `scripts/test-phase2-guard.cjs`, `scripts/audit-client-boot.cjs` |
| Alternativa de isolamento | `scripts/prepare-phase2-isolation.ps1`, `scripts/test-phase2-sandbox.ps1`, `scripts/phase2-sandbox-backend-test.ps1`; WSBs com caminhos reais ficam ignorados |
| Documentação | `README.md`, `backend/README.md`, `launcher/README.md`, `docs/ARCHITECTURE.md`, `docs/SETUP.md`, `docs/DEPENDENCIES.md`, `docs/ROADMAP.md`, `docs/USER_ACTIONS.md`, `docs/PHASE2.md`, `docs/PHASE2_CLIENT_BOOT.md`, este relatório |

Os dois commits upstream permanecem fixados. Não foram modificados gameserver, MapToLoad, binários/assets da build ou controles de segurança do Windows.

## 3. Como o cliente seria iniciado

Nenhum cliente é iniciado pelos scripts disponíveis. `start-phase2.ps1 -Mode Prepare` valida configuração, prepara somente o backend, verifica saúde e escuta, registra PID/start time e estado privado. `-Mode Stop` fecha esse processo local, conferindo sua identidade. `-Mode Launch` recusa falta de aprovação e permanece bloqueado tecnicamente mesmo com o switch Approved.

Alternativa em avaliação: backend e cliente dentro de um único guest sem interface externa, com comunicação via loopback do guest e mapeamento somente leitura da build. O modelo WSB para cliente não contém LogonCommand, nem instala certificados ou modifica hosts. Antes de definir uma execução é preciso validar roteamento nativo, runtime/GPU e pré-requisitos normais do jogo. O teste WSB separado contém somente um comando de backend; não mapeia, copia ou executa o Fortnite.

## 4. Argumentos

**Não há comando/argumentos finais autorizados para Fortnite.** AUTH_LOGIN/AUTH_PASSWORD/AUTH_TYPE, epicapp/epicportal e McpConfig são referências auditadas, não uma receita validada. Não serão usados parâmetros para desabilitar EAC/BattleEye, SSL/TLS, autenticação ou mecanismos de segurança. Não se presume que `-backendHost` exista; não foi inventado um switch de localhost.

O único processo iniciado pelo coordenador no host é Node com preload do guard e o entrypoint do adaptador local. Os únicos dados de login dos testes são uma identidade local e par fictício fixo; tokens opacos locais ficam em memória e não são registrados.

## 5. Conexões esperadas

Nos testes do host: coordenador/smoke -> HTTP 127.0.0.1:3551 -> backend; nenhuma conexão de saída solicitada pelo backend; nenhum listener XMPP ou gameserver. Os probes negativos são separados e bloqueados antes de DNS/TCP/UDP/fetch/processos filhos.

Em um futuro guest válido: backend e cliente usariam exclusivamente loopback dentro desse guest, sem NIC externa. O localhost do host não é automaticamente o localhost do guest. O backend deve rodar dentro do guest; expor apenas um servidor no host não resolve essa arquitetura.

## 6. Como serviços live são excluídos

As rotas implementadas não fazem proxy/fetch/DNS externo; não importam os routers genéricos upstream; retornam dados locais sem imagens/URLs Epic/CDN; bloqueiam qualquer caminho não implementado. O processo escuta somente em loopback e o guard permanece ativo. Logs omitem credenciais/payloads. Isso prova somente os componentes/rotas auditados e exercitados.

O guard Node não protege o binário Fortnite. Portanto, iniciar diretamente no host seria inadequado enquanto não houver isolamento independente verificado. O WSB usa Networking Disable e mapeamento de build somente leitura conforme mecanismo Microsoft, sem alterar rede de outros programas. Seu efeito sobre o cliente e a compatibilidade de GPU/anti-cheat ainda não são uma prova de execução do Fortnite.

## 7. Riscos, limitações e estado

- Smoke backend: passou; perfis persistem somente em runtime, session local e controle de encerramento não usam contas reais.
- Dois advisories moderados de dependências da Fase 1 permanecem no lock; o adaptador não usa uuid nem parser qs. Não se declara eliminação geral dos advisories.
- Compatibilidade real de auth/perfis/timeline, necessidade de EULA/XMPP/party e lista exata de chamadas não foram observadas.
- Configurações nativas MCP foram encontradas como identificadores, mas cobertura e suporte a overrides no Shipping não estão comprovados.
- Proxies que interceptam HTTPS, certificados falsos, DLL/patches e flags de segurança foram rejeitados; nenhum foi implementado.
- Nenhum gameserver foi iniciado e nada de Apollo/bots/loot/progressão foi configurado.

Resultado do teste isolado de backend em Sandbox: **falhou por timeout após 100 segundos, sem qualquer resultado do guest**. O helper desse teste foi encerrado e não há prova de boot, NIC desabilitada em runtime, saúde ou loopback dentro do guest. Fortnite não foi mapeado ou executado nessa tentativa. `logs/phase2-sandbox-test.json` registra a falha; não se tentou diminuir ProtectedClient, modificar segurança, instalar componentes ou lançar o jogo no host como fallback. O test runner passou a limpar automaticamente seu próprio helper e recusar reaproveitamento de uma instância Sandbox já existente. A causa exata da falta de resposta ainda precisa de diagnóstico; não se declara que Sandbox seja incompatível com o jogo.

A primeira execução do Fortnite continua dependendo de uma arquitetura validável e autorização explícita futura. Não solicitar aprovação para um comando indefinido ou para remover qualquer restrição.
