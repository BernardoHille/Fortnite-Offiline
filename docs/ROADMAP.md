# Roadmap — cinco fases

| Fase | Nome | Critério / escopo |
| --- | --- | --- |
| 1 | Ambiente | Localizar e validar build, proteger Git, auditar e fixar stack, compilar gameserver, testar saúde e encerramento do backend, documentar |
| 2 | Lobby local | Somente após autorização explícita e resolução da conexão isolada compatível com as restrições |
| 3 | Partida local | Integração e execução local no mapa Apollo, sem serviços live |
| 4 | Bots e conteúdo C2S3 | Phoebe, Ocean/Jules/Kit, comportamento, loot e posições verificadas |
| 5 | Progressão, quests e Battle Pass local | Persistência local e regras locais de progressão |

Não há fases extras. Fase 1 concluída. Fase 2 autorizada e em andamento: backend simulado/testes passaram, mas lobby real/PLAY não foram testados e o lançamento segue bloqueado tecnicamente. A primeira execução exige aprovação explícita separada. Não avançar à Fase 3. Conexão do cliente é pendência da Fase 2; mapa, partida, IA e progressão permanecem nas fases correspondentes.

Auditoria de roteamento/PAKs concluída para revisão: ROUTE C em PHASE2_ROUTING_REPORT.md. As configurações reais foram encontradas, mas não foi demonstrado um override nativo utilizável. Nenhum cliente ou experimento será iniciado após o relatório; a próxima decisão depende de sua revisão.
