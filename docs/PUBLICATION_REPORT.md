# Conteúdo preparado para publicação

Destino autorizado pelo usuário: **BernardoHille/Fortnite-Offiline**, branch main. O repositório estava vazio antes desta entrega. Publicação reúne a preparação anterior e o marco manual de gameplay; não executa novamente Fortnite.

## Conteúdo versionado

- Fontes próprias de backend/perfis, scripts históricos, controller e Season13Runtime ainda congelado.
- Toda documentação anterior, com ponteiros para o estado atual e separação explícita entre preparação READY B e teste manual posterior.
- [README](../README.md), [guia para rodar](COMO_RODAR_REBOOT.md), [histórico](PROJECT_HISTORY.md), [validação manual](REBOOT_MANUAL_VALIDATION.md), capturas do usuário e trechos selecionados do log sem contas/argumentos.
- [Reboot stack lock](../reboot/stack.lock.json), patches mínimos, pubspec.lock completo e perfil sem credenciais.
- Scripts de restauração, build Debug/Release, build GUI com lock obrigatório, configuração externa ao jogo e conferência das DLLs auxiliares.
- Avisos de licenças e origens upstream. Fontes de terceiros são reconstruídas por checkout oficial fixado, sem copiar repositórios inteiros para este Git.

## Conteúdo mantido local

Fortnite/Engine/PAKs/arquivos extraídos/chaves AES; checkouts vendor; Flutter/Dart e caches de packages; EXEs/DLLs/PDBs; saves/crashes/Procmon; configurações `.gs`/`.bak` com contas/senhas e logs brutos. Esses arquivos não entram no commit. Não é necessário publicá-los para reconstruir nossa preparação a partir dos sources e locks.

Os logs realmente contêm argumentos de lançamento e dados pessoais. Apenas linhas escolhidas com eventos técnicos foram publicadas; credenciais locais não foram copiadas para modelos. As capturas fornecidas foram incluídas como evidência visual da sessão.

## Verificações realizadas

| Verificação | Resultado |
| --- | --- |
| Repositório GitHub e acesso de push | Destino correto, vazio, branch padrão main; conta com push |
| restore-reboot-stack -IncludeFlutterSdk | Passou no ambiente existente; commits/remotes, patches e lock validados sem reset/overwrite |
| build-reboot3 -Configuration Both | Debug e Release aprovados, sem execução da DLL |
| build-reboot-launcher -OfflinePackages -SkipBundleCopy | GUI Release aprovada com cache/lock existentes; nenhum GUI/Shipping iniciado |
| Configurador em diretório novo de teste | Estrutura GetStorage/versão/Headless/contas vazias validada; segunda execução recusou sobrescrever |
| Scripts PowerShell Reboot | Parse sem erros |
| DLLs auxiliares | Três SHA-256 correspondem ao teste; blobs idênticos aos do commit oficial fixado |
| Proteção dos componentes anteriores | 1493 arquivos baseline de runtime-mod/backend/FES sem diferença de tamanho/timestamp nesta publicação |
| Segurança do conteúdo staged | Conferidos nomes/tipos, valores de segredo locais/AES, padrões de credenciais, JSON e links internos. Sem correspondências encontradas |
| Whitespace | Fontes/docs próprios aprovados; whitespace de patches/contexto diff e textos LICENSE upstream conservado |

Os builds de reprodução desta publicação foram **incrementais**, usando checkout/cache e toolchain existentes; não equivalem a um teste em Windows limpo. Nenhuma troca automática de dependências foi feita. A primeira cópia do bundle recompilado encontrou Lawin ainda aberto e foi interrompida; o script foi corrigido para verificar arquivos em uso antes de copiar. A verificação posterior utilizou SkipBundleCopy, preservando o EXE do bundle utilizado no teste manual e sem encerrar o backend do usuário.

## Identidade dos artefatos locais

| Arquivo | SHA-256 |
| --- | --- |
| Reboot3 Debug | fd7fece04c4bb823b9215093b51786b3ba33ea1676b605e99c4c105c8d0bf272 |
| Reboot3 Release utilizado no gameplay | 2f6acb349a942f086a453596d0fd10c65682563b12ee25d27a7d2abdfec35c3c |
| EXE GUI no bundle usado pelo usuário | 5b5f43d320091cdc9efafb5acb70c89ad0038fc9e0dbf7c42ffd59ac700dd1fb |
| EXE GUI recompilado na verificação, em gui/build/windows/x64/runner/Release | d8d1cf36cba62835cbe87307a17e61be6af0b45bc99f787f1e5c7652d2168496 |
| pubspec.lock preservado | db2dff71e1934f97410096529a5a83be9c7217ec12c06cc2737ac875dec4b63d |

Uma recompilação não tem garantia de produzir EXE bit a bit idêntico; há inputs gerados/metadados de build. O SHA do EXE recompilado não deve ser confundido com o bundle do teste manual. Patches/source e lock continuam os documentados; não alteramos o comportamento de launch para a verificação.

Consulta do commit publicado: `git log -1 --oneline` / histórico GitHub. Os resultados do teste local e pendências estão no guia/validação: internet conectada, Headless definitivo On, bots/offline total/logout ainda sem validação completa.
