# Fase 2 — observação fornecida pelo usuário em 2026-10-07

**Resultado: INCONCLUSIVO para RUNTIME A/B/C. A Fase 2 permanece pendente.** O Shipping executou durante a captura, mas houve várias tentativas, incluindo abertura direta do executável. A preparação recusou o isolamento antes de aplicar regras. Esta sessão não valida o protocolo de uma única abertura normal pelo FortniteLauncher.exe nem demonstra lobby ou roteamento local.

## Evidências e preservação

O usuário forneceu `runtime/phase2/runtime-observation/tools/procmon/Logfile.PML` e uma imagem da janela Epic Games Launcher com a mensagem de modo offline. Informou depois que realizou aproximadamente duas ou três tentativas e também abriu FortniteClient-Win64-Shipping.exe diretamente. Não é possível atribuir cada PID a um modo de abertura específico.

O PML foi preservado, sem substituir o original, em `runtime/phase2/runtime-observation/user-capture.original.pml`. Os dois arquivos tinham o mesmo SHA-256; tamanho e data do original permaneceram estáveis durante a cópia. Os artefatos de captura e resumos ficam privados e ignorados pelo Git.

- Formato: PML v9 finalizado; 3.635.847 bytes; 7.131 eventos; quatro registros na tabela de processos.
- SHA-256: `b6ff77d3ad3c0e5f0228c0b65828a4899798ae565322bd782897b6bc03cbf03b`.
- Janela dos eventos: 18:23:32.583–18:25:09.992 UTC, equivalente a 15:23:32.583–15:25:09.992 em America/Sao_Paulo, em 2026-10-07.
- Todos os eventos registrados pertencem aos três PIDs do Shipping; o quarto registro de processo não tem eventos neste arquivo.

A inspeção usa `scripts/summarize-phase2-pml.cjs`, leitor local limitado a metadados do PML e caminhos de arquivos dos eventos Shipping. O formato foi consultado no [código do mantenedor de procmon-parser, commit fixado](https://github.com/eronnen/procmon-parser/blob/d32f1ddd109054cab4be6f727ba9944a7992bd73/procmon_parser/stream_logs_format.py); sua licença MIT acompanha o leitor. Nenhum código Python upstream foi importado ou executado. Não foram decodificados comandos de inicialização, contas, conteúdo dos arquivos, valores de registro, stacks ou tabelas de nomes de rede. Não houve resolução de símbolos, consulta DNS ou execução do cliente durante a análise. Esse leitor seletivo não substitui toda a interpretação possível pelo Procmon.

## Preparação e isolamento

O diagnóstico `logs/phase2-runtime-last-error.json`, de 18:22:18.297 UTC, registra falha em Prepare: o gate offline detectou Local Area Connection* 6, *7 e *8, vEthernet (WSL (Hyper-V firewall)) e vSwitch (WSL (Hyper-V firewall)). Essa recusa aconteceu antes da criação de regras ou estado de sessão. Interfaces virtuais ativas não demonstram, por si sós, uma rota externa, mas o gate conservador não foi atendido.

Na verificação após a captura, não havia `session.local.json` nem regras `FNLC2S3-P2Runtime-*` em PersistentStore ou ActiveStore. Portanto o bloqueio temporário proposto pelo projeto **não foi aplicado**. Não existe baseline dessa sessão para certificar restauração global do firewall; nenhuma remoção ou reset foi feito na análise.

A imagem confirma que a janela Epic apresentava modo offline naquele instante. Não comprova isolamento contínuo de todos os processos ou ausência de acesso externo durante as tentativas. Na verificação posterior, Ethernet estava Up e nenhum processo Fortnite/FortExternal estava ativo. A janela Epic pode ter sido aberta ou ativada: não há eventos de criação de processos no PML para demonstrar a cadeia launcher → Epic.

## Execução observada

Os três registros Shipping apontam para a build fornecida:

`D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe`

| PID | Primeiro evento UTC | Último evento UTC | Eventos | ReadFile com SUCCESS |
| --- | --- | --- | ---: | ---: |
| 35268 | 18:23:32.583 | 18:23:50.837 | 2.376 | 71 |
| 30812 | 18:24:17.767 | 18:24:35.964 | 2.437 | 0 |
| 34004 | 18:24:51.919 | 18:25:09.992 | 2.318 | 1 |

Essas são janelas dos eventos disponíveis, não horários comprovados de criação/saída dos processos. Não há código de saída, exceção do cliente ou imagem de erro do Shipping. A existência de eventos confirma execução; não confirma conclusão do boot.

Todos os eventos são File System:

| Operação | Eventos |
| --- | ---: |
| CreateFile | 2.014 |
| ReadFile | 72 |
| QueryOpen | 105 |
| QueryInformationFile | 1.317 |
| CreateFileMapping | 778 |
| QuerySecurityFile | 870 |
| QueryVolumeInformation | 6 |
| QueryEAFile | 4 |
| CloseFile | 1.965 |

Foram observados principalmente caminhos de bibliotecas/recursos do carregamento e metadados de arquivos. Não houve caminho terminado em `.ini` ou `.pak`, caminho sob uma pasta Saved, nem correspondência de caminho a McpConfig/OnlineSubsystem. As 72 leituras bem-sucedidas pertencem a outros arquivos; não constituem leitura de configuração externa. Abrir ou consultar metadados de um arquivo também não equivale a ler seu conteúdo.

## Classificações

| Item | Classificação | Evidência e limite |
| --- | --- | --- |
| Shipping executou | OBSERVED | Eventos de arquivos em três PIDs da build correta. |
| Saved/Config/WindowsClient/Engine.ini | NOT OBSERVED | Nenhum evento com esse caminho; não há baseline/garantia de cobertura de uma inicialização normal completa. |
| Outros INIs externos | NOT OBSERVED | Nenhum caminho `.ini` nos eventos disponíveis. Não classificar como NOT READ. |
| McpConfig externo | NOT PROVEN | Nenhum arquivo externo correspondente consultado e nenhuma ativação de override demonstrada. |
| Account | NOT OBSERVED | Nenhum evento Network ou log do serviço atribuível à captura. |
| Lightswitch | NOT OBSERVED | Mesma limitação. |
| Profile/MCP | NOT OBSERVED | Mesma limitação. |
| XMPP | NOT OBSERVED | Mesma limitação. |
| TCP/UDP, destinos IP/portas/hostnames | NOT OBSERVED | Zero eventos Network no PML; nenhum destino pode ser informado. |
| Lobby / Bernardo / PLAY | NOT OBSERVED | A imagem mostra Epic Games Launcher; não há prova visual do lobby. |

O arquivo não contém eventos Network, Process/Thread, Registry ou Profiling. A ausência de Network pode decorrer da etapa alcançada ou da captura/configuração; não comprova ausência de conexões, DNS ou tráfego externo. As opções de resolução de nomes/símbolos/profiling da interface não foram verificadas independentemente. Nenhum destino foi sondado para preencher essa lacuna.

Linha temporal comprovada: Prepare recusado → três janelas de eventos Shipping, com consultas/leitura de arquivos de carregamento → usuário apresenta Epic em modo offline → verificação posterior sem Fortnite/FortExternal ativo. A posição da janela Epic em relação a cada PID e o motivo da interrupção do boot permanecem desconhecidos. Não foi observada uma primeira tentativa de serviço que permita ordenar Account/Lightswitch/MCP/XMPP.

## Decisão e estado final

RUNTIME A não foi demonstrado: falta evidência de leitura/ativação de configuração externa. Os eventos confirmam início do Shipping, porém a mistura de aberturas e a preparação recusada impedem certificar esta sessão como RUNTIME B pelo protocolo previsto. A janela Epic offline, isoladamente, também não prova RUNTIME C ou uma exigência específica de autenticação/anti-cheat para cada tentativa. **A classificação permanece inconclusiva, sem escolher A/B/C com evidência insuficiente.** A decisão estática ROUTE C anterior permanece separada deste resultado runtime.

O PML permite registrar o que ocorreu nesta sessão; não permite concluir que INIs foram ignorados, que um override funciona, que houve acesso a serviços Epic, ou que não houve tráfego externo. Nenhum backend ou gameserver foi iniciado pelo agente para a análise, e nenhum EXE, PAK, hosts, certificado ou controle de segurança foi alterado pelo agente.

A análise está encerrada. Não foi preparada outra execução, alteração de McpConfig ou segundo experimento com INI. A evidência exigida para esse segundo experimento — leitura de um arquivo externo específico — não apareceu. Os arquivos privados foram preservados; a auditoria estática não foi reaberta e a Fase 3 não foi iniciada.
