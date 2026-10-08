# Stack Reboot local

Fontes oficiais fixadas, GUI/DLL compiladas e teste manual realizado pelo usuário: lobby Lawin, Apollo, Battle Bus, salto e movimentação. Teste definitivo com Headless On e internet conectada; operação totalmente offline ainda não validada. Os efeitos de auth/EAC/hooks e downloads identificados continuam no upstream.

Comece por [COMO_RODAR_REBOOT](../docs/COMO_RODAR_REBOOT.md) e [MANUAL_VALIDATION](../docs/REBOOT_MANUAL_VALIDATION.md). Lock público em stack.lock.json, patches em patches/, pubspec.lock em locks/, perfil sem credenciais em config/. Artefatos, checkouts, SDKs, settings pessoais, logs e auditoria local continuam ignorados. runtime-mod/backend/FES permanecem separados, sem integração.

Relatórios históricos da preparação: [INSTALL_REPORT](../docs/REBOOT_INSTALL_REPORT.md), [STACK_LOCK](../docs/REBOOT_STACK_LOCK.md), [PRELAUNCH](../docs/REBOOT_PRELAUNCH.md) e [RUNTIME_BLOCKER](../docs/REBOOT_RUNTIME_BLOCKER.md). Os bloqueios eram os limites da etapa sem execução; o teste manual posterior não equivale à remoção deles do código.

Revisões de bots/Phoebe estão preservadas como patches cumulativos, com ordem/hashes em [bot-ai.lock.json](bot-ai.lock.json). BOT-0 cria um bot parado; MoveTo falhou no BOT-1; BOT-2 confirmou NavData vazio. **Native Phoebe V1: NAV-BLOCKED, zero bots ON**, confirmado pelo usuário em 08/10/2026 às 10:46:38. [Auditoria/compilação V1](../docs/NATIVE_PHOEBE_BOOTSTRAP_V1.md), [teste e resultado](../docs/NATIVE_PHOEBE_BOOTSTRAP_V1_TEST.md), [pipeline](../docs/NATIVE_PHOEBE_PIPELINE.md). O build genérico continua sendo o baseline; não escreve sobre outputs experimentais.

Verificação de publicação: upstream fixado → compatibilidade → BOT-0 → BOT-1 → BOT-2 → preflight → V1 reconstruiu exatamente os sete arquivos afetados. DLLs/PDBs ficam locais; o Git preserva o source por patches, os hashes e as evidências selecionadas. O último teste identifica Apollo_Nav_Gameplay carregado e WaterLevel_0..7 não carregados; a seleção correta da variante e a causa restante do lock continuam desconhecidas.
