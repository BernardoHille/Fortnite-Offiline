# BOT-2 — ensaio manual de navegação

**BOT2 PARTIAL — ensaio executado pelo usuário em 07/10/2026, classificado NAV-A.** As consultas funcionaram, mas o bot não caminhou. O Codex não iniciou Launcher, host, cliente ou jogo. Limitações principais: GetNavDataForProps/seleção exata de NavData e associação interna MovementComp/request id permanecem UNKNOWN. Ver [BOT2_NAV_DIAGNOSTICS.md](BOT2_NAV_DIAGNOSTICS.md) e [BOT2_REBOOT_AI_SETUP.md](BOT2_REBOOT_AI_SETUP.md).

## Resultado observado — 23:49–23:50, 07/10/2026

DLL bot2-navdiag confirmada na linha 2589 do launcher.log fornecido. Recorte técnico privado: `reboot/audit/bot2-test-20261007-2349.local.txt`, 327 eventos BOT/NAV com números de linha originais. Um spawn válido às 23:49:34; dois MoveTo efetivos, ambos Failed, às 23:49:56 e 23:50:24.

| Consulta | Resultado confirmado |
| --- | --- |
| NavDataSet | available=true, count=0 (linha 11191) |
| NavigationData no World | Um ator: AbstractNavData-Default; nenhum AthenaNavMesh enumerado |
| Bounds | Um NavMeshBoundsVolume; extensão/tiles não consultados |
| BotProjection / PlayerProjection | APIs disponíveis; ambas success=false |
| FindPathToLocationSynchronously | Chamada submetida; retorno null, nenhum NavigationPath obtido |
| DefaultAgentName | Phoebe; SupportedAgents contém Husk, Smasher, Graph, Phoebe, Deimos |
| Agente do bot | Radius=42, Height=150, PreferredNavData=/Script/FortniteGame.AthenaNavMesh |
| Navegação em construção/bloqueada | building=false, building_or_locked=true; indica bloqueio, origem desconhecida |
| Bloqueio inicial Athena | Getter unavailable; o false de saída não comprova bloqueio inativo |
| PathFollowing | Idle e current path null antes/depois; ownership correto, associação MovementComp ainda UNKNOWN |

O sistema AthenaNavSystem existe, mas seu NavDataSet está vazio. Isso sustenta investigar criação/registro/streaming de AthenaNavMesh antes de comportamento. Não identifica a instrução nativa exata que retorna Failed nem o responsável pelo bloqueio. Main/Default null no logger também pode significar property indisponível; a evidência forte é NavDataSet available=true/count=0. Brain null não foi estabelecido como causa. Não foram ativados setup/BT nem modificados source/DLLs durante a leitura desse log.

A ordem usada foi Spawn → Move → Projection → Path → Dump Nav → Dump Bot → Move; o humano mudou de posição entre consultas. Portanto elas não representam exatamente o mesmo par de pontos. A ausência de NavData foi observada no snapshot do World; cobertura dos bounds e escolha nativa exata do agente continuam desconhecidas.

## DLL e configuração

Fechar normalmente a sessão anterior antes de trocar a DLL. No Launcher compilado, **Settings → Internal files → Game server → Game server type = Custom**, selecionar no **primeiro campo Game server**, anterior à Season 20:

`D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\bot2-navdiag\Project Reboot 3.0.dll`

Não selecionar o campo após Season 20 nem alterar auxiliares. Confirmar no próximo log a linha de carregamento bot2-navdiag. Preservar Backend Embedded / 127.0.0.1 / Detached Off; Host 13.40 CL14113327 / Headless On / restart Off / porta7777 / argumentos vazios / players required1 / Private IPs operator e No MCP marcados. A etapa não valida desconexão da internet; o baseline funcional foi com conexão.

## Ordem exata

1. Iniciar Host normalmente e aguardar Apollo/listening :7777.
2. Cliente entrar pelo Play do Reboot, lobby e conexão local habituais.
3. Entrar na partida.
4. Acionar Start Bus no painel dev do **HOST**.
5. Saltar com o cliente.
6. Pousar em chão terrestre aberto/plano, fora de água/interiores/telhados/penhascos.
7. Na aba **Game → Bots** do menu dev do HOST, clicar **Spawn 1 Bot** uma vez. Confirmar bot visível. Afastar o humano **10–30 m**, na mesma altitude aproximada, e mantê-lo parado durante a sequência seguinte.
8. **Dump Bot State**: aguardar o bloco [BOT], conferir posse/componentes.
9. **Dump Nav State**: aguardar NAV STATE/END NAV STATE.
10. **Test Nav Projection**: aguardar BotProjection, PlayerProjection e projection summary.
11. **Test Path To Player**: aguardar path request/result/pontos, ou razão de API/query indisponível.
12. **Somente depois**, clicar **Move Bot To Player** uma vez. Aguardar snapshots [NAV] before/after, Move result [BOT] e, se aceito, observar o cliente por ~5 s.

Não clicar todos os botões juntos: a fila aceita uma ação pendente e recusa outras, sem retry. Cada botão executa sua operação somente naquele clique, sem automatizar o próximo teste. Dump/queries não movem bot; Move continua o pedido explícito existente. Uma sessão aceita apenas uma tentativa nativa de spawn; reiniciar host normalmente para outro bot.

Se útil, repetir Projection/Path/Move em **um segundo ponto aberto** com o mesmo bot, humano novamente parado e sem movimentação AI ativa do ensaio anterior. Não testar dez locais nem reiniciar sistemas. Manter ambos fora do raio 400 UU antes do Move. Skin/combate/Brain não fazem parte do ensaio.

## O que devolver

- Confirmação técnica da DLL carregada, sem argumentos AUTH.
- Todos os eventos **[BOT] e [NAV]** dessa sessão, do spawn até o último diagnóstico/Move.
- Dump Nav: Main/Default/NavDataSet, atores NavData/bounds, SupportedAgents, NavAgentProps e origem do extent/filtro; estado do bloqueio inicial Athena e metadados de IsNavmeshInRadiusInitialized.
- Projeção: posições, available/success e outputs do bot/humano. API unavailable é diferente de false nativo.
- Path: contexto Controller, Start/End e origem do Start, result Valid/Partial/Success/Fail/Unknown, quantidade de pontos.
- Snapshots de PathFollowing antes/depois do Move, status/destino/current path copy e campos UNKNOWN.
- Relato visual: local do mapa/terreno, distância, se bot andou, permaneceu imóvel ou host crashou. Screenshot opcional.

O launcher.log é `D:\Games\Fortnite-Local-C2S3\reboot\artifacts\launcher\Release\launcher.log`; o logger também escreve reboot.log no cwd do host. Preservar a sessão antes de reiniciar/truncar logs. Extrair apenas eventos técnicos dos dois prefixos:

```powershell
$bot2InputLog = 'D:\Games\Fortnite-Local-C2S3\reboot\artifacts\launcher\Release\launcher.log'
$bot2EventsFile = 'D:\Games\Fortnite-Local-C2S3\reboot\audit\bot2-navdiag-test-events.local.txt'
Get-Content -LiteralPath $bot2InputLog |
  Where-Object { $_ -match '\[(BOT|NAV)\]' -and $_ -notmatch '(?i)AUTH_|password|exchange|token' } |
  Set-Content -LiteralPath $bot2EventsFile -Encoding utf8
```

Esse recorte pode conter sessões anteriores; indicar a sessão nova pela hora/carregamento bot2-navdiag. A linha de carregamento da DLL não está incluída por esse filtro: compartilhar separadamente só o path técnico. Não publicar arquivo bruto com credenciais. Em crash, conservar [NAV][FAIL]/[BOT][FAIL] e diagnóstico do handler normal existente.

## Matriz de diagnóstico

| Código | Resultado | Interpretação para investigar |
| --- | --- | --- |
| NAV-A | BotProjection nativa false | Origem/cobertura/NavData da projeção; compatibilidade do agente ainda precisa ser distinguida |
| NAV-B | BotProjection true, PlayerProjection false | Destino/cobertura/NavData da projeção |
| NAV-C | Ambas true, path Fail | Seleção de NavData do Controller, agente, filtro, start/pathfinding; projeção default não prova compatibilidade com bot |
| NAV-D | Ambas true, path Success completo, Move Failed | Controller/PathFollowing/aceitação da request tornam-se candidatos; conferir igualdade de contexto/filtros/pontos antes de concluir |
| NAV-E | Path Success, Move RequestSuccessful, bot imóvel | Execução PathFollowing/Movement/replicação; observar samples BOT e cliente |
| NAV-F | Projeções/path completos, Move aceito e caminhada comprovada | BOT-1 convertido em SUCCESS para esse ensaio |

Path **Partial** não é Success completo: BOT-1 envia bAllowPartialPath=false. API/signature unavailable, invalid/stale bot, outra fase ou humano não encontrado deixam o respectivo teste inconclusivo, sem forçar classificação NAV-A/C. NavDataSet vazio é diferente de property indisponível. UNKNOWN da associação MovementComp/request id não é prova de ponteiro null ou request inexistente.

A projeção usa default NavData; o path usa seleção nativa pelo BotController e, quando disponível, NavAgentLocation. Os logs identificam essa diferença para não atribuir resultados de consultas diferentes ao mesmo agente indevidamente. Não ativar SetupNavConfig/MANG, GoalManager, Director ou BT com base apenas em uma hipótese. Depois da coleta, **parar**.

## Build e rollback

Release x64 / VS2022 v143 **14.44.35207** / SDK **10.0.26100.0** / sem ABOVE_S20. Output DLL/PDB em bot2-navdiag; intermediários em reboot/artifacts/intermediate/reboot3/bot2-navdiag. Logs privados: reboot/logs/reboot3-bot2-navdiag-Release.log e reboot/logs/reboot3-bot2-navdiag-final-Release.log, sendo o segundo da revisão que inclui bloqueio inicial/metadata do getter Fortnite. **Ambos os builds terminaram com exit code 0**, sem erros. A identidade final abaixo corresponde à última revisão. Permanecem avisos conhecidos do upstream (conversões, World.h C4172, Map.h C4715), além da conversão de offset já presente em BOT-1; não há aviso novo apontado para Bot2Nav.inl.

| Artefato | Identidade verificada |
| --- | --- |
| DLL | Project Reboot 3.0.dll, **3106304 bytes**, PE AMD64 DLL |
| DLL SHA-256 | **0fa99de348d55278734d1b5631572285a598434bc038e118584547c6f81a504f** |
| PDB | Project Reboot 3.0.pdb, **27070464 bytes** |
| PDB SHA-256 | 609c399450c6680da516d6c6e1f386536041a469ccc7e471e614f51011bdca2b |
| CodeView GUID / age | ca948ba4-d235-4df1-9c33-f3dd2295fe32 / 2; corresponde ao PDB |
| Patch | reboot/patches/bot2-nav-diagnostics.patch |
| Patch SHA-256 | 05c8a3f169b294f6c79a6ee65b8c66850a498382ca08dbc3aa31bb1b626b3faa |
| Manifesto privado | reboot/audit/bot2-navdiag-build.local.json |

Verificados: **13 hashes preservados**, incluindo DLL/PDB BOT-0 e BOT-1, baselines antigos, launcher, auxiliares e Shipping; spawn BOT-0 textual idêntico ao baseline BOT-1; propriedades de build idênticas; cinco source files no escopo; FES fixado e sem mudanças; patch completo incluindo o novo .inl, com aplicação reversa conferida; DLL posterior aos source files; DLL/PDB correspondentes e os seis rótulos de botão presentes; links/fences dos três documentos. Patches BOT-0/BOT-1 anteriores mantêm seus hashes.

Essa verificação é de compilação/artefatos/source. O ensaio do usuário descrito acima acrescentou evidência de execução das consultas, sem validar todos os getters internos nem comportamento AI.

Para recompilar o checkout local sem sobrescrever BOT-0/BOT-1:

```powershell
Set-Location 'D:\Games\Fortnite-Local-C2S3'
$bot2MsBuild = 'C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe'
& $bot2MsBuild 'reboot/reboot3/Project Reboot 3.0.sln' /t:Build /m:2 `
  /p:Configuration=Release /p:Platform=x64 /p:PlatformToolset=v143 `
  /p:VCToolsVersion=14.44.35207 /p:WindowsTargetPlatformVersion=10.0.26100.0 `
  /p:CL_MPCount=2 `
  /p:OutDir='D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\bot2-navdiag\' `
  /p:IntDir='D:\Games\Fortnite-Local-C2S3\reboot\artifacts\intermediate\reboot3\bot2-navdiag\' `
  /v:minimal /nologo
```

Reprodução em checkout novo: upstream fixado + ajuste reboot3-build-compat.patch, depois bot0-single-bot.patch, bot1-manual-move.patch e bot2-nav-diagnostics.patch nessa ordem, uma vez e com git apply --check. O patch BOT-2 é relativo ao baseline BOT-1 **0bbf1c5cdff5bd3a92309140930e86ff3906cac5**. Não reaplicar sobre o branch já alterado. Não usar build-reboot3.ps1 com outputs padrão/HEAD upstream para este ensaio.

Rollback: com host/cliente fechados normalmente, selecionar novamente `reboot/artifacts/reboot3/bot1/Project Reboot 3.0.dll`, ou o BOT-0 funcional em bot0-working. A tag baseline/bot1-moveto-failed guarda o source anterior; usar checkout separado se necessário, sem resetar trabalho pendente. Nenhuma configuração do launcher é alterada automaticamente.
