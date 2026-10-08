# Arquitetura V2 — backend modular local, cliente bloqueado

Proposta de 2026-10-07, **STACK B**, aguardando aprovação. Substitui as premissas de arquitetura da Fase 2; documentos anteriores conservam as evidências históricas. [Decisão](COMMUNITY_STACK_DECISION.md), [comparação](COMMUNITY_STACK_COMPARISON.md) e [migração](COMMUNITY_STACK_MIGRATION.md).

**Não existe camada comunitária selecionada que tenha demonstrado boot/roteamento permitido para nosso Shipping 13.40.** A arquitetura abaixo identifica o espaço dessa camada, mas não o preenche com um launcher incompatível. Nenhuma nova integração, servidor, modificação do jogo ou rede foi executada.

## Estados

| Estado | Significado |
| --- | --- |
| EXISTENTE | Arquivo, build ou artefato já presente; não significa que sua função runtime passou |
| REUTILIZADO | Base existente conservada pela proposta ou referência selecionada para especificação futura |
| NOVO | Componente/contrato planejado, ainda sem implementação |
| NÃO TESTADO | Integração cliente/runtime ausente; não promover a funcionalidade comprovada |

No diagrama, linhas tracejadas são **contratos futuros ou referências**, sem conexão operacional implementada. As linhas sólidas do backend representam sua composição existente, testada anteriormente por REST sem cliente. A memória/controlador FES permanece fora do caminho executável proposto.

## Diagrama de camadas e bloqueios

```mermaid
flowchart TD
    CLI["CLIENT: Fortnite 13.40 / CL 14113327<br/>EXISTENTE: build validada<br/>NÃO TESTADO: boot completo permitido e lobby"]
    GATE["COMMUNITY COMPATIBILITY LAYER<br/>NOVO / NÃO TESTADO / BLOQUEADO<br/>Sem candidato elegível demonstrado<br/>Boot, auth aceita pelo cliente e roteamento"]
    REF["Referências comunitárias Velocity<br/>REUTILIZADO como fonte para especificação<br/>MCP / XMPP / party / modelos de sessão<br/>Sem launcher, TLS, hosts ou autostart"]
    BE["LOCAL BACKEND<br/>EXISTENTE / REUTILIZADO<br/>Node + adaptador atual + guard<br/>REST local testado; integração cliente NÃO TESTADO"]
    AUTH["AUTH LOCAL<br/>EXISTENTE / REUTILIZADO<br/>Identidade fictícia e sessão opaca<br/>Aceitação por Shipping NÃO TESTADO"]
    PROF["PROFILES / MCP<br/>EXISTENTE / REUTILIZADO<br/>athena / common_core / common_public<br/>Sem progressão de partida"]
    CP["CommunityProtocol13<br/>NOVO / NÃO TESTADO<br/>Contrato e módulos seletivos futuros<br/>Ainda não implementados"]
    PARTY["XMPP / PARTY<br/>NOVO / NÃO TESTADO<br/>REST presence atual não equivale a XMPP"]
    MM["LOCAL MATCHMAKING<br/>NOVO / NÃO TESTADO<br/>Ticket, identidade e sessão<br/>Atual: rota bloqueada com 503"]
    HOST["GAME SERVER / INTERFACE DE HOST<br/>NOVO / NÃO TESTADO / BLOQUEADO<br/>Nenhum provedor de runtime elegível escolhido"]
    FES["FortExternalServer season-13<br/>EXISTENTE / REUTILIZADO como referência<br/>Release x64 compilado, nunca executado<br/>Controla memória Shipping; fora do runtime aprovado"]
    WORLD["APOLLO / PLAYER<br/>EXISTENTE: referências/assets da build<br/>NOVO: integração de mundo/jogador<br/>NÃO TESTADO"]
    AI["PHOEBE / OCEAN / JULES / KIT<br/>EXISTENTE: referências FES/build<br/>NOVO: integração de IA<br/>NÃO TESTADO / fase futura"]
    PROG["PROGRESSION LOCAL<br/>NOVO / NÃO TESTADO / reservado<br/>Resultados autoritativos, XP e recompensas<br/>Sem implementação nesta fase"]

    CLI -. "boot e endpoints: sem caminho elegível" .-> GATE
    GATE -. "HTTP local: condição ainda não satisfeita" .-> BE
    BE --> AUTH
    BE --> PROF
    REF -. "somente especificação de protocolos" .-> CP
    CP -. "integração futura" .-> BE
    CP -. "transporte/mensagens futuros" .-> PARTY
    BE -. "serviço futuro" .-> MM
    GATE -. "XMPP local futuro" .-> PARTY
    MM -. "registro e readiness, sem spawn de jogo" .-> HOST
    CLI -. "gameplay Unreal direto: futuro, não via backend HTTP" .-> HOST
    FES -. "metadados e estudo; não acionar controlador" .-> HOST
    HOST -. "mundo e jogador: fase futura" .-> WORLD
    WORLD -. "IA: fase futura" .-> AI
    HOST -. "eventos/resultados: contrato futuro" .-> PROG
    PROG -. "persistência/revisões: fase futura" .-> PROF

    classDef blocked fill:#ffe1e1,stroke:#b42318,color:#321010;
    classDef existing fill:#e4f5e9,stroke:#237a40,color:#102619;
    classDef future fill:#eef2ff,stroke:#5968a8,color:#192246;
    class GATE,HOST blocked;
    class CLI,BE,AUTH,PROF,FES existing;
    class REF,CP,PARTY,MM,WORLD,AI,PROG future;
```

## Responsabilidades e fronteiras

**Cliente e compatibilidade.** A build permanece intacta. O espaço da camada comunitária abrange boot e seleção de serviços locais. Nenhum launcher auditado atende integralmente às restrições. Não preencher esse espaço com CA/hosts/TLS bypass/injeção de auth, valores de credenciais ou patch de Shipping. A seleção de módulos do backend não soluciona essa fronteira.

**Backend e auth.** Conservar `backend/phase2/server.cjs`, guard e coordenador. A identidade local e sessões fictícias não representam conta Epic. Permanecer em loopback com as proteções existentes. O guard protege APIs Node auditadas, não o processo do jogo. Não importar inicializadores comunitários com escuta ampla, rede remota ou processos filhos.

**Profiles e protocolo.** Conservar `backend/phase2/profiles.cjs` e snapshots existentes. `CommunityProtocol13` é apenas o nome do contrato futuro proposto. Velocity é referência de JSON/MCP, mensagens XMPP/party e DTOs; código será considerado por arquivo e fechamento de dependências, com licença/proveniência. Anora é referência comparativa, não backend instalado. Auth própria de terceiros não deve substituir automaticamente nossa sessão mínima.

**XMPP/party.** A presença REST atual não fornece transporte XMPP, binding, presença/MUC ou gerenciamento completo de party. São camadas futuras distintas. Código de mensagens não comprova compatibilidade dos endpoints ou transportes esperados pelo cliente 13.40.

**Matchmaking.** Serviço futuro recebe identidade/ticket, seleciona uma sessão elegível e descreve host/porta/versão/playlist. Não inicia Shipping, não injeta DLL e não considera temporizador ou conexão TCP como prova de readiness de uma partida Unreal. O backend atual continua respondendo 503 nessa fronteira. O autostart Velocity não integra a proposta.

**Host e gameplay.** Cliente se comunica diretamente com o host para o protocolo de jogo; backend HTTP não é um túnel entre ambos. Não há provedor de host autorizado selecionado. FES compilado é referência preservada: seu controle de processo/memória, bridge/stubs/hooks e espera de menu não se tornam uma interface independente por trocar o launcher. Separabilidade de dados declarativos é **INFERIDO**, não módulo extraído. Gameplay dependente de objetos Unreal não foi implementado fora desse runtime.

**Apollo, IA e bosses.** Os paths/classes/nomes estão **CONFIRMADO POR CÓDIGO** no perfil FES, sem execução. Default de mapa divergente, IA desligada e posições provisórias permanecem documentados. Não há prova de navegação, visuais, loot ou lógica fiel; não avançar para essas fases agora.

**Progressão.** Campo `xp`, setter de tier e persistência de profile não equivalem a progressão autoritativa. A fase futura precisará de origem validada dos resultados e atualização de revisões sem concessões arbitrárias. Não se criou serviço de XP, quest, Battle Pass ou grants.

## Condições de avanço

O primeiro passo após eventual aprovação é especificação estática dos módulos de protocolo, sem execução de componentes. Implementação depende de autorização posterior de escopo; experimento com cliente depende também de evidência de boot/roteamento permitidos. Se essa evidência continuar ausente, a arquitetura permanece parcial e bloqueada.

Neste ponto o trabalho para. A escolha **STACK B** preserva módulos úteis e não altera a decisão C de boot da [auditoria de lançamento](PHASE2_LAUNCH_CHAIN.md).
