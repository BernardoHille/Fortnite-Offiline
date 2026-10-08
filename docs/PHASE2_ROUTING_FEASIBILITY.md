# Viabilidade do roteamento — Fortnite 13.40 / CL 14113327

Decisão: **ROUTE C — NATIVE ROUTING NOT FOUND**. Foram encontradas configurações nativas reais nos PAKs, mas não um mecanismo demonstrado de override externo que direcione esta Shipping inteira ao backend local. Essa conclusão descreve o resultado da auditoria; não prova que tal mecanismo seja impossível ou inexistente.

## Matriz de mecanismos

“Compatível” exige distinguir arquivo presente de mecanismo utilizável. Nenhum resultado abaixo foi obtido executando Fortnite.

| Método | Fonte / evidência | Compatível com 13.40? | Localhost possível? | Modificar build? | Modificar executável? | Certificado? | Proxy? | Bypass? | Decisão |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A — configurações MCP empacotadas | BaseEngine.ini e DefaultEngine.ini extraídos e verificados | Estruturas confirmadas na build | Modelagem plausível por Protocol/Domain; não validada em runtime | Para editar o PAK, sim; essa edição não é permitida | Não | HTTP conceitual dispensaria; HTTPS local não resolvido | Não intrínseco | Não intrínseco | Configurações identificadas; não editar PAK |
| A — perfil GameServiceMcp Localhost | DefaultEngine.ini:1661–1662 | Seção presente | Apenas Protocol=http confirmado; nenhum Domain loopback nessa seção | Não se seleção nativa existisse; seleção desconhecida | Não | Não presumir ausência para outros serviços | Não intrínseco | Não intrínseco | Não equivale a modo offline global |
| B — AUTH_LOGIN/AUTH_PASSWORD/AUTH_TYPE e epicapp/epicportal | Strings Shipping; launchers externos | Referências presentes | Esses parâmetros não estabelecem URL local | Não | Não | Não solucionam TLS | Não solucionam roteamento | Fluxo oficial/live está fora do escopo | Não usar como mecanismo de roteamento |
| B — seleção McpConfig | Strings McpConfigOverride: %s e Fortnite.McpConfig | Referências presentes; sintaxe e seleção desconhecidas | Desconhecido | Desconhecido | Não foi alterado | Desconhecido | Desconhecido | Nenhum implementado | Não inventar -McpConfig=Localhost |
| C — Saved/Config/WindowsClient/Engine.ini | Hierarquia UE histórica próxima; INIs WindowsClient nos PAKs | Categoria/plataforma confirmadas; aceitação de override MCP não comprovada | Desconhecido | Arquivo externo seria reversível; não criado | Não | Depende do protocolo aceito | Não intrínseco | Nenhum implementado | Candidato de investigação, não experimento validado |
| B/C — -ini:, EngineIni/DefEngineIni | Documentação genérica; literal ini: no Shipping | Presença do literal não prova parser ativo ou prioridade nessa Shipping | Desconhecido | Override temporário poderia preservar originais | Não | Depende de HTTP/HTTPS | Não intrínseco | Nenhum implementado | Não gerar argumento executável com base nisso |
| D — hosts/DNS global | Velocity net-setup.js | Projeto multiversão; não testado aqui | Intercepta destinos, não configuração nativa do cliente | Não necessariamente | Não necessariamente | HTTPS continua exigindo solução | Pode envolver portproxy | Pode depender de outros mecanismos | Rejeitado pelas restrições |
| E — proxy HTTPS / CA customizada | Lawin README; Velocity README/net-setup.js | Abordagens externas documentadas | Sim, segundo seus autores; não testado | Não necessariamente | Não necessariamente | Sim no fluxo com CA | Sim | Algumas variantes alteram validação SSL | Rejeitado; não implementado |
| F — DLL / hooks / memória | FortExternalServer; Project Reboot; ggsplayz launcher | FortExternal profile S13; Reboot declara S3–S15; launcher cita CL exato | Não estabelece por si só um fluxo nativo completo | Pode dispensar edição em disco | Alteração de processo em memória | Depende da variante | Depende da variante | Possível; não avaliar como alternativa autorizada | Somente classificação documental |
| G — autenticação live / suspensão anti-cheat | ggsplayz modo S13; Velocity perfis de lançamento | CL citado pelo ggsplayz; nenhuma execução nossa | Viola o isolamento requerido | Não necessariamente | Processo/controlos seriam alterados | Não resolve arquitetura permitida | Pode combinar outros métodos | Sim ou uso de autenticação live proibida | Rejeitado; não implementado |
| H — cobertura completa de serviços e ordem de boot | Sem trace do cliente | Não conhecida | Não demonstrado | Não determinado | Não determinado | Não determinado | Não determinado | Não determinado | Bloqueio técnico permanece |

## Mapeamento encontrado e destino pretendido

Os endereços abaixo são nomes de configuração lidos localmente, sem consultas DNS/HTTP a esses serviços. O destino pretendido é apenas um desenho: nenhum INI original foi alterado e nenhum override foi aplicado.

| Serviço | Origem confirmada | Campo / valor original relevante | Destino local pretendido | Limitação |
| --- | --- | --- | --- | --- |
| Transporte MCP base | DefaultEngine.ini:1032–1033 | BaseServiceMcp / Protocol=https | Transporte HTTP para serviço próprio em 127.0.0.1:3551, somente se nativamente aceito | Não desativar verificação TLS; aceitação de HTTP desconhecida |
| Account | DefaultEngine.ini:1064–1071 | AccountServiceMcp Prod / Domain=account-public-service-prod.ol.epicgames.com | /account/api/* no backend local | Substituição de Domain/porta e auth sintética não comprovadas |
| Lightswitch | DefaultEngine.ini:1043–1052 | OnlineAccessMcp Prod / Domain=lightswitch-public-service-prod.ol.epicgames.com | /lightswitch/api/service/bulk/status | Domínio principal e AltDomains precisariam de cobertura; não foi aplicada |
| Profile | DefaultEngine.ini:930–933 | McpProfile / McpClientCommandUrl; template relativo de comandos | /fortnite/api/game/v2/profile/local-player/client/QueryProfile | Não fornece sozinho host/base; prefixo de serviço e conta precisam coincidir |
| Serviço de jogo | DefaultEngine.ini:1658–1672 | GameServiceMcp Developer e Localhost / Protocol=http | /fortnite/api/* | Localhost não configura Account, Discovery, XMPP ou demais serviços |
| Discovery | Shipping, identificadores auditados | OnlineDiscoveryMcp / QueryEndpointsUrl | Nenhum endpoint habilitado ainda | Não encontrado valor concreto nas dez configurações selecionadas |
| Base/Client URL | Shipping, identificadores auditados | ClientBaseUrl, BaseUrl, ClientUrlContext | Base local proposta, sem override escrito | Nomes de campos não revelam como valores são compostos nem substituídos |
| XMPP | DefaultEngine.ini:1717–1724 | Xmpp / bUseSSL=true; Domain do ambiente Prod | Nenhum listener nesta fase | Necessidade para lobby desconhecida; TLS não será desativado |
| Outros consumidores | DefaultGame.ini; plugin EarlyStartupPatcher | Analytics, conteúdo, atualização e configurações adicionais | Nenhuma implementação adicional | Roteamento MCP parcial não garante ausência de outras conexões |

## Hierarquia e UE 4.25

O perfil open-source Season13 fixa EngineVersion=4.25 em Season13BuildProfile.cpp:23. Isso é evidência do projeto externo, não introspecção definitiva da versão/fork do cliente. Os PAKs locais usam formato 11; a versão do contêiner não deve ser confundida automaticamente com a versão do engine.

A hierarquia candidata é Base.ini → BaseEngine.ini → bases de plataforma → DefaultEngine.ini → Engine/Config/Windows/WindowsEngine.ini → configuração de projeto/plataforma → Saved/Config/[plataforma]/Engine.ini. Foram encontrados os arquivos base/default/Windows/WindowsClient dentro dos PAKs. A prioridade efetiva entre Windows e WindowsClient, o diretório de Saved, a política de INIs gerados e o acesso a campos MCP pelo cliente não foram observados.

A referência oficial próxima disponível é a [documentação UE 4.27 de configuração](https://dev.epicgames.com/documentation/en-us/unreal-engine/configuration-files?application_version=4.27). Ela sustenta a hierarquia geral e o papel de Saved, mas não prova comportamento da UE 4.25/Fortnite. A [documentação atual de overrides](https://dev.epicgames.com/documentation/en-us/unreal-engine/configuration-files-in-unreal-engine) é apenas referência de sintaxe; não foi tomada como contrato dessa build. Não havia fonte UE 4.25 autorizada no ambiente e não se usou conta Epic ou acesso autenticado para obtê-la.

O literal ini: e UserDir=/SaveToUserDir existem no Shipping. A busca de LEA relativa a RIP, em ambas as seções executáveis, não ligou os identificadores selecionados a funções de leitura de configuração. A primeira seção .text tem alta entropia na amostra; isso limita uma análise estática simples e sugere codificação/proteção, sem identificar definitivamente um protetor. Nenhuma proteção do executável foi removida. Ausência de xrefs nessa heurística não prova ausência de implementação.

## Projetos externos e fontes

| Projeto / commit | Evidência consultada | Classificação | O que não foi demonstrado |
| --- | --- | --- | --- |
| LawinServer / 7f0f26d7a772c6122c42b1783fd75f497e86d3a9 | README:83 recomenda redirecionador externo, citando Fiddler/SSL | E, possivelmente F/G conforme redirecionador | Override nativo do cliente |
| FortExternalServer season-13 / e42ecddbce59163c6a60ab7506766c2a0adfe580 | ServerSettings.cpp e RemoteProcess/GameThreadBridge; perfil S13 | B para args comuns; F para controle do processo | Roteamento localhost de Account/config/lobby |
| Project Reboot 3.0 / 10c659028ad9d6816f78226483f11a884bf81f57 | README S3–S15; DLL entrypoint e hooks em dllmain.cpp | F; transporte de frontend não estabelecido | Não atribuir um redirecionador HTTPS específico sem evidência |
| ggsplayz/FortniteLauncher / 3925256986d7eb6f565b33d142d25899d3a1da07 | README cita CL14113327; Program.cs modo S13 e HybridUtils.cs | F/G; usa autenticação live e suspende EAC | Não representa uma arquitetura local permitida |
| Velocity-OGFN / 8746e8fea254be04396adc9a26d224e84032b8b4 | README, net-setup.js, launch-profiles.js, libcurl-ssl.js | D/E/F/G conforme caminho | Suporte exato a 13.40 não testado; código multiversão não é prova de compatibilidade |

Licenças consultadas: Lawin GPL-3.0, FortExternal MIT, Reboot BSD-3-Clause, Velocity MIT. O GitHub não informou licença para ggsplayz; usou-se somente leitura para referência, sem integração. Nenhum projeto adicional foi clonado/instalado ou executado.

Fontes primárias: [Lawin README fixado](https://github.com/Lawin0129/LawinServer/blob/7f0f26d7a772c6122c42b1783fd75f497e86d3a9/README.md#L83), [FortExternal ServerSettings](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Server/Private/ServerSettings.cpp), [Reboot DLL](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/dllmain.cpp), [ggsplayz S13](https://github.com/ggsplayz/FortniteLauncher/blob/3925256986d7eb6f565b33d142d25899d3a1da07/Program.cs#L372), [Velocity rede](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/launcher/net-setup.js).

## Decisão operacional

Não foi preparado experimento de INI/linha de comando: falta evidência forte de um mecanismo A/B/C **utilizável** pela Shipping. Não se aceita a presença de campos nos PAKs como prova de override em runtime. Cliente, gameserver e Fase 3 permanecem bloqueados. A próxima decisão ocorre após revisão dos três relatórios; não há comando de lançamento pronto para aprovação.
