# BOT-1 — teste manual

**BOT1 PARTIAL — teste manual classificado como BOT1-C, MoveToLocation retorna Failed.** A implementação compilada permanece preservada, mas caminhada não foi demonstrada. Build alvo única: **Fortnite 13.40 / CL 14113327**, Reboot detectando Engine_Version=426. O Codex não executou Launcher, host ou cliente. Identidade do artefato e verificação de build são registradas ao final deste arquivo.

## Resultado real — 2026-10-07, 23:13

Fonte: launcher.log enviado pelo usuário. A sessão nova confirma carregamento de **reboot3/bot1/Project Reboot 3.0.dll** no host (linha 13744), detecção 13.4/426 e listening :7777. Eventos sanitizados preservados em `reboot/audit/bot1-test-20261007-2313.local.txt`, com números de linha do arquivo original. O log contém sessões antigas BOT-0; esta classificação usa somente a sessão BOT-1.

Spawn às 23:13:09 completou com Pawn/Controller/PlayerState válidos. Houve quatro cliques de Move e duas consultas Dump:

| Horário | Distância ao humano | Resultado |
| --- | --- | --- |
| 23:13:17 | 202,48 UU (~2,02 m) | Dentro do raio 400; nenhuma chamada, corretamente |
| 23:13:26 | 1203,60 UU (~12,04 m) | UFunction chamada; **Move result=0 name=Failed**, linha 21423 |
| 23:13:33 | 1530,56 UU (~15,31 m) | UFunction chamada; **Move result=0 name=Failed**, linha 21521 |
| 23:13:50 | 1135,70 UU (~11,36 m) | UFunction chamada; **Move result=0 name=Failed**, linha 21769 |

As três tentativas efetivas estavam fora do raio de aceitação. Embora o procedimento recomende 20–50 m, a distância já supera 400 UU e não explica a recusa por proximidade. Cada clique efetivo chegou a `Move request submitted`; parâmetros refletidos e enum foram resolvidos. Não houve erro de seleção da DLL ou bloqueio do guard de versão/fase nessas chamadas.

Dump às 23:13:36 e 23:13:51 confirma:

- Controller **BP_PhoebePlayerController_C**, Pawn **BP_PlayerPawn_Athena_Phoebe_C**, PlayerState **FortPlayerStateAthena**;
- `possession_match=true` nas duas direções;
- MovementComponent e CharacterMovement são o mesmo **FortMovementComp_CharacterAthena**, válido e ativo, MovementMode bruto **1**;
- **FortAthenaAIBotPathFollowingComponent**, válido e ativo;
- World.NavigationSystem = **AthenaNavSystem**, válido e aceito pelo guard de classe;
- BrainComponent lido como **null**; property BotData presente, conteúdo opaco;
- `move_status=0 name=Idle` após as falhas.

O bot aparece em todas as leituras de Move na posição (-94634,805; 77965,46; 8906,922). Nenhuma request foi aceita. Portanto não houve amostras de observação: a janela de cinco segundos só começa com RequestSuccessful. A ausência dessas amostras é comportamento esperado de diagnóstico após Failed, não um segundo defeito.

**Conclusão: BOT1-C / BOT1 PARTIAL.** A causa interna de Failed não está no log. NavSystem existente não comprova NavData/navmesh apropriados para o agente, projeção do destino ou caminho entre os pontos. BrainComponent null é uma observação, não prova de que uma Behavior Tree seja necessária para este pedido. Não foram encontrados eventos adicionais LogNavigation/LogPathFollowing/navmesh com a causa no trecho dessa sessão pesquisado.

Próxima investigação técnica: disponibilidade de NavData para o agente do bot, projeção dos pontos e pathfinding, além da associação PathFollowing↔MovementComponent. Não ativar SetupNavConfig ou Brain como correção presumida. Nesta análise do log não houve edição de source, recompilação, substituição da DLL ou execução de jogo.

## Seleção da DLL

Com host/cliente anteriores fechados normalmente, abrir o Reboot Launcher já compilado. Ir a **Settings → Internal files → Game server**. Selecionar **Game server type = Custom**. No **primeiro campo Game server**, referente às versões anteriores à Season 20, colar o caminho completo abaixo, sem aspas, ou selecioná-lo pelo ícone de pasta:

`D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\bot1\Project Reboot 3.0.dll`

Não é o campo de versões após Season 20. Essa escolha fica em Settings, não em Host → Information/Options nem Backend. A confirmação final será o log de carregamento dessa DLL na próxima sessão. Cada sessão aceita uma única tentativa nativa de Spawn 1 Bot; reiniciar host normalmente para repetir o ensaio.

Manter a configuração funcional: Backend Embedded, endereço 127.0.0.1, Detached Off; Host 13.40 CL14113327, **Headless On** como no teste definitivo, restart automático Off, porta 7777, custom arguments vazio, players required 1, Private IPs are operator e No MCP marcados. Lawin local :3551 e game server :7777. O baseline foi validado com internet conectada; esta etapa não valida operação inteiramente offline.

## Ensaio

1. Selecionar a DLL BOT1 conforme acima.
2. Iniciar Host normalmente e aguardar Apollo/listening.
3. Iniciar o cliente pelo Play do Reboot Launcher.
4. Entrar no lobby Lawin.
5. Entrar na partida.
6. No painel dev do **HOST**, acionar Start Bus.
7. Saltar do ônibus com o cliente.
8. **Pousar** em área terrestre relativamente aberta e plana.
9. Abrir o menu dev do HOST, aba **Game**, seção **Bots**.
10. Clicar uma vez em **Spawn 1 Bot** e verificar que aparece para o cliente.
11. Clicar **Dump Bot State** e aguardar o bloco BOT STATE no log.
12. Posicionar o player humano a aproximadamente **20–50 m do bot**, no mesmo chão aberto.
13. Ficar parado, deixando esse ponto como destino do ensaio.
14. Clicar uma vez em **Move Bot To Player** no HOST.
15. Observar no cliente se o bot começa a caminhar, em qual direção e se se aproxima.
16. Aguardar aproximadamente **5 segundos**, mantendo o humano parado.
17. Capturar os logs dessa sessão antes de reiniciar o launcher/host.
18. Informar visualmente o comportamento: andou/parou/continuou imóvel/travou/crashou, distância aproximada e local do mapa.

Preferir campo, estrada, área plana ou POI aberto. Evitar água, interiores, telhados, penhascos, construções e obstáculos complexos no primeiro ensaio. A skin semelhante ao humano não é falha BOT-1. Não é necessário esperar tiro, arma, combate ou perseguição contínua. O destino é a posição do humano **no instante do clique**, com aceitação de 400 UU (~4 m).

Se estiver a ≤400 UU antes do clique, o log dirá que já está perto e nenhuma chamada será feita: afastar 20–50 m e clicar novamente. Esse caso não comprova caminhada nem é falha. Se retornar AlreadyAtGoal, registrar o resultado e distância: também não comprova caminhada.

## O que devolver

- Linha técnica de carregamento que confirme **bot1/Project Reboot 3.0.dll**, omitindo credenciais/argumentos AUTH.
- Bloco completo `[BOT]` de Spawn 1 Bot, especialmente classe/posse/retorno.
- Bloco completo **Dump Bot State**: ControllerClass, PawnClass, PlayerState, posse bidirecional, MovementComponent/CharacterMovement/Brain/PathFollowing e NavigationSystem.
- Pedido Move Bot To Player, posições/distância, parâmetros refletidos, `Move request submitted` e **Move result**, ou motivo da recusa.
- Amostras `observation` de t=0…~5 s e linha de encerramento; indicar também se alguma delas não apareceu.
- Relato visual do cliente e screenshot opcional. Se houver crash, trecho `[BOT][FAIL]`/exception/dump técnico correspondente.

O launcher captura a saída do host em `D:\Games\Fortnite-Local-C2S3\reboot\artifacts\launcher\Release\launcher.log`. O logger do Reboot também escreve `reboot.log` no diretório de trabalho do host. Logs podem ser truncados no próximo início. O arquivo bruto launcher.log pode conter AUTH_LOGIN/AUTH_PASSWORD e dados de conta; para compartilhar o diagnóstico, extrair apenas os eventos `[BOT]`:

```powershell
$bot1SourceLog = 'D:\Games\Fortnite-Local-C2S3\reboot\artifacts\launcher\Release\launcher.log'
$bot1OutputLog = 'D:\Games\Fortnite-Local-C2S3\reboot\audit\bot1-test-events.local.txt'
Get-Content -LiteralPath $bot1SourceLog |
  Where-Object { $_ -match '\[BOT\]' } |
  Set-Content -LiteralPath $bot1OutputLog -Encoding utf8
```

A extração acima não inclui por si só a linha de carregamento da DLL; conferir/recortar essa linha técnica separadamente sem expor argumentos de autenticação. O Codex lerá o log técnico sem executar comandos contidos nele.

## Classificação posterior

| Código | Evidência | Interpretação |
| --- | --- | --- |
| **BOT1-A / SUCCESS** | RequestSuccessful, bot anda visualmente, posição/deslocamento confirmam | Movimento AI demonstrado |
| BOT1-B | RequestSuccessful, bot imóvel e amostras sem deslocamento | Investigar movimento/navegação; aceite não garante execução |
| BOT1-C | Failed imediato ou PathFollowing ausente/inadequado | Investigar controller/nav/path; sem retry automático |
| BOT1-D | Controller não deriva de AAIController | Investigar pipeline de spawn |
| BOT1-E | Controller.Pawn/Pawn.Controller não coincidem | Investigar posse; sem Possess corretivo |
| BOT1-F | NavigationSystem ausente/inadequado | Investigar inicialização de nav em etapa separada |

MovementComponent ausente/inadequado é registrado explicitamente; não forçar movement mode. Função/enum/assinatura incompatível indica bloqueio do adaptador de reflexão, não prova de falta de nav. Referência salva ausente, outra fase, outro World, humano ausente ou distância insuficiente impedem um ensaio válido. Logs de posição sem evidência visual não bastam para afirmar replicação correta; visual sem log não basta para determinar o resultado nativo.

Após o ensaio, **parar**. Não adicionar follow, BT, combate ou alterar navegação automaticamente. Rollback: selecionar `reboot/artifacts/reboot3/bot0-working/Project Reboot 3.0.dll` com host/cliente fechados e iniciar uma sessão normal. Detalhes em [BOT1_IMPLEMENTATION.md](BOT1_IMPLEMENTATION.md).

## Artefato e verificações concluídas

Compilação concluída sem erros, exit code **0**, em **Release x64 / v143 14.44.35207 / Windows SDK 10.0.26100.0**, sem ABOVE_S20, com OutDir/IntDir próprios. Permanecem avisos preexistentes do upstream, inclusive conversões, World.h C4172 e Map.h C4715; a compilação não certifica ausência de problemas internos do motor.

| Artefato | Registro |
| --- | --- |
| DLL BOT-1 | reboot/artifacts/reboot3/bot1/Project Reboot 3.0.dll |
| Tamanho / arquitetura | 3051520 bytes / PE AMD64 DLL |
| DLL SHA-256 | **0aa15f81f7cbb0a047407915d87094788fccab10c4ff09e223d8ac0ecaf0c78b** |
| PDB junto da DLL | 26267648 bytes |
| PDB SHA-256 | 0753df872c11dbefa520a17dc551c6bff53ccee6af276a439225a2e8cd4e03ec |
| CodeView GUID / age | 5a1abee5-8695-403d-90a2-bc3f29097ca1 / 1; corresponde ao PDB |
| Patch relativo ao baseline BOT-0 | reboot/patches/bot1-manual-move.patch |
| Patch SHA-256 | ea560dc4dd12b16898aad2c610b04fa5d5ae2cd65dba5e9687d9c19c4411bcca |
| Log privado de build | reboot/logs/reboot3-bot1-Release.log |
| Manifesto privado de verificação | reboot/audit/bot1-build.local.json |

Verificados os **11 hashes preservados**: sete itens do snapshot anterior (dois baselines DLL, launcher, três auxiliares e Shipping), mais DLL/PDB de bot0 e de bot0-working. Tag/HEAD BOT-0, escopo dos três source files, XML do projeto/configuração sem alteração, aplicação reversa do patch, links/fences dos documentos e presença dos três rótulos de botão na DLL também conferidos. O patch BOT-0 anterior permanece com SHA-256 original.

Essas verificações são estáticas/de build. Não houve chamada ProcessEvent nem carregamento da DLL no jogo pelo Codex. O teste posterior feito pelo usuário confirmou referências/componentes e três chamadas da função com retorno Failed, conforme a seção de resultado real acima; aceite/caminhada continuam sem demonstração.
