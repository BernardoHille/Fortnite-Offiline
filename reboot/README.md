# Stack Reboot local

Fontes oficiais fixadas, GUI/DLL compiladas e teste manual realizado pelo usuário: lobby Lawin, Apollo, Battle Bus, salto e movimentação. Teste definitivo com Headless On e internet conectada; operação totalmente offline ainda não validada. Os efeitos de auth/EAC/hooks e downloads identificados continuam no upstream.

Comece por [COMO_RODAR_REBOOT](../docs/COMO_RODAR_REBOOT.md) e [MANUAL_VALIDATION](../docs/REBOOT_MANUAL_VALIDATION.md). Lock público em stack.lock.json, patches em patches/, pubspec.lock em locks/, perfil sem credenciais em config/. Artefatos, checkouts, SDKs, settings pessoais, logs e auditoria local continuam ignorados. runtime-mod/backend/FES permanecem separados, sem integração.

Relatórios históricos da preparação: [INSTALL_REPORT](../docs/REBOOT_INSTALL_REPORT.md), [STACK_LOCK](../docs/REBOOT_STACK_LOCK.md), [PRELAUNCH](../docs/REBOOT_PRELAUNCH.md) e [RUNTIME_BLOCKER](../docs/REBOOT_RUNTIME_BLOCKER.md). Os bloqueios eram os limites da etapa sem execução; o teste manual posterior não equivale à remoção deles do código.
