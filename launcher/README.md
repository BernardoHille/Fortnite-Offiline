# Coordenador local — Fase 2

O coordenador está em `scripts/start-phase2.ps1`. Prepare inicia somente o backend; Stop encerra somente a sessão de PID/start time registrada. Launch exige aprovação e atualmente continua bloqueado por ausência de roteamento/isolamento do cliente comprovados. Não existe chamada a qualquer executável Fortnite ou FortExternalServer.

Modelos WSB gerados com caminhos pessoais são ignorados. O modelo de cliente não contém LogonCommand; o modelo de teste separado contém somente um teste de backend em guest. A tentativa guest falhou por timeout, sem executar ou mapear Fortnite. Nenhum desses modelos representa autorização para iniciar o cliente. Consulte `docs/PHASE2_PRELAUNCH.md`.
