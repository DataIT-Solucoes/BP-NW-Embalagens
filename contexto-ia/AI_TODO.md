# AI_TODO — widget_nw_embalagens

Pendências registradas não autorizam execução. Itens herdados de 07/10/2026 podem já ter sido resolvidos; conferir antes de retomá-los.

## Esperando decisão do usuário
- Grupos definitivos por ação antes de produção (DT-054): pendência herdada. O Dataset atual usa DefaultGroup-1; não presumir aprovação para produção.
- Normalização de maiúsculas na sigla: orientação anterior deixava a decisão em aberto; conferir contrato vigente e aprovação antes de alterar.

## Confirmar no Fluig
- Conferir visualmente o overlay global e o toast info no carregamento inicial, inclusive com rede lenta e falha; os fluxos foram verificados localmente com simulação.
- Estado atual da publicação do Dataset e do widget. Notas de “não publicado” de 07/10 são históricas; não há verificação atual nesta sessão.
- Integração real de consulta, autocomplete, cadastro, edição, inativação/reativação e exclusão. A exclusão existe no fonte, mas não foi homologada nesta revisão.
- Pendências técnicas herdadas: getHttpStatusResult(), envio de params JSON com booleanos/números em POST/PATCH e nomes de colunas de colleagueGroup dentro do Dataset publicado.
- Concorrência, idempotência e resultado incerto no ambiente real; testes simulados não substituem essa validação.

## Dependências externas
- Fluig e serviço DATASUL_REST_HOMOLOG configurados, API Datasul disponível e grupos adequados. Responsáveis atuais pela publicação e aceite: a definir.
- Migração das outras widgets (widget_nw_itensComCtrllDeEmb, widget_nw_manutEtiq): citada como pendente em 07/10; não verificada e fora do escopo desta widget.
