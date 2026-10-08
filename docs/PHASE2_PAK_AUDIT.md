# Auditoria dos PAKs — Fase 2

Inspeção somente leitura para descobrir configuração MCP, sem execução de Fortnite/gameserver. Foram listados 43 PAKs do jogo e o PAK separado do CrashReportClient. Não foram extraídos assets nem publicados valores de chave.

## Ferramentas e proveniência

[repak](https://github.com/trumank/repak) v0.2.3, release oficial, commit e215472c51db69328b1ce77be2db24d24c1d646b; licença MIT OR Apache-2.0. ZIP portátil conferido contra digest SHA-256 publicado pelo GitHub. Binário executado apenas como ferramenta de arquivo, com --version/list/get; não carrega código da build. Possui também modos de escrita, que não foram utilizados. Não houve instalação global.

O leitor Node local abre cada PAK com modo r, decifra índices em memória e produz cópias compactas contendo apenas índices dentro de runtime. repak lista essas cópias sem receber AES por argumento de processo. As listagens foram comparadas ao parser local. A extração seletiva usa Node crypto/zlib, com verificação do SHA-1 de cada entrada; nenhum DLL de compressão do jogo é carregado. O formato foi baseado no código repak auditado no commit 355b5f62f51959c7cc6dd5a51708646ef483065d; a listagem independente usa o release acima. A licença/atribuição da adaptação está em scripts/repak-LICENSE-MIT.txt.

O get foi usado somente para um INI do PAK CrashReportClient, cujo índice não exige chave. Ferramentas e fontes públicas foram obtidas do GitHub oficial; nenhum EXE da instalação Fortnite foi executado.

## Chaves

MAIN_KEY: available, accepted. pakchunk1000–pakchunk1014: available, accepted. São 16 entradas AES-256, armazenadas exclusivamente em configs/aes-keys.local.json, ignorado pelo Git. A apresentação das entradas dinâmicas inclui um identificador adicional; ele não faz parte dos 32 bytes AES. A validação efetiva usa o SHA-1 do índice decifrado, e não somente tamanho/formato da imagem. Erros de transcrição inicial foram corrigidos e todas as entradas foram verificadas. Não houve uso das chaves como credenciais, tokens, sessões ou autenticação.

Todos os 43 índices do jogo exigem criptografia e aceitaram a chave selecionada. O rodapé identifica os PAKs dinâmicos com GUID não nulo; MAIN_KEY não é presumida como substituta dessas chaves. Criptografia de índice e de conteúdo são propriedades distintas: nem todo asset de um PAK com índice cifrado é cifrado. Os INIs selecionados do jogo são cifrados.

## PAKs do jogo inspecionados

Todos: formato PAK 11, índice cifrado, listagem independente conferida. Formato 11 não foi usado para inferir automaticamente a versão/fork do engine. A correspondência de chave cobre cada índice; a criptografia dos INIs extraídos também foi verificada. Os demais assets não foram decifrados ou extraídos.

| PAK em FortniteGame/Content/Paks | Chave selecionada | Resultado do índice | Configurações retidas |
| --- | --- | --- | --- |
| pakchunk0-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 10 |
| pakchunk10-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk1000-WindowsClient.pak | pakchunk1000 | accepted + SHA-1 + repak list | 0 |
| pakchunk1001-WindowsClient.pak | pakchunk1001 | accepted + SHA-1 + repak list | 0 |
| pakchunk1002-WindowsClient.pak | pakchunk1002 | accepted + SHA-1 + repak list | 0 |
| pakchunk1003-WindowsClient.pak | pakchunk1003 | accepted + SHA-1 + repak list | 0 |
| pakchunk1004-WindowsClient.pak | pakchunk1004 | accepted + SHA-1 + repak list | 0 |
| pakchunk1005-WindowsClient.pak | pakchunk1005 | accepted + SHA-1 + repak list | 0 |
| pakchunk1006-WindowsClient.pak | pakchunk1006 | accepted + SHA-1 + repak list | 0 |
| pakchunk1007-WindowsClient.pak | pakchunk1007 | accepted + SHA-1 + repak list | 0 |
| pakchunk1008-WindowsClient.pak | pakchunk1008 | accepted + SHA-1 + repak list | 0 |
| pakchunk1009-WindowsClient.pak | pakchunk1009 | accepted + SHA-1 + repak list | 0 |
| pakchunk1010-WindowsClient.pak | pakchunk1010 | accepted + SHA-1 + repak list | 0 |
| pakchunk1011-WindowsClient.pak | pakchunk1011 | accepted + SHA-1 + repak list | 0 |
| pakchunk1012-WindowsClient.pak | pakchunk1012 | accepted + SHA-1 + repak list | 0 |
| pakchunk1013-WindowsClient.pak | pakchunk1013 | accepted + SHA-1 + repak list | 0 |
| pakchunk1014-WindowsClient.pak | pakchunk1014 | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s1-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s10-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s11-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s12-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s13-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s14-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s15-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s16-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s17-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s18-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s19-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s2-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s20-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s3-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s4-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s5-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s6-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s7-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s8-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk10_s9-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk2-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk5-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk7-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk8-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakchunk9-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 0 |
| pakChunkEarly-WindowsClient.pak | MAIN_KEY | accepted + SHA-1 + repak list | 10 |

Também foi listado Engine/Programs/CrashReportClient/Content/Paks/CrashReportClient.pak: formato 11, índice não cifrado, 6.476 entradas e nenhuma chave necessária. Foi lido somente Engine/Programs/CrashReportClient/Config/DefaultEngine.ini (411 bytes). O SHA-256 do PAK completo foi igual antes e depois dessa leitura. Os PAKs de recursos Chromium/CEF não foram tratados como contêineres Unreal, nem extraídos.

## Configurações selecionadas

Os dez caminhos abaixo foram extraídos de pakchunk0 e pakChunkEarly. Cada par apresentou conteúdo idêntico e o hash de cada entrada foi validado. Nenhum INI original foi modificado.

| Caminho virtual | Bytes por cópia | Relevância |
| --- | --- | --- |
| Engine/Config/BaseEngine.ini | 133188 | MCP/serviços e base de configuração |
| Engine/Config/Windows/WindowsEngine.ini | 466 | Hierarquia de plataforma |
| FortniteGame/Config/DefaultEngine.ini | 214537 | MCP/serviços e base de configuração |
| FortniteGame/Config/DefaultGame.ini | 334516 | Serviços e contexto do jogo |
| FortniteGame/Config/DefaultRuntimeOptions.ini | 875 | Configuração runtime/plataforma |
| FortniteGame/Config/Windows/WindowsEngine.ini | 1052 | Hierarquia de plataforma |
| FortniteGame/Plugins/Runtime/FortniteEarlyStartupPatcher/Config/DefaultFortniteEarlyStartupPatcher.ini | 11498 | Configuração do atualizador inicial |
| FortniteGame/Plugins/Runtime/FortniteEarlyStartupPatcher/Config/Game.ini | 211 | Configuração do atualizador inicial |
| FortniteGame/Config/WindowsClient/WindowsClientEngine.ini | 538 | Hierarquia de plataforma |
| FortniteGame/Config/WindowsClient/WindowsClientRuntimeOptions.ini | 82 | Configuração runtime/plataforma |

Seleção final: 20 cópias de INIs do jogo (1.393.926 bytes), mais o INI CrashReportClient (411 bytes); total 1.394.337 bytes. Dez caminhos do jogo, sem extração massiva. Uma seleção inicial genérica de INIs foi estreitada; os arquivos excedentes da pasta temporária foram removidos.

## Achados de configuração

BaseEngine.ini: seções OnlineSubsystemMcp e BaseServiceMcp. DefaultEngine.ini: AccountServiceMcp, OnlineAccessMcp, McpProfile, GameServiceMcp e Xmpp, com variantes por ambiente. Protocol=https na base; Protocol=http somente em perfis Developer/Localhost do serviço de jogo. O perfil Localhost desse serviço não contém Domain loopback. McpClientCommandUrl é um template relativo, sem indicar destino completo.

Não se localizaram valores ClientBaseUrl/BaseUrl/QueryEndpointsUrl/QueryServiceStatusUrl/ClientUrlContext nos INIs selecionados; referências a esses identificadores no executável não provam valores nem prioridade. A necessidade dos outros serviços e a aceitação de overrides externos permanecem desconhecidas. Valores sensíveis ou de autenticação embutidos em fontes/configurações não foram copiados para documentação pública ou utilizados.

## Artefatos locais e integridade

runtime/phase2/pak-audit contém índices compactos, listagens, vinte INIs selecionados do jogo, o INI do CrashReportClient, achados sanitizados, provas de hash e proveniência de ferramentas. Esses arquivos e quaisquer imagens/textos auxiliares de transcrição ficam ignorados. Chaves não foram passadas em command line, impressas em logs de saída ou incluídas neste relatório.

verify-phase2-routing-audit.cjs verificou que os 43 PAKs mantêm tamanho, mtime e hash do rodapé; a leitura foi exclusiva e nenhum original foi aberto para escrita. Não foi recalculado SHA-256 de todos os 92 GB, portanto não se alega comparação integral de todos os bytes. Shipping foi comparado por SHA-256 à entrada do ZIP original e permanece igual. O PAK pequeno do CrashReportClient teve comparação integral adicional.

## Conclusão

As chaves desbloquearam a leitura de configurações que antes eram desconhecidas. A existência de configurações não demonstra que a Shipping aceite Saved/Config, argumentos INI ou configuração MCP personalizada. A conclusão de roteamento continua ROUTE C, conforme PHASE2_ROUTING_FEASIBILITY.md e PHASE2_ROUTING_REPORT.md. Nenhum experimento de override ou lançamento foi executado.
