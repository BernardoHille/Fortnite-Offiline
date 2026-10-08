# Reboot Launcher — Windows build local

Registro da primeira compilação e preparo, antes do teste manual. [Validação posterior](REBOOT_MANUAL_VALIDATION.md); [recompilação e entrega para Git](PUBLICATION_REPORT.md). O EXE do bundle do teste foi conservado; a recompilação de verificação tem hash próprio registrado no relatório de publicação.

**COMPILED**, GUI10.0.9, Windows x64 Release. Commit base `c6f82298b167ef2076bb59dc621f13dc5bd8d390`, dois ajustes mínimos documentados abaixo. GUI **NÃO ABERTA**, Launch **NÃO PRESSIONADO**; compilação não valida o boot de Fortnite.

| Campo | Valor |
| --- | --- |
| Flutter | 3.29.3, SDK portátil em reboot/tools/flutter-sdk |
| Framework commit / engine | ea121f8859e4b13e47a8f845e4586164519588bc / cf56914b326edb0ccb123ffdc60f00060bd513fa |
| Dart | 3.7.2; incluído no Flutter, não instalado separadamente |
| Target / mode | windows-x64 / Release |
| Native tools | VS2022 17.14.29; v143; Windows SDK10.0.26100.0; CMake3.31.6-msvc6 |
| Command | flutter --no-version-check gen-l10n; flutter --no-version-check build windows --release --no-pub |
| Final log | reboot/logs/launcher-build-release-final.log, exit0, Built build/windows/x64/runner/Release/reboot_launcher.exe |
| Warnings / errors finais | 0 compiler warnings / 0 errors encontrados no log final; SDK doctor tem aviso de canal detached e licenças Android, não exigidas para Windows |
| Original output | reboot/launcher/gui/build/windows/x64/runner/Release/ |
| Bundle entregue | **D:/Games/Fortnite-Local-C2S3/reboot/artifacts/launcher/Release/** |
| EXE SHA-256 | **5b5f43d320091cdc9efafb5acb70c89ad0038fc9e0dbf7c42ffd59ac700dd1fb** |
| pubspec.lock SHA-256 | db2dff71e1934f97410096529a5a83be9c7217ec12c06cc2737ac875dec4b63d |
| Skeletons Git resolved-ref | 81c72420ac1a31a9f0ebf6de9d8dd2bf50fe96ab |

O bundle precisa de flutter_windows.dll, plugins e data/, não distribuir/executar só o EXE. Assets do backend/downloader são cópias dos arquivos no commit oficial, **não foram executados**. Manifesto local registra hashes do bundle, não apenas EXE. Nenhuma DLL externa/mirror/nightly foi obtida para autenticação/gameplay.

## Dependências e correções de build

1. Sem pubspec.lock upstream. Flutter3.24.5/Dart3.5.4 inicial recusado pelo solver: port_forwarder1.0.0 exige Dart^3.7.2. SDK oficial foi fixado em3.29.3; pubspecs não alterados, sem pub upgrade no launcher.
2. Pub get final resolveu110 packages dentro das constraints e escreveu lock. Exit1 ocorreu **depois da resolução** ao criar symlink: Developer Mode não ativo. Criamos11 junctions NTFS locais para packages já resolvidos, validadas por Dart Link.existsSync. Sem admin/registro/Developer Mode; SDK/source não patchados para ignorar permissões. Builds posteriores --no-pub preservaram lock idêntico. Em nova resolução, Flutter pode recriar links; não alterar dependências silenciosamente.
3. `gui/l10n.yaml`: acrescentado `synthetic-package: false`. Imports upstream já esperavam `lib/l10n/reboot_localizations.dart`; gen-l10n agora gera nesse local. Sem mudar texto/traduções ou comportamento de Launch.
4. `common/lib/src/game/game_downloader.dart`: callers referiam duas constantes inexistentes, causando compile error. Restauradas declarações `_kRebootBelowS20FallbackDownloadUrl`/`_kRebootAboveS20FallbackDownloadUrl` do **parent oficial c9ed6a5af3d26474213c130f84fe330a55ee5a6a** de d53a577. Nenhuma URL foi inventada; targets permanecem GitHub oficial do launcher. Não executamos downloader/fallback nem buscamos os ZIPs. Isto corrige declaração para compilar, não desbloqueia boot.

Diff em reboot/audit/launcher-build-compat.patch; arquivos gerados/lock são locais. Source de Launch/auth/suspensão/injeção intacto. NuGet/backend scripts/package.bat/flutter_distributor não executados. Plugins CMake foram inspecionados; download de GoogleTest aparece em blocos de testes opcionais, não foi necessário no log final da GUI.

## Configuração fora da instalação

Storage real do GetStorage2.1.1 é JSON UTF-8 em settings/*.gs, backup *.bak, junto ao bundle (installationDirectory=parent de Platform.resolvedExecutable). Foram preparados:

- v3_game_storage: versões como string JSON, uma entrada selecionada **Fortnite 13.40 CL14113327**, gameVersion13.40, location **D:/Games/FortniteLocal/13.40-CL-14113327/13.40**. A busca recursiva de Shipping aceita a raiz; não copiar a versão para outro local.
- v3_dll_storage: custom_game_server=true; game_server aponta **reboot/artifacts/reboot3/Release/Project Reboot 3.0.dll**, porta7777. Não integra Season13Runtime.
- v3_hosting_storage: headless=false, auto_restart=false; campos de conta/senha/custom args vazios. Nenhuma credencial Epic preenchida.

JSON parse e seleção foram conferidos sem iniciar GUI. Não passamos por Import: _importVersion chama patchHeadless antes de salvar. Não configurar auto-download, autorizar launch ou alterar arquivos da build como parte de uma simples importação.

Teste read-only do método extractGameVersion retornou13.40 **por basename fallback**; findFiles achou único Shipping correto; mapa CL14113327 existe. CL não é campo do model GameVersion e não foi mostrado na GUI. [Detalhes](REBOOT_BUILD_SUPPORT.md).

Abrir GUI stock causa WebSocket/browser remoto e downloads automáticos de DLLs pelo pager, portanto a visualização não foi feita nesta etapa. [Auditoria](REBOOT_LAUNCH_AUDIT.md), [bloqueios](REBOOT_RUNTIME_BLOCKER.md). Arquivo configurado não é prova de GUI ou Fortnite funcional.
