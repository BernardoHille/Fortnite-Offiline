# Auditoria da stack — 2026-10-07

Comparação feita antes de clonar. Foram obtidos somente os dois projetos principais. Os commits efetivamente usados constam em `configs/stack.lock.json`; branches móveis não servem como lock de reprodução.

| Projeto | Evidência primária | Adequação e limites | Decisão |
| --- | --- | --- | --- |
| FortExternalServer, season-13, MIT | [README](https://github.com/OGFN-Open-sourceing/FortExternalServer/tree/season-13), [perfil fixado](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/FortniteGame/Private/Versioning/Season13BuildProfile.cpp) | Perfil específico para 13.40 / CL 14113327, Apollo, Phoebe e três bosses. Compilação não exige bibliotecas terceiras. Execução depende de controlar/alterar memória do jogo; valores padrão contradizem Apollo e bots estão desligados. Nenhuma validação de gameplay. | Gameserver principal para auditoria/compilação; execução não aprovada |
| LawinServer, main, GPL-3.0 | [README](https://github.com/Lawin0129/LawinServer), [manifesto fixado](https://github.com/Lawin0129/LawinServer/blob/7f0f26d7a772c6122c42b1783fd75f497e86d3a9/package.json) | Backend local de usuário único; Node/JSON, sem MongoDB ou token Discord. README declara suporte geral; parser lê season/build/CL do User-Agent, mas isto não comprova compatibilidade ponta a ponta com CL 14113327. Escuta upstream aberta, XMPP na porta 80 e URLs externas exigem adaptação. | Backend principal com patch estrito da Fase 1 |
| Anora, MIT | [Fontes e README](https://github.com/aryanmahalingham/Anora) | Declara foco Season 13; TypeScript, MongoDB, pnpm e integração Discord adicionam serviços/credenciais desnecessários para estudo local. Nenhuma prova independente do CL exato ou gameplay. | Não clonado; candidato somente se o backend principal mostrar limitação real |
| Velocity-OGFN, MIT | [Fontes e README](https://github.com/forevershy/Velocity-OGFN) | Node 18+, testado upstream em 22; inclui Electron, painel e fluxo com hosts/certificados. Matchmaking parcialmente stubbed. Não declara prova para o CL exato; bundle de launcher excede a Fase 1. | Não clonado; sem fallback formal |
| Project-Reboot-3.0, BSD-3-Clause | [Fontes e README](https://github.com/Milxnor/Project-Reboot-3.0) | Declara suporte S3–S15, VS2022; escopo multiversão e launcher não oferecem confirmação mais específica que season-13. Também requer análise de hooks/injeção antes de qualquer execução. | Não clonado; sem fallback formal |
| Project-Reboot, BSD-3-Clause | [README](https://github.com/Milxnor/Project-Reboot) | README descreve S13–S18 com safezone sem funcionamento e recomenda outro projeto. | Não selecionado |

## Evidência efetiva versus promessa

O código do perfil escolhido confirma a presença das referências de versão, mapa, bots e nomes Ocean/Jules/Kit. Isso é evidência estática. Compilação comprova compatibilidade do código com o ambiente local, não funcionamento dessas referências na instalação fornecida. Coordenadas, classes, armas, lógica de IA e compatibilidade de rede continuam sem teste, por determinação da Fase 1.

As instruções upstream de redirecionamento SSL, hosts, bypass ou execução do jogo não foram usadas. Licenças das fontes principais foram mantidas nos checkouts; o código não é redistribuído pelo repositório principal, que registra origem, commit e patches locais. Nenhum arquivo de jogo foi baixado ou adicionado ao Git.

## Auditoria de dependências do backend

O lock original apresentou 7 pacotes sinalizados no npm audit, incluindo severidade crítica em proxy-addr e alta em ws. Foram aplicadas somente correções compatíveis com as faixas declaradas (`npm audit fix --ignore-scripts`, sem `--force`) e o diff do lock foi preservado em `backend/patches/dependency-audit.patch`. Consulte `DEPENDENCIES.md` para as versões finais e pendências. Essas contagens descrevem o banco de advisories consultado na data da auditoria, não uma garantia geral de segurança.
