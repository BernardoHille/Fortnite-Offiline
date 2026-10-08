# Backend local de diagnóstico

Modo atual da Fase 2: adaptador seletivo em `phase2/server.cjs`, usando as dependências e schemas auditados do LawinServer fixado. Perfis próprios em runtime; somente as rotas descritas em `docs/PHASE2_CLIENT_BOOT.md`. Teste com `scripts/test-phase2-backend.ps1`. O entrypoint upstream e os patches da Fase 1 permanecem disponíveis para o modo 1, sem liberar todos os routers.

Fonte principal: [LawinServer](https://github.com/Lawin0129/LawinServer), licença GPL-3.0, branch main e commit fixado em `configs/stack.lock.json`. A licença upstream permanece no checkout `vendor/LawinServer`, ignorado pelo Git. Os patches locais de adaptação desse código seguem GPL-3.0; origem e mudanças estão preservadas em `patches/`.

Use `scripts/restore-stack.ps1` para obter a fonte e aplicar os patches, e `scripts/start-backend.ps1 -SmokeTest` para verificar início/saúde/encerramento. Na Fase 1 só existem acesso a saúde e encerramento, em loopback. Rotas do jogo retornam 503; XMPP está desligado. Dados runtime ficam ignorados. Não use launchers ou instruções de conexão upstream nesta fase.

O guard independente `offline-guard.cjs` protege as APIs auditadas do processo Node e registra tentativas bloqueadas no modo 2. Não protege o Fortnite nem equivale a sandbox de SO. Os limites e os dois avisos moderados restantes de dependências constam em `docs/ARCHITECTURE.md` e `docs/DEPENDENCIES.md`.
