# Comparação de componentes comunitários — Fortnite 13.40

Auditoria de fontes públicas e checkouts existentes em 2026-10-07. **Resultado: STACK B — reutilização parcial, sem solução de boot demonstrada dentro das restrições.** Nenhum componente comunitário foi instalado, compilado ou executado nesta etapa. O FortExternalServer já compilado foi preservado.

## Como ler a evidência

| Marca | Significado |
| --- | --- |
| C | **CONFIRMADO POR CÓDIGO**: implementação, condição de versão ou referência está presente na fonte consultada. Não comprova funcionamento. |
| D | **CONFIRMADO POR DOCUMENTAÇÃO**: estrutura ou procedimento descrito publicamente. |
| P | **DECLARADO PELO PROJETO**: promessa de suporte/recurso, sem validação independente. |
| I | **INFERIDO**: conclusão arquitetural derivada das fontes, identificada como tal. |
| NT | **NÃO TESTADO**: integração com nosso cliente/CL não foi executada. |
| ? | Não determinado pela amostra de fontes. Não significa ausência no projeto inteiro. |
| — | Não é responsabilidade do componente examinado. |

Todas as linhas abaixo têm **NT para funcionamento com nosso Shipping**. “13.40 no código” e “CL explícito” são evidências estáticas diferentes de compatibilidade operacional. Auth de um backend comunitário pode emitir seus próprios tokens/códigos; isso não demonstra autenticação Epic nem torna permitido o mecanismo que faz o cliente aceitá-los.

Escopo: dois gameservers Milxnor separados, o launcher Auties00, os checkouts FortExternalServer/LawinServer, Anora, Velocity e fontes históricas Era. Como referência adicional limitada, reaproveitou-se a auditoria de ggsplayz/FortniteLauncher, cujo README identifica o CL exato. Não foram clonadas coleções de projetos, baixados launchers/DLLs ou consultados serviços live Epic.

## Matriz solicitada

Os detalhes e fontes de cada linha estão nas seções seguintes. “Incompatível” qualifica o fluxo completo observado; um módulo de protocolo pode continuar útil separadamente.

| Projeto | 13.40 | Launcher | Backend | Gameserver | Apollo | Phoebe | Bosses | Profiles | XMPP | Progression | Live Epic? | Anti-cheat bypass? | TLS/proxy? | Injection/hooks? | Licença | Decisão |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Project Reboot original | S13 declarada P; CL ? | Externo D | — | DLL C | Seleção por engine C | ? | ? | — | — | Persistência S13 ? | Bootstrap externo ? | Launcher externo | Roteamento externo | MinHook/ProcessEvent/NoMCP C | BSD-3-Clause | Referência histórica; não escolher runtime |
| Project Reboot 3.0 | Faixa S3–S15 P; ramo até 13.40 C; CL ? | Recomenda Reboot Launcher D | — | DLL C | Referência C | Pawn C | Spawn genérico C; Ocean/Jules/Kit ? | — | — | Contrato persistente S13 ? | Bootstrap externo ? | Via launcher incompatível | Via launcher externo | MinHook e hooks de sessão/MCP/gameplay C | BSD-3-Clause | Referência de gameplay; fluxo de uso incompatível |
| Reboot Launcher | Mapeia CL 14113327 para 13.40 C | Flutter/Dart C | Lawin incorporado C | Carrega DLL externa C | Delegado | Delegado | Delegado | Backend C | Backend C | Backend, sem prova S13 | Auth comunitária; fluxo completo ? | Auxiliares suspensos/provedor alterado C | DLL de auth/redirecionamento; efeito TLS completo ? | Injeção de auth obrigatória no caminho auditado C | Raiz não identificada; backend GPL-3.0 | **INCOMPATÍVEL COM AS RESTRIÇÕES**; apenas estudar metadados |
| FortExternalServer season-13 | Versão e CL exatos C; compilação local documentada D | Bootstrap próprio C | — | Controlador externo C | Caminho C; default divergente | Classes e lógica C | Ocean/Jules/Kit C; posições provisórias | — | — | Contrato de progressão backend ? | Não fornece boot offline completo | Não identificado bypass EAC/BE na amostra; autorização não demonstrada | Não resolve roteamento HTTP/TLS | Escrita/alocação/stubs/hooks de rede C | MIT | Preservar compilado e estudar dados; runtime bloqueado |
| LawinServer upstream | Todas as versões P; schemas sazonais C; CL ? | Externo D | Node/Express C | Externo | — | — | — | MCP C | WS/XMPP C | Comandos/quests C; fidelidade S13 NT | Tokens próprios; sem Epic live na auth consultada | Depende da entrada externa | Receita de integração Fiddler/SSL redirect D | Externo; não necessário para responder REST | GPL-3.0 | Backend seletivo útil; receita de conexão incompatível |
| Anora | Season 13 P; configuração/recursos sazonais C; CL ? | Rotas HTTP, não launcher de processo | TypeScript/MongoDB C | Registro/atribuição, não host Unreal | — | — | — | MCP persistente C | WS/XMPP/party C | Battle Pass/comandos C; eventos de partida NT | Auth própria; Discord remoto no startup C | Não soluciona entrada do cliente | Não demonstra redirecionamento permitido | Backend sem injeção na amostra; entrada externa ? | MIT raiz / GPL-3.0 manifesto: divergência | Referência; não migrar backend integral |
| Velocity-OGFN | Condições abrangem 13.40 C; CL ? | Electron C | Node/Express C | Orquestra Shipping + Reboot DLL C | Delegado | Delegado | Delegado | JSON persistente/MCP C | WS/XMPP + REST party C | Setters de nível/tier C; progressão por partida NT | Auth/códigos próprios C; acesso Epic não exigido nessa rota | Stub/impedimento de auxiliares C | Hosts/CA/portproxy e TLS desabilitado C | DLL host e redirecionamento C | MIT | **INCOMPATÍVEL COM AS RESTRIÇÕES** como stack; módulos puros úteis |
| Era público histórico | CL e C2S3 ?; engine 4.25/Apollo C | C# histórico C | Backend atual reutilizável não demonstrado | Mod DLL, não host S13 provado | Referência C | ? | ? | ? | ? | ? | Endpoint comunitário/config remota histórica C; Epic ? | Argumentos de supressão C | Sem pinning na chamada; cURL redirect documentado D | Injeção e ProcessEvent hooks C | EraFN GPL-3.0; outros sem licença identificada | Histórico incompatível para boot; Era atual descartado como base não demonstrada |
| ggsplayz/FortniteLauncher | 13.40 / CL exatos no README P | C# C | Externo | Externo | — | — | — | Externo | Externo | — | Modo S13 Hybrid usa Epic live C | Suspende EAC C | Substituição de DLL para redirect C | Substituição de DLL/controle de processo C | Não estabelecida nesta auditoria | **INCOMPATÍVEL COM AS RESTRIÇÕES** |

## Eixos complementares

| Candidato | Chapter 2 Season 3 | Consegue iniciar cliente? | Matchmaking | Bots |
| --- | --- | --- | --- | --- |
| Reboot original | P, com limitação de safezone anunciada | Não é launcher; fluxo externo NT | Hosting de partida; serviço de tickets não demonstrado | ? na amostra original |
| Reboot 3.0 | P + código condicional até 13.40 C | DLL carregada em cliente por launcher; NT | Gameplay/rede Unreal; não backend de tickets | Código de bot/pawn e SpawnBot C, NT |
| Reboot Launcher | CL na tabela C; funcionamento NT | Caminho de criação de Shipping C; mecanismos proibidos | Backend/DLL externos ao GUI | Delegado ao host |
| FortExternalServer | Perfil exato C | CreateProcess/attach C; chegar ao menu não demonstrado | Sessões/controlador presentes; integração backend NT | FortAthenaAI C; desabilitados por default |
| LawinServer | Schemas sazonais C; todas as versões P | Não | Ticket HTTP e WS matchmaker C | Não é módulo de IA |
| Anora | Alvo Season13 P; timeline/BattlePass sazonais C | Não | Ticket/registry/sessão HTTP C; matchmaker externo indicado; WS interno ativo não demonstrado | Não é módulo de IA |
| Velocity | Abrangida pela seleção numérica C | Caminho de Shipping C, NT; incompatível | WS de estados, sessão HTTP e autostart de host C | Delegado ao Reboot; não atribuir recursos da DLL ao backend |
| Era histórico / atual | Não comprovado especificamente | Histórico possui chamada C; resultado NT. Atual não auditável como stack aberta S13 | Serviço atual local reproduzível não demonstrado | ? |
| ggsplayz | S13/13.40 explícito P | Chamada de Shipping C; execução nesta máquina NT | Externo | Externo |

## Fontes fixadas e manutenção

Datas são UTC de commits consultados, não promessa de suporte. `pushed_at`/“Updated” não são a data do último commit. A API pública atingiu limite durante uma atualização complementar; os dados obtidos anteriormente nesta sessão e as fontes fixadas foram conservados. Não se usou conta/token para ampliar acesso. Datas desconhecidas não foram preenchidas por inferência.

| Fonte / revisão examinada | Último commit consultado | Interpretação de manutenção |
| --- | --- | --- |
| [FortExternalServer season-13 e42ecddbce59163c6a60ab7506766c2a0adfe580](https://github.com/OGFN-Open-sourceing/FortExternalServer/commit/e42ecddbce59163c6a60ab7506766c2a0adfe580) | 2026-09-15, confirmado pelo Git local | Branch existente preservada; main diferente não substitui o lock |
| [Reboot original 5c9f3861a451ac8d9cac6e83d4353bfeb8700230](https://github.com/Milxnor/Project-Reboot/commit/5c9f3861a451ac8d9cac6e83d4353bfeb8700230) | 2023-04-23 | Histórico, sem manutenção recente de código demonstrada |
| [Reboot 3.0 10c659028ad9d6816f78226483f11a884bf81f57](https://github.com/Milxnor/Project-Reboot-3.0/commit/10c659028ad9d6816f78226483f11a884bf81f57) | 2026-10-01 | Commit recente; não prova teste S13 |
| [Reboot Launcher c6f82298b167ef2076bb59dc621f13dc5bd8d390](https://github.com/Auties00/Reboot-Launcher/commit/c6f82298b167ef2076bb59dc621f13dc5bd8d390) | 2026-09-05 | Commit recente; push em 2026-10-06 é metadado distinto |
| [LawinServer 7f0f26d7a772c6122c42b1783fd75f497e86d3a9](https://github.com/Lawin0129/LawinServer/commit/7f0f26d7a772c6122c42b1783fd75f497e86d3a9) | 2026-08-21 | Já fixado no projeto; sem troca de versão |
| [Anora 455ff6db31738f43026ab19f01780398f6d6f507](https://github.com/aryanmahalingham/Anora/commit/455ff6db31738f43026ab19f01780398f6d6f507) | 2026-09-21 | Commit recente; compatibilidade runtime não demonstrada |
| [Velocity 8746e8fea254be04396adc9a26d224e84032b8b4](https://github.com/forevershy/Velocity-OGFN/commit/8746e8fea254be04396adc9a26d224e84032b8b4) | 2026-07-11 | Fonte atual consultada; não prova funcionamento do launcher |
| [Era2.0 4b194e85ed2129c336389bd9dc3a6cfd1f471e10](https://github.com/EraFNOrg/Era2.0/commit/4b194e85ed2129c336389bd9dc3a6cfd1f471e10) / [Era-Launcher e7d48de4ba652df3efef50c25698ef43549d5d10](https://github.com/EraFNOrg/Era-Launcher/commit/e7d48de4ba652df3efef50c25698ef43549d5d10) | 2021-12-27 / 2021-12-23 | Código histórico; datas “Updated 2023” da organização não tornam o código atual |
| [EraFN 06ee7226fa4dd5aea5766cfc125151fc8f587263](https://github.com/EraFNOrg/EraFN/commit/06ee7226fa4dd5aea5766cfc125151fc8f587263) / [EraScript 58bb8f4759eaa301a3f791b6a2cbe0a029627879](https://github.com/EraFNOrg/EraScript/commit/58bb8f4759eaa301a3f791b6a2cbe0a029627879) | 2021-10-17 / 2021-10-05 | Mod/documentação de scripting históricos |
| [ggsplayz 3925256986d7eb6f565b33d142d25899d3a1da07](https://github.com/ggsplayz/FortniteLauncher/tree/3925256986d7eb6f565b33d142d25899d3a1da07) | Atualidade não estabelecida | Referência já auditada; não escolher manutenção por popularidade |

## Reboot: três componentes diferentes

**Project Reboot original** é fonte de host/mod. O [README original](https://github.com/Milxnor/Project-Reboot/blob/5c9f3861a451ac8d9cac6e83d4353bfeb8700230/README.md) declara S13–S18 e ressalva safezone. O [dllmain original](https://github.com/Milxnor/Project-Reboot/blob/5c9f3861a451ac8d9cac6e83d4353bfeb8700230/Project%20Reboot/dllmain.cpp) confirma DLL/MinHook, seleção Apollo por engine e hooks ProcessEvent/NoMCP; o bloco opcional PreLogin está desabilitado nesse código. Não se demonstrou perfil do CL exato nem Phoebe/Ocean/Jules/Kit na amostra. Sua utilidade nesta seleção é histórica, sem vantagem provada sobre nosso host com perfil exato.

**Project Reboot 3.0** hospeda a partida por código executado dentro do Fortnite. O [entrypoint](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/dllmain.cpp) instala MinHook, altera comportamento MCP/sessão/rede e possui condição de SpawnBot que inclui 13.40. Há seleção Apollo e pawn Phoebe em [bots.h](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/bots.h); o [bot manager](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/FortServerBotManagerAthena.cpp) contém caso comentado S13 para customização. Isso confirma código S13, não bots funcionais nem Ocean/Jules/Kit específicos. Nem todo hook de gameplay é bypass de anti-cheat; hooks de MCP/sessão precisam de avaliação de finalidade. O fluxo documentado exige launcher externo, e o launcher auditado contém mecanismos proibidos. Não selecionar esse conjunto para execução.

**Reboot Launcher (Auties00)** inicia Shipping e prepara o contexto de cliente/host. [game_metadata.dart](https://github.com/Auties00/Reboot-Launcher/blob/c6f82298b167ef2076bb59dc621f13dc5bd8d390/common/lib/src/game/game_metadata.dart) mapeia o CL exato; [game_start_button.dart](https://github.com/Auties00/Reboot-Launcher/blob/c6f82298b167ef2076bb59dc621f13dc5bd8d390/gui/lib/src/button/game_start_button.dart) chama injeção de auth e suspende auxiliares. Tabela de versões é referência estática; boot é **INCOMPATÍVEL COM AS RESTRIÇÕES**. O diretório `auth_backend` contém Lawin: não é backend novo com superioridade S13 provada. A [licença desse backend](https://github.com/Auties00/Reboot-Launcher/blob/c6f82298b167ef2076bb59dc621f13dc5bd8d390/auth_backend/LICENSE) é GPL-3.0; não estender automaticamente essa licença ao GUI sem licença raiz identificada.

| Módulo | Reboot original / 3.0 | Reboot Launcher |
| --- | --- | --- |
| LAUNCHER | Externo; não é o papel da DLL | Incompatível |
| BACKEND | Ausente como serviço HTTP nesta avaliação | Lawin incorporado: referência redundante |
| AUTH | MCP/sessão e bootstrap não aprovados | Injeção de auth: excluir |
| NETWORK REDIRECTION | Externo; não demonstra solução permitida | DLL/contexto não aprovados: excluir |
| GAMESERVER | Dependente do runtime modificado; não selecionar | Carrega host externo; excluir caminho de injeção |
| MATCHMAKING | Separar rede Unreal de serviço de tickets | Backend externo, não solução do GUI |
| PROFILE | Não fornecido pelo host | Backend Lawin, estudar separado |
| XMPP/PARTY | Não fornecido pelo host | Backend Lawin, estudar separado |
| GAMEPLAY | Algoritmos como referência, sem transplante do runtime | Delegado à DLL |
| BOTS | 3.0: referências C; original ? | Delegado à DLL |
| PROGRESSION | Persistência autoritativa S13 não demonstrada | Delegada ao backend; não implementada aqui |

## FortExternalServer: reutilizar o conhecimento exato, preservar o artefato

O checkout existente em `gameserver/vendor/FortExternalServer` continua no commit do lock. A [definição Season13](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/FortniteGame/Private/Versioning/Season13BuildProfile.cpp) identifica 13.40, UE 4.25 e CL 14113327, paths Apollo/Phoebe e definições Ocean/Jules/Kit. É a evidência estática mais específica desta seleção. Compilar Release x64 não validou o processo host nem a partida.

O [GameServerHost](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Server/Private/GameServerHost.cpp) cria/anexa o processo, carrega seu layout, prepara arena/bridge remoto, instala hooks, espera menu e abre mundo/listener. [WindowsProcessAttachment](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Runtime/RemoteProcess/Private/Windows/WindowsProcessAttachment.cpp) fornece acesso ao processo. [NetworkHooks](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Runtime/Engine/Private/Engine/NetworkHooks.cpp) altera NetDriver, modo de rede e tratamento de sessão/controle. Não demonstrou bootstrap offline aprovado nem um adaptador HTTP para nosso backend.

| Módulo | Situação / separabilidade |
| --- | --- |
| LAUNCHER | Bootstrap de Shipping/attach C; não reutilizar para desbloquear boot |
| BACKEND | Não fornece serviços MCP/profile/XMPP |
| AUTH | Argumentos/contexto de bootstrap não demonstram auth local válida; hooks de sessão não são prova de autorização Epic |
| NETWORK REDIRECTION | NetDriver/handshake Unreal não substituem roteamento MCP/HTTP |
| GAMESERVER | Controlador de memória C; runtime bloqueado, não servidor dedicado autônomo |
| MATCHMAKING | Configuração de sessão/partida; contrato com tickets locais NT |
| PROFILE | Perfil de **build/layout**, diferente de profile de jogador MCP |
| XMPP/PARTY | Não é responsabilidade implementada pelo host auditado |
| GAMEPLAY | Mundo, inventário, jogador e safezone dependem de EngineRuntime/reflection C |
| BOTS | [FortAthenaAI](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/FortniteGame/Private/AI/FortAthenaAI.cpp) opera objetos Unreal remotos; não é módulo de bots independente |
| PROGRESSION | Não localizado contrato autoritativo persistente com nosso backend |

Podem servir de referência separada: metadados de versão, identificadores de classes/assets, definições declarativas de loadout e parâmetros de partida. São **I para separabilidade**: ainda não foram extraídos nem implementados. Runtime bridge, offsets, escrita/stubs e hooks não devem ser importados como parte de um módulo de protocolo.

[Configuration.h](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Server/Public/Configuration.h) mantém bots/bosses desligados, mínimo de dois jogadores e `Athena_Terrain`; [ServerSettings](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Server/Private/ServerSettings.cpp) usa esse default, apesar de Apollo no perfil. Posições dos bosses são provisórias. Nenhum desses valores foi alterado. Não afirmar aparência, loot, navegação ou comportamento fiel dos bosses.

## Lawin, Anora e Velocity: backend não desbloqueia cliente

| Módulo | Lawin upstream / nosso adaptador | Anora | Velocity |
| --- | --- | --- | --- |
| LAUNCHER | Externo / coordenador atual só prepara backend | Sem launcher de processo demonstrado | Incompatível |
| BACKEND | Schemas úteis / preservar REST mínimo testado sem cliente | Cobertura maior; startup remoto e licenças pendentes | Referência modular; não importar entrypoint |
| AUTH | Tokens locais / conservar sessão fictícia atual | JWT/usuários próprios; Discord/2FA integrados | Tokens/códigos próprios; preservar auth atual em vez de importar |
| NETWORK REDIRECTION | Receita upstream incompatível / nenhum override implementado | Não oferece entrada permitida | Hosts/TLS/CA/portproxy/stub: excluir |
| GAMESERVER | Externo / artefato FES preservado, bloqueado | Registry, não host Unreal | Shipping + DLL; excluir execução |
| MATCHMAKING | DTOs/WS de referência / atual 503 | Registry/ticket/sessão HTTP; matchmaker externo, NT | DTOs úteis; WS acoplado a autostart proibido |
| PROFILE | MCP sazonal / snapshots existentes | MongoDB/MCP mutável e revisões | JSON por conta/MCP; candidato a referência seletiva |
| XMPP/PARTY | WS/presença upstream / atual só presença REST | WS, presença, MUC/party | WS + REST party; referência seletiva |
| GAMEPLAY | Não implementado no backend | Não implementado no backend | Delegado à DLL |
| BOTS | Não implementados no backend | Não implementados no backend | Delegados à DLL |
| PROGRESSION | Comandos/quests upstream / placeholders atuais | Battle Pass/comandos; fidelidade e eventos de partida NT | Setters de nível/tier; progressão autoritativa não demonstrada |

### Lawin versus Anora

O [Lawin README](https://github.com/Lawin0129/LawinServer/blob/7f0f26d7a772c6122c42b1783fd75f497e86d3a9/README.md) declara suporte amplo e integração via redirecionamento Fiddler/SSL. Essa receita é incompatível. Separadamente, [MCP](https://github.com/Lawin0129/LawinServer/blob/7f0f26d7a772c6122c42b1783fd75f497e86d3a9/structure/mcp.js), [XMPP](https://github.com/Lawin0129/LawinServer/blob/7f0f26d7a772c6122c42b1783fd75f497e86d3a9/structure/xmpp.js) e [matchmaking](https://github.com/Lawin0129/LawinServer/blob/7f0f26d7a772c6122c42b1783fd75f497e86d3a9/structure/matchmaking.js) são fontes de schemas/fluxos. O upstream é muito maior que nosso adaptador: não confundir sua lista de recursos com o que habilitamos localmente.

| Função | Nosso Lawin adaptado | Anora auditado | Conclusão |
| --- | --- | --- | --- |
| Profile/MCP | QueryProfile de três profiles; revisões estáveis, sem mutações gerais | Models MongoDB, comandos e revisões mutáveis C | Anora tem maior cobertura estática |
| Auth local | Sessão fictícia opaca, sem exchange_code; testes próprios anteriores | Senha/JWT e exchange codes emitidos pelo próprio backend C | Mais fluxos; nenhum prova que Shipping aceita sem contorno |
| Timeline | Season13/LobbySeason13 e resposta fixa | Derivação de temporada/flags por versão C | Mais flexível; não mais comprovado para o CL |
| XMPP/party | Só presença REST; XMPP desabilitado | WS/XML, tokens internos, presença/MUC C | Recurso real no código, NT com nosso cliente |
| Matchmaking | 503 intencional | Registry de gameservers, tickets e consulta de sessão C | Não equivale a host pronto ou boot independente |
| Dependências | Node/Express já existentes, arquivos locais | Node/TypeScript, pnpm documentado, MongoDB, bot Discord; KV/Redis no código/pacotes | Mais serviços; offline integral não demonstrado |
| Evidência exata | REST local testado; integração cliente NT | Season13 declarada; CL 14113327 não demonstrado | Não há prova suficiente de superioridade operacional |

[Anora auth](https://github.com/aryanmahalingham/Anora/blob/455ff6db31738f43026ab19f01780398f6d6f507/src/routes/auth.ts), [MCP](https://github.com/aryanmahalingham/Anora/blob/455ff6db31738f43026ab19f01780398f6d6f507/src/routes/mcp.ts), [timeline](https://github.com/aryanmahalingham/Anora/blob/455ff6db31738f43026ab19f01780398f6d6f507/src/routes/timeline.ts), [XMPP](https://github.com/aryanmahalingham/Anora/blob/455ff6db31738f43026ab19f01780398f6d6f507/src/xmpp/xmpp.ts) e [MMS](https://github.com/aryanmahalingham/Anora/blob/455ff6db31738f43026ab19f01780398f6d6f507/src/routes/mms.ts) sustentam a cobertura. O [index.ts](https://github.com/aryanmahalingham/Anora/blob/455ff6db31738f43026ab19f01780398f6d6f507/src/index.ts) chama login do bot Discord no startup e inclui OAuth Discord. KV participa de tokens/2FA; a topologia obrigatória de Redis não foi integralmente verificada. Não instalar nem remover/adaptar essas integrações automaticamente.

O ticket aponta para `MATCHMAKER_IP` e a consulta de sessão acessa esse endereço. No arquivo XMPP, a importação/chamada do matchmaker está comentada: o log que menciona “XMPP and Matchmaker” não comprova WS de matchmaking ativo. XMPP usa servidor HTTP/WS em porta 443, sem TLS criado nesse arquivo; número de porta não significa WSS nem solução de certificado. Essa cadeia de transportes também permanece sem validação para o cliente.

A [LICENSE raiz Anora](https://github.com/aryanmahalingham/Anora/blob/455ff6db31738f43026ab19f01780398f6d6f507/LICENSE) diz MIT, enquanto [package.json](https://github.com/aryanmahalingham/Anora/blob/455ff6db31738f43026ab19f01780398f6d6f507/package.json) diz GPL-3.0 e identifica Momentum/Nexus-FN. A divergência e proveniência impedem classificar todo código como MIT reutilizável sem análise por arquivo. Não migrar integralmente para Anora agora. Essa escolha decorre de evidência, funcionamento local e restrições; não de preferência automática por Lawin.

### Velocity por módulos

[profiles.js](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/structs/profiles.js) lê/grava JSON por conta e implementa loadout/revisões/setters; [partyService](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/structs/partyService.js) mantém estado de party e [XMPP](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/xmpp/xmpp.js) implementa transporte/presença. Modelos de dados e mensagens são candidatos úteis sob a [licença MIT](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/LICENSE), com notices e proveniência preservados. Elegibilidade estática não é aprovação de execução/importação integral.

O [matchmaker](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/matchmaker/matchmaker.js) tem estados WS e chama `ensureGameserver`; o [host controller](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/structs/gameserver.js) usa DLL para builds anteriores a 15, incluindo 13.40. Sua sondagem de porta é TCP: não prova readiness do protocolo Unreal/UDP. [matchSessions.js](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/structs/matchSessions.js) usa Maps e última conta enfileirada global; não assumir associação segura de tickets a usuários. Reutilizar modelos/mensagens exigiria contrato explícito, sem copiar autostart.

[routes/matchmaking.js](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/routes/matchmaking.js) devolve hostname Epic com expectativa de hosts/redirecionamento. [launch-game](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/launcher/launch-game.js), [launch-profiles](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/launcher/launch-profiles.js) e [libcurl-ssl](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/launcher/libcurl-ssl.js) ligam o caminho 13.40 a stub/contexto modificado e desativação de verificações TLS. O conjunto com setup de rede/certificados é **INCOMPATÍVEL COM AS RESTRIÇÕES**. Não transplantar esses mecanismos para “viabilizar” módulos permitidos.

O config de exemplo permite escuta ampla e autostart de host. Não usar o entrypoint como substituto de nosso servidor com guard. Dados JSON/MCP, mensagens XMPP/party e DTOs de sessão são a parte candidata; launcher, TLS, hosts, certificados, execução/injeção de host e URLs dependentes de interceptação são excluídos.

## Era: público histórico não comprova stack atual reutilizável

A [organização EraFNOrg](https://github.com/EraFNOrg) possui quatro repositórios públicos históricos. [EraScript](https://github.com/EraFNOrg/EraScript/blob/58bb8f4759eaa301a3f791b6a2cbe0a029627879/README.md) documenta scripting, não um backend local completo para CL 14113327. [EraFN README](https://github.com/EraFNOrg/EraFN/blob/06ee7226fa4dd5aea5766cfc125151fc8f587263/README.md) descreve hooks e redirecionamento cURL. [Era2.0 core](https://github.com/EraFNOrg/Era2.0/blob/4b194e85ed2129c336389bd9dc3a6cfd1f471e10/core.cpp) contém Apollo e suporte de layouts UE 4.25; não confirma sozinho C2S3/13.40.

[Era-Launcher Home](https://github.com/EraFNOrg/Era-Launcher/blob/e7d48de4ba652df3efef50c25698ef43549d5d10/EraLauncher/Home.xaml.cs) inicia Shipping com contexto de supressão de segurança e injeta EraV2; [EraAPI](https://github.com/EraFNOrg/Era-Launcher/blob/e7d48de4ba652df3efef50c25698ef43549d5d10/EraLauncher/Misc/Classes/EraAPI.cs) busca configuração por URL e trata falha de servidor central. Esse launcher histórico é incompatível. Não foi demonstrado backend atual aberto/autossuficiente, documentação de integração local atual ou suporte específico de runtime C2S3. Não transferir esses achados para serviços modernos que usem o nome Era sem vínculo verificável. Era atual fica descartado como base técnica desta proposta; nenhuma dependência de comunidade remota será adotada.

Para a referência adicional ggsplayz, [Program.cs](https://github.com/ggsplayz/FortniteLauncher/blob/3925256986d7eb6f565b33d142d25899d3a1da07/Program.cs) suspende EAC e contém S13 Hybrid com auth live. Compatibilidade declarada com o CL não supera as restrições. Não reutilizar seu fluxo.

## Seleção

**Melhor doador comunitário para os módulos de protocolo selecionados: Velocity, de forma parcial e sem seu launcher/entrypoint. Melhor fonte estática exata de gameplay/build: FortExternalServer season-13 já existente. Backend principal: nosso adaptador local atual, sem troca integral por Anora.**

Esta é uma arquitetura modular parcial (**STACK B**), não uma compatibilidade operacional demonstrada. Nos caminhos de cliente examinados, não se identificou camada comunitária que una boot, auth e roteamento local sem mecanismos proibidos. Isso mantém o bloqueio C da cadeia de lançamento; não constitui prova universal de inexistência de outra solução.

Ver [decisão](COMMUNITY_STACK_DECISION.md), [migração](COMMUNITY_STACK_MIGRATION.md) e [arquitetura V2](ARCHITECTURE_V2.md). A etapa termina na documentação e espera aprovação; não há novo teste de boot, implantação de módulos, bots ou progressão.
