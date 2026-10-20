# AI_HANDOFF — widget_nw_embalagens

## Última atualização
2026-10-20 — branch main; HEAD anterior à entrega: 3bf6ce3.

## Tarefa atual / última entrega
- Pedido: ao Buscar, aplicar loading global com toast info e retirar o aviso quando terminar.
- JS: overlay criado uma vez no init e ativado em todas as consultas por definirCarregamentoTipos/definirCarregamentoGlobal; retirado spinner interno da tabela. Bloqueio do filtro/Buscar/Novo e aria-busy acompanham a consulta.
- Aguarda todas as páginas e renderização da tabela; sucesso ou erro liberam o overlay e agendam a retirada do toast em 100 ms com fadeOut de 200 ms. Busca próxima cancela a retirada pendente e reutiliza o aviso.
- npm test: Dataset 46/0, transporte 11/0, tela 33/0; 90 cenários sem falhas. Inclui busca após início concluído, falha posterior e reuso de toast entre buscas.
- Diff sem erros, UTF-8 sem BOM/CRLF preservados; hashes de Dataset e teste preexistentes conferidos.
- WAR: target/widget_nw_embalagens.war; 12 entradas, 26730 bytes; integridade ZIP e conteúdo idêntico aos fontes verificados.
- SHA-256 do WAR: 3add20ec4180b6523256d3ecd623f5cf8c0e8c534e984fcf033cfcbc4487ba6a.
- Commit/push: somente JS, testes de tela e documentação/contexto afetados; conferir último commit e origin/main ao retomar.
- Alterações preexistentes fora do commit: datasets/dsNwEmbalagens.js e testes/testar-dataset-unico.cjs.
- Nenhuma publicação realizada; validação visual no Fluig não confirmada.

## Para retomar
- Ler AGENTS.md e os quatro AI_*.md; conferir Git/Dataset atuais.
- Loading global vale para início e Buscar; comandos e autocomplete não foram ampliados.
- Demais pendências: AI_TODO.md; registro não autoriza execução.
