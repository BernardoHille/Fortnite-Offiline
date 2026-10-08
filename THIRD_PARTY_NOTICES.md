# Componentes de terceiros e distribuição

Este repositório publica fontes próprias, documentação, patches de integração/build e locks. **Não contém Fortnite, PAKs, builds, SDKs completos, executáveis/DLLs/PDBs, logs pessoais ou credenciais.** Não há uma licença única inventada para todos os componentes upstream.

| Componente | Origem / commit | Licença e forma de uso |
| --- | --- | --- |
| Project Reboot 3.0 | Milxnor/Project-Reboot-3.0, 10c659028ad9d6816f78226483f11a884bf81f57 | BSD-3-Clause no upstream. Clone oficial local; patch Debug separado; avisos upstream preservados |
| Reboot Launcher | Auties00/Reboot-Launcher, c6f82298b167ef2076bb59dc621f13dc5bd8d390 | Nenhuma licença raiz/GUI identificada. Não vendorizado nem redistribuído como bundle; instruções buscam o repositório oficial |
| Lawin embutido do launcher | auth_backend e assets do commit do launcher | auth_backend/LICENSE GPL-3.0. Não assumir que essa licença cobre a GUI inteira |
| DLLs console/sinum/memory | gui/dependencies/dlls no mesmo commit | Arquivos não redistribuídos; hashes/origem registrados. Licença e comportamento internos não inferidos pelo nome/hash |
| Flutter/Dart | flutter/flutter 3.29.3, ea121f8859e4b13e47a8f845e4586164519588bc | SDK oficial instalado localmente; sem redistribuição do SDK neste Git |
| Packages Pub | reboot/locks/launcher-pubspec.lock | Cada pacote conserva licença própria; lock não substitui avisos/licenças de distribuição |
| FortExternalServer | OGFN-Open-sourceing/FortExternalServer, e42ecddbce59163c6a60ab7506766c2a0adfe580 | MIT. Checkout histórico separado/ignorado; procedência no runtime-mod/THIRD_PARTY_NOTICES.md |
| LawinServer histórico | Lawin0129/LawinServer, 7f0f26d7a772c6122c42b1783fd75f497e86d3a9 | GPL-3.0; patches próprios em backend/patches, fonte obtida do upstream pelo restore histórico |
| Ferramentas auditoria | repak / procmon-parser | Avisos MIT preservados em scripts/*LICENSE-MIT.txt; ferramentas e dados extraídos não redistribuídos |

As capturas em docs/media foram fornecidas pelo usuário como evidência do teste local. Não fazem parte de uma redistribuição de arquivos do jogo. Nomes/marcas/interfaces pertencem aos respectivos titulares.

Consulte também [runtime-mod/THIRD_PARTY_NOTICES](runtime-mod/THIRD_PARTY_NOTICES.md) e as licenças presentes nos checkouts oficiais obtidos durante a reprodução. Eventual distribuição de um bundle compilado exige revisão de todas as licenças envolvidas; esta publicação não inclui esse bundle.
