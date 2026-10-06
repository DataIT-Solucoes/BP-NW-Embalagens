/* Rastreio do Controle de Embalagens.
   Este modulo concentra identidades, eventos, movimentos e suas consultas.
   Operacoes especificas preparam comandos e reutilizam o nucleo comum. */
{fontes/progress/contr-emb.i}

FUNCTION f-emb-char-igual RETURNS LOGICAL
    (INPUT pcA AS CHARACTER, INPUT pcB AS CHARACTER):
    IF pcA = ? AND pcB = ? THEN RETURN YES.
    IF pcA = ? OR pcB = ? THEN RETURN NO.
    RETURN pcA = pcB.
END FUNCTION.

FUNCTION f-emb-int-igual RETURNS LOGICAL
    (INPUT piA AS INTEGER, INPUT piB AS INTEGER):
    IF piA = ? AND piB = ? THEN RETURN YES.
    IF piA = ? OR piB = ? THEN RETURN NO.
    RETURN piA = piB.
END FUNCTION.

FUNCTION f-emb-dec-igual RETURNS LOGICAL
    (INPUT pdeA AS DECIMAL, INPUT pdeB AS DECIMAL):
    IF pdeA = ? AND pdeB = ? THEN RETURN YES.
    IF pdeA = ? OR pdeB = ? THEN RETURN NO.
    RETURN pdeA = pdeB.
END FUNCTION.

FUNCTION f-emb-date-igual RETURNS LOGICAL
    (INPUT pdtA AS DATE, INPUT pdtB AS DATE):
    IF pdtA = ? AND pdtB = ? THEN RETURN YES.
    IF pdtA = ? OR pdtB = ? THEN RETURN NO.
    RETURN pdtA = pdtB.
END FUNCTION.

FUNCTION f-emb-datetime-igual RETURNS LOGICAL
    (INPUT pdtA AS DATETIME-TZ, INPUT pdtB AS DATETIME-TZ):
    IF pdtA = ? AND pdtB = ? THEN RETURN YES.
    IF pdtA = ? OR pdtB = ? THEN RETURN NO.
    RETURN pdtA = pdtB.
END FUNCTION.

FUNCTION f-emb-opcional RETURNS CHARACTER
    (INPUT pcValor AS CHARACTER):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    IF pcValor = ? THEN RETURN ?.
    cValor = TRIM(pcValor, " ").
    IF cValor = "" THEN RETURN ?.
    RETURN cValor.
END FUNCTION.

FUNCTION f-emb-id-opcional RETURNS INTEGER
    (INPUT piValor AS INTEGER):
    IF piValor = ? OR piValor = 0 THEN RETURN ?.
    RETURN piValor.
END FUNCTION.

FUNCTION f-emb-chave-parte RETURNS CHARACTER
    (INPUT pcValor AS CHARACTER):
    DEFINE VARIABLE cValor AS CHARACTER NO-UNDO.
    IF pcValor = ? THEN RETURN "-1:".
    cValor = TRIM(pcValor, " ").
    RETURN STRING(LENGTH(cValor, "CHARACTER")) + ":" + cValor.
END FUNCTION.

FUNCTION f-emb-chave-data RETURNS CHARACTER
    (INPUT pdtValor AS DATE):
    IF pdtValor = ? THEN RETURN "-1:".
    RETURN f-emb-chave-parte(STRING(pdtValor, "99/99/9999")).
END FUNCTION.

FUNCTION f-emb-chave-decimal RETURNS CHARACTER
    (INPUT pdeValor AS DECIMAL):
    IF pdeValor = ? THEN RETURN "-1:".
    RETURN f-emb-chave-parte(TRIM(STRING(pdeValor))).
END FUNCTION.

PROCEDURE registrarEvento:
/* ET-02 / DT-076. Registra somente a identidade duravel do fato. O produtor
   continua responsavel pela classificacao e pelo conteudo canonico. */
DEFINE INPUT  PARAMETER TABLE FOR ttEmbEventoComando.
DEFINE INPUT  PARAMETER plAutorizado AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso    AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao  AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento   AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcSituacao   AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER piVersao     AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro       AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem   AS CHARACTER NO-UNDO.

DEFINE BUFFER bEvento FOR mgesp.contr_emb_evento.
DEFINE VARIABLE iComandos      AS INTEGER NO-UNDO.
DEFINE VARIABLE cOrigem        AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChave         AS CHARACTER NO-UNDO.
DEFINE VARIABLE cHashChave     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cHashConteudo  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipoEvento    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipoDocto     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChaveDocto    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cHashDocto     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCodEstabel    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCgcEmitente   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSerie         AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNroDocto      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChaveAcesso   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNatOperacao   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDadosEvento   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario       AS CHARACTER NO-UNDO.
DEFINE VARIABLE iIdOperacao    AS INTEGER NO-UNDO.
DEFINE VARIABLE iIdEventoOrig  AS INTEGER NO-UNDO.
DEFINE VARIABLE iCodEmitente   AS INTEGER NO-UNDO.
DEFINE VARIABLE lFalhaInclusao AS LOGICAL NO-UNDO.
DEFINE VARIABLE dtAgora        AS DATETIME-TZ NO-UNDO.

ASSIGN plSucesso   = NO
       plRepeticao = NO
       piIdEvento  = 0
       pcSituacao  = ""
       piVersao    = 0
       pcErro      = "SEM_PERMISSAO"
       pcMensagem  = "Operacao nao autorizada.".
IF plAutorizado = ? OR NOT plAutorizado THEN RETURN.
IF NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_MGESP_NAO_CONECTADO"
           pcMensagem = "Banco especifico nao conectado.".
    RETURN.
END.

FOR EACH ttEmbEventoComando:
    iComandos = iComandos + 1.
END.
ASSIGN pcErro = "COMANDO_INVALIDO"
       pcMensagem = "Informe exatamente um evento valido.".
IF iComandos <> 1 THEN RETURN.
FIND FIRST ttEmbEventoComando NO-ERROR.
IF NOT AVAILABLE ttEmbEventoComando THEN RETURN.

ASSIGN cOrigem       = IF ttEmbEventoComando.origem = ? THEN ""
                       ELSE CAPS(TRIM(ttEmbEventoComando.origem, " "))
       cChave        = IF ttEmbEventoComando.chave-evento = ? THEN ""
                       ELSE TRIM(ttEmbEventoComando.chave-evento, " ")
       cHashChave    = IF ttEmbEventoComando.hash-chave = ? THEN ""
                       ELSE CAPS(TRIM(ttEmbEventoComando.hash-chave, " "))
       cHashConteudo = IF ttEmbEventoComando.hash-conteudo = ? THEN ""
                       ELSE CAPS(TRIM(ttEmbEventoComando.hash-conteudo, " "))
       cTipoEvento   = IF ttEmbEventoComando.tipo-evento = ? THEN ""
                       ELSE CAPS(TRIM(ttEmbEventoComando.tipo-evento, " "))
       cTipoDocto    = f-emb-opcional(ttEmbEventoComando.tipo-docto)
       cChaveDocto   = f-emb-opcional(ttEmbEventoComando.chave-docto)
       cHashDocto    = f-emb-opcional(ttEmbEventoComando.hash-docto)
       cCodEstabel   = f-emb-opcional(ttEmbEventoComando.cod-estabel)
       cCgcEmitente  = f-emb-opcional(ttEmbEventoComando.cgc-emitente)
       cSerie        = f-emb-opcional(ttEmbEventoComando.serie)
       cNroDocto     = f-emb-opcional(ttEmbEventoComando.nro-docto)
       cChaveAcesso  = f-emb-opcional(ttEmbEventoComando.chave-acesso)
       cNatOperacao  = f-emb-opcional(ttEmbEventoComando.nat-operacao)
       cDadosEvento  = IF ttEmbEventoComando.dados-evento = ? THEN ""
                       ELSE TRIM(ttEmbEventoComando.dados-evento, " ")
       cUsuario      = IF ttEmbEventoComando.usuario = ? THEN ""
                       ELSE TRIM(ttEmbEventoComando.usuario, " ")
       iIdOperacao   = f-emb-id-opcional(ttEmbEventoComando.id-operacao)
       iIdEventoOrig = f-emb-id-opcional(ttEmbEventoComando.id-evento-origem)
       iCodEmitente  = f-emb-id-opcional(ttEmbEventoComando.cod-emitente).
IF cTipoDocto <> ? THEN cTipoDocto = CAPS(cTipoDocto).
IF cHashDocto <> ? THEN cHashDocto = CAPS(cHashDocto).

IF cOrigem = "" OR LENGTH(cOrigem, "CHARACTER") > 20 OR
   cChave = "" OR LENGTH(cChave, "CHARACTER") > 512 OR
   LENGTH(cHashChave, "CHARACTER") <> 64 OR
   LENGTH(cHashConteudo, "CHARACTER") <> 64 OR
   cTipoEvento = "" OR LENGTH(cTipoEvento, "CHARACTER") > 32 OR
   ttEmbEventoComando.seq-ciclo = ? OR ttEmbEventoComando.seq-ciclo <= 0 OR
   ttEmbEventoComando.dt-evento = ? OR
   ttEmbEventoComando.versao-contrato = ? OR
   ttEmbEventoComando.versao-contrato <= 0 OR
   cDadosEvento = "" OR LENGTH(cDadosEvento, "CHARACTER") > 4000 OR
   cUsuario = "" OR LENGTH(cUsuario, "CHARACTER") > 128 OR
   (ttEmbEventoComando.id-operacao <> ? AND ttEmbEventoComando.id-operacao < 0) OR
   (ttEmbEventoComando.id-evento-origem <> ? AND ttEmbEventoComando.id-evento-origem < 0) OR
   (ttEmbEventoComando.cod-emitente <> ? AND ttEmbEventoComando.cod-emitente < 0) THEN RETURN.

IF cTipoDocto <> ? AND LOOKUP(cTipoDocto, "ENTRADA,SAIDA") = 0 THEN RETURN.
IF (cChaveDocto = ? AND cHashDocto <> ?) OR
   (cChaveDocto <> ? AND (cTipoDocto = ? OR cHashDocto = ? OR
    LENGTH(cHashDocto, "CHARACTER") <> 64)) THEN RETURN.
IF cChaveDocto <> ? AND LENGTH(cChaveDocto, "CHARACTER") > 512 THEN RETURN.
IF cChaveAcesso <> ? AND LENGTH(cChaveAcesso, "CHARACTER") > 44 THEN RETURN.

/* Caminho rapido de repeticao ja persistida. */
FIND FIRST bEvento NO-LOCK
    WHERE bEvento.hash-chave = cHashChave NO-ERROR.
IF AVAILABLE bEvento THEN DO:
    IF NOT f-emb-char-igual(bEvento.origem, cOrigem) OR
       NOT f-emb-char-igual(bEvento.chave-evento, cChave) OR
       NOT f-emb-char-igual(bEvento.hash-conteudo, cHashConteudo) OR
       NOT f-emb-char-igual(bEvento.tipo-evento, cTipoEvento) THEN DO:
        ASSIGN pcErro = "CONFLITO_IDEMPOTENCIA"
               pcMensagem = "A chave informada ja foi utilizada com outro conteudo.".
        RETURN.
    END.
    ASSIGN plSucesso = YES plRepeticao = YES
           piIdEvento = bEvento.id-evento pcSituacao = bEvento.situacao
           piVersao = bEvento.versao pcErro = "" pcMensagem = "".
    RETURN.
END.

registrarTransacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    /* Releitura sob bloqueio reduz a janela entre busca e inclusao. */
    FIND FIRST bEvento EXCLUSIVE-LOCK
        WHERE bEvento.hash-chave = cHashChave NO-ERROR.
    IF AVAILABLE bEvento THEN DO:
        IF NOT f-emb-char-igual(bEvento.origem, cOrigem) OR
           NOT f-emb-char-igual(bEvento.chave-evento, cChave) OR
           NOT f-emb-char-igual(bEvento.hash-conteudo, cHashConteudo) OR
           NOT f-emb-char-igual(bEvento.tipo-evento, cTipoEvento) THEN DO:
            ASSIGN pcErro = "CONFLITO_IDEMPOTENCIA"
                   pcMensagem = "A chave informada ja foi utilizada com outro conteudo.".
            RETURN.
        END.
        ASSIGN plSucesso = YES plRepeticao = YES
               piIdEvento = bEvento.id-evento pcSituacao = bEvento.situacao
               piVersao = bEvento.versao pcErro = "" pcMensagem = "".
        RETURN.
    END.

    ASSIGN dtAgora = NOW
           piIdEvento = NEXT-VALUE(CONTR_EMB_EVENTO_SEQ, mgesp).
    CREATE bEvento NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        lFalhaInclusao = YES.
        UNDO registrarTransacao, LEAVE registrarTransacao.
    END.
    ASSIGN bEvento.id-evento         = piIdEvento
           bEvento.origem            = cOrigem
           bEvento.chave-evento      = cChave
           bEvento.hash-chave        = cHashChave
           bEvento.hash-conteudo     = cHashConteudo
           bEvento.tipo-evento       = cTipoEvento
           bEvento.id-operacao       = iIdOperacao
           bEvento.id-evento-origem  = iIdEventoOrig
           bEvento.seq-ciclo         = ttEmbEventoComando.seq-ciclo
           bEvento.dt-evento         = ttEmbEventoComando.dt-evento
           bEvento.versao-contrato   = ttEmbEventoComando.versao-contrato
           bEvento.tipo-docto        = cTipoDocto
           bEvento.chave-docto       = cChaveDocto
           bEvento.hash-docto        = cHashDocto
           bEvento.cod-estabel       = cCodEstabel
           bEvento.cod-emitente      = iCodEmitente
           bEvento.cgc-emitente      = cCgcEmitente
           bEvento.serie             = cSerie
           bEvento.nro-docto         = cNroDocto
           bEvento.chave-acesso      = cChaveAcesso
           bEvento.nat-operacao      = cNatOperacao
           bEvento.dt-emissao        = ttEmbEventoComando.dt-emissao
           bEvento.dados-evento      = cDadosEvento
           bEvento.situacao          = "RECEBIDO"
           bEvento.tentativas        = 0
           bEvento.dt-proxima-tent   = ?
           bEvento.token-execucao    = ?
           bEvento.dt-expira-exec    = ?
           bEvento.dt-conclusao      = ?
           bEvento.resultado         = ?
           bEvento.mensagem          = ""
           bEvento.dt-inclusao       = dtAgora
           bEvento.usuario-inclusao  = cUsuario
           bEvento.dt-alteracao      = dtAgora
           bEvento.usuario-alteracao = cUsuario
           bEvento.versao            = 1 NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        lFalhaInclusao = YES.
        UNDO registrarTransacao, LEAVE registrarTransacao.
    END.
    ASSIGN plSucesso = YES plRepeticao = NO pcSituacao = "RECEBIDO"
           piVersao = 1 pcErro = "" pcMensagem = "".
    CATCH eRegistro AS Progress.Lang.Error:
        lFalhaInclusao = YES.
    END CATCH.
END.

IF plSucesso THEN RETURN.
IF lFalhaInclusao THEN DO:
    /* Uma inclusao concorrente pode ter confirmado a mesma chave. */
    FIND FIRST bEvento NO-LOCK
        WHERE bEvento.hash-chave = cHashChave NO-ERROR.
    IF AVAILABLE bEvento AND f-emb-char-igual(bEvento.origem, cOrigem) AND
       f-emb-char-igual(bEvento.chave-evento, cChave) AND
       f-emb-char-igual(bEvento.hash-conteudo, cHashConteudo) AND
       f-emb-char-igual(bEvento.tipo-evento, cTipoEvento) THEN DO:
        ASSIGN plSucesso = YES plRepeticao = YES
               piIdEvento = bEvento.id-evento pcSituacao = bEvento.situacao
               piVersao = bEvento.versao pcErro = "" pcMensagem = "".
        RETURN.
    END.
    ASSIGN piIdEvento = 0
           pcErro = "FALHA_REGISTRO_EVENTO"
           pcMensagem = "Nao foi possivel registrar o evento.".
END.
END PROCEDURE.

PROCEDURE aplicarMovimento:
/* ET-02 / DT-076. Persiste um fato ja classificado pelo produtor do fluxo e
   atualiza somente a projecao individual especifica. Nao movimenta o ERP. */
DEFINE INPUT  PARAMETER TABLE FOR ttEmbMovimentoComando.
DEFINE INPUT  PARAMETER plAutorizado      AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso         AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao       AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piIdMovto         AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piVersaoEtiqueta  AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro            AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem        AS CHARACTER NO-UNDO.

DEFINE BUFFER bEvento     FOR mgesp.contr_emb_evento.
DEFINE BUFFER bEtiqueta   FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bMovto      FOR mgesp.contr_emb_movto.
DEFINE BUFFER bMovtoOrig  FOR mgesp.contr_emb_movto.
DEFINE BUFFER bEventoItem FOR mgesp.contr_emb_evento_item.
DEFINE BUFFER bOperItem   FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bBag        FOR mgesp.contr_emb_bag_lacre.
DEFINE VARIABLE iComandos      AS INTEGER NO-UNDO.
DEFINE VARIABLE iItemEvento    AS INTEGER NO-UNDO.
DEFINE VARIABLE iItemOper      AS INTEGER NO-UNDO.
DEFINE VARIABLE iMovtoAnt      AS INTEGER NO-UNDO.
DEFINE VARIABLE iBagRelac      AS INTEGER NO-UNDO.
DEFINE VARIABLE iBagDestino    AS INTEGER NO-UNDO.
DEFINE VARIABLE iMovtoOrigem   AS INTEGER NO-UNDO.
DEFINE VARIABLE iEmitenteDest  AS INTEGER NO-UNDO.
DEFINE VARIABLE cTipoMovto     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUn            AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSituacao      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCodEstabel    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCodDepos      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCodLocaliz    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTipoLocal     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOrigemLocal   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCodLocalExt   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cOrigemErp     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChaveErp      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cJustificativa AS CHARACTER NO-UNDO.
DEFINE VARIABLE lPrimeiro      AS LOGICAL NO-UNDO.
DEFINE VARIABLE deQtidadeAnt   AS DECIMAL NO-UNDO.
DEFINE VARIABLE dtAgora        AS DATETIME-TZ NO-UNDO.

ASSIGN plSucesso = NO plRepeticao = NO piIdMovto = 0
       piVersaoEtiqueta = 0 pcErro = "SEM_PERMISSAO"
       pcMensagem = "Operacao nao autorizada.".
IF plAutorizado = ? OR NOT plAutorizado THEN RETURN.
IF NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_MGESP_NAO_CONECTADO"
           pcMensagem = "Banco especifico nao conectado.".
    RETURN.
END.

FOR EACH ttEmbMovimentoComando:
    iComandos = iComandos + 1.
END.
ASSIGN pcErro = "COMANDO_INVALIDO"
       pcMensagem = "Informe exatamente um movimento valido.".
IF iComandos <> 1 THEN RETURN.
FIND FIRST ttEmbMovimentoComando NO-ERROR.
IF NOT AVAILABLE ttEmbMovimentoComando THEN RETURN.

ASSIGN iItemEvento   = f-emb-id-opcional(ttEmbMovimentoComando.id-item-evento)
       iItemOper     = f-emb-id-opcional(ttEmbMovimentoComando.id-item-oper)
       iMovtoAnt     = f-emb-id-opcional(ttEmbMovimentoComando.id-movto-ant-esperado)
       iBagRelac     = f-emb-id-opcional(ttEmbMovimentoComando.id-bag-relac)
       iBagDestino   = f-emb-id-opcional(ttEmbMovimentoComando.id-bag-destino)
       iMovtoOrigem  = f-emb-id-opcional(ttEmbMovimentoComando.id-movto-origem)
       iEmitenteDest = f-emb-id-opcional(ttEmbMovimentoComando.cod-emitente-dest)
       cTipoMovto    = IF ttEmbMovimentoComando.tipo-movto = ? THEN ""
                       ELSE CAPS(TRIM(ttEmbMovimentoComando.tipo-movto, " "))
       cUn            = IF ttEmbMovimentoComando.un = ? THEN ""
                       ELSE CAPS(TRIM(ttEmbMovimentoComando.un, " "))
       cSituacao      = IF ttEmbMovimentoComando.situacao-atu = ? THEN ""
                       ELSE CAPS(TRIM(ttEmbMovimentoComando.situacao-atu, " "))
       cCodEstabel    = IF ttEmbMovimentoComando.cod-estabel-dest = ? THEN ""
                       ELSE TRIM(ttEmbMovimentoComando.cod-estabel-dest, " ")
       cCodDepos      = f-emb-opcional(ttEmbMovimentoComando.cod-depos-dest)
       cCodLocaliz    = f-emb-opcional(ttEmbMovimentoComando.cod-localiz-dest)
       cTipoLocal     = IF ttEmbMovimentoComando.tipo-local-dest = ? THEN ""
                       ELSE CAPS(TRIM(ttEmbMovimentoComando.tipo-local-dest, " "))
       cOrigemLocal   = f-emb-opcional(ttEmbMovimentoComando.origem-local-ext-dest)
       cCodLocalExt   = f-emb-opcional(ttEmbMovimentoComando.cod-local-ext-dest)
       cOrigemErp     = f-emb-opcional(ttEmbMovimentoComando.origem-movto-erp)
       cChaveErp      = f-emb-opcional(ttEmbMovimentoComando.chave-movto-erp)
       cJustificativa = f-emb-opcional(ttEmbMovimentoComando.justificativa).
IF cOrigemErp <> ? THEN cOrigemErp = CAPS(cOrigemErp).

IF ttEmbMovimentoComando.id-evento = ? OR
   ttEmbMovimentoComando.id-evento <= 0 OR
   ttEmbMovimentoComando.sequencia = ? OR
   ttEmbMovimentoComando.sequencia <= 0 OR
   ttEmbMovimentoComando.id-etiqueta = ? OR
   ttEmbMovimentoComando.id-etiqueta <= 0 OR
   ttEmbMovimentoComando.versao-etiqueta-esperada = ? OR
   ttEmbMovimentoComando.versao-etiqueta-esperada <= 0 OR
   cTipoMovto = "" OR LENGTH(cTipoMovto, "CHARACTER") > 32 OR
   ttEmbMovimentoComando.dt-movto = ? OR
   cUn = "" OR
   ttEmbMovimentoComando.quantidade = ? OR
   ttEmbMovimentoComando.quantidade < 0 OR
   ttEmbMovimentoComando.qtidade-atu = ? OR
   ttEmbMovimentoComando.qtidade-atu < 0 OR
   LOOKUP(cSituacao, "ATIVA,ENCERRADA,CANCELADA,DESCARTADA") = 0 OR
   cCodEstabel = "" OR
   LOOKUP(cTipoLocal, "ESTAB,CAMPO,TERCEIRO,TRANSITO") = 0 OR
   ttEmbMovimentoComando.usuario = ? OR
   TRIM(ttEmbMovimentoComando.usuario, " ") = "" OR
   LENGTH(TRIM(ttEmbMovimentoComando.usuario, " "), "CHARACTER") > 128 THEN RETURN.

IF (ttEmbMovimentoComando.id-item-evento <> ? AND ttEmbMovimentoComando.id-item-evento < 0) OR
   (ttEmbMovimentoComando.id-item-oper <> ? AND ttEmbMovimentoComando.id-item-oper < 0) OR
   (ttEmbMovimentoComando.id-movto-ant-esperado <> ? AND ttEmbMovimentoComando.id-movto-ant-esperado < 0) OR
   (ttEmbMovimentoComando.id-bag-relac <> ? AND ttEmbMovimentoComando.id-bag-relac < 0) OR
   (ttEmbMovimentoComando.id-bag-destino <> ? AND ttEmbMovimentoComando.id-bag-destino < 0) OR
   (ttEmbMovimentoComando.id-movto-origem <> ? AND ttEmbMovimentoComando.id-movto-origem < 0) OR
   (ttEmbMovimentoComando.cod-emitente-dest <> ? AND ttEmbMovimentoComando.cod-emitente-dest < 0) THEN RETURN.
IF (cOrigemErp = ? AND cChaveErp <> ?) OR
   (cOrigemErp <> ? AND cChaveErp = ?) THEN RETURN.
IF cOrigemErp <> ? AND LENGTH(cOrigemErp, "CHARACTER") > 20 THEN RETURN.
IF cChaveErp <> ? AND LENGTH(cChaveErp, "CHARACTER") > 512 THEN RETURN.
IF cJustificativa <> ? AND LENGTH(cJustificativa, "CHARACTER") > 1000 THEN RETURN.
IF iMovtoOrigem <> ? AND cJustificativa = ? THEN DO:
    ASSIGN pcErro = "JUSTIFICATIVA_OBRIGATORIA"
           pcMensagem = "Movimento relacionado a outro fato exige justificativa.".
    RETURN.
END.

movimentoTransacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    ASSIGN pcErro = "EVENTO_NAO_ENCONTRADO"
           pcMensagem = "O evento informado nao foi encontrado.".
    FIND FIRST bEvento EXCLUSIVE-LOCK
        WHERE bEvento.id-evento = ttEmbMovimentoComando.id-evento NO-ERROR.
    IF NOT AVAILABLE bEvento THEN RETURN.

    /* Repeticao e resolvida antes de exigir que o evento ainda esteja aberto. */
    FIND FIRST bMovto NO-LOCK
        WHERE bMovto.id-evento = ttEmbMovimentoComando.id-evento
          AND bMovto.sequencia = ttEmbMovimentoComando.sequencia NO-ERROR.
    IF AVAILABLE bMovto THEN DO:
        IF bMovto.id-etiqueta <> ttEmbMovimentoComando.id-etiqueta OR
           NOT f-emb-int-igual(bMovto.id-item-evento, iItemEvento) OR
           NOT f-emb-int-igual(bMovto.id-item-oper, iItemOper) OR
           NOT f-emb-int-igual(bMovto.id-movto-ant, iMovtoAnt) OR
           NOT f-emb-int-igual(bMovto.id-bag-relac, iBagRelac) OR
           NOT f-emb-int-igual(bMovto.id-movto-origem, iMovtoOrigem) OR
           bMovto.tipo-movto <> cTipoMovto OR
           NOT f-emb-datetime-igual(bMovto.dt-movto, ttEmbMovimentoComando.dt-movto) OR
           bMovto.un <> cUn OR
           NOT f-emb-dec-igual(bMovto.quantidade, ttEmbMovimentoComando.quantidade) OR
           NOT f-emb-dec-igual(bMovto.qtidade-atu, ttEmbMovimentoComando.qtidade-atu) OR
           bMovto.situacao-atu <> cSituacao OR
           bMovto.cod-estabel-dest <> cCodEstabel OR
           NOT f-emb-char-igual(bMovto.cod-depos-dest, cCodDepos) OR
           NOT f-emb-char-igual(bMovto.cod-localiz-dest, cCodLocaliz) OR
           bMovto.tipo-local-dest <> cTipoLocal OR
           NOT f-emb-int-igual(bMovto.cod-emitente-dest, iEmitenteDest) OR
           NOT f-emb-char-igual(bMovto.origem-local-ext-dest, cOrigemLocal) OR
           NOT f-emb-char-igual(bMovto.cod-local-ext-dest, cCodLocalExt) OR
           NOT f-emb-char-igual(bMovto.origem-movto-erp, cOrigemErp) OR
           NOT f-emb-char-igual(bMovto.chave-movto-erp, cChaveErp) OR
           NOT f-emb-char-igual(bMovto.justificativa, cJustificativa) THEN DO:
            ASSIGN pcErro = "CONFLITO_SEQUENCIA"
                   pcMensagem = "A sequencia do evento ja foi usada por outro movimento.".
            RETURN.
        END.
        FIND FIRST bEtiqueta NO-LOCK
            WHERE bEtiqueta.id-etiqueta = bMovto.id-etiqueta NO-ERROR.
        ASSIGN plSucesso = YES plRepeticao = YES
               piIdMovto = bMovto.id-movto
               piVersaoEtiqueta = IF AVAILABLE bEtiqueta THEN bEtiqueta.versao ELSE 0
               pcErro = "" pcMensagem = "".
        RETURN.
    END.

    ASSIGN pcErro = "EVENTO_NAO_ABERTO"
           pcMensagem = "O evento nao aceita novos movimentos.".
    IF bEvento.situacao = ? OR
       LOOKUP(bEvento.situacao, "RECEBIDO,PROCESSANDO") = 0 THEN RETURN.

    ASSIGN pcErro = "ETIQUETA_NAO_ENCONTRADA"
           pcMensagem = "A embalagem informada nao foi encontrada.".
    FIND FIRST bEtiqueta EXCLUSIVE-LOCK
        WHERE bEtiqueta.id-etiqueta = ttEmbMovimentoComando.id-etiqueta NO-ERROR.
    IF NOT AVAILABLE bEtiqueta THEN RETURN.
    ASSIGN pcErro = "ETIQUETA_NAO_MOVIMENTAVEL"
           pcMensagem = "Somente embalagens individualizadas recebem movimentos.".
    IF bEtiqueta.tipo-controle = ? OR
       bEtiqueta.tipo-controle <> "EMBALAGEM" THEN RETURN.
    ASSIGN pcErro = "CONFLITO_VERSAO"
           pcMensagem = "A embalagem foi alterada por outra operacao.".
    IF bEtiqueta.versao = ? OR
       bEtiqueta.versao <> ttEmbMovimentoComando.versao-etiqueta-esperada THEN RETURN.
    IF NOT f-emb-char-igual(bEtiqueta.un, cUn) THEN DO:
        ASSIGN pcErro = "UNIDADE_DIVERGENTE"
               pcMensagem = "A unidade do movimento difere da embalagem.".
        RETURN.
    END.

    ASSIGN lPrimeiro = bEtiqueta.id-movto-ult = ?.
    IF lPrimeiro THEN DO:
        ASSIGN pcErro = "ESTADO_ANTERIOR_INVALIDO"
               pcMensagem = "O primeiro movimento nao possui movimento anterior.".
        IF iMovtoAnt <> ? THEN RETURN.
        IF NOT f-emb-dec-igual(ttEmbMovimentoComando.qtidade-atu,
                              bEtiqueta.qtidade-ini) THEN DO:
            ASSIGN pcErro = "QUANTIDADE_INICIAL_DIVERGENTE"
                   pcMensagem = "O primeiro movimento deve confirmar a quantidade inicial.".
            RETURN.
        END.
        deQtidadeAnt = 0.
    END.
    ELSE DO:
        ASSIGN pcErro = "CONFLITO_MOVIMENTO_ANTERIOR"
               pcMensagem = "O ultimo movimento da embalagem foi alterado.".
        IF iMovtoAnt = ? OR iMovtoAnt <> bEtiqueta.id-movto-ult THEN RETURN.
        IF bEtiqueta.qtidade-atu = ? OR bEtiqueta.qtidade-atu < 0 OR
           bEtiqueta.situacao = ? OR bEtiqueta.cod-estabel = ? OR
           TRIM(bEtiqueta.cod-estabel, " ") = "" OR
           bEtiqueta.tipo-local = ? OR TRIM(bEtiqueta.tipo-local, " ") = "" THEN DO:
            ASSIGN pcErro = "ESTADO_ATUAL_INVALIDO"
                   pcMensagem = "A projecao atual da embalagem esta incompleta.".
            RETURN.
        END.
        deQtidadeAnt = bEtiqueta.qtidade-atu.
    END.

    IF iItemEvento <> ? THEN DO:
        ASSIGN pcErro = "ITEM_EVENTO_INVALIDO"
               pcMensagem = "O item do evento nao corresponde a embalagem.".
        FIND FIRST bEventoItem NO-LOCK
            WHERE bEventoItem.id-item-evento = iItemEvento NO-ERROR.
        IF NOT AVAILABLE bEventoItem OR bEventoItem.id-evento <> bEvento.id-evento OR
           NOT f-emb-char-igual(bEventoItem.it-codigo, bEtiqueta.it-codigo) OR
           NOT f-emb-char-igual(bEventoItem.lote, bEtiqueta.lote) OR
           NOT f-emb-date-igual(bEventoItem.dt-vali-lote, bEtiqueta.dt-vali-lote) THEN RETURN.
    END.
    IF iItemOper <> ? THEN DO:
        ASSIGN pcErro = "ITEM_OPERACAO_INVALIDO"
               pcMensagem = "O item da operacao nao corresponde a embalagem.".
        FIND FIRST bOperItem NO-LOCK
            WHERE bOperItem.id-item-oper = iItemOper NO-ERROR.
        IF NOT AVAILABLE bOperItem OR
           NOT f-emb-char-igual(bOperItem.it-codigo, bEtiqueta.it-codigo) THEN RETURN.
    END.
    IF iMovtoOrigem <> ? THEN DO:
        ASSIGN pcErro = "MOVIMENTO_ORIGEM_INVALIDO"
               pcMensagem = "O movimento relacionado nao pertence a embalagem.".
        FIND FIRST bMovtoOrig NO-LOCK
            WHERE bMovtoOrig.id-movto = iMovtoOrigem NO-ERROR.
        IF NOT AVAILABLE bMovtoOrig OR
           bMovtoOrig.id-etiqueta <> bEtiqueta.id-etiqueta THEN RETURN.
    END.
    IF iBagRelac <> ? THEN DO:
        ASSIGN pcErro = "BAG_INCOMPATIVEL"
               pcMensagem = "A Bag relacionada nao existe ou possui outro tipo.".
        FIND FIRST bBag NO-LOCK WHERE bBag.id-bag = iBagRelac NO-ERROR.
        IF NOT AVAILABLE bBag OR
           NOT f-emb-char-igual(bBag.cod-tipo, bEtiqueta.cod-tipo) THEN RETURN.
    END.
    IF iBagDestino <> ? THEN DO:
        ASSIGN pcErro = "BAG_INCOMPATIVEL"
               pcMensagem = "A Bag de destino nao existe ou possui outro tipo.".
        FIND FIRST bBag NO-LOCK WHERE bBag.id-bag = iBagDestino NO-ERROR.
        IF NOT AVAILABLE bBag OR
           NOT f-emb-char-igual(bBag.cod-tipo, bEtiqueta.cod-tipo) THEN RETURN.
    END.
    IF NOT f-emb-int-igual(bEtiqueta.id-bag, iBagDestino) THEN DO:
        ASSIGN pcErro = "BAG_RELACIONADA_OBRIGATORIA"
               pcMensagem = "A mudanca de vinculo deve identificar a Bag relacionada.".
        IF iBagRelac = ? THEN RETURN.
        IF iBagDestino <> ? AND iBagRelac <> iBagDestino THEN RETURN.
        IF iBagDestino = ? AND iBagRelac <> bEtiqueta.id-bag THEN RETURN.
    END.

    ASSIGN dtAgora  = NOW
           piIdMovto = NEXT-VALUE(CONTR_EMB_MOVTO_SEQ, mgesp).
    CREATE bMovto.
    ASSIGN bMovto.id-movto              = piIdMovto
           bMovto.id-evento             = bEvento.id-evento
           bMovto.sequencia             = ttEmbMovimentoComando.sequencia
           bMovto.id-etiqueta           = bEtiqueta.id-etiqueta
           bMovto.id-item-evento        = iItemEvento
           bMovto.id-item-oper          = iItemOper
           bMovto.id-movto-ant          = IF lPrimeiro THEN ? ELSE bEtiqueta.id-movto-ult
           bMovto.id-bag-relac          = iBagRelac
           bMovto.id-movto-origem       = iMovtoOrigem
           bMovto.tipo-movto            = cTipoMovto
           bMovto.dt-movto              = ttEmbMovimentoComando.dt-movto
           bMovto.un                    = cUn
           bMovto.quantidade            = ttEmbMovimentoComando.quantidade
           bMovto.qtidade-ant           = deQtidadeAnt
           bMovto.qtidade-atu           = ttEmbMovimentoComando.qtidade-atu
           bMovto.situacao-ant          = IF lPrimeiro THEN ? ELSE bEtiqueta.situacao
           bMovto.situacao-atu          = cSituacao
           bMovto.cod-estabel-orig      = IF lPrimeiro THEN ? ELSE bEtiqueta.cod-estabel
           bMovto.cod-depos-orig        = IF lPrimeiro THEN ? ELSE bEtiqueta.cod-depos
           bMovto.cod-localiz-orig      = IF lPrimeiro THEN ? ELSE bEtiqueta.cod-localiz
           bMovto.tipo-local-orig       = IF lPrimeiro THEN ? ELSE bEtiqueta.tipo-local
           bMovto.cod-emitente-orig     = IF lPrimeiro THEN ? ELSE bEtiqueta.cod-emitente-posse
           bMovto.origem-local-ext-orig = IF lPrimeiro THEN ? ELSE bEtiqueta.origem-local-ext
           bMovto.cod-local-ext-orig    = IF lPrimeiro THEN ? ELSE bEtiqueta.cod-local-ext
           bMovto.cod-estabel-dest      = cCodEstabel
           bMovto.cod-depos-dest        = cCodDepos
           bMovto.cod-localiz-dest      = cCodLocaliz
           bMovto.tipo-local-dest       = cTipoLocal
           bMovto.cod-emitente-dest     = iEmitenteDest
           bMovto.origem-local-ext-dest = cOrigemLocal
           bMovto.cod-local-ext-dest    = cCodLocalExt
           bMovto.origem-movto-erp      = cOrigemErp
           bMovto.chave-movto-erp       = cChaveErp
           bMovto.justificativa         = cJustificativa
           bMovto.dt-registro           = dtAgora
           bMovto.usuario               = TRIM(ttEmbMovimentoComando.usuario, " ").

    ASSIGN bEtiqueta.qtidade-atu         = ttEmbMovimentoComando.qtidade-atu
           bEtiqueta.situacao            = cSituacao
           bEtiqueta.cod-estabel         = cCodEstabel
           bEtiqueta.cod-depos           = cCodDepos
           bEtiqueta.cod-localiz         = IF cCodLocaliz = ? THEN "" ELSE cCodLocaliz
           bEtiqueta.tipo-local          = cTipoLocal
           bEtiqueta.cod-emitente-posse  = iEmitenteDest
           bEtiqueta.origem-local-ext    = cOrigemLocal
           bEtiqueta.cod-local-ext       = cCodLocalExt
           bEtiqueta.id-bag              = iBagDestino
           bEtiqueta.id-movto-ult        = piIdMovto
           bEtiqueta.dt-alteracao        = dtAgora
           bEtiqueta.usuario-alteracao   = TRIM(ttEmbMovimentoComando.usuario, " ")
           bEtiqueta.versao              = bEtiqueta.versao + 1
           piVersaoEtiqueta              = bEtiqueta.versao
           plSucesso                     = YES
           plRepeticao                   = NO
           pcErro                        = ""
           pcMensagem                    = "".
END.
END PROCEDURE.

PROCEDURE processarRecebimento:
/* GER-01. Classifica somente a compra de fornecedor confirmada no recorte
   inicial. O ROWID e transporte interno do EPC; nunca e persistido como chave.
   Transferencia, terceiros e emprestimo permanecem fora deste dispatcher. */
DEFINE INPUT  PARAMETER prDocumEst       AS ROWID NO-UNDO.
DEFINE INPUT  PARAMETER plAutorizado     AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plAplicavel      AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso        AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao      AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento       AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piQtdEtiquetas   AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcClassificacao  AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro           AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem       AS CHARACTER NO-UNDO.

DEFINE BUFFER bDocumEst FOR mgmov.docum-est.
DEFINE BUFFER bItemDoc  FOR mgmov.item-doc-est.
DEFINE BUFFER bParamRec FOR mgesp.contr_emb_param.
DEFINE VARIABLE cNaturezaCompra AS CHARACTER NO-UNDO INITIAL "1101IS".
DEFINE VARIABLE cChaveDocto     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cChaveEvento    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConteudo       AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario        AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErroGeracao    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMsgGeracao     AS CHARACTER NO-UNDO.
DEFINE VARIABLE iSeqAnterior    AS INTEGER NO-UNDO.
DEFINE VARIABLE iSeqLote        AS INTEGER NO-UNDO.
DEFINE VARIABLE iLinhas         AS INTEGER NO-UNDO.
DEFINE VARIABLE iQtdValidada    AS INTEGER NO-UNDO.
DEFINE VARIABLE lValidacao      AS LOGICAL NO-UNDO.

EMPTY TEMP-TABLE ttEmbGeracaoLinha.
EMPTY TEMP-TABLE ttEmbGeracaoValidada.
EMPTY TEMP-TABLE ttEmbEventoComando.
ASSIGN plAplicavel = NO
       plSucesso = NO
       plRepeticao = NO
       piIdEvento = 0
       piQtdEtiquetas = 0
       pcClassificacao = ""
       pcErro = "SEM_PERMISSAO"
       pcMensagem = "Operacao nao autorizada.".
IF plAutorizado = ? OR NOT plAutorizado THEN RETURN.
IF NOT CONNECTED("mgmov") OR NOT CONNECTED("mgcad") OR NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_NAO_CONECTADO"
           pcMensagem = "Bancos necessarios para processar o recebimento nao conectados.".
    RETURN.
END.
IF prDocumEst = ? THEN DO:
    ASSIGN pcErro = "DOCUMENTO_NAO_INFORMADO"
           pcMensagem = "Informe o documento confirmado pelo ponto de extensao.".
    RETURN.
END.

FIND FIRST bDocumEst NO-LOCK WHERE ROWID(bDocumEst) = prDocumEst NO-ERROR.
IF NOT AVAILABLE bDocumEst THEN DO:
    ASSIGN pcErro = "DOCUMENTO_NAO_ENCONTRADO"
           pcMensagem = "O documento informado pelo ponto de extensao nao foi encontrado.".
    RETURN.
END.

IF CAPS(TRIM(bDocumEst.nat-operacao, " ")) <> cNaturezaCompra THEN DO:
    ASSIGN plSucesso = YES
           pcClassificacao = "NAO_APLICAVEL"
           pcErro = ""
           pcMensagem = "Natureza fora do recorte inicial de compra de fornecedor.".
    RETURN.
END.
ASSIGN plAplicavel = YES
       pcClassificacao = "COMPRA_FORNECEDOR".
IF bDocumEst.ce-atual = ? OR bDocumEst.ce-atual <> YES THEN DO:
    ASSIGN pcErro = "RECEBIMENTO_NAO_CONFIRMADO"
           pcMensagem = "O documento ainda nao esta confirmado no estoque do Datasul.".
    RETURN.
END.

ASSIGN cUsuario = IF bDocumEst.usuario = ? THEN ""
                  ELSE TRIM(bDocumEst.usuario, " ").
IF cUsuario = "" THEN cUsuario = USERID("mgcad").
IF cUsuario = ? OR TRIM(cUsuario, " ") = "" THEN DO:
    ASSIGN pcErro = "USUARIO_NAO_IDENTIFICADO"
           pcMensagem = "Nao foi possivel identificar o usuario da atualizacao confirmada.".
    RETURN.
END.

ASSIGN cChaveDocto = "ENTRADA|"
        + f-emb-chave-parte(bDocumEst.cod-estabel)
        + f-emb-chave-parte(STRING(bDocumEst.cod-emitente))
        + f-emb-chave-parte(bDocumEst.serie-docto)
        + f-emb-chave-parte(bDocumEst.nro-docto)
        + f-emb-chave-parte(CAPS(TRIM(bDocumEst.nat-operacao, " ")))
       cChaveEvento = "RE1005RP|FIM-ATUALIZACAO|1|" + cChaveDocto
       cConteudo = cChaveEvento
        + f-emb-chave-data(bDocumEst.dt-emissao)
       iSeqAnterior = 0
       iSeqLote = 0.

FOR EACH bItemDoc OF bDocumEst NO-LOCK
    BY bItemDoc.sequencia
    BY bItemDoc.seq-comp:
    IF bItemDoc.sequencia <> iSeqAnterior THEN
        ASSIGN iSeqAnterior = bItemDoc.sequencia
               iSeqLote = 0.
    iSeqLote = iSeqLote + 1.

    IF NOT CAN-FIND(FIRST bParamRec NO-LOCK
        WHERE bParamRec.cod-estabel = bDocumEst.cod-estabel
          AND bParamRec.it-codigo = bItemDoc.it-codigo
          AND bParamRec.ativo) THEN NEXT.

    CREATE ttEmbGeracaoLinha.
    ASSIGN ttEmbGeracaoLinha.sequencia = bItemDoc.sequencia
           ttEmbGeracaoLinha.seq-lote = iSeqLote
           ttEmbGeracaoLinha.cod-estabel = bDocumEst.cod-estabel
           ttEmbGeracaoLinha.it-codigo = bItemDoc.it-codigo
           ttEmbGeracaoLinha.cod-item-origem = bItemDoc.it-codigo
           ttEmbGeracaoLinha.lote = bItemDoc.lote
           ttEmbGeracaoLinha.dt-vali-lote = bItemDoc.dt-vali-lote
           ttEmbGeracaoLinha.qt-origem = bItemDoc.quantidade
           ttEmbGeracaoLinha.un-origem = bItemDoc.un
           ttEmbGeracaoLinha.cod-depos = bItemDoc.cod-depos
           iLinhas = iLinhas + 1
           cConteudo = cConteudo
            + "|LINHA|" + f-emb-chave-parte(STRING(bItemDoc.sequencia))
            + f-emb-chave-parte(STRING(iSeqLote))
            + f-emb-chave-parte(bItemDoc.it-codigo)
            + f-emb-chave-parte(bItemDoc.lote)
            + f-emb-chave-data(bItemDoc.dt-vali-lote)
            + f-emb-chave-decimal(bItemDoc.quantidade)
            + f-emb-chave-parte(bItemDoc.un)
            + f-emb-chave-parte(bItemDoc.cod-depos).
END.

IF iLinhas = 0 THEN DO:
    ASSIGN plSucesso = YES
           pcErro = ""
           pcMensagem = "Recebimento confirmado sem itens parametrizados; nenhuma etiqueta gerada.".
    RETURN.
END.

RUN validarGeracao IN THIS-PROCEDURE(
    INPUT TABLE ttEmbGeracaoLinha,
    INPUT YES,
    OUTPUT TABLE ttEmbGeracaoValidada,
    OUTPUT iQtdValidada,
    OUTPUT lValidacao,
    OUTPUT cErroGeracao,
    OUTPUT cMsgGeracao).
IF NOT lValidacao THEN DO:
    ASSIGN pcErro = cErroGeracao
           pcMensagem = cMsgGeracao.
    RETURN.
END.

CREATE ttEmbEventoComando.
ASSIGN ttEmbEventoComando.origem = "RE1005RP"
       ttEmbEventoComando.chave-evento = cChaveEvento
       ttEmbEventoComando.hash-chave = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cChaveEvento))
       ttEmbEventoComando.hash-conteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cConteudo))
       ttEmbEventoComando.tipo-evento = "RECEBIMENTO_COMPRA"
       ttEmbEventoComando.seq-ciclo = 1
       ttEmbEventoComando.dt-evento = NOW
       ttEmbEventoComando.versao-contrato = 1
       ttEmbEventoComando.tipo-docto = "ENTRADA"
       ttEmbEventoComando.chave-docto = cChaveDocto
       ttEmbEventoComando.hash-docto = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cChaveDocto))
       ttEmbEventoComando.cod-estabel = bDocumEst.cod-estabel
       ttEmbEventoComando.cod-emitente = bDocumEst.cod-emitente
       ttEmbEventoComando.serie = bDocumEst.serie-docto
       ttEmbEventoComando.nro-docto = bDocumEst.nro-docto
       ttEmbEventoComando.nat-operacao = CAPS(TRIM(bDocumEst.nat-operacao, " "))
       ttEmbEventoComando.dt-emissao = bDocumEst.dt-emissao
       ttEmbEventoComando.dados-evento = "RE1005RP fim-atualizacao; compra confirmada; linhas participantes="
                                         + STRING(iLinhas)
       ttEmbEventoComando.usuario = cUsuario.

RUN gerarEtiquetas IN THIS-PROCEDURE(
    INPUT TABLE ttEmbEventoComando,
    INPUT TABLE ttEmbGeracaoValidada,
    INPUT YES,
    OUTPUT plSucesso,
    OUTPUT plRepeticao,
    OUTPUT piIdEvento,
    OUTPUT piQtdEtiquetas,
    OUTPUT pcErro,
    OUTPUT pcMensagem).
END PROCEDURE.

PROCEDURE reverterRecebimentoCompra:
/* RE0402RP: compensa exclusivamente embalagens ainda no nascimento.
   O documento e o estoque padrao sao responsabilidade do Datasul. */
DEFINE INPUT  PARAMETER prDocumEst     AS ROWID NO-UNDO.
DEFINE INPUT  PARAMETER plAutorizado   AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plAplicavel    AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso      AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao    AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento     AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piQtdEtiquetas AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro         AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem     AS CHARACTER NO-UNDO.

DEFINE BUFFER bDocRev  FOR mgmov.docum-est.
DEFINE BUFFER bOrig    FOR mgesp.contr_emb_evento.
DEFINE BUFFER bRev     FOR mgesp.contr_emb_evento.
DEFINE BUFFER bEtiq    FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bNasc    FOR mgesp.contr_emb_movto.
DEFINE VARIABLE cChaveRev     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cConteudo     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErroNucleo   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMsgNucleo    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cSituacao     AS CHARACTER NO-UNDO.
DEFINE VARIABLE iOrig         AS INTEGER NO-UNDO.
DEFINE VARIABLE iOrigens      AS INTEGER NO-UNDO.
DEFINE VARIABLE iReversoes    AS INTEGER NO-UNDO.
DEFINE VARIABLE iSeq          AS INTEGER NO-UNDO.
DEFINE VARIABLE iIdMovto      AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersao       AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersaoEvento AS INTEGER NO-UNDO.
DEFINE VARIABLE lNucleo       AS LOGICAL NO-UNDO.
DEFINE VARIABLE lRepNucleo    AS LOGICAL NO-UNDO.
DEFINE VARIABLE dtAgora       AS DATETIME-TZ NO-UNDO.

EMPTY TEMP-TABLE ttEmbEventoComando.
EMPTY TEMP-TABLE ttEmbMovimentoComando.
ASSIGN plAplicavel = NO plSucesso = NO plRepeticao = NO
       piIdEvento = 0 piQtdEtiquetas = 0
       pcErro = "SEM_PERMISSAO" pcMensagem = "Operacao nao autorizada.".
IF plAutorizado = ? OR NOT plAutorizado THEN RETURN.
IF NOT CONNECTED("mgmov") OR NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_NAO_CONECTADO"
           pcMensagem = "Bancos necessarios nao conectados.".
    RETURN.
END.
IF prDocumEst = ? THEN DO:
    ASSIGN pcErro = "DOCUMENTO_NAO_INFORMADO"
           pcMensagem = "Informe o documento da desatualizacao confirmada.".
    RETURN.
END.
FIND FIRST bDocRev NO-LOCK WHERE ROWID(bDocRev) = prDocumEst NO-ERROR.
IF NOT AVAILABLE bDocRev THEN DO:
    ASSIGN pcErro = "DOCUMENTO_NAO_ENCONTRADO"
           pcMensagem = "Documento informado pelo EPC nao encontrado.".
    RETURN.
END.
IF CAPS(TRIM(bDocRev.nat-operacao, " ")) <> "1101IS" THEN DO:
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "Natureza nao aplicavel.".
    RETURN.
END.
ASSIGN plAplicavel = YES
       pcErro = "DOCUMENTO_AINDA_ATUALIZADO"
       pcMensagem = "A desatualizacao do estoque ainda nao foi confirmada.".
IF bDocRev.ce-atual = ? OR bDocRev.ce-atual <> NO THEN RETURN.

/* A chave canonica e a mesma da geracao; ROWID nao entra na identidade. */
FOR EACH bOrig NO-LOCK
    WHERE bOrig.tipo-evento = "RECEBIMENTO_COMPRA"
      AND bOrig.cod-estabel = bDocRev.cod-estabel
      AND bOrig.cod-emitente = bDocRev.cod-emitente
      AND bOrig.serie = bDocRev.serie-docto
      AND bOrig.nro-docto = bDocRev.nro-docto
      AND bOrig.nat-operacao = bDocRev.nat-operacao:
    ASSIGN iOrigens = iOrigens + 1 iOrig = bOrig.id-evento.
END.
IF iOrigens = 0 THEN DO:
    ASSIGN plAplicavel = NO plSucesso = YES pcErro = ""
           pcMensagem = "Documento sem geracao especifica a compensar.".
    RETURN.
END.
IF iOrigens <> 1 THEN DO:
    ASSIGN pcErro = "CICLO_ORIGEM_AMBIGUO"
           pcMensagem = "Ha mais de um recebimento gerador para o documento.".
    RETURN.
END.
FIND FIRST bOrig NO-LOCK WHERE bOrig.id-evento = iOrig NO-ERROR.
IF NOT AVAILABLE bOrig OR bOrig.situacao <> "CONCLUIDO" THEN DO:
    ASSIGN pcErro = "ORIGEM_NAO_CONCLUIDA"
           pcMensagem = "O evento gerador nao foi concluido.".
    RETURN.
END.
FOR EACH bRev NO-LOCK
    WHERE bRev.id-evento-origem = iOrig
      AND bRev.tipo-evento = "DESATUALIZACAO_COMPRA":
    ASSIGN iReversoes = iReversoes + 1 piIdEvento = bRev.id-evento.
    IF bRev.situacao <> "CONCLUIDO" THEN DO:
        ASSIGN pcErro = "REVERSAO_NAO_CONCLUIDA"
               pcMensagem = "Ja existe reversao ainda nao concluida.".
        RETURN.
    END.
END.
IF iReversoes > 1 THEN DO:
    ASSIGN pcErro = "REVERSAO_AMBIGUA"
           pcMensagem = "Ha mais de uma reversao do evento gerador.".
    RETURN.
END.
IF iReversoes = 1 THEN DO:
    ASSIGN plSucesso = YES plRepeticao = YES pcErro = "" pcMensagem = "".
    FOR EACH bEtiq NO-LOCK WHERE bEtiq.id-evento-geracao = iOrig:
        piQtdEtiquetas = piQtdEtiquetas + 1.
    END.
    RETURN.
END.
ASSIGN piIdEvento = 0
       pcErro = "ETIQUETA_COM_DEPENDENCIA"
       pcMensagem = "Uma embalagem gerada ja possui movimento posterior ou outro estado.".
FOR EACH bEtiq NO-LOCK WHERE bEtiq.id-evento-geracao = iOrig:
    IF bEtiq.tipo-controle = ? OR bEtiq.tipo-controle <> "EMBALAGEM" OR
       bEtiq.situacao = ? OR bEtiq.situacao <> "ATIVA" OR
       bEtiq.qtidade-atu = ? OR bEtiq.qtidade-ini = ? OR
       bEtiq.qtidade-atu <> bEtiq.qtidade-ini OR
       bEtiq.id-bag <> ? OR bEtiq.id-movto-ult = ? THEN RETURN.
    FIND FIRST bNasc NO-LOCK
        WHERE bNasc.id-movto = bEtiq.id-movto-ult NO-ERROR.
    IF NOT AVAILABLE bNasc OR bNasc.id-evento <> iOrig OR
       bNasc.id-etiqueta <> bEtiq.id-etiqueta OR
       bNasc.tipo-movto <> "NASCIMENTO_RECEBIMENTO" THEN RETURN.
    piQtdEtiquetas = piQtdEtiquetas + 1.
END.

ASSIGN cUsuario = IF bDocRev.usuario = ? THEN ""
                  ELSE TRIM(bDocRev.usuario, " ").
IF cUsuario = "" THEN cUsuario = USERID("mgmov").
IF cUsuario = ? OR cUsuario = "" THEN DO:
    ASSIGN pcErro = "USUARIO_NAO_IDENTIFICADO"
           pcMensagem = "Usuario da desatualizacao nao identificado.".
    RETURN.
END.
ASSIGN cChaveRev = "RE0402RP|FIM-ATUALIZACAO|ORIGEM|" + STRING(iOrig)
       cConteudo = cChaveRev + "|" + bOrig.hash-conteudo.
CREATE ttEmbEventoComando.
ASSIGN ttEmbEventoComando.origem = "RE0402RP"
       ttEmbEventoComando.chave-evento = cChaveRev
       ttEmbEventoComando.hash-chave = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cChaveRev))
       ttEmbEventoComando.hash-conteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256", cConteudo))
       ttEmbEventoComando.tipo-evento = "DESATUALIZACAO_COMPRA"
       ttEmbEventoComando.id-evento-origem = iOrig
       ttEmbEventoComando.seq-ciclo = bOrig.seq-ciclo + 1
       ttEmbEventoComando.dt-evento = NOW
       ttEmbEventoComando.versao-contrato = 1
       ttEmbEventoComando.tipo-docto = bOrig.tipo-docto
       ttEmbEventoComando.chave-docto = bOrig.chave-docto
       ttEmbEventoComando.hash-docto = bOrig.hash-docto
       ttEmbEventoComando.cod-estabel = bOrig.cod-estabel
       ttEmbEventoComando.cod-emitente = bOrig.cod-emitente
       ttEmbEventoComando.serie = bOrig.serie
       ttEmbEventoComando.nro-docto = bOrig.nro-docto
       ttEmbEventoComando.nat-operacao = bOrig.nat-operacao
       ttEmbEventoComando.dt-emissao = bOrig.dt-emissao
       ttEmbEventoComando.dados-evento = "RE0402RP; documento desatualizado; origem="
                                        + STRING(iOrig)
                                        + ";serie=" + bDocRev.serie-docto
                                        + ";documento=" + bDocRev.nro-docto
       ttEmbEventoComando.usuario = cUsuario.

reversaoTransacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    RUN registrarEvento IN THIS-PROCEDURE(
        INPUT TABLE ttEmbEventoComando, INPUT YES,
        OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT piIdEvento,
        OUTPUT cSituacao, OUTPUT iVersaoEvento,
        OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
    IF NOT lNucleo THEN DO:
        ASSIGN pcErro = cErroNucleo pcMensagem = cMsgNucleo
               piIdEvento = 0.
        UNDO reversaoTransacao, LEAVE reversaoTransacao.
    END.
    IF lRepNucleo THEN DO:
        IF cSituacao <> "CONCLUIDO" THEN DO:
            ASSIGN pcErro = "REVERSAO_NAO_CONCLUIDA"
                   pcMensagem = "A reversao idempotente ainda nao foi concluida."
                   piIdEvento = 0.
            UNDO reversaoTransacao, LEAVE reversaoTransacao.
        END.
        ASSIGN plSucesso = YES plRepeticao = YES pcErro = "" pcMensagem = "".
        LEAVE reversaoTransacao.
    END.
    ASSIGN dtAgora = NOW iSeq = 0.
    FOR EACH bEtiq NO-LOCK WHERE bEtiq.id-evento-geracao = iOrig
        BY bEtiq.id-etiqueta:
        FIND FIRST bNasc NO-LOCK
            WHERE bNasc.id-movto = bEtiq.id-movto-ult NO-ERROR.
        IF NOT AVAILABLE bNasc OR bNasc.id-evento <> iOrig OR
           bNasc.tipo-movto <> "NASCIMENTO_RECEBIMENTO" THEN DO:
            ASSIGN pcErro = "ETIQUETA_COM_DEPENDENCIA"
                   pcMensagem = "A embalagem mudou durante a reversao."
                   piIdEvento = 0.
            UNDO reversaoTransacao, LEAVE reversaoTransacao.
        END.
        ASSIGN iSeq = iSeq + 1.
        EMPTY TEMP-TABLE ttEmbMovimentoComando.
        CREATE ttEmbMovimentoComando.
        ASSIGN ttEmbMovimentoComando.id-evento = piIdEvento
               ttEmbMovimentoComando.sequencia = iSeq
               ttEmbMovimentoComando.id-etiqueta = bEtiq.id-etiqueta
               ttEmbMovimentoComando.versao-etiqueta-esperada = bEtiq.versao
               ttEmbMovimentoComando.id-item-evento = 0
               ttEmbMovimentoComando.id-item-oper = 0
               ttEmbMovimentoComando.id-movto-ant-esperado = bEtiq.id-movto-ult
               ttEmbMovimentoComando.id-bag-relac = 0
               ttEmbMovimentoComando.id-bag-destino = 0
               ttEmbMovimentoComando.id-movto-origem = bNasc.id-movto
               ttEmbMovimentoComando.tipo-movto = "CANCELAMENTO_RECEBIMENTO"
               ttEmbMovimentoComando.dt-movto = dtAgora
               ttEmbMovimentoComando.un = bEtiq.un
               ttEmbMovimentoComando.quantidade = bEtiq.qtidade-atu
               ttEmbMovimentoComando.qtidade-atu = 0
               ttEmbMovimentoComando.situacao-atu = "CANCELADA"
               ttEmbMovimentoComando.cod-estabel-dest = bEtiq.cod-estabel
               ttEmbMovimentoComando.cod-depos-dest = bEtiq.cod-depos
               ttEmbMovimentoComando.cod-localiz-dest = bEtiq.cod-localiz
               ttEmbMovimentoComando.tipo-local-dest = bEtiq.tipo-local
               ttEmbMovimentoComando.cod-emitente-dest = bEtiq.cod-emitente-posse
               ttEmbMovimentoComando.origem-local-ext-dest = bEtiq.origem-local-ext
               ttEmbMovimentoComando.cod-local-ext-dest = bEtiq.cod-local-ext
               ttEmbMovimentoComando.justificativa =
                   "Documento desatualizado no RE0402; serie=" + bDocRev.serie-docto
                   + "; documento=" + bDocRev.nro-docto
                   + "; emitente=" + STRING(bDocRev.cod-emitente) + "."
               ttEmbMovimentoComando.usuario = cUsuario.
        RUN aplicarMovimento IN THIS-PROCEDURE(
            INPUT TABLE ttEmbMovimentoComando, INPUT YES,
            OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT iIdMovto,
            OUTPUT iVersao, OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
        IF NOT lNucleo OR lRepNucleo THEN DO:
            ASSIGN pcErro = IF cErroNucleo = "" THEN "FALHA_MOVIMENTO_REVERSAO"
                            ELSE cErroNucleo
                   pcMensagem = IF cMsgNucleo = "" THEN "Movimento compensatorio nao registrado."
                                ELSE cMsgNucleo
                   piIdEvento = 0.
            UNDO reversaoTransacao, LEAVE reversaoTransacao.
        END.
    END.
    FIND FIRST bRev EXCLUSIVE-LOCK
        WHERE bRev.id-evento = piIdEvento NO-ERROR.
    IF NOT AVAILABLE bRev OR bRev.situacao <> "RECEBIDO" THEN DO:
        ASSIGN pcErro = "EVENTO_NAO_ABERTO"
               pcMensagem = "A reversao nao pode ser concluida."
               piIdEvento = 0.
        UNDO reversaoTransacao, LEAVE reversaoTransacao.
    END.
    ASSIGN bRev.situacao = "CONCLUIDO"
           bRev.dt-conclusao = dtAgora
           bRev.resultado = "ETIQUETAS=" + STRING(iSeq)
           bRev.mensagem = ""
           bRev.dt-alteracao = dtAgora
           bRev.usuario-alteracao = cUsuario
           bRev.versao = bRev.versao + 1
           plSucesso = YES plRepeticao = NO pcErro = "" pcMensagem = "".
    CATCH eReversao AS Progress.Lang.Error:
        ASSIGN plSucesso = NO plRepeticao = NO piIdEvento = 0
               pcErro = "FALHA_REVERSAO"
               pcMensagem = "Nao foi possivel concluir a reversao das embalagens.".
    END CATCH.
END.
END PROCEDURE.

PROCEDURE validarGeracao:
/* GER-02. Valida e calcula a memoria da geracao sem persistir. Conversao
   diferente de 1 depende de regra Datasul comprovada e, por isso, e recusada. */
DEFINE INPUT  PARAMETER TABLE FOR ttEmbGeracaoLinha.
DEFINE INPUT  PARAMETER plAutorizado       AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbGeracaoValidada.
DEFINE OUTPUT PARAMETER piQtdEtiquetas     AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso          AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro             AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem         AS CHARACTER NO-UNDO.

DEFINE BUFFER bParam FOR mgesp.contr_emb_param.
DEFINE BUFFER bTipo  FOR mgesp.contr_emb_bag.
DEFINE BUFFER bItem  FOR mgcad.item.
DEFINE BUFFER bEstab FOR mgcad.estabelec.
DEFINE BUFFER bGeracaoLinha FOR ttEmbGeracaoLinha.
DEFINE VARIABLE iLinhas       AS INTEGER NO-UNDO.
DEFINE VARIABLE iParametros   AS INTEGER NO-UNDO.
DEFINE VARIABLE iQtd          AS INTEGER NO-UNDO.
DEFINE VARIABLE cEstabel      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cItem         AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLote         AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUnOrigem     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCodDepos     AS CHARACTER NO-UNDO.
DEFINE VARIABLE deQuantidade  AS DECIMAL NO-UNDO.
DEFINE VARIABLE deCapacidade  AS DECIMAL NO-UNDO.
DEFINE VARIABLE deResiduo     AS DECIMAL NO-UNDO.

EMPTY TEMP-TABLE ttEmbGeracaoValidada.
ASSIGN piQtdEtiquetas = 0 plSucesso = NO pcErro = "SEM_PERMISSAO"
       pcMensagem = "Operacao nao autorizada.".
IF plAutorizado = ? OR NOT plAutorizado THEN RETURN.
IF NOT CONNECTED("mgesp") OR NOT CONNECTED("mgcad") THEN DO:
    ASSIGN pcErro = "BANCO_NAO_CONECTADO"
           pcMensagem = "Bancos necessarios para validar a geracao nao conectados.".
    RETURN.
END.

FOR EACH ttEmbGeracaoLinha:
    iLinhas = iLinhas + 1.
END.
ASSIGN pcErro = "GERACAO_SEM_ITENS"
       pcMensagem = "Informe ao menos uma ocorrencia para a geracao.".
IF iLinhas = 0 THEN RETURN.

validacao:
DO ON ERROR UNDO, THROW:
    FOR EACH ttEmbGeracaoLinha
        BY ttEmbGeracaoLinha.sequencia
        BY ttEmbGeracaoLinha.seq-lote:
        ASSIGN cEstabel = IF ttEmbGeracaoLinha.cod-estabel = ? THEN ""
                          ELSE TRIM(ttEmbGeracaoLinha.cod-estabel, " ")
               cItem = IF ttEmbGeracaoLinha.it-codigo = ? THEN ""
                       ELSE TRIM(ttEmbGeracaoLinha.it-codigo, " ")
               cLote = IF ttEmbGeracaoLinha.lote = ? THEN ""
                       ELSE TRIM(ttEmbGeracaoLinha.lote, " ")
               cUnOrigem = IF ttEmbGeracaoLinha.un-origem = ? THEN ""
                           ELSE CAPS(TRIM(ttEmbGeracaoLinha.un-origem, " "))
               cCodDepos = f-emb-opcional(ttEmbGeracaoLinha.cod-depos)
               deQuantidade = ttEmbGeracaoLinha.qt-origem.

        ASSIGN iQtd = 0.
        FOR EACH bGeracaoLinha
            WHERE bGeracaoLinha.sequencia = ttEmbGeracaoLinha.sequencia
              AND bGeracaoLinha.seq-lote = ttEmbGeracaoLinha.seq-lote:
            iQtd = iQtd + 1.
        END.
        ASSIGN pcErro = "OCORRENCIA_REPETIDA"
               pcMensagem = "A mesma sequencia e lote foi informada mais de uma vez.".
        IF iQtd > 1 THEN LEAVE validacao.

        ASSIGN pcErro = "OCORRENCIA_INVALIDA"
               pcMensagem = "Linha, lote, estabelecimento, item, quantidade, unidade, lote e validade sao obrigatorios.".
        IF ttEmbGeracaoLinha.sequencia = ? OR ttEmbGeracaoLinha.sequencia <= 0 OR
           ttEmbGeracaoLinha.seq-lote = ? OR ttEmbGeracaoLinha.seq-lote <= 0 OR
           cEstabel = "" OR cItem = "" OR cLote = "" OR
           ttEmbGeracaoLinha.dt-vali-lote = ? OR deQuantidade = ? OR
           deQuantidade <= 0 OR cUnOrigem = "" THEN LEAVE validacao.
        IF LENGTH(cEstabel, "CHARACTER") > 5 OR LENGTH(cItem, "CHARACTER") > 16 OR
           LENGTH(cLote, "CHARACTER") > 40 OR LENGTH(cUnOrigem, "CHARACTER") > 12 OR
           (cCodDepos <> ? AND LENGTH(cCodDepos, "CHARACTER") > 3) OR
           (ttEmbGeracaoLinha.cod-item-origem <> ? AND
            LENGTH(ttEmbGeracaoLinha.cod-item-origem, "CHARACTER") > 80) THEN LEAVE validacao.

        ASSIGN pcErro = "PRECISAO_INVALIDA"
               pcMensagem = "A quantidade recebida aceita no maximo quatro casas decimais.".
        IF ROUND(deQuantidade, 4) <> deQuantidade THEN LEAVE validacao.

        ASSIGN pcErro = "ESTABELECIMENTO_NAO_ENCONTRADO"
               pcMensagem = "O estabelecimento informado nao foi encontrado.".
        FIND FIRST bEstab NO-LOCK WHERE bEstab.cod-estabel = cEstabel NO-ERROR.
        IF NOT AVAILABLE bEstab THEN LEAVE validacao.
        ASSIGN pcErro = "ITEM_NAO_ENCONTRADO"
               pcMensagem = "O item informado nao foi encontrado.".
        FIND FIRST bItem NO-LOCK WHERE bItem.it-codigo = cItem NO-ERROR.
        IF NOT AVAILABLE bItem THEN LEAVE validacao.

        ASSIGN iParametros = 0.
        FOR EACH bParam NO-LOCK
            WHERE bParam.cod-estabel = cEstabel
              AND bParam.it-codigo = cItem
              AND bParam.ativo:
            iParametros = iParametros + 1.
        END.
        ASSIGN pcErro = "PARAMETRIZACAO_AMBIGUA"
               pcMensagem = "Existe mais de uma parametrizacao ativa para o item e estabelecimento.".
        IF iParametros > 1 THEN LEAVE validacao.

        CREATE ttEmbGeracaoValidada.
        ASSIGN ttEmbGeracaoValidada.sequencia = ttEmbGeracaoLinha.sequencia
               ttEmbGeracaoValidada.seq-lote = ttEmbGeracaoLinha.seq-lote
               ttEmbGeracaoValidada.cod-estabel = cEstabel
               ttEmbGeracaoValidada.it-codigo = cItem
               ttEmbGeracaoValidada.cod-item-origem = f-emb-opcional(ttEmbGeracaoLinha.cod-item-origem)
               ttEmbGeracaoValidada.lote = cLote
               ttEmbGeracaoValidada.dt-vali-lote = ttEmbGeracaoLinha.dt-vali-lote
               ttEmbGeracaoValidada.qt-origem = deQuantidade
               ttEmbGeracaoValidada.un-origem = cUnOrigem
               ttEmbGeracaoValidada.cod-depos = cCodDepos.

        IF iParametros = 0 THEN DO:
            ASSIGN ttEmbGeracaoValidada.fator-conversao = 1
                   ttEmbGeracaoValidada.quantidade = deQuantidade
                   ttEmbGeracaoValidada.un = CAPS(TRIM(bItem.un, " "))
                   ttEmbGeracaoValidada.qtd-etiquetas = 0
                   ttEmbGeracaoValidada.qt-residuo = deQuantidade
                   ttEmbGeracaoValidada.situacao-item = "IGNORADO"
                   ttEmbGeracaoValidada.mensagem = "Item sem parametrizacao ativa no estabelecimento.".
            NEXT.
        END.

        FIND FIRST bParam NO-LOCK
            WHERE bParam.cod-estabel = cEstabel
              AND bParam.it-codigo = cItem
              AND bParam.ativo NO-ERROR.
        ASSIGN pcErro = "ITEM_NAO_CONTROLADO_LOTE"
               pcMensagem = "O item participante ainda nao esta controlado por lote.".
        IF bItem.tipo-con-est <> 3 THEN LEAVE validacao.
        ASSIGN pcErro = "PARAMETRIZACAO_INVALIDA"
               pcMensagem = "Tipo, capacidade e unidade da parametrizacao ativa devem ser validos.".
        IF bParam.cod-tipo = ? OR TRIM(bParam.cod-tipo, " ") = "" OR
           bParam.capacidade-emb = ? OR bParam.capacidade-emb <= 0 OR
           bParam.un = ? OR TRIM(bParam.un, " ") = "" OR
           ROUND(bParam.capacidade-emb, 4) <> bParam.capacidade-emb THEN LEAVE validacao.
        FIND FIRST bTipo NO-LOCK WHERE bTipo.cod-tipo = bParam.cod-tipo NO-ERROR.
        IF NOT AVAILABLE bTipo OR NOT bTipo.ativo THEN DO:
            ASSIGN pcErro = "TIPO_EMBALAGEM_INATIVO"
                   pcMensagem = "O tipo de embalagem parametrizado nao esta ativo.".
            LEAVE validacao.
        END.
        ASSIGN pcErro = "UNIDADE_PARAMETRIZACAO_DIVERGENTE"
               pcMensagem = "A unidade parametrizada difere da unidade de estoque do item.".
        IF CAPS(TRIM(bParam.un, " ")) <> CAPS(TRIM(bItem.un, " ")) THEN LEAVE validacao.
        ASSIGN pcErro = "CONVERSAO_UNIDADE_NAO_COMPROVADA"
               pcMensagem = "A unidade recebida difere da unidade parametrizada; a conversao Datasul ainda nao foi comprovada.".
        IF cUnOrigem <> CAPS(TRIM(bParam.un, " ")) THEN LEAVE validacao.

        ASSIGN deCapacidade = bParam.capacidade-emb
               iQtd = INTEGER(TRUNCATE(deQuantidade / deCapacidade, 0))
               deResiduo = ROUND(deQuantidade - (iQtd * deCapacidade), 4).
        ASSIGN pcErro = "CALCULO_INVALIDO"
               pcMensagem = "O calculo da geracao nao preservou quantidade, capacidade e residuo.".
        IF iQtd < 0 OR deResiduo < 0 OR deResiduo >= deCapacidade OR
           ROUND((iQtd * deCapacidade) + deResiduo, 4) <> deQuantidade THEN LEAVE validacao.

        ASSIGN ttEmbGeracaoValidada.fator-conversao = 1
               ttEmbGeracaoValidada.quantidade = deQuantidade
               ttEmbGeracaoValidada.un = CAPS(TRIM(bParam.un, " "))
               ttEmbGeracaoValidada.id-param-origem = bParam.id-param
               ttEmbGeracaoValidada.versao-param = bParam.versao
               ttEmbGeracaoValidada.cod-tipo = bParam.cod-tipo
               ttEmbGeracaoValidada.capacidade-emb = deCapacidade
               ttEmbGeracaoValidada.qtd-etiquetas = iQtd
               ttEmbGeracaoValidada.qt-residuo = deResiduo
               ttEmbGeracaoValidada.situacao-item = "VALIDADO"
               ttEmbGeracaoValidada.mensagem = ""
               piQtdEtiquetas = piQtdEtiquetas + iQtd.
    END.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    CATCH eValidacao AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbGeracaoValidada.
        ASSIGN piQtdEtiquetas = 0 plSucesso = NO pcErro = "FALHA_VALIDACAO_GERACAO"
               pcMensagem = "Nao foi possivel validar a geracao.".
    END CATCH.
END.
IF NOT plSucesso THEN DO:
    EMPTY TEMP-TABLE ttEmbGeracaoValidada.
    piQtdEtiquetas = 0.
END.
END PROCEDURE.

PROCEDURE gerarEtiquetas:
/* GER-03. Persiste a geracao previamente validada e reutiliza integralmente
   registrarEvento/aplicarMovimento. Nao altera estoque padrao do Datasul. */
DEFINE INPUT  PARAMETER TABLE FOR ttEmbEventoComando.
DEFINE INPUT  PARAMETER TABLE FOR ttEmbGeracaoValidada.
DEFINE INPUT  PARAMETER plAutorizado       AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso          AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao        AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento         AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER piQtdEtiquetas     AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro             AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem         AS CHARACTER NO-UNDO.

DEFINE BUFFER bEvento     FOR mgesp.contr_emb_evento.
DEFINE BUFFER bEventoItem FOR mgesp.contr_emb_evento_item.
DEFINE BUFFER bEtiqueta   FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bParamGer   FOR mgesp.contr_emb_param.
DEFINE VARIABLE lNucleo        AS LOGICAL NO-UNDO.
DEFINE VARIABLE lRepNucleo     AS LOGICAL NO-UNDO.
DEFINE VARIABLE iVersaoEvento  AS INTEGER NO-UNDO.
DEFINE VARIABLE iVersaoEtiq    AS INTEGER NO-UNDO.
DEFINE VARIABLE iIdItemEvento  AS INTEGER NO-UNDO.
DEFINE VARIABLE iIdEtiqueta    AS INTEGER NO-UNDO.
DEFINE VARIABLE iIdMovto       AS INTEGER NO-UNDO.
DEFINE VARIABLE iSeqMovto      AS INTEGER NO-UNDO.
DEFINE VARIABLE iSeqGeracao    AS INTEGER NO-UNDO.
DEFINE VARIABLE iComandos      AS INTEGER NO-UNDO.
DEFINE VARIABLE iLinhas        AS INTEGER NO-UNDO.
DEFINE VARIABLE i              AS INTEGER NO-UNDO.
DEFINE VARIABLE cSituacao      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cErroNucleo    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMsgNucleo     AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUsuario       AS CHARACTER NO-UNDO.
DEFINE VARIABLE dtAgora        AS DATETIME-TZ NO-UNDO.

ASSIGN plSucesso = NO plRepeticao = NO piIdEvento = 0 piQtdEtiquetas = 0
       pcErro = "SEM_PERMISSAO" pcMensagem = "Operacao nao autorizada.".
IF plAutorizado = ? OR NOT plAutorizado THEN RETURN.
IF NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_MGESP_NAO_CONECTADO"
           pcMensagem = "Banco especifico nao conectado.".
    RETURN.
END.
FOR EACH ttEmbEventoComando:
    iComandos = iComandos + 1.
    cUsuario = IF ttEmbEventoComando.usuario = ? THEN ""
               ELSE TRIM(ttEmbEventoComando.usuario, " ").
END.
FOR EACH ttEmbGeracaoValidada:
    iLinhas = iLinhas + 1.
END.
ASSIGN pcErro = "GERACAO_NAO_VALIDADA"
       pcMensagem = "Informe um evento e ao menos uma ocorrencia previamente validada.".
IF iComandos <> 1 OR iLinhas = 0 OR cUsuario = "" THEN RETURN.
FIND FIRST ttEmbEventoComando NO-ERROR.
IF NOT AVAILABLE ttEmbEventoComando OR ttEmbEventoComando.cod-estabel = ? OR
   TRIM(ttEmbEventoComando.cod-estabel, " ") = "" THEN RETURN.
FOR EACH ttEmbGeracaoValidada:
    IF ttEmbGeracaoValidada.cod-estabel <> TRIM(ttEmbEventoComando.cod-estabel, " ") OR
       LOOKUP(ttEmbGeracaoValidada.situacao-item, "VALIDADO,IGNORADO") = 0 OR
       ttEmbGeracaoValidada.quantidade = ? OR ttEmbGeracaoValidada.quantidade <= 0 OR
       ttEmbGeracaoValidada.qtd-etiquetas = ? OR ttEmbGeracaoValidada.qtd-etiquetas < 0 OR
       ttEmbGeracaoValidada.qt-residuo = ? OR ttEmbGeracaoValidada.qt-residuo < 0 THEN RETURN.
    IF ttEmbGeracaoValidada.situacao-item = "VALIDADO" THEN DO:
        IF ttEmbGeracaoValidada.id-param-origem = ? OR ttEmbGeracaoValidada.id-param-origem <= 0 OR
           ttEmbGeracaoValidada.versao-param = ? OR ttEmbGeracaoValidada.versao-param <= 0 OR
           ttEmbGeracaoValidada.cod-tipo = ? OR ttEmbGeracaoValidada.capacidade-emb = ? OR
           ttEmbGeracaoValidada.capacidade-emb <= 0 OR
           ROUND((ttEmbGeracaoValidada.qtd-etiquetas * ttEmbGeracaoValidada.capacidade-emb) +
                 ttEmbGeracaoValidada.qt-residuo, 4) <> ttEmbGeracaoValidada.quantidade THEN RETURN.
        piQtdEtiquetas = piQtdEtiquetas + ttEmbGeracaoValidada.qtd-etiquetas.
    END.
    ELSE IF ttEmbGeracaoValidada.qtd-etiquetas <> 0 THEN RETURN.
END.

gerarTransacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    /* A memoria nao pode atravessar uma alteracao do parametro vigente. */
    FOR EACH ttEmbGeracaoValidada:
        IF ttEmbGeracaoValidada.situacao-item = "VALIDADO" THEN DO:
            FIND FIRST bParamGer EXCLUSIVE-LOCK
                WHERE bParamGer.id-param = ttEmbGeracaoValidada.id-param-origem NO-ERROR.
            IF NOT AVAILABLE bParamGer OR NOT bParamGer.ativo OR
               bParamGer.versao <> ttEmbGeracaoValidada.versao-param OR
               bParamGer.cod-estabel <> ttEmbGeracaoValidada.cod-estabel OR
               bParamGer.it-codigo <> ttEmbGeracaoValidada.it-codigo OR
               bParamGer.cod-tipo <> ttEmbGeracaoValidada.cod-tipo OR
               bParamGer.capacidade-emb <> ttEmbGeracaoValidada.capacidade-emb OR
               CAPS(TRIM(bParamGer.un, " ")) <> ttEmbGeracaoValidada.un THEN DO:
                ASSIGN pcErro = "PARAMETRO_ALTERADO"
                       pcMensagem = "A parametrizacao mudou depois da validacao da geracao."
                       piQtdEtiquetas = 0.
                UNDO gerarTransacao, LEAVE gerarTransacao.
            END.
        END.
        ELSE IF CAN-FIND(FIRST bParamGer NO-LOCK
            WHERE bParamGer.cod-estabel = ttEmbGeracaoValidada.cod-estabel
              AND bParamGer.it-codigo = ttEmbGeracaoValidada.it-codigo
              AND bParamGer.ativo) THEN DO:
            ASSIGN pcErro = "PARAMETRO_ALTERADO"
                   pcMensagem = "O item passou a participar depois da validacao da geracao."
                   piQtdEtiquetas = 0.
            UNDO gerarTransacao, LEAVE gerarTransacao.
        END.
    END.

    RUN registrarEvento IN THIS-PROCEDURE(INPUT TABLE ttEmbEventoComando, INPUT YES,
        OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT piIdEvento,
        OUTPUT cSituacao, OUTPUT iVersaoEvento, OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
    IF NOT lNucleo THEN DO:
        ASSIGN pcErro = cErroNucleo pcMensagem = cMsgNucleo piQtdEtiquetas = 0.
        UNDO gerarTransacao, LEAVE gerarTransacao.
    END.

    IF lRepNucleo THEN DO:
        FIND FIRST bEvento NO-LOCK WHERE bEvento.id-evento = piIdEvento NO-ERROR.
        IF NOT AVAILABLE bEvento OR bEvento.situacao <> "CONCLUIDO" THEN DO:
            ASSIGN pcErro = "EVENTO_EM_PROCESSAMENTO"
                   pcMensagem = "O evento idempotente existe, mas a geracao ainda nao foi concluida."
                   piQtdEtiquetas = 0.
            UNDO gerarTransacao, LEAVE gerarTransacao.
        END.
        ASSIGN i = 0.
        FOR EACH bEventoItem NO-LOCK WHERE bEventoItem.id-evento = piIdEvento:
            i = i + 1.
            FIND FIRST ttEmbGeracaoValidada
                WHERE ttEmbGeracaoValidada.sequencia = bEventoItem.sequencia
                  AND ttEmbGeracaoValidada.seq-lote = bEventoItem.seq-lote NO-ERROR.
            IF NOT AVAILABLE ttEmbGeracaoValidada OR
               NOT f-emb-char-igual(bEventoItem.it-codigo, ttEmbGeracaoValidada.it-codigo) OR
               NOT f-emb-char-igual(bEventoItem.lote, ttEmbGeracaoValidada.lote) OR
               NOT f-emb-date-igual(bEventoItem.dt-vali-lote, ttEmbGeracaoValidada.dt-vali-lote) OR
               NOT f-emb-dec-igual(bEventoItem.quantidade, ttEmbGeracaoValidada.quantidade) OR
               bEventoItem.qtd-etiquetas <> ttEmbGeracaoValidada.qtd-etiquetas THEN DO:
                ASSIGN pcErro = "CONFLITO_IDEMPOTENCIA"
                       pcMensagem = "O evento concluido possui outro calculo de geracao."
                       piQtdEtiquetas = 0.
                UNDO gerarTransacao, LEAVE gerarTransacao.
            END.
        END.
        IF i <> iLinhas THEN DO:
            ASSIGN pcErro = "CONFLITO_IDEMPOTENCIA"
                   pcMensagem = "O evento concluido possui outra quantidade de ocorrencias."
                   piQtdEtiquetas = 0.
            UNDO gerarTransacao, LEAVE gerarTransacao.
        END.
        ASSIGN plSucesso = YES plRepeticao = YES pcErro = "" pcMensagem = "".
        LEAVE gerarTransacao.
    END.

    ASSIGN dtAgora = NOW iSeqMovto = 0 iSeqGeracao = 0.
    FOR EACH ttEmbGeracaoValidada
        BY ttEmbGeracaoValidada.sequencia
        BY ttEmbGeracaoValidada.seq-lote:
        ASSIGN iIdItemEvento = NEXT-VALUE(CONTR_EMB_EVENTO_ITEM_SEQ, mgesp).
        CREATE bEventoItem.
        ASSIGN bEventoItem.id-item-evento = iIdItemEvento
               bEventoItem.id-evento = piIdEvento
               bEventoItem.sequencia = ttEmbGeracaoValidada.sequencia
               bEventoItem.seq-lote = ttEmbGeracaoValidada.seq-lote
               bEventoItem.it-codigo = ttEmbGeracaoValidada.it-codigo
               bEventoItem.cod-item-origem = ttEmbGeracaoValidada.cod-item-origem
               bEventoItem.lote = ttEmbGeracaoValidada.lote
               bEventoItem.dt-vali-lote = ttEmbGeracaoValidada.dt-vali-lote
               bEventoItem.qt-origem = ttEmbGeracaoValidada.qt-origem
               bEventoItem.un-origem = ttEmbGeracaoValidada.un-origem
               bEventoItem.fator-conversao = ttEmbGeracaoValidada.fator-conversao
               bEventoItem.quantidade = ttEmbGeracaoValidada.quantidade
               bEventoItem.un = ttEmbGeracaoValidada.un
               bEventoItem.cod-depos = ttEmbGeracaoValidada.cod-depos
               bEventoItem.id-param-origem = ttEmbGeracaoValidada.id-param-origem
               bEventoItem.versao-param = ttEmbGeracaoValidada.versao-param
               bEventoItem.cod-tipo = ttEmbGeracaoValidada.cod-tipo
               bEventoItem.capacidade-emb = ttEmbGeracaoValidada.capacidade-emb
               bEventoItem.qtd-etiquetas = ttEmbGeracaoValidada.qtd-etiquetas
               bEventoItem.qt-residuo = ttEmbGeracaoValidada.qt-residuo
               bEventoItem.situacao-item = IF ttEmbGeracaoValidada.situacao-item = "VALIDADO"
                                            THEN "PROCESSADO" ELSE "IGNORADO"
               bEventoItem.mensagem = ttEmbGeracaoValidada.mensagem
               bEventoItem.dt-inclusao = dtAgora
               bEventoItem.usuario-inclusao = cUsuario
               bEventoItem.dt-alteracao = dtAgora
               bEventoItem.usuario-alteracao = cUsuario
               bEventoItem.versao = 1.
        RELEASE bEventoItem.

        DO i = 1 TO ttEmbGeracaoValidada.qtd-etiquetas:
            ASSIGN iIdEtiqueta = NEXT-VALUE(CONTR_EMB_ETIQUETA_SEQ, mgesp)
                   iSeqGeracao = iSeqGeracao + 1
                   iSeqMovto = iSeqMovto + 1.
            CREATE bEtiqueta.
            ASSIGN bEtiqueta.id-etiqueta = iIdEtiqueta
                   bEtiqueta.cod-etiqueta = TRIM(STRING(iIdEtiqueta, "9999999999"), " ")
                   bEtiqueta.tipo-controle = "EMBALAGEM"
                   bEtiqueta.id-pre-origem = ?
                   bEtiqueta.id-evento-geracao = piIdEvento
                   bEtiqueta.id-item-evento = iIdItemEvento
                   bEtiqueta.seq-geracao = iSeqGeracao
                   bEtiqueta.it-codigo = ttEmbGeracaoValidada.it-codigo
                   bEtiqueta.cod-tipo = ttEmbGeracaoValidada.cod-tipo
                   bEtiqueta.lote = ttEmbGeracaoValidada.lote
                   bEtiqueta.dt-vali-lote = ttEmbGeracaoValidada.dt-vali-lote
                   bEtiqueta.un = ttEmbGeracaoValidada.un
                   bEtiqueta.capacidade-emb = ttEmbGeracaoValidada.capacidade-emb
                   bEtiqueta.qtidade-ini = ttEmbGeracaoValidada.capacidade-emb
                   bEtiqueta.qtidade-atu = ttEmbGeracaoValidada.capacidade-emb
                   bEtiqueta.cod-estabel = ttEmbGeracaoValidada.cod-estabel
                   bEtiqueta.cod-depos = ttEmbGeracaoValidada.cod-depos
                   bEtiqueta.cod-localiz = ""
                   bEtiqueta.tipo-local = "ESTAB"
                   bEtiqueta.cod-emitente-posse = ?
                   bEtiqueta.origem-local-ext = ?
                   bEtiqueta.cod-local-ext = ?
                   bEtiqueta.id-bag = ?
                   bEtiqueta.situacao = "ATIVA"
                   bEtiqueta.id-movto-ult = ?
                   bEtiqueta.dt-inclusao = dtAgora
                   bEtiqueta.usuario-inclusao = cUsuario
                   bEtiqueta.dt-alteracao = dtAgora
                   bEtiqueta.usuario-alteracao = cUsuario
                   bEtiqueta.versao = 1.
            RELEASE bEtiqueta.

            EMPTY TEMP-TABLE ttEmbMovimentoComando.
            CREATE ttEmbMovimentoComando.
            ASSIGN ttEmbMovimentoComando.id-evento = piIdEvento
                   ttEmbMovimentoComando.sequencia = iSeqMovto
                   ttEmbMovimentoComando.id-etiqueta = iIdEtiqueta
                   ttEmbMovimentoComando.versao-etiqueta-esperada = 1
                   ttEmbMovimentoComando.id-item-evento = iIdItemEvento
                   ttEmbMovimentoComando.id-item-oper = 0
                   ttEmbMovimentoComando.id-movto-ant-esperado = 0
                   ttEmbMovimentoComando.id-bag-relac = 0
                   ttEmbMovimentoComando.id-bag-destino = 0
                   ttEmbMovimentoComando.id-movto-origem = 0
                   ttEmbMovimentoComando.tipo-movto = "NASCIMENTO_RECEBIMENTO"
                   ttEmbMovimentoComando.dt-movto = dtAgora
                   ttEmbMovimentoComando.un = ttEmbGeracaoValidada.un
                   ttEmbMovimentoComando.quantidade = ttEmbGeracaoValidada.capacidade-emb
                   ttEmbMovimentoComando.qtidade-atu = ttEmbGeracaoValidada.capacidade-emb
                   ttEmbMovimentoComando.situacao-atu = "ATIVA"
                   ttEmbMovimentoComando.cod-estabel-dest = ttEmbGeracaoValidada.cod-estabel
                   ttEmbMovimentoComando.cod-depos-dest = ttEmbGeracaoValidada.cod-depos
                   ttEmbMovimentoComando.tipo-local-dest = "ESTAB"
                   ttEmbMovimentoComando.cod-emitente-dest = 0
                   ttEmbMovimentoComando.usuario = cUsuario.
            RUN aplicarMovimento IN THIS-PROCEDURE(INPUT TABLE ttEmbMovimentoComando, INPUT YES,
                OUTPUT lNucleo, OUTPUT lRepNucleo, OUTPUT iIdMovto,
                OUTPUT iVersaoEtiq, OUTPUT cErroNucleo, OUTPUT cMsgNucleo).
            IF NOT lNucleo OR lRepNucleo THEN DO:
                ASSIGN pcErro = IF cErroNucleo = "" THEN "FALHA_MOVIMENTO_INICIAL" ELSE cErroNucleo
                       pcMensagem = IF cMsgNucleo = "" THEN "Nao foi possivel aplicar o primeiro movimento." ELSE cMsgNucleo
                       piQtdEtiquetas = 0 piIdEvento = 0.
                UNDO gerarTransacao, LEAVE gerarTransacao.
            END.
        END.
    END.

    FIND FIRST bEvento EXCLUSIVE-LOCK WHERE bEvento.id-evento = piIdEvento NO-ERROR.
    IF NOT AVAILABLE bEvento OR bEvento.situacao <> "RECEBIDO" THEN DO:
        ASSIGN pcErro = "EVENTO_NAO_ABERTO"
               pcMensagem = "O evento nao pode ser concluido pela geracao."
               piQtdEtiquetas = 0 piIdEvento = 0.
        UNDO gerarTransacao, LEAVE gerarTransacao.
    END.
    ASSIGN bEvento.situacao = "CONCLUIDO"
           bEvento.dt-conclusao = dtAgora
           bEvento.resultado = "ITENS=" + STRING(iLinhas) + ";ETIQUETAS=" + STRING(piQtdEtiquetas)
           bEvento.mensagem = ""
           bEvento.dt-alteracao = dtAgora
           bEvento.usuario-alteracao = cUsuario
           bEvento.versao = bEvento.versao + 1
           plSucesso = YES plRepeticao = NO pcErro = "" pcMensagem = "".
    CATCH eGeracao AS Progress.Lang.Error:
        ASSIGN plSucesso = NO plRepeticao = NO piIdEvento = 0 piQtdEtiquetas = 0
               pcErro = "FALHA_GERACAO"
               pcMensagem = "Nao foi possivel concluir a geracao.".
    END CATCH.
END.
END PROCEDURE.

PROCEDURE consultarEtiquetas:
    DEFINE INPUT  PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT  PARAMETER pcCodEstabel   AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcCodEtiqueta  AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcItem         AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcLote         AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcCodTipo      AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcTipoControle AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcTipoLocal    AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER pcSituacao     AS CHARACTER NO-UNDO.
    DEFINE INPUT  PARAMETER piIdBag        AS INTEGER   NO-UNDO.
    DEFINE INPUT  PARAMETER piAposId       AS INTEGER   NO-UNDO.
    DEFINE INPUT  PARAMETER piLimite       AS INTEGER   NO-UNDO.
    DEFINE OUTPUT PARAMETER TABLE FOR ttEmbEtiqueta.
    DEFINE OUTPUT PARAMETER plTemMais      AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER piProximoId    AS INTEGER   NO-UNDO.
    DEFINE OUTPUT PARAMETER plSucesso      AS LOGICAL   NO-UNDO.
    DEFINE OUTPUT PARAMETER pcErro         AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER pcMensagem     AS CHARACTER NO-UNDO.

    DEFINE BUFFER bEtiqueta FOR contr_emb_etiqueta.
    DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
    DEFINE VARIABLE iUltimo     AS INTEGER NO-UNDO.

    EMPTY TEMP-TABLE ttEmbEtiqueta.
    ASSIGN plTemMais   = NO
           piProximoId = 0
           plSucesso   = NO
           pcErro      = "SEM_PERMISSAO"
           pcMensagem  = "Consulta nao autorizada.".

    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN RETURN.
    FOR EACH ttEmbEstabelPermitido:
        IF ttEmbEstabelPermitido.cod-estabel = ? OR
           TRIM(ttEmbEstabelPermitido.cod-estabel) = "" THEN RETURN.
    END.

    ASSIGN pcErro         = "FILTRO_INVALIDO"
           pcMensagem     = "Confira os filtros informados."
           pcCodEstabel   = IF pcCodEstabel = ? THEN ? ELSE TRIM(pcCodEstabel, " ")
           pcCodEtiqueta  = IF pcCodEtiqueta = ? THEN ? ELSE TRIM(pcCodEtiqueta, " ")
           pcItem         = IF pcItem = ? THEN ? ELSE TRIM(pcItem, " ")
           pcLote         = IF pcLote = ? THEN ? ELSE TRIM(pcLote, " ")
           pcCodTipo      = IF pcCodTipo = ? THEN ? ELSE CAPS(TRIM(pcCodTipo, " "))
           pcTipoControle = IF pcTipoControle = ? THEN ? ELSE CAPS(TRIM(pcTipoControle, " "))
           pcTipoLocal    = IF pcTipoLocal = ? THEN ? ELSE CAPS(TRIM(pcTipoLocal, " "))
           pcSituacao     = IF pcSituacao = ? THEN ? ELSE CAPS(TRIM(pcSituacao, " ")).

    IF pcCodEstabel = ? OR pcCodEtiqueta = ? OR pcItem = ? OR pcLote = ? OR
       pcCodTipo = ? OR pcTipoControle = ? OR pcTipoLocal = ? OR
       pcSituacao = ? OR piIdBag = ? OR piAposId = ? OR piLimite = ? THEN RETURN.
    IF piIdBag < 0 OR piAposId < 0 THEN RETURN.
    IF LENGTH(pcCodEtiqueta, "CHARACTER") > 24 OR
       LENGTH(pcCodTipo, "CHARACTER") > 3 THEN RETURN.
    IF pcTipoControle <> "" AND
       LOOKUP(pcTipoControle, "EMBALAGEM,PRE_SALDO") = 0 THEN RETURN.
    IF pcTipoLocal <> "" AND
       LOOKUP(pcTipoLocal, "ESTAB,CAMPO,TERCEIRO,TRANSITO") = 0 THEN RETURN.
    IF pcSituacao <> "" AND
       LOOKUP(pcSituacao, "ATIVA,ENCERRADA,CANCELADA,DESCARTADA") = 0 THEN RETURN.
    IF pcCodEstabel <> "" AND NOT CAN-FIND(FIRST ttEmbEstabelPermitido
        WHERE ttEmbEstabelPermitido.cod-estabel = pcCodEstabel) THEN DO:
        ASSIGN pcErro = "SEM_PERMISSAO"
               pcMensagem = "O usuario nao possui acesso ao estabelecimento informado.".
        RETURN.
    END.

    ASSIGN pcErro = "LIMITE_INVALIDO"
           pcMensagem = "Informe um limite entre 1 e 100; zero usa 20.".
    IF piLimite = 0 THEN piLimite = 20.
    IF piLimite < 1 OR piLimite > 100 THEN RETURN.

    DO ON ERROR UNDO, THROW:
        FOR EACH bEtiqueta NO-LOCK
            WHERE bEtiqueta.id-etiqueta > piAposId
              AND (pcCodEstabel = "" OR bEtiqueta.cod-estabel = pcCodEstabel)
              AND (pcCodEtiqueta = "" OR bEtiqueta.cod-etiqueta = pcCodEtiqueta)
              AND (pcItem = "" OR bEtiqueta.it-codigo = pcItem)
              AND (pcLote = "" OR bEtiqueta.lote = pcLote)
              AND (pcCodTipo = "" OR bEtiqueta.cod-tipo = pcCodTipo)
              AND (pcTipoControle = "" OR bEtiqueta.tipo-controle = pcTipoControle)
              AND (pcTipoLocal = "" OR bEtiqueta.tipo-local = pcTipoLocal)
              AND (pcSituacao = "" OR bEtiqueta.situacao = pcSituacao)
              AND (piIdBag = 0 OR bEtiqueta.id-bag = piIdBag)
            BY bEtiqueta.id-etiqueta:

            IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
                WHERE ttEmbEstabelPermitido.cod-estabel = bEtiqueta.cod-estabel) THEN NEXT.
            IF iQuantidade = piLimite THEN DO:
                ASSIGN plTemMais = YES
                       piProximoId = iUltimo.
                LEAVE.
            END.

            CREATE ttEmbEtiqueta.
            BUFFER-COPY bEtiqueta TO ttEmbEtiqueta.
            ASSIGN iQuantidade = iQuantidade + 1
                   iUltimo = bEtiqueta.id-etiqueta.
        END.
        ASSIGN plSucesso = YES
               pcErro = ""
               pcMensagem = "".

        CATCH oErro AS Progress.Lang.Error:
            EMPTY TEMP-TABLE ttEmbEtiqueta.
            ASSIGN plTemMais = NO
                   piProximoId = 0
                   plSucesso = NO
                   pcErro = "FALHA_CONSULTA"
                   pcMensagem = "Nao foi possivel concluir a consulta de etiquetas.".
            UNDO, THROW oErro.
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE consultarGeracao:
/* GER-04: consulta somente leitura de um evento de geracao confirmado ou em
   diagnostico. A pagina percorre somente as embalagens nascidas no evento. */
DEFINE INPUT  PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT  PARAMETER piIdEvento  AS INTEGER NO-UNDO.
DEFINE INPUT  PARAMETER piAposId    AS INTEGER NO-UNDO.
DEFINE INPUT  PARAMETER piLimite    AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbGeracao.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbGeracaoItem.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbEtiquetaGerada.
DEFINE OUTPUT PARAMETER plTemMais   AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piProximoId AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso   AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro      AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem  AS CHARACTER NO-UNDO.

DEFINE BUFFER bEvento       FOR mgesp.contr_emb_evento.
DEFINE BUFFER bEventoItem   FOR mgesp.contr_emb_evento_item.
DEFINE BUFFER bGerada       FOR mgesp.contr_emb_etiqueta.
DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
DEFINE VARIABLE iUltimo     AS INTEGER NO-UNDO.

EMPTY TEMP-TABLE ttEmbGeracao.
EMPTY TEMP-TABLE ttEmbGeracaoItem.
EMPTY TEMP-TABLE ttEmbEtiquetaGerada.
ASSIGN plTemMais   = NO
       piProximoId = 0
       plSucesso   = NO
       pcErro      = "SEM_PERMISSAO"
       pcMensagem  = "Consulta nao autorizada.".

IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN RETURN.
FOR EACH ttEmbEstabelPermitido:
    IF ttEmbEstabelPermitido.cod-estabel = ? OR
       TRIM(ttEmbEstabelPermitido.cod-estabel) = "" THEN RETURN.
END.

ASSIGN pcErro = "FILTRO_INVALIDO"
       pcMensagem = "Informe um evento, cursor e limite validos.".
IF piIdEvento = ? OR piIdEvento <= 0 OR
   piAposId = ? OR piAposId < 0 OR piLimite = ? THEN RETURN.

ASSIGN pcErro = "LIMITE_INVALIDO"
       pcMensagem = "Informe um limite entre 1 e 100; zero usa 20.".
IF piLimite = 0 THEN piLimite = 20.
IF piLimite < 1 OR piLimite > 100 THEN RETURN.

IF NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_MGESP_NAO_CONECTADO"
           pcMensagem = "Banco especifico nao conectado.".
    RETURN.
END.

DO ON ERROR UNDO, THROW:
    ASSIGN pcErro = "GERACAO_NAO_DISPONIVEL"
           pcMensagem = "Geracao nao disponivel para consulta.".
    FIND FIRST bEvento NO-LOCK
        WHERE bEvento.id-evento = piIdEvento NO-ERROR.
    IF NOT AVAILABLE bEvento THEN RETURN.
    IF bEvento.cod-estabel = ? OR
       NOT CAN-FIND(FIRST ttEmbEstabelPermitido
           WHERE ttEmbEstabelPermitido.cod-estabel = bEvento.cod-estabel) THEN RETURN.

    CREATE ttEmbGeracao.
    BUFFER-COPY bEvento TO ttEmbGeracao.

    FOR EACH bEventoItem NO-LOCK
        WHERE bEventoItem.id-evento = piIdEvento
        BY bEventoItem.sequencia
        BY bEventoItem.seq-lote:
        CREATE ttEmbGeracaoItem.
        BUFFER-COPY bEventoItem TO ttEmbGeracaoItem.
    END.

    FOR EACH bGerada NO-LOCK
        WHERE bGerada.id-evento-geracao = piIdEvento
          AND bGerada.tipo-controle = "EMBALAGEM"
          AND bGerada.id-etiqueta > piAposId
        BY bGerada.id-etiqueta:
        IF iQuantidade = piLimite THEN DO:
            ASSIGN plTemMais = YES
                   piProximoId = iUltimo.
            LEAVE.
        END.
        CREATE ttEmbEtiquetaGerada.
        BUFFER-COPY bGerada TO ttEmbEtiquetaGerada.
        ASSIGN iQuantidade = iQuantidade + 1
               iUltimo = bGerada.id-etiqueta.
    END.

    ASSIGN plSucesso = YES
           pcErro = ""
           pcMensagem = "".
    CATCH eGeracao AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbGeracao.
        EMPTY TEMP-TABLE ttEmbGeracaoItem.
        EMPTY TEMP-TABLE ttEmbEtiquetaGerada.
        ASSIGN plTemMais = NO
               piProximoId = 0
               plSucesso = NO
               pcErro = "FALHA_CONSULTA"
               pcMensagem = "Nao foi possivel consultar a geracao.".
    END CATCH.
END.
END PROCEDURE.


PROCEDURE obterDadosImpressao:
/* GER-05 / DT-072: somente dados da identidade; nao imprime nem grava. */
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER piIdEtiqueta AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbEtiqueta.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bEtiquetaImpressao FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bGeracaoImpressao FOR mgesp.contr_emb_evento.
EMPTY TEMP-TABLE ttEmbEtiqueta.
ASSIGN plSucesso = NO pcErro = "SEM_PERMISSAO" pcMensagem = "Consulta nao autorizada.".
IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN RETURN.
FOR EACH ttEmbEstabelPermitido:
    IF ttEmbEstabelPermitido.cod-estabel = ? OR
       TRIM(ttEmbEstabelPermitido.cod-estabel) = "" THEN RETURN.
END.
ASSIGN pcErro = "FILTRO_INVALIDO" pcMensagem = "Informe uma identidade de etiqueta positiva.".
IF piIdEtiqueta = ? OR piIdEtiqueta <= 0 THEN RETURN.
IF NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_MGESP_NAO_CONECTADO" pcMensagem = "Banco especifico nao conectado.".
    RETURN.
END.
DO ON ERROR UNDO, THROW:
    ASSIGN pcErro = "ETIQUETA_NAO_DISPONIVEL" pcMensagem = "Etiqueta nao disponivel para consulta.".
    FIND FIRST bEtiquetaImpressao NO-LOCK
        WHERE bEtiquetaImpressao.id-etiqueta = piIdEtiqueta NO-ERROR.
    IF NOT AVAILABLE bEtiquetaImpressao THEN RETURN.
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
        WHERE ttEmbEstabelPermitido.cod-estabel = bEtiquetaImpressao.cod-estabel) THEN RETURN.
    ASSIGN pcErro = "ETIQUETA_NAO_IMPRIMIVEL" pcMensagem = "O registro nao identifica uma embalagem individual.".
    IF bEtiquetaImpressao.tipo-controle = ? OR bEtiquetaImpressao.tipo-controle <> "EMBALAGEM" THEN RETURN.
    ASSIGN pcErro = "GERACAO_NAO_CONFIRMADA" pcMensagem = "Geracao da embalagem ainda nao confirmada.".
    IF bEtiquetaImpressao.id-evento-geracao = ? OR bEtiquetaImpressao.id-evento-geracao <= 0 THEN RETURN.
    FIND FIRST bGeracaoImpressao NO-LOCK
        WHERE bGeracaoImpressao.id-evento = bEtiquetaImpressao.id-evento-geracao NO-ERROR.
    IF NOT AVAILABLE bGeracaoImpressao THEN RETURN.
    IF bGeracaoImpressao.situacao = ? OR bGeracaoImpressao.situacao <> "CONCLUIDO" THEN RETURN.
    CREATE ttEmbEtiqueta.
    BUFFER-COPY bEtiquetaImpressao TO ttEmbEtiqueta.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    CATCH eImpressao AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbEtiqueta.
        ASSIGN plSucesso = NO pcErro = "FALHA_CONSULTA"
            pcMensagem = "Nao foi possivel obter os dados de impressao.".
    END CATCH.
END.
END PROCEDURE.
