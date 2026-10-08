# Fortnite-Offiline — Chapter 2 Season 3

Projeto local de estudo para **Fortnite 13.40 / CL 14113327** usando Reboot Launcher, Project Reboot 3.0 e Lawin Embedded.

**Marco atual:** lobby, host Apollo, Battle Bus, salto e movimentação pelo usuário; BOT-0 cria um bot Phoebe que permanece parado. O **Native Phoebe V1 terminou NAV-BLOCKED, sem criar bot**, no teste de 08/10/2026 às 10:46:38. O teste definitivo de gameplay usou **Headless On**, backend e game server locais, **com internet conectada**. Execução completamente offline, AI autônoma, bosses e estabilidade prolongada ainda não foram validados.

![Battle Bus no teste local](docs/media/season13-battle-bus.png)

## Comece aqui

- **[Como preparar e rodar](docs/COMO_RODAR_REBOOT.md)**: pré-requisitos, comandos de compilação/configuração e ordem Host → Play → partida → Start Bus.
- **[Validação manual e evidências](docs/REBOOT_MANUAL_VALIDATION.md)**: capturas, trechos sanitizados do log, DLLs realmente carregadas, Headless e limites do teste.
- **[Histórico de tudo que fizemos](docs/PROJECT_HISTORY.md)**: fases iniciais, auditorias, runtime próprio congelado, preparação Reboot e próximas etapas.
- **[Estado de bots e reprodução Native Phoebe V1](docs/NATIVE_PHOEBE_BOOTSTRAP_V1.md)** e **[resultado/procedimento do teste](docs/NATIVE_PHOEBE_BOOTSTRAP_V1_TEST.md)**: patches cumulativos, DLL/PDB, navegação e bloqueios confirmados.
- [Arquitetura Reboot](docs/REBOOT_COMPONENT_MAP.md), [auditoria Launch/auth/EAC/TLS](docs/REBOOT_LAUNCH_AUDIT.md), [fluxo de bots ainda não validado](docs/REBOOT_BOT_FLOW.md).

## Reproduzir a preparação

Windows x64, PowerShell 7, Git, VS 2022 Desktop C++, MSVC v143 **14.44.35207**, Windows SDK **10.0.26100.0**. O SDK Flutter oficial **3.29.3 / Dart 3.7.2** fica portátil no projeto.

```powershell
git clone https://github.com/BernardoHille/Fortnite-Offiline.git
Set-Location Fortnite-Offiline
./scripts/restore-reboot-stack.ps1 -IncludeFlutterSdk
./scripts/build-reboot3.ps1 -Configuration Both
./scripts/build-reboot-launcher.ps1
./scripts/configure-reboot-launcher.ps1 -BuildPath 'D:\Games\FortniteLocal\13.40-CL-14113327\13.40'
```

Esses comandos não iniciam GUI, Fortnite ou backend e não baixam outra build do jogo. A instalação existente precisa ficar fora do Git. O configurador deixa contas/senhas vazias e preserva settings já existentes. Veja o guia antes da execução manual: o fluxo upstream usa auth DLL, suspensão de auxiliares e hooks, já documentados.

Saídas locais: `reboot/artifacts/reboot3/{Debug,Release}/Project Reboot 3.0.dll` e bundle `reboot/artifacts/launcher/Release/`. Execute a GUI a partir do bundle completo, mantendo DLLs/plugins/data junto ao EXE. Na máquina original os artefatos já estão preparados; não precisa recompilar/importar o jogo novamente.

Os comandos acima restauram o baseline de gameplay. Para reproduzir os ensaios de bots, aplicar a cadeia de patches indicada em [reboot/bot-ai.lock.json](reboot/bot-ai.lock.json) sobre o upstream fixado, conforme o guia V1. Os seis patches foram verificados em um checkout de auditoria separado e reconstruíram os sete arquivos afetados exatamente. Não reaplicar patches no checkout local já modificado; o build V1 usa OutDir/IntDir próprios.

## Bots e Phoebe — estado comprovado

| Revisão | Resultado |
| --- | --- |
| BOT-0 | Um Pawn/Controller Phoebe criado, posse e PlayerState válidos; parado, Brain null |
| BOT-1 | MoveToLocation retorna Failed |
| BOT-2 | NavDataSet vazio; projeções falham e query de caminho retorna null |
| Native Phoebe preflight | Manager/assets/metadados válidos; spawn deliberadamente não chamado |
| Native Phoebe V1 | NAV-BLOCKED, zero spawn ON; flags GoalManager/Director true, initial lock false, nenhuma AthenaNavMesh registrada |

No V1, `Apollo_Nav_Gameplay` está carregado/visível, mas as oito variantes `WaterLevel_0..7` estão descarregadas. O sistema usa streamed nav com autocriação/rebuild desativados. Isso direciona a investigação à seleção/carregamento da variante de navegação da água; ainda não é uma causa comprovada. Não foi removido lock nem implementada AI customizada. Evidência selecionada em [trechos técnicos V1](docs/evidence/native-phoebe-v1-runtime-excerpts.txt). Os guards do Reboot usam o valor runtime `Engine_Version=426` medido nesta build.

## O que este Git preserva

```text
reboot/stack.lock.json        repositórios, commits, SDK/toolchain e hashes
reboot/patches/               compatibilidade de build e revisões cumulativas de bots/Phoebe
reboot/bot-ai.lock.json       ordem/hashes dos patches e identidade do V1
reboot/locks/                 pubspec.lock completo da GUI
reboot/config/                perfil reproduzível sem dados pessoais
scripts/*reboot*.ps1          restauração, compilação, configuração e verificação
docs/                        auditorias, histórico, guia e evidências selecionadas
runtime-mod/                 controller/Season13Runtime próprios, congelados
backend/, gameserver/        patches/referências históricas; não integrados ao Reboot
```

Checkouts/SDKs podem ser reconstruídos dos locks; não são vendorizados. Jogo/PAKs/chaves, executáveis/DLLs/PDBs, saves, logs brutos e settings com contas/senhas **não são publicados**. As DLLs auxiliares baixadas pelo launcher foram identificadas por hashes e correspondem ao commit oficial fixado; seu download não comprova que todas foram injetadas.

No Git ficam todos os scripts e patches necessários para reconstruir nossa preparação. Credenciais/perfis pessoais devem ser configurados localmente. O nome "Offiline" é o nome escolhido para o repositório, não uma afirmação de que o teste já ocorreu sem internet.

## Próximas etapas

Investigar seleção/carregamento dos níveis de navegação WaterLevel e a origem restante de building_or_locked; validar perfil/component pipeline BR antes de habilitar spawn/Brain nativo. Validar encerramento, falha inicial de host/Log Out, estabilidade e operação desconectada. Season13Runtime ainda não foi integrado. Os relatórios READY B anteriores são históricos da preparação, antes do teste manual de gameplay.

[Licenças e componentes terceiros](THIRD_PARTY_NOTICES.md) · [Setup histórico do backend anterior](docs/SETUP.md) · [Preparação Reboot e hashes dos builds](docs/REBOOT_INSTALL_REPORT.md)
