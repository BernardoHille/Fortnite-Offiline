# Season13Runtime

**ARCH C — MILESTONE 0 READY**, código R0/R1 compilado para revisão. Windows x64, somente Fortnite 13.40 / CL 14113327, arquivo/path/SHA fixos em include/Season13Target.h. Nenhum teste real no jogo foi executado.

Build e testes offline: `../scripts/build-season13-runtime.ps1 -Configuration Debug -Test`. Também aceita RelWithDebInfo/Release. Binários e PDBs ficam em out/CONFIG, fora da instalação Fortnite.

Controller `--inspect` valida somente o arquivo; nenhuma execução/attach. O modo futuro `--attach` exige PID explícito e milestone 0/1, carrega DLL adjacente e não inicia o jogo. Nenhum script de build faz attach. Não há hooks, rede/backend, auth ou gameplay. R2–R5 permanecem documentados e não implementados.

Leia o [plano e primeiro teste FUTURO R0](../docs/RUNTIME_BOOTSTRAP_IMPLEMENTATION.md), [cadeia Shipping → World](../docs/SHIPPING_TO_GWORLD.md) e [proveniência](THIRD_PARTY_NOTICES.md). As signatures não tiveram matches no Shipping em disco; resolução runtime não comprovada. Não executar o modo attach antes da revisão e autorização da etapa seguinte.
