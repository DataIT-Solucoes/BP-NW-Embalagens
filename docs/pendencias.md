# Pendências — widget_nw_embalagens

> Pendências, perguntas ao usuário e propostas não aprovadas. Ao resolver: tirar daqui e, se for decisão, registrar em `decisoes.md`.
> Pendência registrada não autoriza execução. Itens herdados de 07/10 podem já ter sido resolvidos: conferir antes de retomar.

## Esperando decisão do usuário
- Grupos definitivos por ação antes de produção (DT-054): herdada. O Dataset atual usa `DefaultGroup-1`; não presumir aprovação para produção.
- Normalização de maiúsculas na sigla: a decisão ficou em aberto; conferir contrato vigente e aprovação antes de alterar.
- **Identificação fora do padrão da raiz** (21/10): o `CLAUDE.md` da raiz diz prefixo `nwe` e `id` = `<nome>_${instanceId}`; o fonte usa
  container `cadastro-embalagens_${instanceId}`, SuperWidget `cadastroEmbalagens` e escopo CSS `.fluig-style-guide.cadastro-embalagens`
  (classes `embalagens-*`). Ajustar a raiz, o widget ou deixar como está.
- **Cópia local do Dataset** (21/10): `datasets/dsNwEmbalagens.js` tem alterações locais não commitadas; o publicado é o do GitHub `BP-NW-DATASET`.
  Confirmar se a cópia local continua sendo mantida e se deve ficar igual ao GitHub.

## Confirmar no Fluig de TESTE (nada visto ainda)
- Spinner no lugar do interruptor ao ativar/inativar, inclusive com rede lenta e falha (bloqueio/liberação verificados só nos testes locais).
- Overlay global e toast info no carregamento inicial e ao Buscar, inclusive com rede lenta, erro e buscas consecutivas (verificado só com simulação).
- Estado atual da publicação do Dataset e do widget (notas de "não publicado" de 07/10 são históricas). Página registrada: `/portal/p/1/cadastro_de_embalagens`.
- Integração real de consulta, autocomplete, cadastro, edição, inativação/reativação e **exclusão** (existe no fonte, não homologada).
- Pendências técnicas herdadas: `getHttpStatusResult()`, envio de `params` JSON com booleanos/números em POST/PATCH e nomes de colunas
  de `colleagueGroup` dentro do Dataset publicado.
- Concorrência, idempotência e resultado incerto no ambiente real; testes simulados não substituem essa validação.

## Fora do widget
- Fluig e serviço `DATASUL_REST_HOMOLOG` configurados, API Datasul disponível e grupos adequados. Responsáveis pela publicação e aceite: a definir.
