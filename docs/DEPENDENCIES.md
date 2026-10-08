# Dependências Windows

Derivadas dos manifestos e arquivos de build dos commits em `configs/stack.lock.json`, com verificação local em 2026-10-07. Não houve instalação de Visual Studio, SDK, .NET, Python ou runtimes aleatórios.

| Dependência | Versão usada / requisito | Motivo | Verificação |
| --- | --- | --- | --- |
| PowerShell | 7.6.5 usado; Fase 1 requer 7, coordenador/testes da Fase 2 requerem >=7.4 | Scripts locais; Fase 2 usa `Start-Process -Environment` | `$PSVersionTable.PSVersion` |
| Git | 2.55.0.windows.2 | Fonte open-source fixada em commits | `git --version` |
| Visual Studio | Community 2022, 17.14.37111.16 | MSBuild e workload Desktop development with C++ instalados | `vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64` |
| MSVC | v143, 14.44.35207 | C++20. Upstream usa v145 por padrão, mas documenta override `FortExternalServerToolset=v143`, confirmado por compilação local | `check-environment.ps1`; `VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/cl.exe` na instalação VS |
| Windows SDK | 10.0.26100.0 | Headers/libs Win32, psapi, ole32, shlwapi; versão fixada no comando de compilação | `check-environment.ps1`; Windows Kits/10/Include |
| Node.js | 22.23.1 instalado e testado | Runtime LawinServer; upstream não define `engines` nem versão exata, portanto esta é a versão local validada, não um requisito alegado do autor | `node --version` |
| npm | 10.9.8 instalado | `npm ci` reproduz lock; pacotes instalados sem lifecycle scripts | `npm --version` |
| CMake | >=3.21 no CMakeLists; 3.31.6-msvc6 já disponível dentro do VS | Alternativa, não necessária à rota MSBuild usada | CMake do VS: Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe --version |
| .NET | SDK 9.0.312 encontrado | Não é requisito de runtime dos projetos escolhidos; MSBuild do VS é suficiente | `dotnet --list-sdks` |
| Python | Alias WindowsApps encontrado; interpretador real não verificado | Não utilizado / não requerido | `Get-Command python`; alias não comprova instalação |
| pnpm, MongoDB, Redis, Electron, Ninja | Não requeridos nesta rota | Não foram escolhidos Anora, launcher Velocity ou CMake/Ninja | Sem instalação necessária |

MSVC 14.38.33130 e SDK 10.0.22621.0 também estão presentes, mas não foram usados. CMake não está no PATH; isso não bloqueia a compilação feita com MSBuild. Nenhuma dependência obrigatória está faltando.

## Pacotes backend fixados no lock local

| Pacote direto | Versão efetivamente instalada |
| --- | --- |
| cookie-parser | 1.4.7 |
| express | 4.22.1 |
| ini | 2.0.0 |
| path | 0.12.7 |
| uuid | 8.3.2 |
| ws | 8.22.0 |
| xml-parser | 1.2.1 |
| xmlbuilder | 15.1.1 |

O diff completo de package-lock após correções compatíveis está em `backend/patches/dependency-audit.patch`, reaplicado pelo script de restauração. Transitividades relevantes corrigidas: body-parser 1.20.8 e proxy-addr 2.0.8. npm audit original: 7 pacotes sinalizados (3 baixos, 2 moderados, 1 alto, 1 crítico); final: 2 moderados, 0 altos, 0 críticos.

Pendências reais: Express ainda usa qs 6.14.2 (sua dependência body-parser já usa qs 6.16.0) e uuid permanece 8.3.2. O npm sugere upgrade major para uuid; ele não foi forçado sem avaliação da API. Os avisos são [qs](https://github.com/advisories/GHSA-4mjr-xmp4-gh2g) e [uuid](https://github.com/advisories/GHSA-w5hq-g745-h8pq), com detalhes completos nos logs locais de audit. Na Fase 1, o parser de query strings está desativado, o middleware bloqueia as rotas antes dos parsers de corpo e nenhuma rota de jogo/XMPP recebe tráfego. Isso limita a exposição, mas não equivale a eliminar os avisos. Avaliação de dependências e compatibilidade é trabalho técnico antes de habilitar novas rotas; não exige uma ação manual do usuário agora.
