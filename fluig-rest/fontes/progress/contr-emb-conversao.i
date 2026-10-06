/* Contrato compartilhado da conversao do controle de estoque.
   Projecao transitoria: nao cria tabela fisica. */
DEFINE TEMP-TABLE ttEmbConversaoDiagnostico NO-UNDO
    FIELD nome-tabela AS CHARACTER
    FIELD quantidade  AS INTEGER
    FIELD tratamento  AS CHARACTER
    INDEX pk IS PRIMARY UNIQUE nome-tabela.

