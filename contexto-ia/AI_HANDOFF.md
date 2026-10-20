# AI_HANDOFF — widget_nw_embalagens

## Última atualização
2026-10-20 — branch main; HEAD anterior à entrega: 1f0ec9c.

## Tarefa atual / última entrega
- Pedido aprovado: ao ativar/inativar, substituir o interruptor por spinner no mesmo lugar e manter o botão bloqueado até concluir.
- Mudança somente no CSS da interface: aria-busy=true esconde fundo/bolinha e exibe ::after circular de 18 px, borda neutra com trecho verde, animação existente de 1 s. Dimensões do botão e posição das ações preservadas.
- Reutilizado o fluxo JS existente de disabled/aria-busy em definirSalvando e alterarSituacao; nenhuma mudança no comando ou contrato. Situação segue a confirmação do servidor; falhas mantêm o estado anterior e mostram erro.
- npm test passou: Dataset 46/0, transporte 11/0, tela 33/0, total 90; testes existentes verificam bloqueio, resposta, recusa, rede e atualização da tabela.
- WAR: target/widget_nw_embalagens.war, 12 entradas, 26835 bytes; ZIP íntegro e conteúdo igual aos fontes.
- SHA-256 do WAR: b225822532bdc9482cadb895fe3059119ccba9bd76142292369cdecbe1a99801.
- UTF-8 sem BOM/CRLF e diff conferidos; hashes das alterações preexistentes preservados.
- Commit/push desta entrega: CSS, README e contexto afetado; conferir último commit e origin/main ao retomar.
- Fora do commit: alterações preexistentes em datasets/dsNwEmbalagens.js e testes/testar-dataset-unico.cjs.
- Aparência/animação no Fluig não confirmadas; nenhuma publicação realizada.

## Para retomar
- Ler AGENTS.md e os quatro AI_*.md; conferir Git e Dataset atuais.
- Loading global continua valendo para início/Buscar; o feedback de ativar/inativar é local no interruptor.
- Demais pendências: AI_TODO.md; registro não autoriza execução.
