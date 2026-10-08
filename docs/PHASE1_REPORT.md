# Relatório da Fase 1 — 2026-10-07

## Build

ZIP original localizado: `13.40-CL-14113327.zip`; caminho real registrado somente na configuração e logs locais ignorados. Tamanho: 42.358.852.229 bytes. SHA-256: `3ee0440fd5299af6b856d85eaa82198ef9ec1098a9112ec8ff3df5d0be1857c8`.

Estrutura Engine/FortniteGame/Win64/Shipping verificada. String interna `++Fortnite+Release-13.40-CL-14113327` encontrada por leitura do Shipping, confirmando sua identificação declarada. Isso não autentica a procedência e não equivale a CRC integral de todos os membros do ZIP. A pasta extraída contém uma camada adicional `13.40`.

Extração externa autorizada e concluída. Inventário independente após a extração: 429 arquivos previstos, 429 arquivos presentes, 92.857.442.082 bytes previstos e presentes, nenhuma divergência de caminho ou tamanho. Validação estrutural e da string de versão repetida após a extração. A instalação permanece fora do Git; os arquivos extraídos não foram modificados ou executados.

## Stack e ambiente

| Componente | Branch | Commit |
| --- | --- | --- |
| FortExternalServer | season-13 | `e42ecddbce59163c6a60ab7506766c2a0adfe580` |
| LawinServer | main | `7f0f26d7a772c6122c42b1783fd75f497e86d3a9` |

Visual Studio 2022 17.14, MSVC v143 14.44.35207, SDK 10.0.26100.0, Git 2.55.0, Node 22.23.1, npm 10.9.8 e PowerShell 7.6.5 já disponíveis. CMake 3.31.6 está incluído no VS; .NET 9.0.312 instalado, mas não requerido. Nenhuma dependência obrigatória faltando; Python real não foi verificado e não é usado.

## O que funcionou e limites

- Gameserver compilou em Release x64, sem erro, com avisos C4100 de parâmetros não usados. Binário produzido permaneceu no checkout ignorado; não foi executado nem copiado para a build.
- Backend iniciou somente em `127.0.0.1:3551`, `/health` respondeu, rotas do jogo retornaram 503 e encerrou com código 0. XMPP e matchmaking não foram iniciados. O teste foi repetido com as dependências corrigidas.
- Restauração pelos commits e patches passou; o script é idempotente nos checkouts preparados. npm ci executado sem lifecycle scripts. Guards impediram tentativas de conexões externas e processos filhos antes de qualquer acesso.
- Scripts PowerShell analisados sem erro de sintaxe; diagnóstico encontrou todos os requisitos da rota MSBuild. Extração recusou destino dentro do repositório; Git ignorou os padrões de arquivos proprietários, runtime, logs e configuração pessoal.
- Auditoria npm reduziu 7 pacotes sinalizados para 2 moderados (`qs` e `uuid`), sem alertas altos/críticos. Não houve upgrade major forçado; detalhes e versões em DEPENDENCIES.
- Suporte de gameplay não testado. O gameserver usa controle/patches de memória; sua execução não foi aprovada. Mapa padrão aponta Athena em vez de Apollo, bots/bosses estão desligados e posições dos bosses são provisórias. São pendências para fases futuras.
- A primeira tentativa de extração parou por um cálculo de progresso incompatível com tamanho acima de Int32. O script foi corrigido para Int64 e a extração reiniciada em um destino novo. A pequena pasta parcial foi preservada fora do Git porque a revisão automática rejeitou a limpeza por política.

## Critérios da Fase 1

- [x] Build localizada.
- [x] Build validada estruturalmente.
- [x] SHA-256 registrado.
- [x] Build fora do Git.
- [x] Arquitetura documentada.
- [x] Dependências documentadas.
- [x] Gameserver escolhido.
- [x] Backend escolhido.
- [x] Gameserver compilado.
- [x] Backend iniciando localmente.
- [x] Scripts de diagnóstico funcionando.

Fase 1 concluída pelos critérios definidos, incluindo a extração posteriormente autorizada. A decisão necessária para trabalho futuro é a autorização explícita da Fase 2; nenhuma credencial ou instalação manual é solicitada. Fortnite nunca foi iniciado. Não houve conexão aos serviços live da Epic, alteração da conta ou modificação dos arquivos da build extraída.
