# Trace Reboot 3.0: DllMain → Unreal

Revisão fixa `10c659028ad9d6816f78226483f11a884bf81f57`, arquivos textuais selecionados, sem clone completo, compilação ou execução de upstream/launcher. Linhas aproximadas dos arquivos auditados em `runtime/phase2/community-stack-audit`; caminhos da tabela relativos a `Project Reboot 3.0/`. Todas as funções descritas são evidência de código, **não execução comprovada em nosso CL**.

## Ordem real de inicialização

| Ordem / arquivo / linha aprox. | Função / classe | Chamada / mecanismo | Responsabilidade e classificação |
| --- | --- | --- | --- |
| 1 `dllmain.cpp` ~1854 | `DllMain(DLL_PROCESS_ATTACH)` | CreateThread → Main | Bootstrap interno; REQUIRED_FOR_RUNTIME no upstream. Não copiar trabalho sob loader lock. Nosso DllMain só desabilita notificações de thread. |
| 2 `dllmain.cpp` ~906 | `Main` | InitLogger, MH_Initialize, GetModuleHandleW(0) | Logger/base: REQUIRED_FOR_RUNTIME/OPTIONAL; MinHook: necessário ao host hooked upstream, **não a leitura inicial** |
| 3 `addresses.cpp` ~22 | `Addresses::SetupVersion` | Signature para GetEngineVersion; chamada native retornando FString; parsing de versão | VERSIONING_ONLY. Multiversão e CL parcialmente tratado em branches; não substitui hash/guard exato. Nosso guard não chama Unreal. |
| 4 `dllmain.cpp` ~934 | `Main` | NumElementsPerChunk selecionado; Offsets::FindAll/Print | Para 13.40 seleciona 0x10000 **elementos** por chunk. Layout/reflection: REQUIRED_FOR_RUNTIME; offsets de replicação são NETWORK_ONLY |
| 5 `addresses.cpp` ~413 | `Offsets::FindAll` | SuperStruct/Children/PropertiesSize/Offset_Internal e outros por versão | Layout para reflection; engine425/13.40 dá SuperStruct 0x40, Children FField 0x50, Offset_Internal 0x4C. UFunction exec difere do FES; não transplantado |
| 6 `dllmain.cpp` ~938 / `addresses.cpp` ~123 | `Addresses::FindAll` | FindProcessEvent, FindStaticFindObject, FindObjectArray e muitos finders de hosting | Resolver mínimo está misturado a NETWORK_ONLY/GAMEPLAY_ONLY. Nosso código não importa FindAll integral |
| 7 `finder.h` ~132 | `FindProcessEvent` | Para versão <14: string wide AccessNoneNoContext → string ref → busca bytes 40 55 em janela ~2000 | Endereço de função por anchor/backtracking; não é RVA fixo. Escolha heurística não fornece validação de ABI/vtable nem unicidade. R3 futuro exige validação adicional |
| 8 `finder.h` ~146 | `FindObjectArray` | Pattern x64 → RelativeOffset(3) | Para engine425/13.40 usa a mesma signature principal do FES. Resolve global por RIP; não enumera objetos nesse passo |
| 9 `finder.h` ~66 | `FindStaticFindObject` | Patterns/anchor de erro StaticFindObject conforme branch | Native lookup de UObject. Outros helpers podem inicializar lookup preguiçosamente; não confundir disponibilidade do wrapper com execução de Addresses::FindAll |
| 10 `addresses.cpp` ~558 | `Addresses::Init` | Preenche pointers de funções; ObjectArray → ChunkedObjects para engine>=421 | Bindings internos. Rede/gameplay/session também estão aqui; somente acesso de objeto é parte do diagnóstico |
| 11 `UObjectArray.h` ~94 | `FChunkedFixedUObjectArray::GetItemByIndex` | Objects[chunkIndex] + withinChunkIndex; FUObjectItem contém UObject* | Traversal interno, NumElements/MaxElements/NumChunks; REQUIRED_FOR_RUNTIME para R1. Sem marshaling remoto |
| 12 `Object.h` ~33 / `Object.cpp` | `UObject`, GetName/GetFullName/GetOffset | ClassPrivate, NamePrivate, OuterPrivate; reflexão de propriedades/superstruct | REQUIRED_FOR_RUNTIME para reflection. Field/UFunction layouts precisam corresponder à build |
| 13 `UnrealNames.cpp` ~8 / ~71 | `FName::ToString` | FindObject KismetStringLibrary + Conv_NameToString → **ProcessEvent** | Name conversion usa chamada refletida no Reboot; não é só FNamePool read. Não copiado: nosso R1 usa ABI NameToString/Realloc do FES, sem ProcessEvent |
| 14 `Object.h` ~47 | `UObject::ProcessEvent` | ProcessEventOriginal(this, Function, Parms) | Chamada direta de função resolvida; não exige instalar hook ProcessEvent para invocar. Exige params/thread/ABI; fora de R0/R1 |
| 15 `reboot.h` ~74 | `GetEngine` | FindObject /Engine/Transient.FortEngine_0; fallback de nomes FortEngine | Reflection/lookup de instância. Fallback numérico histórico não copiado; nosso futuro lookup será por classe/instâncias e sem escolher primeiro candidato ambíguo |
| 16 `reboot.h` ~92 | `GetWorld` | Engine.GetOffset(GameViewport) → GameViewport.GetOffset(World) → UWorld* | **Equivalente de mundo ativo por reflection**, não resolução de global GWorld |
| 17 `Object.cpp`, `World.h` | GetOffset/Get por metadata; UWorld GameMode/GameState getters | Lista de properties e superstruct; offsets lidos dinamicamente | REQUIRED_FOR_RUNTIME para R2/R5; GameMode pode ser nulo no cliente inicial |
| 18 `dllmain.cpp` ~1051 em diante | Main instala hooks | NoMCP/DispatchRequest/KickPlayer/GetNetMode/TickFlush e gameplay hooks | NETWORK_ONLY / SESSION / SECURITY_RELATED ou UNKNOWN pela finalidade; não importado para diagnóstico |
| 19 `dllmain.cpp` restante | GUI, host lifecycle, gameplay | Hosting e modificações multiversão | GAMEPLAY_ONLY/OPTIONAL; fora da vertical slice. Não seguir bots/inventory/storm/cosmetics/progression nesta etapa |

## Separação por finalidade

| Grupo | Aproveitamento nesta etapa |
| --- | --- |
| Runtime | Ideia de executar dentro do address space; layouts UObject/chunk count e lookup/reflection como evidência |
| Gameplay | Somente localização dos limites da inicialização; hooks/spawn/match não importados |
| Network | NetDriver/replicação/hosting excluídos do código R0/R1 |
| Session | KickPlayer/NoMCP/DispatchRequest não importados; não remover recusas de sessão para desbloquear boot |
| Auth/security | Launcher não usado; nenhum argumento, patch, suspensão de EAC/BE ou função de bypass adotado |

MinHook inicializa cedo porque o Reboot é um host com hooks, não porque GUObjectArray ou uma classe só possam ser lidos com MinHook. Nossa DLL não depende de MinHook/trampolines/VEH. O caminho mínimo escolhido não chama InitLogger/SetupVersion/Offsets::FindAll/Addresses::FindAll do Reboot, nem utiliza seu DLL prontamente executável.

## O que foi reutilizado e o que permanece desconhecido

Reutilizado como **evidência factual**: classe UObject, arrays chunked com 65536 itens, campos de capacidade, acesso interno e rota GameViewport.World. Não se copiou gameplay. A entrada no address space do alvo é responsabilidade do nosso controlador, separado de auth/anti-cheat. Entry/lookup/nomes em runtime ainda NÃO TESTADOS.

O conflito `UFunction Exec: FES 0xD8 / Reboot engine425 0xF0` não foi resolvido por suposição. Não é necessário a R0/R1 e não está em nosso código. A estabilidade da versão exata, signatures e afinidade de threads será verificada por milestone posterior; não prometer que a DLL Reboot sirva ao nosso CL só porque há ramo Season13.

Fontes: [dllmain](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/dllmain.cpp), [addresses](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/addresses.cpp), [finder](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/finder.h), [UObjectArray](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/UObjectArray.h), [UnrealNames](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/UnrealNames.cpp), [reboot helpers](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/reboot.h). Licença BSD-3-Clause registrada nos notices do projeto de diagnóstico.
