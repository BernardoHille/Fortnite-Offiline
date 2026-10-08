# Toolchain Reboot — auditoria antes da instalação

2026-10-07. Fontes fixadas: Reboot3 `10c659028ad9d6816f78226483f11a884bf81f57`, Launcher `c6f82298b167ef2076bb59dc621f13dc5bd8d390`. README, solution/vcxproj, workflow msbuild.yml, pubspecs, CMake e scripts batch foram lidos antes de instalar dependências ou compilar. Nenhum AGENTS.md encontrado nos checkouts.

| Dependency | Required Version | Installed Version inicial | Required By | Status inicial |
| --- | --- | --- | --- | --- |
| Git | Git capaz de checkout do SHA | 2.55.0.windows.2 | Checkouts oficiais | INSTALADO |
| Visual Studio | 2022, componente Desktop C++ | Community 17.14.37111.16 | DLL/Flutter Windows | INSTALADO |
| MSVC | v143, stdcpplatest no Reboot3 | 14.38.33130 e 14.44.35207 | Reboot3 vcxproj | INSTALADO; versões exatas de cada build serão registradas |
| Windows SDK | 10.0, versionável via MSBuild | 10.0.22621.0 / 10.0.26100.0 | Reboot3/GUI | INSTALADO; fixar 10.0.26100.0 para DLL |
| CMake | >=3.14 | Bundled VS2022 | Flutter Windows/runner/plugins | INSTALADO fora do PATH |
| Flutter | Windows desktop; selecionado 3.24.5 | Não encontrado no PATH/locais usuais | GUI | Instalação portátil necessária |
| Dart | Pubspec GUI >=3.0.0 <=3.19.0; flutter_lints 5 requer >=3.5 | Incluído no SDK Flutter selecionado: 3.5.4 | GUI/common | Instalação conjunta, sem SDK Dart separado |
| .NET | MSBuild do VS; nenhum csproj Reboot | SDK 9.0.312 presente | Não exigido como app runtime | NÃO INSTALAR |
| Node/npm | Só reconstrução de auth_backend/lawinserver.exe | Node/npm disponíveis | Backend embutido já contém EXE/assets | NÃO NECESSÁRIO À GUI/DLL; não executar scripts backend |
| fmt/spdlog/curl/zlib/MinHook/ImGui | Vendorizados no commit Reboot3 | Fonte/headers e .lib presentes | DLL | Usar exatamente vendor oficial; sem vcpkg/download adicional |
| flutter_distributor | Script package.bat, empacotador de installer | Não consultado | Installer EXE, não build Windows bundle | NÃO NECESSÁRIO; não executar package.bat |

`environment.sdk` é restrição de **Dart**, apesar do comentário sobre Flutter 3.19 no pubspec. Flutter 3.24.5/Dart 3.5.4 foi o candidato inicial com base nas constraints diretas; a resolução comprovou um requisito transitivo maior de port_forwarder. O SDK foi substituído após confirmar esse requisito, conforme registrado abaixo.

**Nenhum pubspec.lock é versionado neste commit**, em gui/common/cli/server_browser_backend. Não há lock existente para respeitar/atualizar. A primeira resolução da GUI usará as constraints inalteradas e gerará um lock local novo, preservado e hashado; não usar pub upgrade. A dependência skeletons usa Git ref main upstream: registrar resolved-ref no novo lock. São dependências declaradas pelo repositório, não forks alternativos de Reboot.

Workflow Reboot3 não exige vcpkg/NuGet package references; vcxproj não contém Pre/PostBuild ou custom Exec. MSBuild Build basta, sem reproduzir nuget restore/CI upload/keepalive. Flutter CMake chama somente tool_backend e copia assets para bundle do próprio launcher; remover/recriar flutter_assets limita-se ao build do launcher, fora do jogo. Scripts backend (`npm install`, `npx nexe --build`, `node index.js`) não serão executados.

Referências: [Reboot3 project](https://github.com/Milxnor/Project-Reboot-3.0/blob/10c659028ad9d6816f78226483f11a884bf81f57/Project%20Reboot%203.0/Project%20Reboot%203.0.vcxproj), [GUI pubspec](https://github.com/Auties00/Reboot-Launcher/blob/c6f82298b167ef2076bb59dc621f13dc5bd8d390/gui/pubspec.yaml), [Flutter oficial/arquivo de versões](https://docs.flutter.dev/install/archive).

Atualização determinada por evidência: o primeiro `pub get` recusou Dart 3.5.4 porque **port_forwarder 1.0.0 exige ^3.7.2**. Metadados do pacote foram confirmados no registry oficial pub.dev e salvos em reboot/audit/port-forwarder-sdk-requirement.local.json. Selecionado **Flutter 3.29.3 / Dart 3.7.2**, tag do repositório oficial flutter/flutter, no mesmo SDK portátil, sem mudar pubspec/dependências do launcher. O SDK inicial 3.24.5 ficou supersedido. Versão final e ambiente confirmados por --version/doctor.

O bootstrap do próprio flutter_tools imprime `pub upgrade` para preparar o SDK recém-clonado; isso não é pub upgrade no launcher e não atualiza suas constraints/lock. GUI teve pub get inicial e builds --no-pub depois. Resultados finais em [REBOOT3_BUILD](REBOOT3_BUILD.md) e [REBOOT_LAUNCHER_BUILD](REBOOT_LAUNCHER_BUILD.md). Nenhuma instalação do jogo foi baixada, copiada, substituída ou atualizada.

## Toolchain final validada

| Dependency | Required Version | Installed Version final | Required By | Status final |
| --- | --- | --- | --- | --- |
| Git | Checkout dos commits fixados | 2.55.0.windows.2 | Fontes oficiais | VALIDADO |
| Visual Studio 2022 | Desktop C++ | Community 17.14.37111.16 / 17.14.29 | DLL e GUI | JÁ INSTALADO; build aprovada |
| MSVC | v143 compatível com .lib vendor | 14.44.35207; compiler 19.44.35225 | Reboot3 e runner Windows | JÁ INSTALADO; Debug/Release aprovados |
| Windows SDK | 10.0 | 10.0.26100.0 | DLL e GUI | JÁ INSTALADO; utilizado |
| CMake | >=3.14 | 3.31.6-msvc6, bundled VS | Flutter Windows | JÁ INSTALADO; utilizado |
| Flutter | Windows desktop com Dart >=3.7.2 | 3.29.3 oficial, SDK portátil | GUI e plugins | INSTALADO LOCALMENTE; Release aprovado |
| Dart | >=3.7.2 por port_forwarder | 3.7.2 incluído | GUI/common | VALIDADO |
| Pub packages | Constraints upstream inalteradas | 110 packages resolvidos; lock salvo | GUI | LOCK PRESERVADO; sem pub upgrade |
| .NET | Apenas infraestrutura VS/MSBuild | SDK 9.0.312 já presente | Não há app .NET a compilar | SEM INSTALAÇÃO ADICIONAL |
| Node/npm | Só reconstrução backend | Já disponíveis; não utilizados | Backend prebuilt embutido | NÃO NECESSÁRIO NESTA ETAPA |

Flutter doctor registra aviso de canal detached/origem do checkout e licenças Android pendentes. Remote do SDK é oficial; Windows/VS estavam disponíveis e a build Windows passou. Não foi alterado PATH global, registro Developer Mode ou instalação Android. Onze junctions NTFS locais resolveram a necessidade de links dos plugins sem privilégios de symlink; detalhes no relatório do launcher.
