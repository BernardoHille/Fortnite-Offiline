# Fase 2 — cadeia de inicialização de Fortnite 13.40 / CL 14113327

Auditoria somente leitura, em 2026-10-07. **Decisão: C — fluxo normal vinculado ao Epic Launcher, autenticação e contexto de anti-cheat; nenhuma entrada independente demonstrada nas condições do projeto.** Essa decisão descreve a evidência disponível, não uma prova de impossibilidade para qualquer ambiente. O comando oficial completo dessa build não foi recuperado.

O usuário confirmou que abrir `FortniteGame/Binaries/Win64/FortniteLauncher.exe` abriu o Epic Games Launcher. Esse teste não foi repetido. **FortniteLauncher.exe deixa de ser tratado como entrada independente para o experimento.** Nenhum comando alternativo foi implementado.

## CONFIRMADO, INFERIDO e DESCONHECIDO

CONFIRMADO significa encontrado em arquivo/fonte ou relatado pelo usuário. Uma receita comunitária confirmada continua sendo apenas uma receita daquele projeto. INFERIDO significa interpretação compatível com as evidências, sem validação da cadeia oficial em runtime. DESCONHECIDO identifica lacunas que não foram preenchidas por execução.

```text
Epic Games Launcher
  │ app/ambiente e autenticação [CONFIRMADO: documentação geral Epic]
  ↓
FortniteLauncher.exe como seletor/intermediário [INFERIDO para a cadeia oficial 13.40]
  │ nomes de wrappers e modelos de argumentos [CONFIRMADO: binário local]
  ├─ FortniteClient-Win64-Shipping_BE.exe
  │    ↓ infraestrutura BattlEye / serviço [INFERIDO: funcionamento, sem execução]
  │    ↓ destino Shipping e BEArg=-frombe [CONFIRMADO: BELauncher.ini]
  └─ FortniteClient-Win64-Shipping_EAC.exe
       ↓ infraestrutura Easy Anti-Cheat [INFERIDO: funcionamento, sem execução]
       ↓ destino Shipping e repasse da linha de comando [CONFIRMADO: Settings.json]
  ↓
FortniteClient-Win64-Shipping.exe
  ↓
AUTH_* + epicapp/epicenv/locale/portal + contexto do provedor
  [INFERIDO como conjunto histórico; comando integral e valores DESCONHECIDOS]
```

O diagrama representa coordenação lógica, não parentesco direto comprovado no Windows: serviços/bibliotecas dos provedores podem participar da criação. Não exclui que a Epic inicie um wrapper diretamente pelo manifesto. Escolha BE versus EAC, entrada inicial do manifesto 13.40 e pais/PIDs oficiais permanecem DESCONHECIDOS.

O caminho observado pelo usuário foi: abertura manual de FortniteLauncher.exe → janela Epic Games Launcher. O efeito é CONFIRMADO pelo relato; mecanismo exato e parâmetros do handoff permanecem DESCONHECIDOS.

## Fontes comunitárias auditadas

FortExternalServer/LawinServer conservaram os commits do lock. Para os outros projetos, foram consultados arquivos textuais de commits fixados, sem clone completo, instalação, compilação ou execução. Esta leitura de fontes de lançamento foi solicitada pelo usuário; a auditoria de PAK/roteamento não foi reaberta.

| Projeto / commit | Evidência de lançamento | Alcance para 13.40 |
| --- | --- | --- |
| FortExternalServer season-13, `e42ecddbce59163c6a60ab7506766c2a0adfe580` | ServerSettings aponta para Shipping puro; AUTH_* fictícios, app Fortnite, Prod, locale, EpicPortal, nosplash, log e port. GameServerHost passa os argumentos a LaunchAndAttach/CreateProcessW. | Perfil da build exata, mas gameserver com controle de memória; não é cadeia oficial Epic nem prova de boot sem intervenções. |
| LawinServer, `7f0f26d7a772c6122c42b1783fd75f497e86d3a9` | README orienta iniciar backend e usar redirecionador. | Não fornece comando oficial 13.40 ou seletor de wrappers. Backend não substitui contexto de lançamento. |
| Project-Reboot-3.0, `10c659028ad9d6816f78226483f11a884bf81f57`; Project-Reboot, `5c9f3861a451ac8d9cac6e83d4353bfeb8700230` | 3.0 recomenda Reboot Launcher. Fontes de entrada/game mode consultadas não forneceram comando AUTH_* ou CreateProcess do cliente. Os repositórios Milxnor são gameservers. | Suporte multiversão anunciado não prova comando histórico do CL. A busca nos arquivos consultados não é prova de ausência em todo o repositório. |
| ggsplayz/FortniteLauncher, `3925256986d7eb6f565b33d142d25899d3a1da07` | Program.cs inicia Shipping diretamente com AUTH_*, app/env/portal, seleção de provedor, token fixo e skippatchcheck; inicia/suspende auxiliares e substitui DLLs para redirecionar. S13 Hybrid obtém autenticação live. | README cita 13.40-CL-14113327, mas os mecanismos excedem as restrições. A variável FortniteBEEXE aponta para FortniteLauncher.exe; esse nome não prova papel BattlEye do arquivo. |
| Velocity-OGFN, `8746e8fea254be04396adc9a26d224e84032b8b4` | Condições para 13.40 selecionam Shipping direto, código de autenticação no backend do projeto, contexto/seleção de provedor, stub do launcher, bloqueio de arquivos anti-cheat e alterações TLS/redirecionamento. | Ramo multiversão que abrange 13.40; não é captura histórica oficial nem prova do CL. |

Fontes fixadas: [FortExternal ServerSettings](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Server/Private/ServerSettings.cpp), [GameServerHost](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Server/Private/GameServerHost.cpp), [Lawin README](https://github.com/Lawin0129/LawinServer/blob/7f0f26d7a772c6122c42b1783fd75f497e86d3a9/README.md), [Reboot 3.0 README](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/README.md), [Reboot entrada](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/dllmain.cpp), [Reboot game mode](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/FortGameModeAthena.cpp), [Reboot antigo README](https://github.com/Milxnor/Project-Reboot/blob/5c9f3861a451ac8d9cac6e83d4353bfeb8700230/README.md), [ggs Program.cs](https://github.com/ggsplayz/FortniteLauncher/blob/3925256986d7eb6f565b33d142d25899d3a1da07/Program.cs), [ggs README](https://github.com/ggsplayz/FortniteLauncher/blob/3925256986d7eb6f565b33d142d25899d3a1da07/README.md), [Velocity auth-launch](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/launcher/auth-launch.js), [launch-profiles](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/launcher/launch-profiles.js) e [launch-game](https://github.com/forevershy/Velocity-OGFN/blob/8746e8fea254be04396adc9a26d224e84032b8b4/launcher/launch-game.js).

Complemento separado: **Auties00/Reboot-Launcher**, commit `c6f82298b167ef2076bb59dc621f13dc5bd8d390`, launcher comunitário do ecossistema Reboot, não o gameserver Milxnor. createRebootArgs monta AUTH_* por password, app/env/locale/portal, skippatchcheck, seleção de provedor, token fixo e Caldera fixo. O botão inicia Shipping e possui fluxo de injeção; flags de host/log/headless são condicionais. O conjunto não é específico de 13.40: Caldera nesse código não comprova exigência da build. Fontes: [game_metadata.dart](https://github.com/Auties00/Reboot-Launcher/blob/c6f82298b167ef2076bb59dc621f13dc5bd8d390/common/lib/src/game/game_metadata.dart) e [game_start_button.dart](https://github.com/Auties00/Reboot-Launcher/blob/c6f82298b167ef2076bb59dc621f13dc5bd8d390/gui/lib/src/button/game_start_button.dart).

## Classificação dos argumentos encontrados

Valores de autenticação, tokens fixos e identidades não são reproduzidos. Este inventário não é linha de comando para executar. Nenhum argumento foi aplicado.

| Argumento / família | Categoria | Interpretação e limite |
| --- | --- | --- |
| AUTH_LOGIN, AUTH_PASSWORD | Autenticação | Identificador/material de login. No fluxo de código, password transporta o código e login pode ser unused. Valores fictícios upstream não tornam o fluxo offline. |
| AUTH_TYPE=epic / exchangecode | Autenticação | Modos encontrados; password comunitário não comprova lançamento oficial da build. |
| epicapp=Fortnite | Seleção de app/environment | Nome usado pelas fontes; nome do manifesto histórico não recuperado. Não é endereço do backend. |
| epicenv=Prod | Seleção de app/environment | Ambiente do produto, não redirecionamento local. |
| epiclocale | Normal Fortnite/UE | Idioma; não autentica nem escolhe servidor. |
| epicportal / EpicPortal | Seleção de app/environment | Marca contexto Epic Games Store; não comprova sessão válida. |
| epicusername, epicuserid | Autenticação / contexto de identidade | Metadados da identidade do launcher; escrever nomes não cria autenticação válida. |
| log, nosplash, nosound, nullrhi | Normal Fortnite/UE | Logging, apresentação, áudio e renderização headless; também presentes em caminhos de host. Não comprovam suporte/efeito na Shipping 13.40. |
| server, messaging, nosteam | Normal UE / contexto de gameserver | Encontrados no host Velocity; não demonstrados como argumentos normais do cliente Epic 13.40. |
| port / PORT | Normal UE / contexto de gameserver | Porta de jogo/host nas fontes, não endpoint MCP. |
| Playlist | Contexto de gameserver / extensão comunitária | Seleção usada pelo host; suporte nativo da Shipping não demonstrado. |
| HTTP=WinInet | Normal UE, empregado em redirecionamento comunitário | Seleciona implementação HTTP nas fontes, não um backend localhost. Efeito em 13.40 não testado. |
| noeac, nobe | Anti-cheat; bypass conforme contexto | O launcher original contém modelos que excluem o provedor alternativo ao selecionar BE/EAC. Não são automaticamente prova de bypass. Desativar ambos/forçar Shipping com intervenções upstream não demonstra cadeia protegida normal. |
| fromfl=be / eac / none | Anti-cheat / contexto do launcher | Marcadores no launcher original. Não substituem contexto real; none não comprova boot independente permitido. |
| frombe | Anti-cheat | BEArg no BELauncher.ini. ggs também passa esse argumento ao EAC em um ramo; não presumir que essa receita represente sequência oficial. |
| fltoken | Anti-cheat / contexto do launcher; bypass em receitas fixas | Prefixo no launcher original; comunidades usam constantes para imitar contexto. Geração/validação/valor oficial DESCONHECIDOS; nenhum valor usado. |
| skippatchcheck | Patch/bypass de verificação de atualização | Fontes comunitárias e referência na Shipping; não demonstrado como parte da linha oficial Epic. |
| bVerifyPeer, n.VerifyPeer, ini:Engine com VerifyPeer desativado | Patch/bypass TLS, empregado em redirecionamento | Velocity tenta reduzir validação TLS. Não é roteamento permitido; existência no código não prova eficácia na build. |
| EditOnRelease, InstantReset, SprintByDefault, DisablePreEdit | Extensão comunitária / possível patch | Mods opcionais Velocity; suporte nativo 13.40 DESCONHECIDO. Não são requisitos Epic demonstrados. |
| caldera | Autenticação / anti-cheat, reutilizado em receita comunitária | Reboot-Launcher usa valor genérico fixo; Velocity condiciona a versões posteriores. Não demonstrado como requisito 13.40. |
| noeaceos, epicsandboxid | Anti-cheat/bypass e seleção de app/environment | Ramos Velocity posteriores a 13.40. Não transferir requisitos de UE5/EOS moderno para esta build. |

A semântica geral de AUTH_*/app/env/identidade/locale e a entrega de código pelo launcher constam da [documentação Epic de autenticação](https://dev.epicgames.com/docs/web-api-ref/authentication?lang=en-US&sessionInvalidated=true). É documentação atual e geral, **não manifesto/captura oficial de 13.40**. Os endpoints EOS modernos dessa página não foram presumidos para a build nem consultados. A [referência UE de argumentos](https://dev.epicgames.com/documentation/unreal-engine/unreal-engine-command-line-arguments-reference?lang=en-US) auxilia a classificação geral, sem provar disponibilidade na Shipping histórica.

Redirecionamento nas fontes também envolve ações fora da linha de comando: proxy/redirecionador no Lawin, substituição de DLLs no ggs e alterações de hosts/certificados/TLS no Velocity. Nada foi reproduzido. Não foi encontrada receita comprovada de 13.40 baseada só em argumentos normais que eliminasse autenticação e contexto protegido.

## FortniteLauncher.exe — análise somente leitura

333.056 bytes; PE x64; Authenticode **Valid**, signatário Epic Games Inc. SHA-256: `678e8ed73ed09f5545bf46df036f28284c5e01a9af7b953ad3545d1f3ad1444e`.

| Evidência | Estado | Alcance |
| --- | --- | --- |
| Imports CreateProcessW / ShellExecuteExW | CONFIRMADO | Mecanismos de criação de processo/abertura via shell existem. Imports não identificam destino, parâmetros ou ramo executado. |
| RegOpenKeyExW / RegQueryValueExW e referências EAC/GamesInstalled | CONFIRMADO | Referências de detecção/configuração. Nenhuma chave do registro do usuário foi consultada. |
| Nomes Shipping_BE.exe, Shipping_EAC.exe e Shipping.exe | CONFIRMADO | O launcher conhece os três destinos. |
| Modelos `-noeac -fromfl=be`, `-nobe -fromfl=eac`, `-noeac -nobe -fromfl=none` e prefixo fltoken | CONFIRMADO | Literais UTF-16 nos offsets de arquivo 0x9408, 0x9480, 0x9500 e 0x95c8. Condições e uso efetivo não recuperados. |
| BELauncher.ini / EAC Launcher Settings.json | CONFIRMADO | Referências às configurações de ambos os provedores. |
| URI/protocolo Epic exato | DESCONHECIDO | Busca ASCII/UTF-16 não encontrou com.epicgames.launcher, EpicGamesLauncher, apps/Fortnite ou launch?action=launch. Ausência de literal não prova ausência de construção dinâmica. |
| App name/parâmetros do handoff | DESCONHECIDO | Fortnite é consistente com fontes/configurações, mas nenhum app name de URI/manifesto foi ligado à abertura relatada. |
| Mecanismo que abriu Epic | INFERIDO / DESCONHECIDO | Relato confirma efeito; shell/process invocation são possibilidades. Chamada e argumentos finais não demonstrados. |

A desassemblagem linear com dumpbin instalado não estabeleceu referências de código confiáveis entre literais e chamadas. O PE contém duas seções .text; não foi inventado fluxo de controle a partir de trechos sem interpretação útil. Não houve unpack em runtime, carregamento do PE, debugger, patch ou execução para esclarecer a lacuna. Portanto nenhuma URI específica foi recuperada/confirmada.

## Shipping / BE / EAC

Arquivos sob `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64`:

| Arquivo | Tamanho / arquitetura | Papel confirmado |
| --- | --- | --- |
| FortniteClient-Win64-Shipping.exe | 174.908.672 bytes / x64 | Cliente principal; captura anterior confirmou execução em três PIDs, sem provar boot completo ou parentesco com wrappers. |
| FortniteClient-Win64-Shipping_BE.exe | 759.040 bytes / x86 | Launcher BattlEye, referências a BELauncher.ini/BEService; INI define destino x64 Shipping. |
| FortniteClient-Win64-Shipping_EAC.exe | 1.092.864 bytes / x86 | Launcher Easy Anti-Cheat, biblioteca EAC x86 e metadados ExecutablePath/LaunchParameters; Settings.json define destino x64 Shipping. |

Wrappers x86 podem coordenar cliente x64; a diferença não indica outra build. As configurações foram apenas lidas:

- `BattlEye/BELauncher.ini`: GameID=fn; 64BitExe=FortniteClient-Win64-Shipping.exe; BEArg=-frombe. BasePort nesse arquivo é contexto BE, não porta MCP.
- `EasyAntiCheat/Launcher/Settings.json`: executable=FortniteClient-Win64-Shipping.exe; parameters vazio; use_cmdline_parameters=1; wait_for_game_process_exit=1. Isso configura repasse dos parâmetros recebidos, sem fornecer sozinho contexto autenticado.

**Qual era normalmente usado pela Epic?** Compatível com FortniteLauncher selecionando BE ou EAC, ambos coordenando o mesmo Shipping. Não há prova de BE único, EAC único ou ambos em série. Manifesto oficial e árvore normal dessa build não foram obtidos.

**Shipping puro normalmente é filho de BE/EAC?** É destino configurado de ambos, CONFIRMADO. Criação protegida por essas infraestruturas é INFERIDA; pai imediato no Windows é DESCONHECIDO. O PML anterior sem Process/Thread não resolve parentesco.

**Argumentos normais que chegam ao Shipping?** EAC configurado para repassar linha recebida; BE define frombe. AUTH_*/app/env/locale/portal e contexto do provedor são a estrutura mais consistente com fontes/documentação. Sequência completa, valores, aspas, adicionais e seleção oficial para o CL permanecem DESCONHECIDOS. Não montar os modelos como novo comando.

Hashes para identificar os arquivos auditados:

- Shipping: `fb348e9a239a52170f2b46e99c225d4ec2bded53e40f8e7ff9daec3ac39a9f21`.
- BE: `5cbec8cf100c30beab2c8d0d7af37daf4f838311cf405d2eaa2ad9c5c678d5e2`.
- EAC: `f527c55993fdbb9bb9a27b4c66c12f4f81bdca3f40a266c608b02aa63a00a648`.

## Resultado A/B/C e parada

| Alternativa | Resultado |
| --- | --- |
| A. Forma normal local sem infraestrutura live | **NÃO DEMONSTRADA** sob as restrições. |
| B. Shipping inicia, mas depende de contexto adicional | **PARCIALMENTE CONFIRMADA**: início anterior observado; contexto faltante e boot normal completo não identificados. |
| C. Fluxo normal depende de Epic Launcher/auth/anti-cheat, sem entrada independente demonstrada | **DECISÃO ADOTADA** para este projeto. Estrutura inferida de documentação, referências/configurações e relato; seleção/comando histórico exatos desconhecidos. |

C não transforma a captura anterior em execução controlada conclusiva: ela segue inconclusiva conforme [PHASE2_RUNTIME_OBSERVATION](PHASE2_RUNTIME_OBSERVATION.md). Esta auditoria não diagnostica a causa específica de saída de cada PID.

Nenhum Fortnite, wrapper, gameserver ou código upstream foi executado. Nenhuma credencial/código de troca foi criado, obtido ou usado. Não houve conta Epic, chamada de autenticação/live, suspensão, injeção, patch ou alteração de hosts/proxy/certificados. Consultas externas limitaram-se a GitHub/documentação pública. Metadados, fontes consultadas e desassemblagem ficam privados em `runtime/phase2/launch-chain-audit/`, ignorado pelo Git. Nenhum código de lançamento foi implementado.

**PARADA:** relatório concluído; não repetir FortniteLauncher.exe nem tentar outro executável/argumentos. Fase 2 permanece sem lobby demonstrado; Fase 3 não iniciada.
