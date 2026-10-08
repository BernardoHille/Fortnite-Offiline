# PHASE 2 — ROUTING REPORT

Resultado: **ROUTE C — NATIVE ROUTING NOT FOUND**. A auditoria encontrou configurações MCP reais e referências a perfis locais, mas não comprovou um mecanismo externo suportado por esta Shipping que coloque Account/MCP/config e demais dependências exclusivamente em localhost. Não se afirma impossibilidade técnica nem se transforma hipótese em suporte confirmado.

## 1. Arquivos externos aos PAKs

Engine/Config e FortniteGame/Config não existem como diretórios externos nesta instalação. Foram inventariados e examinados 28 arquivos legíveis por extensão/nome, incluindo configurações de launchers de segurança, localização, licenças e textos legais. Não houve correspondência MCP/roteamento relevante. Nenhum arquivo de anti-cheat foi executado ou alterado.

## 2. PAKs e chaves

Os 43 PAKs de FortniteGame/Content/Paks tiveram seus índices inspecionados. Todos os índices estavam criptografados; MAIN_KEY e as 15 entradas pakchunk1000–1014 foram aceitas pela verificação SHA-1 dos índices locais. Os trechos adicionais de identificação presentes nas imagens foram separados do material AES-256. Nenhum valor de chave aparece nos relatórios, documentos públicos ou logs de saída da auditoria.

Listagem independente com repak validou os nomes dos arquivos de todos os índices. Foram retidos apenas dez INIs relevantes de pakchunk0 e os dez correspondentes de pakChunkEarly: **1.393.926 bytes**, com conteúdo idêntico entre os dois e hash de cada entrada verificado. Também foi listado o PAK separado do CrashReportClient, de índice não cifrado, e lido um INI de 411 bytes: **1.394.337 bytes retidos no total**. Não foram extraídos meshes, texturas, áudio, UAssets ou dezenas de GB. Uma seleção inicial mais ampla de INIs foi reduzida; os arquivos locais excedentes foram removidos apenas da pasta de auditoria.

Detalhes, ferramentas e tabela por PAK: [PHASE2_PAK_AUDIT.md](PHASE2_PAK_AUDIT.md).

## 3. Configurações encontradas

BaseEngine.ini e DefaultEngine.ini contêm OnlineSubsystemMcp, BaseServiceMcp, AccountServiceMcp, OnlineAccessMcp, McpProfile, GameServiceMcp e Xmpp. Confirmaram-se Protocol, Domain e o template McpClientCommandUrl. Existem ambientes Prod/Stage/GameDev/CI e seções Developer/Localhost para GameServiceMcp.

Em particular, GameServiceMcp Localhost contém Protocol=http; **não contém Domain=127.0.0.1** e não estabelece um modo local para todos os serviços. DefaultGame.ini e o plugin EarlyStartupPatcher acrescentam outros consumidores/configurações. Identificadores como ClientBaseUrl e QueryEndpointsUrl aparecem no Shipping, mas não se localizaram seus valores concretos nas configurações selecionadas.

## 4. Override encontrado ou não

Não foi comprovado override por Saved/Config, EngineIni, DefEngineIni, -ini: ou seleção McpConfig. Strings existentes — inclusive Fortnite.McpConfig, McpConfigOverride: %s e ini: — são evidência de referências, não de sintaxe/aceitação/prioridade.

A análise PE incluiu ambas as seções executáveis e busca heurística de referências RIP-relative LEA. Não recuperou ligação verificável dos identificadores selecionados com um consumidor MCP/config. A alta entropia amostrada da primeira seção limita a análise simples; não houve desempacotamento executável, remoção de proteção ou execução para obter memória decodificada.

Não foram escritos overrides especulativos nem comandos de lançamento. A hierarquia UE candidata e as limitações da referência 4.27 frente à 4.25 estão documentadas na matriz.

## 5. Projetos externos analisados

LawinServer e FortExternalServer nos commits já fixados; Project Reboot 3.0, ggsplayz/FortniteLauncher e Velocity-OGFN em commits registrados na matriz. Foram lidos apenas arquivos-fonte/documentação relevantes via GitHub oficial; nenhum launcher/redirecionador externo foi executado. Não se clonaram dezenas de projetos.

## 6. Como fazem o roteamento

Lawin delega a um redirecionador externo; sua [documentação fixada](https://github.com/Lawin0129/LawinServer/blob/7f0f26d7a772c6122c42b1783fd75f497e86d3a9/README.md#L83) cita proxy/SSL. Velocity oferece hosts e certificados, além de variantes de integração SSL. O launcher ggsplayz para o CL exato utiliza fluxo de conta live e suspensão de anti-cheat. Essas alternativas foram rejeitadas.

FortExternal e Reboot demonstram hooks/controle de processo; isso não prova que seu roteamento de frontend seja nativo. Não se atribuiu a Reboot um mecanismo HTTPS específico que não foi demonstrado pelos arquivos examinados. Classificação A–H, evidências e links fixados: [PHASE2_ROUTING_FEASIBILITY.md](PHASE2_ROUTING_FEASIBILITY.md).

## 7. Localhost

O backend próprio funciona em 127.0.0.1:3551, conforme testes anteriores. Isso não significa que o cliente real use esse endereço. Protocol/Domain e ambientes são candidatos nativos plausíveis, mas o caminho efetivo de substituição e a cobertura de todos os serviços continuam desconhecidos.

## 8. HTTP ou HTTPS

O transporte base MCP empacotado declara HTTPS; GameServiceMcp Developer/Localhost declara HTTP. Xmpp declara SSL. Nenhum desses fatos, isoladamente, prova que Account/config/lobby aceitem HTTP local nessa Shipping. Não foram instaladas CAs, criados certificados ou desativadas verificações TLS. Se HTTPS com identidade confiável exigida for obrigatório para a integração, isso é bloqueio arquitetural sob as restrições atuais.

## 9. Dependências faltando

Faltam evidências de: aceitação de overrides externos; seleção de ambiente/config e ordem de prioridade; composição de URL/porta/prefixo e AltDomains; compatibilidade da autenticação sintética com o cliente; obrigatoriedade de discovery, party/XMPP/EULA/atualização/telemetria; cobertura integral de destinos; isolamento independente que funcione em runtime. O teste Sandbox anterior falhou sem resultados do guest; não foi repetido nesta etapa.

Não falta chave para os 43 índices examinados nem ferramenta para ler os INIs selecionados. Não se pede credencial Epic, certificado, desativação de segurança ou outra build para concluir esta auditoria.

## 10. Riscos e verificações

Uma configuração MCP parcial pode deixar outros destinos live ativos. Um perfil chamado Localhost pode herdar valores de outro ambiente. BaseUrl em uma string não prova que seja o campo correto para override; protocolo HTTP em um serviço não elimina TLS dos demais. Também não há comprovação de que o envelope local permita renderizar lobby/PLAY.

O script verify-phase2-routing-audit.cjs confirmou: tamanho, data de modificação e hash de footer inalterados para cada PAK; listagens/entradas selecionadas verificadas; Shipping com o mesmo SHA-256 da entrada do ZIP original; nenhum valor AES em arquivos públicos examinados; chaves, extrações e dados temporários ignorados pelo Git. Não se recalculou hash de todo o conteúdo de 92 GB: a garantia dos PAKs combina leitura exclusiva, metadados e footers, sem alegar comparação integral byte a byte.

Não foram alterados hosts, certificados, controles de segurança, arquivos originais, gameserver ou backend. A AES foi usada exclusivamente para leitura de arquivos locais. As únicas consultas externas da pesquisa foram fontes públicas/documentação; nenhum serviço de jogo/auth/CDN live da Epic foi consultado. Fortnite e FortExternalServer não foram iniciados. Os scripts não contêm caminho de execução desses dois binários.

## 11. Conclusão e parada

**ROUTE C — NATIVE ROUTING NOT FOUND**, com configurações nativas identificadas e limitações explícitas. Escolher ROUTE A ou B exigiria demonstrar um mecanismo utilizável, além da presença das configurações. Os projetos externos examinados não forneceram esse mecanismo dentro das restrições.

Esta etapa de auditoria está encerrada para revisão. A Fase 2 continua incompleta: não houve lobby real, nome renderizado ou PLAY verificado. Não será iniciado cliente, gameserver, experimento ou Fase 3 após gerar estes relatórios.
