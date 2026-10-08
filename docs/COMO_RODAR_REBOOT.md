# Como preparar e rodar a configuração validada

Build única: **Fortnite 13.40 / CL 14113327 / UE 4.25 / Chapter 2 Season 3**. Marco atual: lobby, host Apollo, Battle Bus, salto e movimentação obtidos manualmente com internet conectada. Leia [a validação e suas limitações](REBOOT_MANUAL_VALIDATION.md).

## Quem já está nesta máquina

Não é necessário restaurar, recompilar, importar ou baixar Fortnite novamente. O bundle existente fica em:

```text
D:\Games\Fortnite-Local-C2S3\reboot\artifacts\launcher\Release\reboot_launcher.exe
```

Manter as DLLs/plugins/data/settings junto ao EXE. DLL de host selecionada:

```text
D:\Games\Fortnite-Local-C2S3\reboot\artifacts\reboot3\Release\Project Reboot 3.0.dll
```

Os settings atuais possuem dados pessoais e ficam apenas locais. Não copiar esses arquivos ao Git. O procedimento manual usado está na seção de execução abaixo; os scripts históricos OBSERVACAO-RUNTIME.bat/start-phase2 não são o launcher desse stack.

## Preparação em outro checkout/PC

Pré-requisitos: Windows x64, Git, **PowerShell 7**, Visual Studio **2022** com Desktop development with C++, MSVC **v143 14.44.35207** e Windows SDK **10.0.26100.0**. CMake do VS é suficiente. Flutter **3.29.3 / Dart 3.7.2** será um SDK portátil em reboot/tools; não é preciso alterar PATH global ou instalar Node/npm para compilar GUI/DLL.

A instalação Fortnite deve ser fornecida pelo usuário e ficar **fora do repositório**. Este projeto não fornece jogo, PAKs, chaves AES, conta Epic ou downloader de build. Usar a raiz que contém Engine e FortniteGame:

```text
D:\Games\FortniteLocal\13.40-CL-14113327\13.40
```

Com internet para fontes e dependências de desenvolvimento:

```powershell
git clone https://github.com/BernardoHille/Fortnite-Offiline.git
Set-Location Fortnite-Offiline
./scripts/restore-reboot-stack.ps1 -IncludeFlutterSdk
./scripts/build-reboot3.ps1 -Configuration Both
./scripts/build-reboot-launcher.ps1
./scripts/configure-reboot-launcher.ps1 -BuildPath 'D:\Games\FortniteLocal\13.40-CL-14113327\13.40'
```

Esses scripts **somente restauram fontes, aplicam patches de build, compilam e escrevem settings no bundle**. Não iniciam Fortnite/backend/GUI nem injetam DLLs. `Both` compila Debug e só prossegue a Release se Debug passar. O SDK/commits e pubspec.lock estão fixados em [reboot/stack.lock.json](../reboot/stack.lock.json); não usar pub upgrade.

O launcher não versionava pubspec.lock: preservamos o lock inicial completo. O build usa `pub get --enforce-lockfile`; se a resolução/hash mudar, ele para. Plugins usam links locais para o cache; na ausência de privilégio de symlink são criadas junctions NTFS, sem mexer no registro/Developer Mode. `-OfflinePackages` no script de build permite recompilar com SDK/pacotes **já em cache**; não significa que o jogo foi validado offline.

O configurador valida Shipping por SHA-256, usa o caminho real do novo checkout para a DLL Release e deixa conta/senha vazias. Não passa por Import, que tenta patchHeadless no EXE. Se settings já existirem, o script para sem sobrescrevê-los. Não há necessidade de clonar/restaurar FES, backend antigo ou runtime-mod para esse caminho Reboot; são componentes históricos separados.

## Opções do teste

| Área | Opção | Valor de referência |
| --- | --- | --- |
| Build | Versão selecionada | Fortnite 13.40 CL 14113327 |
| Backend | Type | Embedded |
| Backend | Game server address | 127.0.0.1 |
| Backend | Detached | Off |
| Backend | Lawin REST | 3551; XMPP/Matchmaker 80 |
| Game server | Custom game server DLL | On; arquivo Project Reboot 3.0.dll Release local |
| Host | Headless | **On no teste definitivo**, confirmado pelo usuário e pelo log. Off ainda sem validação isolada |
| Host | Automatic restart | Off |
| Host | Port | 7777 |
| Host/client | Custom launch arguments | Vazio |
| Painel dev host | Players required to start the match | 1 |
| Painel dev host | Private IPs are operator | Marcado no teste do usuário |
| Painel dev host | No MCP | Marcado no teste do usuário |

Campos de usuário/senha utilizados no backend comunitário permanecem pessoais e não são fornecidos no repositório. A preparação não usa credenciais reais Epic. As opções do painel dev são registro do teste, não alterações de código, nem switches aplicados automaticamente pelo configurador.

## Execução manual reproduzindo o teste relatado

1. Abra `reboot/artifacts/launcher/Release/reboot_launcher.exe` a partir do bundle completo. Confira build, Embedded, localhost e DLL custom antes de iniciar. Na primeira abertura o launcher pode consultar serviços remotos e baixar suas DLLs auxiliares; o teste validado teve internet conectada.
2. Se necessário, configure o perfil local do backend pela GUI. Não reutilize uma conta/senha Epic. Confira que não está usando um backend remoto ou downloader de Fortnite.
3. Na área Host, selecione a build e use **Start hosting**. Aguarde a inicialização do host com Reboot. O sinal esperado é **Apollo_Terrain** e **Listening on port 7777**; o backend deve ter informado **3551** e XMPP/Matchmaker **80**.
4. Confira as opções do painel dev do host registradas na tabela. Abra a área **Play** do launcher para iniciar o cliente, mantendo o host aberto.
5. Aguarde o cliente chegar ao lobby do LawinServer. Entre na partida pelo botão **PLAY!** do jogo.
6. Com o jogador conectado à partida, no painel dev do **HOST** use **Start Bus**. Na 13.40 esse botão chama StartAircraftPhase; é diferente do botão Play da GUI do launcher.
7. No cliente, aguarde o Battle Bus e salte normalmente. O log pode registrar ServerAttemptAircraftJumpHook, criação de Pawn e acknowledge possession. Confirme movimentação no mapa antes de considerar a repetição concluída.
8. Para encerrar, feche cliente e host pelos controles do launcher e pare o backend local. **Log Out apresentou erro no teste relatado**; encerramento limpo ainda requer validação. Não encerrar processos arbitrários por PID/porta fora dessa sessão.

O fluxo acima é o procedimento informado pelo usuário e corroborado pelo log/capturas, não uma nova execução automática pelo Codex. As funções upstream de suspensão de auxiliares, auth DLL e hooks continuam presentes. A auditoria [REBOOT_LAUNCH_AUDIT](REBOOT_LAUNCH_AUDIT.md) explica esses efeitos; este guia não os remove nem implementa bypass próprio. Não é um método stock de autenticação Epic ou um launcher oficial da Epic.

## DLLs e origem

No início da sessão foram baixadas console.dll, sinum.dll e memory.dll do upstream do launcher. Auth sinum foi carregada em host/cliente; console no cliente. **Download de memory.dll não prova que ela foi injetada na 13.40**. A DLL Reboot do host é a compilada localmente, não a nightly padrão.

Depois que os arquivos já existirem, confira-os sem abrir o jogo:

```powershell
./scripts/verify-reboot-dependencies.ps1
```

O script compara as três DLLs com os hashes da sessão validada e não baixa/carrega nada. URLs master do upstream são mutáveis: se houver divergência, investigar a versão e a origem, sem substituir silenciosamente o estado testado. Hashes provam identidade, não o comportamento interno de sinum/auth/TLS. Não redistribuímos essas DLLs no Git.

## Diagnóstico e pendências

- Build falha: consultar reboot/logs/*reproduction.log; validar MSVC/SDK/Flutter fixados e patches. Não editar gameplay/offsets para esconder compile errors.
- Recompilar GUI com backend aberto: encerrar GUI/backend pelos controles antes de atualizar o bundle. O script verifica arquivos em uso antes da cópia e não mata processos. Para apenas validar compilação sem substituir o bundle atual, usar `./scripts/build-reboot-launcher.ps1 -OfflinePackages -SkipBundleCopy`.
- Paths: BuildPath é a raiz com Engine/FortniteGame; game server DLL é a Release dentro do checkout atual. Não reutilizar path absoluto de outro PC.
- Portas 80/3551/7777: se ocupadas, identificar o programa antes de agir. Não executar novamente os scripts históricos do backend simultaneamente com Lawin Embedded.
- GUI fora da tela: o storage pessoal pode conter offset_x/offset_y de outro monitor. Não transferir v3_settings_storage entre PCs.
- Crash de host ou logout: preservar o log local, identificar tentativa/horário e redigir uma cópia sanitizada antes de compartilhar. O log fornecido contém uma primeira tentativa que falhou; o sucesso posterior não prova estabilidade prolongada.
- Totalmente offline: testar em etapa separada, com dependências previamente obtidas e comparação explícita conectado/desconectado. Ainda não há confirmação de operação sem internet.
- Bots/bosses/Phoebe, progressão e Season13Runtime: **pendentes**. Não foram parte da validação e não são necessários para repetir lobby/ônibus/mapa.

Histórico e documentação de cada etapa: [PROJECT_HISTORY](PROJECT_HISTORY.md). Licenças e componentes não redistribuídos: [THIRD_PARTY_NOTICES](../THIRD_PARTY_NOTICES.md).
