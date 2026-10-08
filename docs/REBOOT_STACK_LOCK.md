# Reboot stack lock

2026-10-07. Checkouts separados, fora da build Fortnite. Ambos detached HEAD no SHA auditado, não seguir master durante builds.

| Repository | Commit | Branch de referência / checkout | Remote | License | Local |
| --- | --- | --- | --- | --- | --- |
| Milxnor/Project-Reboot-3.0 | 10c659028ad9d6816f78226483f11a884bf81f57 | master / detached | https://github.com/Milxnor/Project-Reboot-3.0.git | BSD-3-Clause, LICENSE raiz | reboot/reboot3/ |
| Auties00/Reboot-Launcher | c6f82298b167ef2076bb59dc621f13dc5bd8d390 | master / detached | https://github.com/Auties00/Reboot-Launcher.git | Nenhuma licença raiz/gui identificada; auth_backend/LICENSE GPL-3.0 | reboot/launcher/ |

O launcher SHA foi recuperado da auditoria local anterior e continua disponível no remoto oficial. Git clone --no-checkout --filter=blob:none, seguido de checkout explícito; sem submodule scripts/launch/installer. Não se obteve Reboot DLL por release/nightly/mirror/Discord.

SDK auxiliar oficial: flutter/flutter, tag **3.29.3**, em reboot/tools/flutter-sdk. SHA/version output registrados em reboot/audit e REBOOT_LAUNCHER_BUILD.md. Primeiro SDK 3.24.5 foi substituído após solver comprovar requisito Dart ^3.7.2 do port_forwarder. Nenhum SDK de sistema/PATH global alterado.

Pubspecs permanecem no commit. Nenhum pubspec.lock upstream existe: o lock inicial gerado pelo resolver foi preservado em reboot/audit/launcher-pubspec.lock, SHA-256 **db2dff71e1934f97410096529a5a83be9c7217ec12c06cc2737ac875dec4b63d**. Conferência final confirmou igualdade com gui/pubspec.lock. skeletons aponta main no pubspec; resolved-ref **81c72420ac1a31a9f0ebf6de9d8dd2bf50fe96ab** está fixado nesse lock local. Não confundir SHA do Reboot com SHA de dependências transitivas.

Alteração no source Reboot3: compatibilidade de build Debug x64 com CRT/ABI das libs vendor, documentada em [REBOOT3_BUILD](REBOOT3_BUILD.md) e patch local em reboot/audit/reboot3-build-compat.patch. Nenhuma mudança de auth, hooks, gameplay ou startup. No launcher: l10n.yaml gera no local já importado; duas declarações de fallback esquecidas foram restauradas de `c9ed6a5af3d26474213c130f84fe330a55ee5a6a`, parent oficial de d53a577. Diff local em reboot/audit/launcher-build-compat.patch. Nenhum botão/fluxo de Launch foi alterado para desbloquear boot; URLs restauradas não foram consultadas ou baixadas.

Binários/PDBs/SDK/checkouts/logs/auditoria/configuração pessoal ficam ignorados no Git principal. runtime-mod/, backend/ e FES não são integrados nem alterados. Snapshot inicial local em reboot/audit/preservation-before.local.json serve à conferência final.

Fontes oficiais: [Reboot3 no SHA](https://github.com/Milxnor/Project-Reboot-3.0/tree/10c659028ad9d6816f78226483f11a884bf81f57), [Launcher no SHA](https://github.com/Auties00/Reboot-Launcher/tree/c6f82298b167ef2076bb59dc621f13dc5bd8d390).

Para reconstrução pelo Git publicado, usar o [lock público](../reboot/stack.lock.json), [pubspec.lock preservado](../reboot/locks/launcher-pubspec.lock), [patch Reboot3](../reboot/patches/reboot3-build-compat.patch) e [patch Launcher](../reboot/patches/launcher-build-compat.patch). O comando restore-reboot-stack aplica essas cópias; a pasta audit/ citada acima continua privada. [Guia completo](COMO_RODAR_REBOOT.md).
