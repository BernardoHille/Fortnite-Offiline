# Mapa de endereços/layout — somente 13.40 / CL 14113327

Data: 2026-10-07. **Nenhum endereço foi RuntimeConfirmed.** `CONFIRMADO POR CÓDIGO` valida o que a fonte contém, não o offset em um processo vivo. Endereços globais/funções e offsets de membros são categorias distintas. Não usar VA preferencial como base real sob ASLR.

Fontes de referência: FES season-13 `e42ecddbce59163c6a60ab7506766c2a0adfe580` e Reboot 3.0 `10c659028ad9d6816f78226483f11a884bf81f57`. Tabelas citam arquivos por identificador definido ao final. Código novo usa somente o subconjunto R0/R1. Campos para R2–R5 permanecem estratégia documentada.

## Identidade exata

| Nome | Tipo | Valor | Fonte / consumidor | Obrigatório agora? | Confiança |
| --- | --- | --- | --- | --- | --- |
| Build | String / identidade | Fortnite 13.40; `++Fortnite+Release-13.40` | Profile FES; guard/teste offline em arquivo original | Sim R0 | StaticAnalysis e verificação de hash/strings nesta etapa |
| EngineVersion | Perfil double | 4.25 | Season13BuildProfile, motor/layout | Perfil alvo; runtime não inferido por versão aproximada | FES, CONFIRMADO POR CÓDIGO |
| CL | int32 | 14113327 | Perfil + strings originais + SHA integral registrado | Sim R0 | FES / StaticAnalysis |
| EXE path | Caminho canônico Win32 | `D:/Games/FortniteLocal/13.40-CL-14113327/13.40/FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping.exe` | Auditoria/build validada; controller e DLL guard | Sim; não aceitar basename sozinho | Arquivo local confirmado |
| File size | uint64 bytes | 174908672 | PE audit anterior + inspeção própria atual | Sim R0 | StaticAnalysis |
| SHA-256 | Digest integral | `fb348e9a239a52170f2b46e99c225d4ec2bded53e40f8e7ff9daec3ac39a9f21` | Registro anterior e BCrypt próprio no arquivo, antes/depois | Sim R0 | StaticAnalysis; inalterado |
| Architecture | COFF uint16 / PE magic | AMD64 0x8664 / PE32+ 0x20B | Headers originais | Sim R0 | StaticAnalysis |
| PE TimeDateStamp | uint32 | 0x5F36A4A1 | Headers originais; carregado precisa concordar com arquivo validado | Sim R0 loaded-header check | StaticAnalysis |
| SizeOfImage | uint32 | 0x0AA81E00 | Headers originais, inclui nove sections (duas chamadas .text) | Sim R0 e bounds de scan | StaticAnalysis |
| ImageBase preferencial | uint64 | 0x140000000 | Optional header; **não** assumido no processo | Informativo | StaticAnalysis |

## Symbol / mecanismo de resolução

| Symbol | RVA/Pattern | Source | HowResolved | RuntimeValidated | RequiredMilestone |
| --- | --- | --- | --- | --- | --- |
| ImageBase real | Sem RVA fixo | Windows GetModuleHandleW / snapshot modules | Base do EXE carregado, header confrontado com arquivo validado | NÃO | R0 |
| GObjects / ponteiro para FChunkedFixedUObjectArray | `48 8B 05 ? ? ? ? 48 8B 0C C8 48 8B 04 D1` | FES signatures; Reboot FindObjectArray | Scan seções executáveis → **1 match** → disp32 signed em +3 → `instructionRVA+7+disp32` → global, base+RVA | NÃO; 0 matches no disco | R1 |
| GObjects signature alternativa | `48 8B 05 ? ? ? ? 48 8B 0C C8 48 8D 04 D1` | FES ObjectArrayReferenceAlternate | Apenas se principal tem zero; >1 em qualquer tentativa é AMBIGUOUS, sem escolher primeiro | NÃO; 0 no disco | R1, mesma build guardada |
| NameToString | Pattern constante FES em RuntimeAddresses.h | FES signatures / GetNameString | Unique executable scan → base+function RVA; página executável validada | NÃO; 0 no disco | R1 para nomes |
| MemoryRealloc | Pattern constante FES em RuntimeAddresses.h | FES signatures / GetNameString | Unique executable scan; ABI (ptr, size, align), usado só para liberar FString retornado | NÃO; 0 no disco; thread safety desconhecida | R1 para nomes, não R0 |
| GWorld **global** | Ausente no Season13BuildProfile / EngineOffsets | FES GetWorld e Reboot GetWorld | Nenhum endereço global resolvido. Não inventar RVA; opcional investigar futuramente | NÃO / DESCONHECIDO | Não obrigatório se equivalente UWorld validado R2 |
| Active UWorld | Sem offset fixo | FES EngineRuntime.GetWorld / Reboot reboot.h | FortEngine instância → propriedade GameViewport → World; FES fallback GameInstance.WorldContext | NÃO; ainda não implementado | R2 |
| ProcessEvent | Sem RVA fixo; wide anchor `AccessNoneNoContext` | FES ResolveProcessEvent; Reboot FindProcessEvent | Anchor literal → RIP xref executável → função candidata/backtrack → confirmação vtable. FES fallback heurístico não será adotado silenciosamente | NÃO; ainda não implementado | R3 resolução; invocação fora do mínimo |
| StaticFindObject | EngineOffsets.StaticFindObject=0; signatures/anchor FES | FES ResolveGlobals / Reboot finder | Pattern ou string de erro → xref → function start. Lookup nativo opcional; traversal pode evitá-lo | NÃO | R4 possível, não R0/R1 |
| StaticLoadObject | EngineOffsets.StaticLoadObject=0; `STAT_LoadObject` anchor | FES ResolveGlobals | Wide literal/xref → function start | NÃO | Não: não carregar assets neste milestone |
| SpawnActor | EngineOffsets.SpawnActor=0; anchor de erro SpawnActor | FES ResolveGlobals | Anchor → scan de prologue; função futura de gameplay | NÃO | Não: GAMEPLAY_ONLY |
| NameConstructor | EngineOffsets.NameConstructor=0; ClientIgnoreLookInput anchor | FES ResolveNameConstructor | Xref → LEA + call/jmp relativo → destino | NÃO | Não no traversal mínimo; não adicionar nomes ao pool |
| GameInstance | OwningGameInstance / Engine.GameInstance, sem valor fixo | FES EngineRuntime/World.cpp | FindPropertyInStruct e ler ponteiro em baseObjeto+offset obtido por reflection | NÃO | R2/R5 |
| GameMode | AuthorityGameMode, sem offset fixo | FES UWorld::GetAuthorityGameMode | Reflection da propriedade, pode ser nulo em client/front-end | NÃO | R5 |
| GameState | GameState, sem offset fixo | FES UWorld::GetGameState | Reflection, leitura e validação de classe | NÃO | R5 |
| PlayerController | LocalPlayers[i].PlayerController | FES GetLocalPlayer; ObjectHandle property API | Reflection de array e propriedade, bounds/ponteiros | NÃO | R5 |
| Pawn | PlayerController.Pawn; perfil PlayerPawnClassPath | Profile FES + reflection | Classe/path não é pointer/offset de instância; ler propriedade futuramente | NÃO | Não obrigatório agora |
| NetDriver | UWorld.NetDriver, sem offset fixo | FES World/GetNetDriver | Reflection; nulo é possível. Não instalar hooks/listen | NÃO | R5 somente leitura |

**EngineOffsets do perfil: ObjectArray/StaticFindObject/StaticLoadObject/NameConstructor/NameToString/ProcessEvent/MemoryRealloc/SpawnActor permanecem 0.** No FES, override não zero seria **RVA**: ApplyOffsetOverrides faz ImageBase+Override. O perfil não fornece tabela de RVAs para nosso CL. A resolução combina patterns, RIP-relative, strings/xrefs, prologues, vtables, reflection e chamadas via bridge; não depende de PDB/export de Fortnite. Exports são usados apenas para nosso Season13Start/LoadLibraryW no bootstrap.

## Layout exato declarado e consumidores

| Nome | Tipo | Offset/valor | Fonte | Consumidor | Obrigatório? | Confiança |
| --- | --- | --- | --- | --- | --- | --- |
| UObjectSize | int32 | 0x28 | Profile | ObjectView bounded read | R1 | FES, código; runtime pending |
| VTable / ObjectFlags / InternalIndex | int32 byte offsets | 0x00 / 0x08 / 0x0C | FES UnrealLayout; Reboot UObject | Vtable/index validity, flags apenas referência | Vtable/index R1; flags opcional | FES/Reboot, código |
| UObject.Class / Name / Outer | int32 byte offsets | 0x10 / 0x18 / 0x20 | Profile | ObjectView / FName / traversal futuro | Class/Name R1; Outer lido, traversal R4 | FES/Reboot, código |
| FName comparison / number | int32 + int32 | FName+0 / +4; size 8 | FES UnrealTypes; Reboot NameTypes | ReadName | R1 | Código, ABI runtime pending |
| Object item object / stride | int32 | 0 / 0x18 | Profile + Reboot FUObjectItem layout | ObjectArray.At | R1 | Código |
| Chunked array Objects / PreAllocatedObjects | offsets | 0 / 8 | Reboot UObjectArray | Chunks pointer; PreAllocated não usado | Objects R1 | Código |
| MaxElements / NumElements | offsets | 0x10 / 0x14 | Reboot UObjectArray + FES GetObjectCountOffset | Capacity/count guard | R1 | Código |
| MaxChunks / NumChunks | offsets | 0x18 / 0x1C | Reboot UObjectArray | Header coherence guard | R1 | Código |
| ObjectsPerChunk | int32 contagem | **65536 (0x10000)** | Reboot Main/UObjectArray; FES default header | ObjectArray.At; teste entre índices 0 e 65536 | R1 | Código corroborado; não RuntimeConfirmed |
| UField.Next | int32 | 0x28 | Profile | Function traversal futuro | R4 | FES, código |
| UStruct.SuperStruct / Children | int32 | 0x40 / 0x48 | Profile | Classes/UFunctions futuros | R4 | FES, código |
| UStruct.ChildProperties / PropertiesSize | int32 | 0x50 / 0x58 | Profile | FField property reflection | R2/R4/R5 | FES/Reboot, código |
| FField.Next / Name | int32 | 0x20 / 0x28 | Profile | Property chain/name matching | R2/R4 | FES, código |
| UProperty.ElementSize / Flags / Offset_Internal | int32 | 0x3C / 0x40 / 0x4C | Profile | Reflection property extraction | R2/R4/R5 | FES, código |
| UBoolProperty.FieldMask | int32 | 0x7B | Profile | Bitfield extraction futuro | Opcional | FES, código |
| UFunction.Flags / Exec | int32 | 0xB0 / **0xD8 no FES** | Profile | Native function metadata futuro | Não R0/R1 | FES, código; Exec conflita com Reboot 0xF0 para engine425 |
| PersistentLevel / Actors / WorldType | Propriedade; tipo via metadata | **Sem offset inventado** | UWorld/ULevel reflection | World inspector | R2/R5, WorldType opcional | Estratégia INFERIDO, ainda não implementado |

Dois conflitos materiais: o override do profile FES usa **2730** (`64*1024/0x18`) apesar de default/header/estrutura em elementos; nosso código não copiou esse valor. UFunction.Exec diverge entre upstreams; não é usado agora. Os testes de fixtures verificam a matemática de chunks escolhida, **não o layout vivo de Fortnite**.

## Referências e prova

- [FES profile](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/FortniteGame/Private/Versioning/Season13BuildProfile.cpp), [profile types](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/FortniteGame/Public/Versioning/FortBuildProfile.h), [UnrealLayout](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Runtime/CoreUObject/Public/UObject/UnrealLayout.h), [signatures](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Runtime/CoreUObject/Public/UObject/CoreUObjectSignatures.h).
- [FES resolver/reflection](https://github.com/OGFN-Open-sourceing/FortExternalServer/blob/e42ecddbce59163c6a60ab7506766c2a0adfe580/Source/Runtime/CoreUObject/Private/UObject/UnrealRuntime.cpp); [Reboot arrays](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/UObjectArray.h), [addresses/offsets](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/addresses.cpp).
- Nosso [RuntimeAddresses](../runtime-mod/src/RuntimeAddresses.cpp) e [guard](../runtime-mod/src/Season13BuildGuard.cpp), auditoria anterior [LAUNCH_CHAIN](PHASE2_LAUNCH_CHAIN.md). Proveniência local e hashes ficam em `runtime/season13/audit/`, ignorado.

Nenhum valor é marcado RuntimeConfirmed. Uma futura captura só poderá promover uma linha após evidência estrutural específica; não basta logar um endereço não nulo.
