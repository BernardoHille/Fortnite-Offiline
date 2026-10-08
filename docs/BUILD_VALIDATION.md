# Validação da build fornecida

Arquivo localizado no ambiente atual: `13.40-CL-14113327.zip`. O caminho absoluto local fica somente em `configs/local.json` e nos logs ignorados, sem incorporar a instalação ao repositório. Não houve busca ou download de outra build.

| Medida | Resultado |
| --- | --- |
| Tamanho ZIP | 42.358.852.229 bytes; 42,36 GB / 39,45 GiB |
| SHA-256 | `3ee0440fd5299af6b856d85eaa82198ef9ec1098a9112ec8ff3df5d0be1857c8` |
| Entradas na central ZIP | 493 |
| Arquivos / diretórios declarados | 429 / 64 |
| Soma dos tamanhos descompactados declarados | 92.857.442.082 bytes; 92,86 GB / 86,48 GiB |
| Pasta de encapsulamento | `13.40/` |
| Shipping | `13.40/FortniteGame/Binaries/Win64/FortniteClient-Win64-Shipping.exe`, 174.908.672 bytes |
| Evidência interna do executável | `++Fortnite+Release-13.40-CL-14113327` |

Estrutura observada: `13.40/Engine/Binaries/ThirdParty/`, `13.40/FortniteGame/Binaries/Win64/` e `13.40/FortniteGame/Content/Paks/`. Os detalhes de entradas permanecem nos logs locais. O script reconhece automaticamente a pasta de encapsulamento.

```text
[OK] Engine
[OK] FortniteGame
[OK] Win64 binaries
[OK] Shipping executable
[OK] Expected build structure
[OK] Embedded identity: ++Fortnite+Release-13.40-CL-14113327
```

O script `scripts/verify-build.ps1 -Path "CAMINHO_DA_BUILD"` aceita ZIP ou pasta extraída e é somente leitura. Para ZIP calcula SHA-256, tamanho, estrutura, soma descompactada, lista a raiz e lê o conteúdo Shipping em memória para buscar a string de versão; não extrai nem executa o binário. `-Json` oferece resultado estruturado no stdout para redirecionamento a logs. `-MetadataOnly` permite repetir a leitura estrutural sem recalcular o hash, retornando SHA-256 nulo nessa execução e indicando expressamente a limitação. O hash registrado acima veio de uma execução inicial concluída de Get-FileHash; a leitura duplicada foi interrompida para reduzir a disputa pelo disco durante a extração, e sua proveniência está registrada no JSON local consolidado.

A string embutida permite confirmar programaticamente a identificação declarada 13.40 / CL 14113327 do binário fornecido. Ela não autentica sua procedência: não há hash oficial confiável para comparação, nem a análise comprova integridade criptográfica de todos os arquivos. Leitura da central e Shipping não equivale a teste CRC completo do ZIP. A extração lê todos os membros e compara tamanhos finais, sem executar ou editar os arquivos de saída depois da extração.

Extração autorizada pelo usuário durante a Fase 1 e concluída. Inventário independente confirmou 429 arquivos, todos nos caminhos esperados e com o tamanho declarado no ZIP; total exato de 92.857.442.082 bytes, sem divergências. Diretório externo adequado indicado em configuração local. O caminho de build termina em `13.40`, que contém diretamente Engine/FortniteGame. Resultado final está em `PHASE1_REPORT.md`; evidências brutas em `logs/extraction.log`, `logs/extracted-inventory.json` e `logs/extracted-build-validation.json`.
