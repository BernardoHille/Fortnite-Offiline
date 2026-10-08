# Preparação local

**Documento histórico do backend anterior.** O caminho que chegou a lobby/ônibus/mapa usa Reboot Launcher + Lawin Embedded + Project Reboot 3.0. Use [COMO_RODAR_REBOOT](COMO_RODAR_REBOOT.md) para o procedimento atual; não misture os scripts abaixo com esse stack. Estado e evidências atuais em [MANUAL_VALIDATION](REBOOT_MANUAL_VALIDATION.md).

## Modo atual: Fase 2 sem executar Fortnite

Use PowerShell 7.4+ (testado em 7.6.5; Start-Process -Environment requer essa linha de versões), Node e dependências já restauradas na Fase 1. O exemplo agora usa phase=2, accountId=local-player e displayName=Bernardo. Preserve `buildPath`/`buildArchivePath` existentes em `configs/local.json`; não recopie nem extraia a build de novo.

```powershell
./scripts/test-phase2-backend.ps1
node ./scripts/test-phase2-guard.cjs
./scripts/start-phase2.ps1 -Mode Prepare
./scripts/start-phase2.ps1 -Mode Stop
```

`start-backend.ps1 -SmokeTest` despacha para o teste do modo configurado; sem SmokeTest, modo 2 prepara o backend em background. Para encerrar modo 2 use o coordenador Stop. O estado contém PID, start time e chave local de controle apenas em runtime ignorado. Não imprime tokens e não encerra processos de outra sessão.

`prepare-phase2-isolation.ps1` gera somente XML/readiness local, sem iniciar Sandbox ou Fortnite. `test-phase2-sandbox.ps1` foi executado como teste de backend em guest e expirou sem prova de funcionamento; não o repita até diagnosticar o problema. Esse teste não mapeia a build. O template destinado a uma futura investigação do cliente mapeia a build somente leitura e não contém comando automático, mas permanece sem validação em runtime.

**Launch está bloqueado**, inclusive com Approved, até existir uma arquitetura validada e nova aprovação explícita para o primeiro cliente. Não use scripts/instruções upstream, WSBs ou argumentos especulativos para contornar o gate. Veja `PHASE2_PRELAUNCH.md`. Backend e Sandbox helper foram encerrados ao fim dos testes; nenhum game/gameserver foi iniciado.

## Auditoria de roteamento e PAKs concluída

Leia os três relatórios PHASE2_ROUTING_REPORT, PHASE2_ROUTING_FEASIBILITY e PHASE2_PAK_AUDIT antes de qualquer nova decisão. Resultado ROUTE C: configurações presentes, mas override externo não demonstrado. Não há experimento de configuração pronto para lançamento.

Os scripts audit-pak-footers.cjs, audit-phase2-paks.cjs, audit-phase2-configs.cjs e audit-shipping-routing-xrefs.cjs fazem leitura estática; as saídas ficam em runtime/phase2/pak-audit. O leitor de PAK requer o arquivo AES privado e repak oficial validado, também local. Não execute o inventário de footers novamente para substituir a referência de integridade de uma auditoria já realizada. Para verificar os artefatos existentes sem executar jogo ou sobrescrever a referência:

```powershell
node ./scripts/verify-phase2-routing-audit.cjs
```

Chaves, imagens auxiliares, listagens, índices decifrados e INIs extraídos não devem ser adicionados ao Git. Nenhum resultado de arquivo estático autoriza a execução do cliente.

## Histórico da preparação da Fase 1

Abra PowerShell 7 na raiz do projeto. Os comandos não iniciam o Fortnite. `configs/local.example.json` é o modelo versionável; copie para `configs/local.json` e preencha seus caminhos somente nesse arquivo ignorado. `buildPath` deve apontar à pasta que contém diretamente `Engine` e `FortniteGame`, observando a pasta adicional `13.40` dentro deste ZIP.

```powershell
Copy-Item configs/local.example.json configs/local.json
./scripts/check-environment.ps1
./scripts/restore-stack.ps1
./scripts/build-gameserver.ps1
./scripts/start-backend.ps1 -SmokeTest
./scripts/verify-build.ps1 -Path "CAMINHO_ABSOLUTO_DO_ZIP"
./scripts/verify-build.ps1 -Path "CAMINHO_ABSOLUTO_DA_PASTA_EXTRAIDA"
```

`restore-stack.ps1` busca somente dois repositórios GitHub nos commits fixados e pacotes do registro npm. Reaplica patches preservados, não executa lifecycle scripts de pacotes e não baixa builds. Precisa de internet apenas para obtenção inicial de fontes/dependências. Falha se encontrar checkout inesperado, preservando arquivos existentes. O gameserver não exige package restore. Compilação não executa o binário resultante.

`start-backend.ps1` mantém o backend em primeiro plano até Ctrl+C. `-SmokeTest` inicia sem janela, valida `/health`, endereço de escuta e bloqueio das rotas do jogo, pede encerramento local e confirma exit code 0. Não inicia XMPP, matchmaking, Fortnite ou gameserver. Logs são locais e ignorados. Use somente esses scripts, não os launchers/instruções upstream.

## Extração com autorização

```powershell
./scripts/extract-build.ps1 -Path "CAMINHO_ABSOLUTO_DO_ZIP" -Destination "PASTA_EXTERNA_NOVA" -Approved
```

O switch `-Approved` registra a condição operacional de que a autorização deve existir antes do comando. O script exige destino novo fora do repositório, valida caminhos contra traversal/links, verifica espaço livre com margem de 10 GiB, não sobrescreve arquivos e confere o tamanho de cada arquivo extraído. Em seguida verifica a estrutura e strings da build somente por leitura. Se interrompido, preserve a pasta parcial e use um destino novo; não limpe arquivos existentes sem saber sua origem.

O ZIP descompacta aproximadamente 86,48 GiB. Extração autorizada em 2026-10-07. Não se copiou o gameserver para a build e não se alterou a instalação extraída.

## Proteção do Git

ZIP, pastas Engine/FortniteGame, PAK/UCAS/UTOC, EXE/DLL e artefatos de compilação, saves, logs, credenciais, runtime e configuração pessoal estão ignorados. Checkouts terceiros ficam em `backend/vendor` e `gameserver/vendor`, também ignorados. Origem/commit e patches são versionáveis. `.gitignore` não impede um `git add -f` deliberado: nunca force a inclusão da build. Nenhum remote de publicação foi configurado.
