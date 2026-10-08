# Decisão de arquitetura comunitária — STACK B

Data: 2026-10-07. **Existe código comunitário útil, mas somente alguns módulos podem ser reutilizados. Nenhuma camada de boot/compatibilidade completa foi demonstrada dentro das restrições.** A Fase 2 continua incompleta; lobby e PLAY não foram demonstrados.

## 1. Candidatos avaliados

Project Reboot original, Project Reboot 3.0 e Reboot Launcher foram examinados separadamente. Também foram avaliados FortExternalServer season-13, LawinServer, Anora, Velocity-OGFN, fontes públicas históricas Era e a referência já auditada ggsplayz/FortniteLauncher. Fontes, revisões, licenças, manutenção, matriz dos vinte eixos e graus de evidência estão em [COMMUNITY_STACK_COMPARISON](COMMUNITY_STACK_COMPARISON.md).

## 2. Melhor candidato e arquitetura principal

**Velocity é o melhor doador comunitário dos módulos de protocolo selecionados; a proposta é incorporar referências seletivas ao backend atual, sem usar seu launcher, entrypoint, redirecionamento ou host controller.** Seus schemas JSON/MCP, mensagens XMPP/party e modelos de sessão estão disponíveis sob MIT. A compatibilidade desses módulos com nosso cliente é **NÃO TESTADO**. Esta escolha não afirma que Velocity inteiro seja adequado.

Há uma única arquitetura proposta: **backend local atual + referências seletivas Velocity + perfil exato FortExternalServer preservado para estudo**. FortExternalServer não será substituído por Reboot; também não será tratado como host autorizado ou independente. A camada de cliente permanece sem candidato elegível. [ARCHITECTURE_V2](ARCHITECTURE_V2.md) representa o bloqueio explicitamente.

## 3. Por que essa escolha

| Prioridade do pedido | Evidência e consequência |
| --- | --- |
| Compatibilidade comprovada 13.40 | FES identifica CL 14113327 no código; nenhum conjunto demonstrou lobby/partida desse CL dentro das restrições. Não promover declaração a prova. |
| Funcionamento local | Nosso backend já teve testes REST locais, sem cliente. Anora inicia Discord remoto; launchers auditados dependem de mecanismos excluídos. |
| Código aberto | Velocity MIT e FES MIT; Lawin GPL-3.0 preservado com proveniência. Anora apresenta divergência de licença; Era atual aberto/autossuficiente não demonstrado. |
| Arquitetura compreensível | Separar serviço de perfil, mensagens de party, seleção de sessão e runtime Unreal; nenhum backend inicia automaticamente Shipping. |
| Menos componentes/dependências | Conservar Node/Express e arquivos locais existentes; não adicionar MongoDB, Redis, Discord ou segundo backend integral. |
| Adaptação e reutilização | Preservar identidade, profiles, guard, testes, coordenador, lock e build. Usar referências comunitárias apenas onde houver lacuna documentada. |

Anora é mais completo em **cobertura de código** para MCP mutável, XMPP/party e matchmaking que nosso adaptador mínimo. Isso não prova superioridade para o CL exato nem funcionamento offline. Seu startup remoto e divergência MIT/GPL no manifesto impedem uma migração integral justificada agora. Lawin não é mantido por preferência: conserva-se a base comprovada localmente porque nenhum substituto passou os critérios anteriores.

## 4. Componentes reutilizados

Reutilização **existente**: build validada 13.40, backend mínimo, auth fictícia, snapshots de três profiles, scripts/guard, documentação e checkout/compilação FES. Chaves AES continuam privadas e apenas de auditoria.

Reutilização **proposta**, ainda sem cópia de código: modelos/mensagens Velocity para revisão MCP, XMPP/party e DTOs de sessão, com notices e proveniência. Dados declarativos FES de versão/classes/loadouts podem orientar especificações posteriores, separados do runtime de memória. Não são bots implementados. A elegibilidade de cada arquivo e suas dependências terá de ser confirmada antes de qualquer importação.

## 5. Componentes descartados da proposta

Excluir launchers Reboot/Velocity/ggsplayz/Era histórico; DLL de auth, TLS bypass/redirecionamento, certificados/CA, hosts/portproxy/interceptação, suspensão/impedimento de anti-cheat, códigos Epic reais e serviços live. Não importar o autostart de gameserver Velocity ou pipeline de injeção. Não substituir o backend inteiro por Anora nem usar serviço remoto Era.

Nenhum arquivo foi apagado. Fontes de auditoria e binário FES compilado permanecem preservados; “descartar” significa excluir do desenho executável. Hooks de gameplay não são automaticamente bypass de segurança, mas runtime FES/Reboot e hooks de sessão/MCP não receberam demonstração suficiente de conformidade para execução.

## 6. Riscos e bloqueios materiais

| Risco / bloqueio | Efeito na decisão |
| --- | --- |
| Boot e roteamento local não resolvidos | Seleção de backend/mensagens não permite iniciar o jogo. A camada de compatibilidade continua bloqueada. |
| Protocolos só verificados estaticamente | Shapes MCP/XMPP/tickets podem divergir de 13.40; REST próprio não prova aceitação por Shipping. |
| FES acoplado ao processo | Arena/stubs/hooks/memória e chegada ao menu são pré-requisitos; compilação não valida nenhum deles. |
| Matchmaking Velocity acoplado ao host | WS chama autostart com DLL para 13.40; DTOs podem ser estudados, mas a cadeia executável é excluída. Porta TCP aberta não valida Unreal/UDP. |
| Profiles/progressão confundidos | Nível/tier e persistência JSON não comprovam cálculo de XP, quests, recompensas ou eventos autoritativos de partida. |
| Licença e proveniência | Anora tem metadados conflitantes; GUI Reboot/Era não possuem licença raiz identificada na amostra. Não copiar código assumindo licença. |
| Default e fidelidade de gameplay | FES default Athena diverge de Apollo; IA desligada e posições provisórias. Não avançar fase para corrigir isso agora. |

Não há pontuação artificial que compense um mecanismo proibido com mais recursos. Um caminho obrigatório incompatível exclui o fluxo completo; preservar módulos sem essa dependência não autoriza adaptar o cliente para aceitá-los.

## 7. Dependências

Base conservada: Node/Express já presentes, dependências fixadas Lawin e arquivos de estado locais. Toolchain MSVC existente e artefato FES são apenas preservados. Referências futuras XMPP/party podem exigir bibliotecas WS/XML e revisão de bindings em loopback; nada foi instalado ou habilitado. Não se escolheu MongoDB/pnpm/Redis/Discord como nova dependência de runtime.

## 8. Compatibilidade com CL 14113327

**CONFIRMADO POR CÓDIGO:** perfil FES exato e tabela de build Reboot Launcher. **DECLARADO PELO PROJETO:** Season13 em Anora/Reboot e build exata em ggsplayz. **INFERIDO:** 13.40 entra nos ramos numéricos Velocity. **CONFIRMADO POR DOCUMENTAÇÃO:** compilação prévia FES e testes REST anteriores registrados no projeto. **NÃO TESTADO:** boot permitido completo, lobby, XMPP real, PLAY, matchmaking, partida, Apollo, bots, bosses e progressão com esta stack.

Nenhuma dessas evidências altera a decisão C registrada em [PHASE2_LAUNCH_CHAIN](PHASE2_LAUNCH_CHAIN.md). Aqui escolhe-se **STACK B** porque há módulos úteis; para uma **stack completa que inicie o cliente**, nenhum candidato auditado demonstrou atendimento às restrições. Não se afirma inexistência universal de outra solução.

## 9. Arquitetura final proposta

Cliente existente → **gate de compatibilidade sem solução selecionada** → backend local reutilizado, com módulos de protocolo comunitário a especificar. O matchmaking futuro retorna uma sessão; o tráfego de jogo liga cliente e host diretamente. FES é referência técnica preservada, sem adaptador de execução escolhido. Progressão continua reservada para a fase própria.

Os caminhos futuros são condicionais e não executáveis. Não haverá integração improvisada do backend HTTP com controladores de memória nem receita de launch flags para contornar o bloqueio.

## 10. Próximo passo exato e parada

**Agora: parar e aguardar aprovação desta proposta STACK B.** Os quatro documentos estão entregues; nenhum componente novo será executado.

Se o plano for aprovado, o primeiro trabalho proposto é **especificação estática, sem cliente**, de um contrato `CommunityProtocol13`: limites de módulo, schema/revisão MCP, identidade/sessão local, mensagens XMPP/party e DTO de sessão; listar arquivo/revisão/licença/dependências de cada referência Velocity e o que deve ser excluído. Esse contrato ainda não existe. Não inclui copiar/iniciar upstream, criar bots/progressão, mudar rede ou desbloquear launch.

Antes de qualquer experimento com Shipping, uma camada de boot/roteamento permitida precisa ser demonstrada com fonte verificável. Caso continue ausente, registrar o bloqueio; não adaptar automaticamente as soluções incompatíveis. Aprovar o plano não aprova mecanismos proibidos ou execução de cliente/gameserver.
