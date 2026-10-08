# Fase 2 — preparação da observação de runtime

**Atualização posterior:** o usuário confirmou que a abertura manual de FortniteLauncher.exe acionou Epic Games Launcher. A orientação histórica de abertura única abaixo foi retirada para próximos experimentos: não repetir o teste e não tratar esse arquivo como entrada independente. Auditoria somente leitura e decisão C em [PHASE2_LAUNCH_CHAIN](PHASE2_LAUNCH_CHAIN.md). Nenhum comando substituto foi implementado.

Data: 2026-10-07. Build: Fortnite 13.40 / CL 14113327. **PREPARAÇÃO SOMENTE; EXECUÇÃO NÃO AUTORIZADA NESTA ETAPA.**

A auditoria estática está encerrada em ROUTE C. Não houve nova pesquisa de strings, configurações MCP ou conteúdo de PAK nesta etapa. O objetivo futuro é uma única abertura limpa, offline, por no máximo três minutos, para observar arquivos consultados, tentativas de rede e a falha normal. Não há tentativa de obter lobby/PLAY. Nenhum cliente, launcher da build, anti-cheat, gameserver, captura ou script de aplicação/cleanup foi executado nesta preparação.

O usuário abrirá os programas manualmente quando receber instrução aqui no chat; não será utilizado computer use. **Não abrir Fortnite agora.**

## Executável e argumentos propostos

O candidato é o launcher original da build:

`D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64\FortniteLauncher.exe`

**Argumentos: nenhum.** A futura abertura será pelo usuário, a partir desse diretório, uma única vez. Os scripts preparados não possuem Start-Process, execução de EXE da build ou código para iniciar o backend/gameserver.

Isso é uma proposta de entrada normal pelo launcher fornecido, **não uma comprovação de que ele consegue iniciar offline**. Não será iniciado o Shipping diretamente para evitar um launcher ou requisito de segurança. Se o launcher pedir fluxo oficial, credencial/ticket, instalação de componente, atualização ou infraestrutura indisponível, parar e registrar o impedimento. Não abrir alternativamente EAC/BE, instaladores, Shipping ou launcher comunitário. Não fornecer credenciais, parâmetros AUTH, flags para ignorar segurança ou flags de roteamento. O eventual acionamento normal de componentes pelo launcher é observado sem suspender serviços/processos.

## Executáveis afetados pelas regras propostas

Lista exata levantada por inventário dos arquivos EXE, sem executar os arquivos. Cada caminho receberia duas regras, Inbound e Outbound: **16 regras ao todo**. A presença na lista não significa que o executável será iniciado.

| Executável: caminho absoluto | Motivo do escopo |
| --- | --- |
| `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\Engine\Binaries\Win64\CrashReportClient.exe` | Relatório de falhas: impedir envio direto |
| `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\Engine\Binaries\Win64\UnrealCEFSubProcess.exe` | Auxiliar CEF da build |
| `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping_BE.exe` | Wrapper BE fornecido, sem iniciar separadamente |
| `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping_EAC.exe` | Wrapper EAC fornecido, sem iniciar separadamente |
| `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe` | Processo que se deseja observar |
| `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64\FortniteLauncher.exe` | Entrada normal proposta |
| `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64\BattlEye\BEService_x64.exe` | Componente distribuído nesta build; não modificar/instalar |
| `D:\Games\FortniteLocal\13.40-CL-14113327\13.40\FortniteGame\Binaries\Win64\EasyAntiCheat\EasyAntiCheat_Setup.exe` | Instalador distribuído; bloquear, mas não executar |

Não serão criadas regras para outros jogos, cópias externas de anti-cheat, svchost, DNS Client, PowerShell, navegador, Codex ou qualquer programa fora desses oito caminhos. Serviços compartilhados ou componentes já instalados em outros caminhos são uma limitação desse escopo, tratada pelo requisito de desconexão abaixo.

## Isolamento e comprovação

Preparados, **sem execução**:

- `scripts/prepare-phase2-runtime-observation.ps1`: sem `-Apply`, apenas apresenta o plano. Com `-Apply`, após autorização futura e pré-condições, cria as 16 regras e verifica a política efetiva.
- `scripts/cleanup-phase2-runtime-observation.ps1`: sem `-Apply`, apenas apresenta o cleanup. Com `-Apply`, remove exclusivamente as regras identificadas da sessão, verificando proprietário, caminho e escopo.
- `scripts/phase2-runtime-observation-common.ps1`: auxiliares, sem ações automáticas de firewall/captura/lançamento.

Regras: `Action=Block`, `Enabled=True`, `Profile=Any`, `Protocol=Any`, endereços/portas locais e remotos `Any`, caminho absoluto `Program`, uma regra por direção. Grupo: `Fortnite-Local-C2S3 Phase2 Runtime Observation`. Nome: `FNLC2S3-P2Runtime-<identidade da sessão>-<índice 0–7>-<Inbound|Outbound>`. Não há wildcard de aplicativo. A [documentação Microsoft](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/rules) descreve regras por caminho e precedência dos bloqueios explícitos; o script verifica as regras no ActiveStore, não apenas sua criação no PersistentStore.

**Limitação decisiva:** regras por programa comprovam política para aquele caminho, não isolamento completo de solicitações delegadas a serviços compartilhados. O [DNS Client do Windows](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-dns-client) pode usar cache ou consultar servidores remotos. Não se deve concluir que bloquear Shipping bloqueou qualquer consulta originada pelo DNS Client, auxiliar fora da build ou serviço oficial instalado. A garantia não será baseada em ausência de eventos.

Por isso a execução proposta exige uma proteção independente: **desconexão física da rede externa pelo usuário durante toda a observação** — retirar o cabo Ethernet e manter Wi-Fi, VPN, tethering e outras interfaces sem conexão. Os scripts não desabilitam adaptadores ou serviços. Isso afeta temporariamente a conectividade do computador, mas não muda regras de outros programas. Não foi feito nesta preparação. Se essa condição não for aceita ou não puder ser comprovada, manter cliente fechado e registrar isolamento insuficiente; não improvisar regras globais.

O gate conservador recusa a aplicação se qualquer adaptador, inclusive oculto/virtual, estiver Up ou se alguma interface IP não loopback estiver Connected. Pode recusar redes virtuais sem Internet; essa recusa não será contornada automaticamente. A checagem é um retrato do estado e não impede uma reconexão posterior. O usuário deverá manter a desconexão até os processos terminarem e o cleanup ser confirmado. O chat poderá ficar indisponível enquanto o cabo estiver desconectado; todas as instruções deverão estar disponíveis localmente antes disso.

Verificações antes de qualquer abertura futura:

1. Autorização explícita para a observação, PowerShell 7 elevado e cliente/auxiliares parados.
2. Serviços BFE/MpsSvc ativos, três perfis de firewall habilitados e regras locais permitidas; recusar política com regras de bypass autenticado existentes. Se não, abortar sem alterar a política existente.
3. Conferência do inventário exato de EXEs; arquivos/caminhos extras ou reparse points causam recusa.
4. Desconexão independente e leitura de adaptadores/interfaces; não fazer ping, resolução DNS ou requisição externa de teste.
5. Criação/verificação das 16 regras no ActiveStore, incluindo caminho, direção, bloqueio, todos os perfis/protocolos/endereços/portas e PrimaryStatus OK.
6. Captura limitada configurada e iniciada; repetição da verificação offline imediatamente antes de autorizar a abertura manual.

Confirmar regras e ausência de interface externa demonstra as condições de isolamento propostas, **não um teste de tráfego real do executável**. Não haverá teste usando outro EXE como substituto, renomeação de binário ou requisição aos destinos Epic.

## Observação de arquivos: Process Monitor oficial

[Process Monitor / Sysinternals Microsoft](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon), versão 4.11. ZIP obtido de `https://download.sysinternals.com/files/ProcessMonitor.zip`. Aplicação portátil local em `runtime/phase2/runtime-observation/tools/procmon/Procmon64.exe`, ignorada pelo Git. Executável não iniciado; assinatura Authenticode Valid, Microsoft Corporation. Windows 11 Pro local compatível com o requisito publicado. Licença: EULA Sysinternals fornecida no ZIP, não biblioteca incorporada ao projeto.

SHA-256 do ZIP: `80A6442B46AF762ED1432F6FEC3F7E20366BED62A2522B3486503398A40A1128`.

SHA-256 de Procmon64.exe: `FC3AF5317C707E0555AD6E7590AD65CEB5C5085B053B41221944AC3CA3492D9C`.

Configuração futura pelo usuário, antes de abrir Fortnite:

- Abrir Procmon64 com `/NoConnect` para configuração inicial sem começar captura. Conferir visualmente que Capture Events está desligado; não iniciar captura sem os filtros. O comportamento dessa versão não foi testado nesta preparação.
- Manter captura de Registry, Process/Thread e Profiling desligada; habilitar somente File System e Network.
- Desativar resolução de endereços de rede, downloads de símbolos e boot logging; não usar Stack Summary ou mecanismos de profiling. Não acionar recursos que consultem a Internet.
- Remover filtros anteriores que adicionem outros processos. Usar `Process Name is FortniteClient-Win64-Shipping.exe Include`, **Drop Filtered Events habilitado**. O menu e a configuração são descritos no [material Microsoft sobre Procmon](https://learn.microsoft.com/en-us/shows/defrag-tools/3-process-monitor). A verificação prática de que o filtro descarta outros processos é pré-condição pendente; a configuração manual não foi realizada nesta etapa.
- Acrescentar operações Include: CreateFile, ReadFile, QueryOpen; TCP Connect, TCP Send, TCP Receive, TCP Disconnect, UDP Send e UDP Receive, conforme disponíveis. Operações da mesma coluna são alternativas; o filtro por processo deve continuar obrigatório. Não filtrar por Result, nem somente por sucesso: NAME NOT FOUND é evidência de consulta importante.
- Nenhuma outra cópia de Shipping com esse nome poderá estar aberta. Registrar PID e confirmar Image Path desta build antes de interpretar os eventos. O nome sozinho não comprova caminho.
- Usar backing file somente depois de configurar/verificar os filtros: `runtime/phase2/runtime-observation/capture-<sessão>.pml`. Limpar eventos anteriores e salvar o filtro localmente como `.pmc` no mesmo diretório. Não foi fabricado arquivo PMC binário nem salva configuração não verificada.

Na análise do trace filtrado, procurar Engine.ini, DefaultEngine.ini, Game.ini, DefaultGame.ini, GameUserSettings.ini; caminhos contendo Saved, Saved/Config/Windows, Saved/Config/WindowsClient, FortniteGame/Saved, McpConfig e OnlineSubsystem. Não restringir o Path durante a coleta inicial: isso poderia ocultar a hierarquia real. Verificar tanto caminhos relativos à build quanto `%LOCALAPPDATA%/FortniteGame/Saved` e qualquer destino externo efetivamente observado. Esses locais são candidatos, não leituras comprovadas.

Registrar timestamp, PID, operação, caminho, Result e metadados de ReadFile. Procmon observa metadados de operações, sem coletar corpo de requisição/conteúdo de arquivo. CreateFile/QueryOpen com NAME NOT FOUND é consulta, não leitura. **READ** exige ReadFile bem-sucedido no arquivo exato; **NOT READ** exige cobertura suficiente e consulta sem leitura; ausência/início incompleto de captura resulta em **NOT OBSERVED**. Leitura de Engine.ini não prova que uma chave MCP seja aceita, nem sua prioridade.

Procmon utiliza componente de observação do sistema; não injeta DLL ou altera memória do cliente neste plano. Sua inicialização pode carregar driver e registrar preferência/EULA da própria ferramenta. Se controles normais impedirem a ferramenta, não reduzir segurança para carregá-la. Se anti-cheat recusar a execução com a ferramenta, registrar essa falha e parar; não remover, suspender ou ignorar anti-cheat.

## Observação de rede e limites de visibilidade

Ferramenta principal: eventos Network do mesmo trace Procmon, filtrados somente para Shipping. Exportar somente metadados de tentativa (UTC/tempo relativo, PID, destino IP se presente, porta, TCP/UDP, resultado). Não realizar reverse DNS, Resolve-DnsName, nslookup, ping, request HTTP ou validação TLS contra qualquer destino encontrado.

Fonte complementar: eventos **já existentes** do Windows Security/WFP, especialmente [5157, conexão bloqueada](https://learn.microsoft.com/de-de/previous-versions/windows/it-pro/windows-10/security/threat-protection/auditing/event-5157). Usar filtro de origem, EventID, janela da sessão e PID/Application do Shipping antes de exportar; não exportar o log Security inteiro. Incluir somente campos de tempo, processo/aplicativo, Direction, DestAddress, DestPort, Protocol e FilterRTID. Confirmar caminho e período para evitar reutilização de PID. Eventos 5152, se disponíveis e corretamente atribuídos, complementam bloqueios de pacote.

A leitura da auditoria com auditpol nesta sessão sem elevação retornou privilégio insuficiente. Portanto a disponibilidade de 5157 é **NÃO CONHECIDA**. Não foi habilitada política de auditoria global, log de firewall global, DNS Client log, Sysmon, WPR ou netsh trace. Se a auditoria não estiver ativa, ausência de 5157 não significa ausência de tentativa. O plano não modifica auditoria para coletar tráfego de outros processos.

Hostname só será registrado se aparecer em metadados/log do próprio cliente ou evento já disponível que permita atribuição segura à sessão. Não consultar todo o cache DNS da máquina, inferir domínio pelo IP, ou resolver nomes manualmente. DNS executado por serviço compartilhado não é necessariamente visível sob o filtro Shipping; HTTP/TLS podem falhar antes de um evento de conexão. **Não se garante lista completa de hosts, nem que todas as tentativas bloqueadas apareçam no Procmon.** Se faltar evidência, registrar NOT OBSERVED/hostname desconhecido, mantendo a limitação explícita. Não executar cliente para preencher lacunas de isolamento ou captura.

Ordem aproximada por timestamp/sequence da captura; combinar fontes usando UTC e início/fim da sessão, mantendo tolerância de relógio, buffering e concorrência. Não apresentar eventos concorrentes como causalidade provada.

## Execução futura, somente após autorização

Roteiro a ser disponibilizado localmente antes de desconectar a rede:

1. Registrar baseline de política de firewall e metadados das pastas Saved existentes; não ler contas/credenciais. Garantir que não há outro Fortnite ou gameserver aberto.
2. Desconectar fisicamente a rede externa. Em PowerShell 7 elevado, aplicar o script preparado. Não usar ExecutionPolicy Bypass/Unrestricted, certificados de código novos ou alteração de política para executá-lo. A sessão de preparação possui RemoteSigned, sem mudança efetuada.
3. Conferir regras efetivas e interfaces offline. Preparar/validar filtros Procmon e iniciar captura. O script mantém LaunchReady=false mesmo após verificar regras: isso não é permissão para abrir.
4. Somente então avisar o usuário para abrir o FortniteLauncher.exe original, sem argumentos. Observar uma única tentativa, até a falha normal ou no máximo três minutos. Não clicar em login real, PLAY, atualização ou instalação de anti-cheat. Se login oficial for necessário, registrar impedimento e encerrar.
5. Fechar normalmente o cliente e todos os auxiliares desta build; não suspender controles. Se não for possível fechá-los, manter rede desconectada e regras presentes, sem iniciar outra tentativa.
6. Parar captura, salvar somente a sessão filtrada e fechar Procmon normalmente. Não usar comando de término que encerre instâncias de ferramenta pertencentes a outras tarefas.
7. Executar cleanup autorizado. Somente após comprovar processos encerrados, regras ausentes e resultado do baseline, reconectar a rede.

Comandos **de referência para a etapa futura**, não executados agora, em PowerShell 7 elevado a partir da raiz do projeto:

```powershell
./scripts/prepare-phase2-runtime-observation.ps1 -Apply
# Cliente e captura deverão estar encerrados antes do comando seguinte.
./scripts/cleanup-phase2-runtime-observation.ps1 -Apply
```

Nenhum comando acima abre Fortnite ou gameserver. Nenhum backend será iniciado para esta observação limpa. Não utilizar start-phase2.ps1 ou qualquer coordenador de lobby nesta etapa.

Atalho preparado para uso manual: `OBSERVACAO-RUNTIME.bat`, na raiz do projeto. Menu **1 = preparar**, **2 = limpar**, **0 = sair**. O bootstrap `scripts/invoke-phase2-runtime-observation.ps1` encontra PowerShell 7.4+ instalado ou o runtime local já disponível, solicita elevação normal via UAC e chama somente o script escolhido com `-Apply`. Não usa ExecutionPolicy Bypass/Unrestricted, não instala software e não abre cliente/captura/gameserver. Se a elevação for recusada, a política impedir o script, a rede estiver conectada ou outra pré-condição falhar, não contorna. A janela com o resultado fica aberta até Enter. O atalho foi criado, não executado para aplicar regras nesta etapa.

Correção após a primeira tentativa manual: o BAT passa a chamar PowerShell 7 diretamente. A entrada inicial por Windows PowerShell 5.1 encontrou uma sessão com política Restricted e poderia terminar antes do tratamento de erro. A sessão nova de PowerShell 7 existente foi consultada somente para confirmar versão/política, sem executar scripts de firewall: 7.6.5, RemoteSigned. Nenhuma política foi alterada. O BAT mantém a janela original aberta mesmo se o bootstrap falhar; erros tratados pelo bootstrap são salvos em `logs/phase2-runtime-last-error.json`, ignorado pelo Git. O gate offline permanece conservador, incluindo interfaces virtuais, e agora informa seus nomes quando recusa a operação. Não foi aplicada regra durante a correção.

Correção da falha PSIsContainer: o diagnóstico local confirmou erro na travessia dos diretórios em Get-RuntimeObservationTargets, antes da criação de qualquer regra/estado. FileInfo.Directory retorna DirectoryInfo sem a propriedade sintética PSIsContainer do provider PowerShell. A validação usa agora os tipos .NET FileInfo/DirectoryInfo, confere todos os ancestrais até a raiz e preserva a recusa de reparse points. A função foi verificada em leitura nos oito EXEs reais, com StrictMode, e em arquivo/diretório próprios de teste; um ancestral junction de teste foi rejeitado. Nenhum arquivo da build foi modificado. Não foi chamado prepare/cleanup com -Apply. A falha corrigida não equivale a aprovação do gate de rede ou autorização para iniciar o cliente.

## Cleanup e artefatos

O estado local `runtime/phase2/runtime-observation/session.local.json` registra identidade aleatória e plano antes da primeira regra. Falha na preparação chama cleanup automaticamente, usando identidades exatas e validação de proprietário. Uma interrupção abrupta pode deixar regras; o arquivo preservado permite executar cleanup posteriormente. Não há timer que remova isolamento enquanto o cliente pode continuar aberto.

Cleanup recusa remoção se um processo desta build/gameserver estiver ativo ou houver divergência de propriedade/escopo. Não usa remoção por wildcard/grupo sozinho, reset do firewall ou importação global. Revalida cada regra antes de removê-la; confirma ausência em PersistentStore/ActiveStore. Compara hash de campos observados da política persistente e perfis antes/depois, incluindo filtros de aplicativo/endereço/porta/serviço/interface/segurança. A comparação é de metadados selecionados, não de todo o estado interno WFP/GPO. Divergência concorrente será relatada, sem restaurar/modificar regras de terceiros.

Arquivos PML/PMC/CSV, baseline, estado e ferramentas portáteis ficam em `runtime/phase2/runtime-observation/`, já ignorado pelo Git. São preservados para análise/revisão. Após o relatório e liberação da retenção, fechar Procmon, confirmar cleanup e remover somente esse diretório resolvido dentro de runtime, usando Remove-Item -LiteralPath e validação de contenção; nunca remover diretórios calculados sem conferência. Não apagar logs Security nem drivers/serviços do Windows manualmente. Preferências da ferramenta preexistentes devem ser preservadas; configurações novas devem ser revertidas pela própria ferramenta, com baseline anterior à primeira abertura.

Nenhuma configuração externa será criada para o cliente nesta primeira tentativa. Se o cliente criar Saved/Config/logs, separar arquivos novos de preexistentes com baseline; remoção seletiva somente de artefatos comprovadamente criados nessa sessão. Nunca apagar FortniteGame/Saved ou `%LOCALAPPDATA%/FortniteGame` inteiros. Build, PAKs, EXEs, hosts, certificados e controles de segurança permanecem fora do cleanup.

## Resultado futuro e decisão

`PHASE2_RUNTIME_OBSERVATION.md` será escrito após a observação real, sem fabricar READ ou destinos. Hoje essas classificações permanecem **NOT OBSERVED / NOT PROVEN**, sem conclusão RUNTIME A/B/C de execução.

O relatório futuro terá: CLIENT START → arquivos consultados → Saved/Config consultadas → primeira tentativa de serviço → outros destinos → falha → estado final do processo. Classificações: Saved/Config/WindowsClient/Engine.ini [READ / NOT READ / NOT OBSERVED]; McpConfig externo [SUPPORTED / NOT PROVEN]; Account, Lightswitch, Profile/MCP e XMPP [OBSERVED / NOT OBSERVED]. Separar falha do launcher de ausência de eventos Shipping. Sem Shipping iniciado, os INIs ficam NOT OBSERVED; não afirmar que foram ignorados.

RUNTIME A requer evidência nova suficiente de configuração externa e possível override reversível; RUNTIME B indica início sem essa evidência; RUNTIME C indica que o início normal exige fluxo fora das restrições. Falha de ferramenta/captura ou isolamento insuficiente será limitação, não diagnóstico inventado de RUNTIME C. B/C não serão contornados.

Um segundo experimento só será preparado separadamente se esta tentativa demonstrar leitura do arquivo externo específico. Usaria opção inofensiva e reversível, sem endpoints MCP e sem alteração de PAK; não está preparado ou autorizado agora.

## Estado desta preparação e riscos conhecidos

- Firewall ativo nos três perfis, BFE/MpsSvc/DNS Client ativos; sessão atual não elevada. Ethernet estava conectada: **o gate offline ainda não foi atendido**.
- Nenhuma regra foi criada/removida e nenhum perfil/política/serviço/interface foi modificado. Os scripts foram analisados por parser PowerShell, sem invocação de prepare/cleanup; funções de validação foram verificadas isoladamente com mocks, sem comandos de mutação reais.
- Captura, filtro PMC e telemetria WFP ainda não estão validados em execução. Procmon pode ter visibilidade incompleta de bloqueios/DNS; anti-cheat pode impedir início ou observação. O launcher pode falhar antes de criar Shipping.
- A desconexão independente torna Codex/chat temporariamente indisponíveis. Captura tem custo de I/O e pode criar logs/crash reports locais; limitar a três minutos e encerrar em falha.
- Chaves AES, dados temporários e extrações anteriores permanecem privados/ignorados. Nenhum PAK, Shipping, hosts, certificado, anti-cheat ou dado de conta foi alterado nesta preparação. Consultas externas limitaram-se a documentação/download Microsoft; nenhum serviço live Epic foi consultado.

**PARADA:** preparação pronta para revisão, sem aplicação de regras ou captura e sem abertura do cliente. A futura execução exige autorização separada, isolamento independente atendido e captura filtrada validada. Não avançar para Fase 3.

## Atualização — abertura do Procmon autorizada pelo usuário

O usuário autorizou abrir/configurar somente o Procmon antes de desconectar a Internet. A ferramenta foi aberta com `/NoConnect`; a janela confirmou **No events (capture disabled)**. Fortnite/gameserver não foram iniciados e as regras de firewall continuam não aplicadas.

A interface informou integridade Windows superior à do helper Computer Use. Uma tentativa de menu e uma tentativa de Ctrl+L após confirmar foco não alteraram a janela. **Filtros, categorias e opções ainda não foram configurados nem verificados.** A captura permanece desligada; a ferramenta estar aberta não significa que a preparação de captura terminou. Nenhuma configuração PMC foi fabricada ou salva como validada.

Para concluir manualmente: Ctrl+L → manter exclusivamente Process Name is FortniteClient-Win64-Shipping.exe Include, removendo inclusões de outros processos; incluir CreateFile, ReadFile, QueryOpen e operações TCP/UDP desejadas; habilitar Drop Filtered Events; manter apenas File System/Network; desligar Resolve Network Addresses, Registry, Process/Thread e Profiling. Não usar resolução de símbolos, Stack Summary, boot logging ou Enable Profiling Events. Aplicar/salvar o filtro local e manter Capture Events desligado até a etapa autorizada com isolamento verificado.

## Atualização — captura manual analisada

As seções anteriores registram o plano e os estados históricos da preparação. O usuário forneceu depois um PML com 7.131 eventos de arquivos e três PIDs Shipping, informando várias tentativas e abertura direta do Shipping. Prepare havia falhado no gate offline, antes de criar estado ou regras; nenhuma regra do projeto foi encontrada nos stores persistente/ativo após a captura. A imagem mostra Epic Games Launcher em modo offline, sem prova do lobby. Resultado **INCONCLUSIVO**, sem classificação definitiva RUNTIME A/B/C. Não foram observados caminhos INI/Saved nem eventos Network; isso não comprova ausência de leitura/tráfego fora da captura. O relatório está em [PHASE2_RUNTIME_OBSERVATION](PHASE2_RUNTIME_OBSERVATION.md). Nenhum segundo experimento foi preparado; a auditoria estática permanece encerrada.
