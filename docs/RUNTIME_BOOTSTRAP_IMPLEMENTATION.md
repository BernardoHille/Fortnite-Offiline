# Season13Runtime — implementação e primeiro teste futuro

2026-10-07. **ARCH C — MILESTONE 0 READY.** Código R0/R1 compilado nas três configurações; testes offline aprovados. R0/R1 no Fortnite **NÃO EXECUTADOS**. Nenhum resultado de GObjects, GWorld, ProcessEvent ou controle do jogo foi demonstrado. Esta etapa termina aqui para revisão.

## Decisão baseada nas fontes

| Critério | ARCH A: FES externo | ARCH B: DLL com inicialização Reboot | ARCH C: controlador mínimo + DLL própria |
| --- | --- | --- | --- |
| Quantidade de código | Infraestrutura pronta, mas arena/bridge/pump e servidor acoplados | Acesso interno curto; entrypoint importa inicialização extensa | Dois binários pequenos; somente loader explícito, guard e R0/R1 |
| Estabilidade | Ponte no game thread, dependente de hook de rede e timing | Acesso direto; Main instala muitas funções/hooks | Remove esses acoplamentos; carregamento/ABI/thread ainda não testados |
| Debugging | Separar controller, stubs e alvo | PDB local da DLL; crash pode encerrar alvo | PDBs próprios de controller/DLL; export explícito facilita breakpoint |
| Marshaling | Argumentos/resultados remotos em cada chamada | Chamadas internas diretas | Apenas caminho DLL e RuntimeRequest no bootstrap; zero bridge por UObject |
| UObject | Handles remotos e leituras via bridge/memory | Layout/traversal interno | Leitura interna limitada, mesmos layouts com validação adicional |
| Chamadas virtuais | Ponte remota precisa representar ABI | Vtable acessível diretamente | Possíveis internamente; R0/R1 só validam entrada executável |
| ProcessEvent | CallProcessEvent via bridge | Função interna direta, usada amplamente | Resolução futura, sem hook/invocação agora |
| Reflection | Implementada em UnrealRuntime | Helpers e propriedade por metadata | Planejada como subconjunto, sem servidor ou multiversão |
| Crash diagnostics | Falha remota exige identificar stub/alvo | Stack da DLL/alvo | Logger com flush, PDBs próprios e endereço/RVA em falha FName |
| Offsets necessários | Profile + globals + hooks de rede | Grande matriz de versões/endereços | Layout mínimo 13.40; globals por signatures únicas; sem GWorld RVA inventado |
| Manutenção | Muitas dependências do host | Muitos caminhos de versões/gameplay | Uma build, SHA fixo, falha explícita sem fallback de versão |
| Bots futuros | FortAthenaAI e definicões existentes | Implementações internas existentes | Acesso interno adequado, mas bots não importados neste milestone |
| Networking futuro | EngineRuntime exige NetworkEssentials | Init e hooks misturam rede/session | Não necessário para R0/R1; etapa futura separada |
| Season13 específica | Profile existe, com divergências de layout registradas | 13.4 tratada dentro de código multiversão | Só CL 14113327 e arquivo exato; outra identidade aborta |

Escolha **C**: preservar evidência de Season13 do FES e a simplicidade de acesso interno do Reboot, sem carregar seus inicializadores completos. Nenhuma arquitetura elimina os requisitos de startup do Shipping. Nosso controlador **não inicia o jogo**. Se não existir processo elegível sem autenticação live ou bypass de anti-cheat, o teste permanece bloqueado; nenhum desses mecanismos foi implementado.

## Arquivos e reaproveitamento

| Arquivos novos | Responsabilidade |
| --- | --- |
| runtime-mod/CMakeLists.txt; scripts/build-season13-runtime.ps1 | Windows x64/C++20, builds e CTest offline |
| include/Season13Runtime.h; src/dllmain.cpp; src/Season13Runtime.cpp | Request com magic, único export Season13Start, inicialização única, R0/R1 e parada |
| include/Season13Target.h; src/Season13BuildGuard.cpp | Identidade única: caminho canônico, tamanho, PE, SHA integral, build/CL |
| src/controller.cpp | PID explícito, guard antes de alteração, loader/export futuro; modo --inspect somente arquivo |
| src/PeImage.cpp; src/PatternScanner.cpp; src/Memory.cpp | PE/bounds, seções executáveis, match único, RIP signed, VirtualQuery/RPM local |
| src/RuntimeAddresses.cpp; include/RuntimeAddresses.h | Subconjunto GObjects, NameToString e Realloc |
| src/Unreal/ObjectArray.cpp; src/Unreal/FName.cpp | Header/chunks/UObject/classes e conversão de nome limitada |
| src/RuntimeLog.cpp; tests/CoreTests.cpp | Append/flush; fixtures offline independentes do jogo |
| README.md; THIRD_PARTY_NOTICES.md; licenses/ | Escopo, proveniência e textos das licenças upstream |

Headers equivalentes acompanham os componentes em include/. ObjectView está em ObjectArray.cpp; não é necessário um UObject.cpp vazio. World.cpp/reflection/ProcessEvent/world inspector **ainda não existem**. R2–R5 são documentação, não promessa de código já preparado.

Reutilizado como referência, sem alterações ao checkout: FES season-13 `e42ecddbce59163c6a60ab7506766c2a0adfe580`, Season13BuildProfile, CoreUObjectSignatures e GetNameString; Reboot `10c659028ad9d6816f78226483f11a884bf81f57`, UObject/UObjectArray e abordagem interna. Foram adaptadas constants/layouts e a ABI de FName/FString; os controladores, scanner, guard e logger são próprios. Os textos das licenças acompanham o módulo. Não compilamos/carregamos launcher ou DLL Reboot.

Fontes e cadeia detalhada: [FES](FES_RUNTIME_TRACE.md), [Reboot](REBOOT_RUNTIME_TRACE.md), [mapa](SEASON13_ADDRESS_MAP.md), [Shipping → mundo](SHIPPING_TO_GWORLD.md). Não reutilizamos GameThreadBridge, MinHook, NetDriver pump, argumentos de auth, bypasses, init de sessão, travel ou bot. Backend e instalação do jogo permanecem separados deste módulo.

## Toolchain e evidência offline

Visual Studio 2022 Community, MSVC **19.38.33145.0**, ferramentas VC **14.38.33130**, Windows SDK **10.0.26100.0**, CMake bundled, gerador Visual Studio 17 2022 x64. Flags /W4, /permissive-, /EHsc, /guard:cf, /Zi; linker /DEBUG, /DYNAMICBASE, /NXCOMPAT. PDBs próprios nas três configurações, inclusive Release. Não é necessário PDB Fortnite ou servidor de símbolos.

```powershell
# BUILD/TESTE OFFLINE: não inicia nem anexa Fortnite.
& 'D:\Games\Fortnite-Local-C2S3\scripts\build-season13-runtime.ps1' -Configuration Debug -Test
# Outras configurações aceitas: RelWithDebInfo, Release.
```

| Verificação executada | Resultado / limite da prova |
| --- | --- |
| Debug, RelWithDebInfo, Release | Controller, DLL e testes compilados; 1/1 CTest aprovado em cada configuração |
| SHA guard | Vetor SHA conhecido; fixture tamanho incorreto; fixture do tamanho alvo com SHA incorreto rejeitada |
| PE/scanner/RIP | AMD64 válido, PE truncado/32-bit rejeitados, scan somente executable, 0/1/múltiplos matches, wildcard inválido, RIP signed/bounds |
| ObjectArray | Header/count/capacidade inválidos rejeitados; fronteira índices 0/65536 e acesso fora do limite testados com fixture |
| Memory/logger | Leitura da própria fixture, ponteiro nulo rejeitado, append/flush/arquivo crescendo comprovados fora da instalação |
| Inspeção de Shipping em disco | Identidade exata aprovada; quatro signatures com **zero matches**; nenhum endereço runtime comprovado |

Logs completos e manifesto de hashes: runtime/season13/audit/ (local ignorado). Binários/PDBs: **D:/Games/Fortnite-Local-C2S3/runtime-mod/out/Debug/**, /RelWithDebInfo/ e /Release/. DLL fica adjacente ao controller; **não foi copiada para FortniteGame/Binaries/Win64**. Os testes não carregam DLL no jogo nem chamam funções Unreal. Fixtures não validam ABI ou layout em processo vivo.

## Contrato de bootstrap e ordem

1. FUTURO: PID revisado → QueryFullProcessImageName → guard exato → headers carregados versus arquivo.
2. DLL própria adjacente → export obtido do PE em disco. Loader resolve LoadLibraryW pelo módulo efetivo da função (incluindo forwarder), base remota + RVA, sem assumir VA local igual à remota.
3. Aloca/escreve somente parâmetros próprios → LoadLibraryW → valida caminho/SizeOfImage do módulo carregado → Season13Start. DllMain só DisableThreadLibraryCalls; nenhuma rotina Unreal sob loader lock.
4. R0: log, nova validação de identidade, base real e headers → PASS → retornar. R1 não roda no milestone 0.
5. RUN 2 separado, se aprovado: snapshot limitado de sections executable → signature única/RIP → array coherent → pequena amostra e nomes. Zero/ambíguo/falha abortam, sem scan infinito.

Objeto non-null não é prova: R1 confere região readable, capacidade/count/chunks, stride, index, classe e vtable executável. Exige oito objetos válidos dentre até 256 índices. O array pode mudar durante a leitura; count é reavaliado e o log registra ausência de snapshot sincronizado.

FName usa NameToString e Realloc do jogo, com contrato FString derivado do FES, limites e SEH nas chamadas. Isso pode alocar/liberar memória do jogo: não é puro ReadProcessMemory. Thread affinity/init/ABI ainda desconhecidos. Buffer incoerente não é liberado por um ponteiro arbitrário; aborta com possível pequena alocação retida até fechar o processo. Falha nativa não implica recuperação segura do jogo. Revisar essas condições antes de RUN 2; não instalar pump/hook de rede para escondê-las.

## Logs e diagnóstico de crash

Arquivo futuro: **D:/Games/Fortnite-Local-C2S3/runtime/season13/logs/runtime.log**. Timestamp, PID, tag e flush por linha; BOOT/BUILD/PE/R0/ADDRESS/OBJECT/R1/FAIL. Os arquivos de fixtures são separados, sob runtime-mod/out/. Não escrevemos um runtime.log fictício de sucesso no Fortnite.

R0 registra build/base; R1 só até oito nomes/classes curtos e ASCII, com redução/redação de termos sensíveis. Não há dump genérico de memória, requests, tokens ou credenciais. R2–R5 não geram valores fictícios. Campos World/GameMode/GameState só serão registrados quando implementados e observados.

SEH da conversão FName captura exception code/address e, quando dentro do EXE, `Shipping+RVA = address - ImageBase`. Outros crashes assíncronos não são cobertos pelo catch C++; logger pode registrar só a última linha já flushada. Não há VEH, dump automático ou stack trace automático implementado.

Diagnóstico futuro de dump obtido em contexto autorizado, com debugger local e **apenas PDBs próprios**: configure caminho local dos PDBs correspondentes, use `.exr -1`, `.ecxr`, `k` e `lm`. Preserve code/address/stack e base dos módulos; para Shipping calcule RVA sem inventar nome de função. Breakpoints podem ser no nosso Season13Start/Initialize. Não configurar symbol server, profiling ou hooks de segurança. Dumps são privados e podem conter dados pessoais; não versioná-los nem coletá-los nesta etapa.

## Primeiro comando de teste FUTURO — NÃO EXECUTADO

Pré-condições: revisão desta entrega, autorização específica da execução e Shipping exato **já em execução em contexto elegível**, cuja disponibilidade ainda não foi demonstrada. A captura manual anterior não estabelece um fluxo de startup repetível. Não repetir FortniteLauncher.exe, usar credenciais live ou neutralizar EAC/BE para satisfazer a pré-condição.

Use o PID confirmado manualmente para aquele processo. O placeholder abaixo precisa ser substituído; não selecionamos PID automaticamente.

```powershell
# FUTURO RUN 1 — substituir PID_VALIDADO pelo PID confirmado após revisão.
& 'D:\Games\Fortnite-Local-C2S3\runtime-mod\out\Debug\Season13Controller.exe' --attach PID_VALIDADO --milestone 0 --permit-local-runtime
```

RUN 1 passa somente com DLL/entrypoint atingido, identidade completa aprovada, base conhecida, logger funcionando, R0 PASS e retorno zero do controller. Não exige GObjects e não tenta R5. Se startup não for viável, acesso negado, headers divergentes, crash, timeout ou initialization não alcançada: FAIL/BLOQUEADO, preservar evidência e parar.

| Execução futura | Limite | Rollback / condição de próxima etapa |
| --- | --- | --- |
| RUN 1 | R0 apenas | Fechar Shipping normalmente, preservar log; revisar antes de RUN 2 |
| RUN 2 | R1 somente depois de revisão de assinatura/ABI/thread | Qualquer 0/ambíguo/estrutura/nome incoerente: parar; fechar alvo normalmente; sem retry no mesmo processo |
| RUN 3 | R2 após implementação | World/PersistentLevel/GameInstance coerentes; mundo ausente é estado/falha a registrar, sem travel |
| RUN 4 | R3 após implementação | Resolver/validar ProcessEvent, sem hook/invocação; candidato inconclusivo aborta |
| RUN 5 | R4 após implementação | Lookups reais limitados, sem resultado hardcoded; ciclos/layout incerto abortam |
| RUN 6 | R5 após implementação | Inspector somente leitura; distinguir null esperado de inválido; não iniciar partida |

Não fazer RUN 2 nesta etapa e não usar --milestone 2–5: CLI os recusa. Não há autoexec no script de build.

## Rollback e riscos restantes

Controller não eleva privilégios nem habilita SeDebugPrivilege. OpenProcess/alloc/thread negados encerram o teste; sem alternativa de bypass. Parâmetros são liberados após thread concluir; se timeout/Wait falhar, a alocação fica retida porque a thread pode usá-la. Não TerminateThread, não unload concorrente, não retry. A DLL fica ociosa carregada após resultado e o controller recusa reinjeção; rollback é **encerrar normalmente o alvo e começar processo novo somente após revisão**. O controller não força encerramento. Fechar o processo libera a DLL/alocações próprias; não há EXE/INI/PAK/hook para restaurar.

Riscos materiais: startup ainda desconhecido; carregamento/API podem ser negados; nenhuma ABI/thread affinity provada; todas as signatures dão zero no disco e podem falhar no runtime; array concorrente; divergência FES ObjectsPerChunk versus Reboot; UFunction.Exec FES 0xD8 versus Reboot 0xF0 (não usado); global GWorld não localizado. ARCH C reduz marshaling/acoplamento, mas não foi provada mais estável por execução.

Apollo futuro: Season13BuildProfile.Map referencia Apollo, enquanto Configuration.h/ServerSettings usam Athena_Terrain; conferir o consumidor e unificar a configuração somente em R6. Nenhuma correção/travel foi aplicada. Parada atual: cinco documentos e R0/R1 compilados, **nenhuma execução Fortnite**, aguardar revisão.
