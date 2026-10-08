# Project Reboot3 — build local

Projeto correto: **reboot/reboot3/Project Reboot 3.0.sln**, único vcxproj **Project Reboot 3.0/Project Reboot 3.0.vcxproj**, ConfigurationType=DynamicLibrary. Commit base10c659028ad9d6816f78226483f11a884bf81f57. DLL e não EXE independente. Nenhuma DLL carregada/executada.

Toolchain final: VisualStudio2022 Community17.14.37111.16, MSBuild bundled, MSVCv143 ferramentas14.44.35207 / compiler19.44.35225, WindowsSDK10.0.26100.0, x64/stdcpplatest. fmt/spdlog/curl/zlib/MinHook/ImGui do vendor oficial, sem instalação vcpkg. ABOVE_S20 não definido.

| Configuration | Platform | Status | Warnings / errors finais | Output / SHA-256 |
| --- | --- | --- | --- | --- |
| Debug | x64 | COMPILED, exit0 | 1140 warning occurrences / 0 errors | reboot/artifacts/reboot3/Debug/Project Reboot 3.0.dll; **fd7fece04c4bb823b9215093b51786b3ba33ea1676b605e99c4c105c8d0bf272** |
| Release | x64 | COMPILED, exit 0 | 1120 warning occurrences / 0 errors | reboot/artifacts/reboot3/Release/Project Reboot 3.0.dll; **2f6acb349a942f086a453596d0fd10c65682563b12ee25d27a7d2abdfec35c3c** |

Debug PDB SHA **f7edbedb41c1ac83eae2fbbffb61adef4e098e65797fb5b718b9b2999383e2ea**, mesmo diretório. IntDir separado em reboot/artifacts/intermediate/reboot3/CONFIG; nenhum output na instalação Fortnite. Logs completos em reboot/logs/reboot3-Debug-final.log e reboot3-Release.log.

Release PDB SHA-256 **400d293d050e0e9ebb7c05fa2345572e5ddba549366e3a37269f3e143bb0144f**, 25.907.200 bytes. DLL Debug: 9.791.488 bytes; DLL Release: 2.988.032 bytes. Headers PE das duas DLLs confirmam AMD64 (0x8664), característica DLL; verificação por leitura, sem LoadLibrary. Hashes, tamanhos e contagens finais em `reboot/audit/evidence.local.json`.

## Ajuste mínimo de build / diff

Primeira build Debug com ferramentas14.38 falhou LNK2038 (CRT/iterator ABI das bibliotecas prebuilt) e LNK2019 para helpers STL recentes em spdlog. Usadas ferramentas14.44 já instaladas. Ajuste inicial de /MT mantendo _DEBUG ainda produziu CRT debug incompatível, registrado em reboot3-Debug-fixed.log; não ocultamos errors com /NODEFAULTLIB.

Único arquivo upstream alterado: vcxproj, grupo **Debug|x64**:

```diff
- <PreprocessorDefinitions>_DEBUG;PROJECTREBOOT30_EXPORTS;_WINDOWS;_USRDLL;%(PreprocessorDefinitions)</PreprocessorDefinitions>
+ <PreprocessorDefinitions>_ITERATOR_DEBUG_LEVEL=0;PROJECTREBOOT30_EXPORTS;_WINDOWS;_USRDLL;%(PreprocessorDefinitions)</PreprocessorDefinitions>
+ <RuntimeLibrary>MultiThreaded</RuntimeLibrary>
```

Motivo: bibliotecas vendorizadas requerem CRT static Release /MT e iterator0. Debug conserva configuração sem otimização e símbolos PDB, **não possui heap CRT Debug nem iterator checks Debug**. Não chamá-lo Debug CRT completo. Macro _DEBUG não dirige lógica de gameplay/auth no source do projeto; não acrescentamos NDEBUG nem trocamos hooks/offsets/args. Release vcxproj não alterado. Patch integral em reboot/audit/reboot3-build-compat.patch, inclui apenas newline final adicional.

## Comando de compilação equivalente

Executar MSBuild do VS com /t:Build /m:2, solution acima, /p:Configuration=Debug ouRelease, /p:Platform=x64, /p:PlatformToolset=v143, /p:VCToolsVersion=14.44.35207, /p:WindowsTargetPlatformVersion=10.0.26100.0, /p:CL_MPCount=2 e OutDir/IntDir separados. Release só iniciado depois de Debug aprovado. Build não contém hooks Pre/PostBuild ou custom launch. Não usar o workflow acimaS20 nem executar o artefato.

## Warnings preservados e limite da prova

Debug: C4244(975), C4267(104), C4172(20), C4715(17), C5260(9), C4305(6), C4624(5), C4828(2), demais2. Contagem de ocorrências repetidas de headers/TUs, não bugs distintos. **C4172 retorna endereço/referência de variável local/temporária; C4715 falta retorno em alguns caminhos.** São riscos reais de runtime upstream; não alteramos lógica para eliminá-los nesta etapa. Conversões/narrowing também exigem validação futura.

Release: C4244 (975), C4267 (104), C4172 (16), C5260 (9), C4305 (6), C4624 (5), C4828 (2), C4099 (1), C4715 (1), C4838 (1). Total: 1120 ocorrências, nenhum erro de compilador/linker. Final do log confirma geração de código e output da DLL; processo MSBuild terminou com exit 0. Os warnings de lifetime/retorno continuam sendo limitações de runtime.

COMPILED comprova compiler/linker, não ABI/offsets, boot, estado Apollo ou estabilidade. O loader/auth/EAC do launcher continua [bloqueado](REBOOT_RUNTIME_BLOCKER.md). Nenhum teste de gameplay/bots realizado; [suporte por código](REBOOT_BUILD_SUPPORT.md) não equivale a suporte do CL em execução.
