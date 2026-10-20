# AI_HANDOFF — widget_nw_embalagens

## Última atualização
2026-10-20 — branch main; HEAD anterior à entrega: 454e744.

## Tarefa atual / última entrega
- Pedido: aplicar loading global durante o carregamento inicial.
- Implementado no JS/CSS: overlay restrito à widget, spinner e toast info “Carregando...”, aria-busy e filtro/Buscar/Novo bloqueados.
- O overlay aguarda biblioteca, todas as páginas da primeira consulta e renderização. Sucesso ou erro liberam o bloqueio; toast é retirado após 100 ms com fadeOut de 200 ms. Buscas posteriores mantêm o loading da tabela.
- Testes: npm test passou, Dataset 46/0, transporte 11/0, tela 31/0 (88 cenários). Três novos cenários cobrem sucesso com espera até a renderização, falha da biblioteca e falha de consulta.
- Verificados diff sem erros, UTF-8 sem BOM e CRLF. Alterações preexistentes de Dataset/teste preservadas por SHA-256.
- WAR regenerado e validado: target/widget_nw_embalagens.war, 12 arquivos, 26786 bytes; ZIP íntegro e entradas idênticas aos fontes.
- SHA-256 do WAR: 534af9fdf57a4202165f1d4e379b983375fb5883459066a8c7302debc1153d34.
- Commit/push desta entrega incluem somente JS, CSS, testes de tela e documentos afetados; conferir último commit e origin/main ao retomar.
- Alterações preexistentes fora do commit: datasets/dsNwEmbalagens.js e testes/testar-dataset-unico.cjs.
- Validação visual no Fluig não confirmada; nenhuma publicação realizada.

## Para retomar
- Ler AGENTS.md e os quatro arquivos AI_*.md e conferir Git/Dataset atuais.
- Loading inicial implementado; validação no Fluig segue pendente, sem autorização de publicação nesta tarefa.
- Demais pendências: AI_TODO.md; registro não autoriza execução.
