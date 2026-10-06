/* Modulo central do Controle de Embalagens.
   Regras transversais, tipos, parametros, Bags/lacres e auditoria. */
BLOCK-LEVEL ON ERROR UNDO, THROW.
{fontes/progress/contr-emb.i}
{fontes/progress/contr-emb-conversao.i}

PROCEDURE consultarEstabelecimentos:
/* DT-064 / ET-01I. Somente leitura; autorizacao precede a paginacao. */
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER pcFiltro AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcAposCodigo AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbEstabelecimento.
DEFINE OUTPUT PARAMETER plTemMais AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcProximoCodigo AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bEstabelecimentoApoio FOR mgcad.estabelec.
DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
DEFINE VARIABLE cUltimo AS CHARACTER NO-UNDO.
EMPTY TEMP-TABLE ttEmbEstabelecimento.
ASSIGN plTemMais = NO pcProximoCodigo = "" plSucesso = NO
       pcErro = "SEM_PERMISSAO" pcMensagem = "Consulta nao autorizada.".
IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN RETURN.
RUN validarFiltroApoio(INPUT-OUTPUT pcFiltro, INPUT pcAposCodigo,
    INPUT-OUTPUT piLimite, OUTPUT plSucesso, OUTPUT pcErro, OUTPUT pcMensagem).
IF NOT plSucesso THEN RETURN.
plSucesso = NO.
IF NOT CONNECTED("mgcad") THEN DO:
    ASSIGN pcErro = "BANCO_MGCAD_NAO_CONECTADO" pcMensagem = "Cadastro nao conectado.".
    RETURN.
END.
FOR EACH bEstabelecimentoApoio NO-LOCK
    WHERE (pcAposCodigo = "" OR bEstabelecimentoApoio.cod-estabel > pcAposCodigo)
      AND (bEstabelecimentoApoio.cod-estabel BEGINS pcFiltro
           OR INDEX(bEstabelecimentoApoio.nome, pcFiltro) > 0)
    BY bEstabelecimentoApoio.cod-estabel:
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
        WHERE ttEmbEstabelPermitido.cod-estabel = bEstabelecimentoApoio.cod-estabel) THEN NEXT.
    IF iQuantidade = piLimite THEN DO:
        ASSIGN plTemMais = YES pcProximoCodigo = cUltimo.
        LEAVE.
    END.
    CREATE ttEmbEstabelecimento.
    ASSIGN ttEmbEstabelecimento.codigo = bEstabelecimentoApoio.cod-estabel
           ttEmbEstabelecimento.descricao = bEstabelecimentoApoio.nome
           iQuantidade = iQuantidade + 1 cUltimo = ttEmbEstabelecimento.codigo.
END.
ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
END PROCEDURE.

PROCEDURE consultarItens:
/* Catalogo global: o estabelecimento valida contexto, nao vinculo/saldo. */
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER pcEstabel AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcFiltro AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcAposCodigo AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbItem.
DEFINE OUTPUT PARAMETER plTemMais AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcProximoCodigo AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bItemApoio FOR mgcad.item.
DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
DEFINE VARIABLE cUltimo AS CHARACTER NO-UNDO.
EMPTY TEMP-TABLE ttEmbItem.
ASSIGN plTemMais = NO pcProximoCodigo = "" plSucesso = NO
       pcErro = "SEM_PERMISSAO" pcMensagem = "Escolha um estabelecimento autorizado.".
IF pcEstabel = ? THEN RETURN.
pcEstabel = TRIM(pcEstabel).
IF pcEstabel = "" OR NOT CAN-FIND(FIRST ttEmbEstabelPermitido
    WHERE ttEmbEstabelPermitido.cod-estabel = pcEstabel) THEN RETURN.
RUN validarFiltroApoio(INPUT-OUTPUT pcFiltro, INPUT pcAposCodigo,
    INPUT-OUTPUT piLimite, OUTPUT plSucesso, OUTPUT pcErro, OUTPUT pcMensagem).
IF NOT plSucesso THEN RETURN.
plSucesso = NO.
IF NOT CONNECTED("mgcad") THEN DO:
    ASSIGN pcErro = "BANCO_MGCAD_NAO_CONECTADO" pcMensagem = "Cadastro nao conectado.".
    RETURN.
END.
FOR EACH bItemApoio NO-LOCK
    WHERE (pcAposCodigo = "" OR bItemApoio.it-codigo > pcAposCodigo)
      AND (bItemApoio.it-codigo BEGINS pcFiltro
           OR INDEX(bItemApoio.desc-item, pcFiltro) > 0)
    BY bItemApoio.it-codigo:
    IF iQuantidade = piLimite THEN DO:
        ASSIGN plTemMais = YES pcProximoCodigo = cUltimo.
        LEAVE.
    END.
    CREATE ttEmbItem.
    ASSIGN ttEmbItem.codigo = bItemApoio.it-codigo
           ttEmbItem.descricao = bItemApoio.desc-item
           ttEmbItem.un = bItemApoio.un
           ttEmbItem.tipo-controle-estoque = bItemApoio.tipo-con-est
           iQuantidade = iQuantidade + 1 cUltimo = ttEmbItem.codigo.
END.
ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
END PROCEDURE.

PROCEDURE consultarTiposApoio:
/* DT-070: catalogo global, busca OR codigo/descricao; sem mutacao. */
DEFINE INPUT PARAMETER plAutorizado AS LOGICAL NO-UNDO.
DEFINE INPUT PARAMETER pcFiltro AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcAposCodigo AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER plAtivo AS LOGICAL NO-UNDO.
DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbTipo.
DEFINE OUTPUT PARAMETER plTemMais AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcProximoCodigo AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bTipoApoio FOR mgesp.contr_emb_bag.
DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
DEFINE VARIABLE cUltimo AS CHARACTER NO-UNDO.
DEFINE VARIABLE iPos AS INTEGER NO-UNDO.
EMPTY TEMP-TABLE ttEmbTipo.
ASSIGN plTemMais = NO pcProximoCodigo = "" plSucesso = NO
       pcErro = "SEM_PERMISSAO" pcMensagem = "Consulta nao autorizada.".
IF plAutorizado = ? OR NOT plAutorizado THEN RETURN.
RUN validarFiltroApoio(INPUT-OUTPUT pcFiltro, INPUT pcAposCodigo,
    INPUT-OUTPUT piLimite, OUTPUT plSucesso, OUTPUT pcErro, OUTPUT pcMensagem).
IF NOT plSucesso THEN RETURN.
ASSIGN plSucesso = NO pcAposCodigo = CAPS(TRIM(pcAposCodigo," ")).
IF pcAposCodigo <> "" THEN DO:
    ASSIGN pcErro = "FILTRO_INVALIDO" pcMensagem = "Confira o cursor de tipo.".
    IF LENGTH(pcAposCodigo) < 2 OR LENGTH(pcAposCodigo) > 3 THEN RETURN.
    DO iPos = 1 TO LENGTH(pcAposCodigo):
        IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",SUBSTRING(pcAposCodigo,iPos,1)) = 0 THEN RETURN.
    END.
END.
IF NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_MGESP_NAO_CONECTADO" pcMensagem = "Banco especifico nao conectado.".
    RETURN.
END.
DO ON ERROR UNDO, THROW:
    FOR EACH bTipoApoio NO-LOCK
        WHERE (pcAposCodigo = "" OR bTipoApoio.cod-tipo > pcAposCodigo)
          AND (plAtivo = ? OR bTipoApoio.ativo = plAtivo)
          AND (bTipoApoio.cod-tipo BEGINS CAPS(pcFiltro)
               OR INDEX(bTipoApoio.desc-embalagem,pcFiltro) > 0)
        BY bTipoApoio.cod-tipo:
        IF iQuantidade = piLimite THEN DO:
            ASSIGN plTemMais = YES pcProximoCodigo = cUltimo.
            LEAVE.
        END.
        CREATE ttEmbTipo.
        BUFFER-COPY bTipoApoio TO ttEmbTipo.
        ASSIGN iQuantidade = iQuantidade + 1 cUltimo = bTipoApoio.cod-tipo.
    END.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    CATCH eTipoApoio AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbTipo.
        ASSIGN plTemMais = NO pcProximoCodigo = "" plSucesso = NO
               pcErro = "FALHA_CONSULTA" pcMensagem = "Nao foi possivel consultar os tipos.".
    END CATCH.
END.
END PROCEDURE.


PROCEDURE consultarFamilias:
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER pcFiltro AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcAposCodigo AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbFamilia.
DEFINE OUTPUT PARAMETER plTemMais AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcProximoCodigo AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bFamilia FOR mgcad.familia.
DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
DEFINE VARIABLE cUltimo AS CHARACTER NO-UNDO.
EMPTY TEMP-TABLE ttEmbFamilia.
ASSIGN plTemMais = NO pcProximoCodigo = "" plSucesso = NO
       pcErro = "SEM_PERMISSAO" pcMensagem = "Consulta nao autorizada.".
IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN RETURN.
FOR EACH ttEmbEstabelPermitido:
    IF ttEmbEstabelPermitido.cod-estabel = ? OR
       TRIM(ttEmbEstabelPermitido.cod-estabel) = "" THEN RETURN.
END.
RUN validarFiltroApoio(INPUT-OUTPUT pcFiltro,INPUT pcAposCodigo,INPUT-OUTPUT piLimite,
    OUTPUT plSucesso,OUTPUT pcErro,OUTPUT pcMensagem).
IF NOT plSucesso THEN RETURN.
ASSIGN plSucesso = NO pcAposCodigo = TRIM(pcAposCodigo," ").
IF NOT CONNECTED("mgcad") THEN DO:
    ASSIGN pcErro = "BANCO_MGCAD_NAO_CONECTADO" pcMensagem = "Banco cadastral nao conectado.".
    RETURN.
END.
DO ON ERROR UNDO, THROW:
    FOR EACH bFamilia NO-LOCK
        WHERE (pcAposCodigo = "" OR bFamilia.fm-codigo > pcAposCodigo)
          AND (bFamilia.fm-codigo BEGINS pcFiltro OR INDEX(bFamilia.descricao,pcFiltro) > 0)
        BY bFamilia.fm-codigo:
        IF iQuantidade = piLimite THEN DO:
            ASSIGN plTemMais = YES pcProximoCodigo = cUltimo.
            LEAVE.
        END.
        CREATE ttEmbFamilia.
        ASSIGN ttEmbFamilia.codigo = bFamilia.fm-codigo
               ttEmbFamilia.descricao = bFamilia.descricao
               iQuantidade = iQuantidade + 1 cUltimo = bFamilia.fm-codigo.
    END.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    CATCH eFamilia AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbFamilia.
        ASSIGN plTemMais = NO pcProximoCodigo = "" plSucesso = NO
            pcErro = "FALHA_CONSULTA" pcMensagem = "Nao foi possivel consultar as familias.".
    END CATCH.
END.
END PROCEDURE.

PROCEDURE validarFiltroApoio:
DEFINE INPUT-OUTPUT PARAMETER pcFiltro AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcAposCodigo AS CHARACTER NO-UNDO.
DEFINE INPUT-OUTPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
ASSIGN plSucesso = NO pcErro = "FILTRO_INVALIDO" pcMensagem = "Confira os filtros.".
IF pcFiltro = ? OR pcAposCodigo = ? THEN RETURN.
pcFiltro = TRIM(pcFiltro).
IF LENGTH(pcFiltro, "CHARACTER") > 100 OR LENGTH(pcAposCodigo, "CHARACTER") > 100 THEN RETURN.
IF LENGTH(pcFiltro, "CHARACTER") < 2 THEN DO:
    ASSIGN pcErro = "FILTRO_CURTO" pcMensagem = "Digite ao menos dois caracteres.".
    RETURN.
END.
ASSIGN pcErro = "LIMITE_INVALIDO" pcMensagem = "Informe limite de 1 a 20; zero usa 20.".
IF piLimite = ? THEN RETURN.
IF piLimite = 0 THEN piLimite = 20.
IF piLimite < 1 OR piLimite > 20 THEN RETURN.
ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
END PROCEDURE.

PROCEDURE validarTipo:
/* ET-01A / DT-037. Validacao pura: nao consulta nem grava cadastros.
   Contrato: docs/06_CATALOGO_PROCEDURES.md, secao 15.
   Compilar e executar os testes no OpenEdge do ambiente de teste. */
DEFINE INPUT  PARAMETER pcCodTipo               AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcDescricao             AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER plAtivo                 AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER pcCodNormalizado        AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcDescricaoNormalizada AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plValido                AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro                  AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem              AS CHARACTER NO-UNDO.

DEFINE VARIABLE cCodigo    AS CHARACTER NO-UNDO.
DEFINE VARIABLE cDescricao AS CHARACTER NO-UNDO.
DEFINE VARIABLE cNaoBranco AS CHARACTER NO-UNDO.
DEFINE VARIABLE iPosicao   AS INTEGER   NO-UNDO.
DEFINE VARIABLE iCaractere AS INTEGER   NO-UNDO.

ASSIGN pcCodNormalizado        = ""
       pcDescricaoNormalizada = ""
       plValido                = NO
       pcErro                  = "CODIGO_INVALIDO"
       pcMensagem              = "Informe um codigo com 2 ou 3 letras ASCII ou numeros.".

IF pcCodTipo = ? THEN RETURN.
cCodigo = TRIM(pcCodTipo, " ").
IF LENGTH(cCodigo, "CHARACTER") < 2 OR
   LENGTH(cCodigo, "CHARACTER") > 3 THEN RETURN.

DO iPosicao = 1 TO LENGTH(cCodigo, "CHARACTER"):
    iCaractere = ASC(SUBSTRING(cCodigo, iPosicao, 1, "CHARACTER")).
    IF iCaractere >= 97 AND iCaractere <= 122 THEN DO:
        iCaractere = iCaractere - 32.
        SUBSTRING(cCodigo, iPosicao, 1, "CHARACTER") = CHR(iCaractere).
    END.
    IF NOT ((iCaractere >= 65 AND iCaractere <= 90) OR
            (iCaractere >= 48 AND iCaractere <= 57)) THEN RETURN.
END.

ASSIGN pcErro     = "DESCRICAO_INVALIDA"
       pcMensagem = "Informe uma descricao com 1 a 100 caracteres.".
IF pcDescricao = ? THEN RETURN.
cDescricao = TRIM(pcDescricao, " ").
cNaoBranco = REPLACE(REPLACE(REPLACE(cDescricao, CHR(9), ""),
                       CHR(10), ""), CHR(13), "").
IF TRIM(cNaoBranco, " ") = "" OR
   LENGTH(cDescricao, "CHARACTER") > 100 THEN RETURN.

ASSIGN pcErro     = "SITUACAO_INVALIDA"
       pcMensagem = "Informe a situacao ativa ou inativa.".
IF plAtivo = ? THEN RETURN.

ASSIGN pcCodNormalizado        = cCodigo
       pcDescricaoNormalizada = cDescricao
       plValido                = YES
       pcErro                  = ""
       pcMensagem              = "".

END PROCEDURE.

PROCEDURE salvarTipo:
/* DT-049. Comando cadastral interno, atomico e idempotente.
   O adaptador publico deve resolver autorizacao, usuario e hashes. */
DEFINE INPUT  PARAMETER pcAcao                 AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcCodTipo              AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcDescricao            AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER plAtivo                AS LOGICAL   NO-UNDO.
DEFINE INPUT  PARAMETER piVersaoEsperada       AS INTEGER   NO-UNDO.
DEFINE INPUT  PARAMETER pcOrigem               AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcChaveIdempotente     AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcHashChave            AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcHashConteudo         AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcUsuario              AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER plAutorizado           AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso              AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao            AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER pcCodNormalizado       AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcDescricaoNormalizada AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plAtivoResultante      AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER piVersaoResultante     AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento             AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro                 AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem             AS CHARACTER NO-UNDO.

DEFINE BUFFER bTipo   FOR contr_emb_bag.
DEFINE BUFFER bEvento FOR contr_emb_evento.
DEFINE BUFFER bAudit  FOR contr_emb_audit.

DEFINE VARIABLE cAcao          AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cCodigo        AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cDescricao     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cOrigem        AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cChave         AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cHashChave     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cHashConteudo  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cUsuario       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cDadosAntes    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cDadosDepois   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cResultado     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lEntradaValida AS LOGICAL     NO-UNDO.
DEFINE VARIABLE cErroValidacao AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cMsgValidacao  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lAtivoAntes    AS LOGICAL     NO-UNDO.
DEFINE VARIABLE iVersaoAntes   AS INTEGER     NO-UNDO.
DEFINE VARIABLE iSep1          AS INTEGER     NO-UNDO.
DEFINE VARIABLE iSep2          AS INTEGER     NO-UNDO.
DEFINE VARIABLE iSep3          AS INTEGER     NO-UNDO.
DEFINE VARIABLE dtAgora        AS DATETIME-TZ NO-UNDO.

ASSIGN plSucesso              = NO
       plRepeticao            = NO
       pcCodNormalizado       = ""
       pcDescricaoNormalizada = ""
       plAtivoResultante      = ?
       piVersaoResultante     = 0
       piIdEvento             = 0
       pcErro                 = "SEM_PERMISSAO"
       pcMensagem             = "Operacao nao autorizada.".

IF plAutorizado = ? OR NOT plAutorizado THEN RETURN.

ASSIGN cAcao         = IF pcAcao = ? THEN "" ELSE CAPS(TRIM(pcAcao, " "))
       cOrigem       = IF pcOrigem = ? THEN "" ELSE CAPS(TRIM(pcOrigem, " "))
       cChave        = IF pcChaveIdempotente = ? THEN "" ELSE TRIM(pcChaveIdempotente, " ")
       cHashChave    = IF pcHashChave = ? THEN "" ELSE CAPS(TRIM(pcHashChave, " "))
       cHashConteudo = IF pcHashConteudo = ? THEN "" ELSE CAPS(TRIM(pcHashConteudo, " "))
       cUsuario      = IF pcUsuario = ? THEN "" ELSE TRIM(pcUsuario, " ")
       pcErro        = "CONTEXTO_INVALIDO"
       pcMensagem    = "Confira a acao e o contexto confiavel do comando.".

IF LOOKUP(cAcao, "INCLUIR,ALTERAR,INATIVAR") = 0 OR
   cOrigem = "" OR LENGTH(cOrigem, "CHARACTER") > 20 OR
   cChave = "" OR LENGTH(cChave, "CHARACTER") > 512 OR
   LENGTH(cHashChave, "CHARACTER") <> 64 OR
   LENGTH(cHashConteudo, "CHARACTER") <> 64 OR
   cUsuario = "" OR LENGTH(cUsuario, "CHARACTER") > 128 OR
   piVersaoEsperada = ? OR piVersaoEsperada < 0 THEN RETURN.

RUN validarTipo(
    INPUT  pcCodTipo,
    INPUT  pcDescricao,
    INPUT  (IF cAcao = "INATIVAR" THEN NO ELSE plAtivo),
    OUTPUT cCodigo,
    OUTPUT cDescricao,
    OUTPUT lEntradaValida,
    OUTPUT cErroValidacao,
    OUTPUT cMsgValidacao).

IF NOT lEntradaValida THEN DO:
    ASSIGN pcErro     = cErroValidacao
           pcMensagem = cMsgValidacao.
    RETURN.
END.

/* Recuperacao duravel de uma chamada ja concluida. */
FIND FIRST bEvento NO-LOCK
     WHERE bEvento.hash-chave = cHashChave
     NO-ERROR.
IF AVAILABLE bEvento THEN DO:
    IF bEvento.origem        <> cOrigem OR
       bEvento.chave-evento  <> cChave OR
       bEvento.hash-conteudo <> cHashConteudo OR
       bEvento.tipo-evento   <> "CADASTRO_TIPO" THEN DO:
        ASSIGN pcErro     = "CONFLITO_IDEMPOTENCIA"
               pcMensagem = "A chave informada ja foi utilizada com outro conteudo.".
        RETURN.
    END.
    IF bEvento.situacao <> "CONCLUIDO" OR bEvento.resultado = ? THEN DO:
        ASSIGN pcErro     = "COMANDO_EM_PROCESSAMENTO"
               pcMensagem = "O comando informado ainda nao possui resultado concluido.".
        RETURN.
    END.

    ASSIGN cResultado = bEvento.resultado
           iSep1      = INDEX(cResultado, "|")
           iSep2      = IF iSep1 > 0 THEN INDEX(cResultado, "|", iSep1 + 1) ELSE 0
           iSep3      = IF iSep2 > 0 THEN INDEX(cResultado, "|", iSep2 + 1) ELSE 0.
    IF iSep1 = 0 OR iSep2 = 0 OR iSep3 = 0 THEN DO:
        ASSIGN pcErro     = "RESULTADO_INVALIDO"
               pcMensagem = "O resultado persistido do comando nao pode ser recuperado.".
        RETURN.
    END.

    ASSIGN pcCodNormalizado       = SUBSTRING(cResultado, 1, iSep1 - 1, "CHARACTER")
           piVersaoResultante     = INTEGER(SUBSTRING(cResultado, iSep1 + 1,
                                          iSep2 - iSep1 - 1, "CHARACTER"))
           plAtivoResultante      = SUBSTRING(cResultado, iSep2 + 1,
                                          iSep3 - iSep2 - 1, "CHARACTER") = "1"
           pcDescricaoNormalizada = SUBSTRING(cResultado, iSep3 + 1)
           piIdEvento             = bEvento.id-evento
           plSucesso              = YES
           plRepeticao            = YES
           pcErro                 = ""
           pcMensagem             = "".
    RETURN.
END.

ASSIGN pcCodNormalizado       = cCodigo
       pcDescricaoNormalizada = cDescricao
       pcErro                 = "VERSAO_INVALIDA"
       pcMensagem             = "A versao esperada nao corresponde a acao informada.".
IF cAcao = "INCLUIR" AND piVersaoEsperada <> 0 THEN RETURN.
IF cAcao <> "INCLUIR" AND piVersaoEsperada <= 0 THEN RETURN.

DO TRANSACTION ON ERROR UNDO, THROW:
    FIND FIRST bTipo EXCLUSIVE-LOCK
         WHERE bTipo.cod-tipo = cCodigo
         NO-ERROR.

    IF cAcao = "INCLUIR" THEN DO:
        IF AVAILABLE bTipo THEN DO:
            ASSIGN pcErro     = "TIPO_JA_EXISTE"
                   pcMensagem = "Ja existe um tipo com o codigo informado.".
            RETURN.
        END.

        ASSIGN dtAgora            = NOW
               iVersaoAntes      = 0
               cDadosAntes       = ?
               plAtivoResultante = plAtivo
               piVersaoResultante = 1.

        CREATE bTipo.
        ASSIGN bTipo.cod-tipo          = cCodigo
               bTipo.desc-embalagem    = cDescricao
               bTipo.ativo             = plAtivoResultante
               bTipo.dt-inclusao       = dtAgora
               bTipo.usuario-inclusao  = cUsuario
               bTipo.dt-alteracao      = dtAgora
               bTipo.usuario-alteracao = cUsuario
               bTipo.versao            = piVersaoResultante.
    END.
    ELSE DO:
        IF NOT AVAILABLE bTipo THEN DO:
            ASSIGN pcErro     = "TIPO_NAO_ENCONTRADO"
                   pcMensagem = "O tipo informado nao foi encontrado.".
            RETURN.
        END.
        IF bTipo.versao <> piVersaoEsperada THEN DO:
            ASSIGN pcErro     = "CONFLITO_VERSAO"
                   pcMensagem = "O tipo foi alterado por outra operacao.".
            RETURN.
        END.

        ASSIGN lAtivoAntes   = bTipo.ativo
               iVersaoAntes = bTipo.versao
               cDadosAntes  = bTipo.cod-tipo + "|" + STRING(bTipo.versao) + "|" +
                              (IF bTipo.ativo THEN "1" ELSE "0") + "|" +
                              bTipo.desc-embalagem
               plAtivoResultante = IF cAcao = "INATIVAR" THEN NO ELSE plAtivo
               cDescricao        = IF cAcao = "INATIVAR" THEN bTipo.desc-embalagem ELSE cDescricao.

        IF bTipo.desc-embalagem = cDescricao AND
           bTipo.ativo = plAtivoResultante THEN DO:
            ASSIGN pcErro     = "SEM_ALTERACAO"
                   pcMensagem = "O comando nao altera os dados atuais do tipo.".
            RETURN.
        END.

        ASSIGN dtAgora                 = NOW
               piVersaoResultante      = bTipo.versao + 1
               bTipo.desc-embalagem    = cDescricao
               bTipo.ativo             = plAtivoResultante
               bTipo.dt-alteracao      = dtAgora
               bTipo.usuario-alteracao = cUsuario
               bTipo.versao            = piVersaoResultante.
    END.

    ASSIGN pcDescricaoNormalizada = cDescricao
           cDadosDepois = cCodigo + "|" + STRING(piVersaoResultante) + "|" +
                          (IF plAtivoResultante THEN "1" ELSE "0") + "|" + cDescricao
           cResultado   = cDadosDepois
           piIdEvento   = NEXT-VALUE(CONTR_EMB_EVENTO_SEQ, mgesp).

    CREATE bEvento.
    ASSIGN bEvento.id-evento         = piIdEvento
           bEvento.origem            = cOrigem
           bEvento.chave-evento      = cChave
           bEvento.hash-chave        = cHashChave
           bEvento.hash-conteudo     = cHashConteudo
           bEvento.tipo-evento       = "CADASTRO_TIPO"
           bEvento.seq-ciclo         = 1
           bEvento.dt-evento         = dtAgora
           bEvento.versao-contrato   = 1
           bEvento.dados-evento      = cDadosDepois
           bEvento.situacao          = "CONCLUIDO"
           bEvento.tentativas        = 1
           bEvento.dt-conclusao      = dtAgora
           bEvento.resultado         = cResultado
           bEvento.mensagem          = ""
           bEvento.dt-inclusao       = dtAgora
           bEvento.usuario-inclusao  = cUsuario
           bEvento.dt-alteracao      = dtAgora
           bEvento.usuario-alteracao = cUsuario
           bEvento.versao            = 1.

    CREATE bAudit.
    ASSIGN bAudit.id-audit       = NEXT-VALUE(CONTR_EMB_AUDIT_SEQ, mgesp)
           bAudit.id-evento      = piIdEvento
           bAudit.nome-tabela    = "CONTR_EMB_BAG"
           bAudit.chave-registro = cCodigo
           bAudit.acao           = IF cAcao = "INCLUIR" THEN "INCLUSAO" ELSE "ALTERACAO"
           bAudit.versao-ant     = iVersaoAntes
           bAudit.versao-atu     = piVersaoResultante
           bAudit.dados-ant      = cDadosAntes
           bAudit.dados-atu      = cDadosDepois
           bAudit.justificativa  = IF cAcao = "INATIVAR" THEN "INATIVACAO" ELSE ?
           bAudit.dt-registro    = dtAgora
           bAudit.usuario        = cUsuario.

    ASSIGN plSucesso   = YES
           plRepeticao = NO
           pcErro      = ""
           pcMensagem  = "".
END.

END PROCEDURE.

PROCEDURE validarParametro:
/* ET-01C: validacao pura dos dados de parametrizacao.
   Nao consulta item, estabelecimento, unidade, tipo ou permissao.
   Essas validacoes pertencem ao comando integrado no ambiente Datasul. */
DEFINE INPUT  PARAMETER pcEstabelecimento          AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcItem                     AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcCodTipo                  AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pdCapacidade               AS DECIMAL   NO-UNDO.
DEFINE INPUT  PARAMETER pcUnidade                  AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER plAtivo                    AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER pcEstabelNormalizado       AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcItemNormalizado          AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcCodTipoNormalizado       AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcUnidadeNormalizada       AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plValido                   AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro                     AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem                 AS CHARACTER NO-UNDO.

DEFINE VARIABLE iPosicao   AS INTEGER   NO-UNDO.
DEFINE VARIABLE iCaractere AS INTEGER   NO-UNDO.
DEFINE VARIABLE cEstabel   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cItem      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCodTipo   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cUnidade   AS CHARACTER NO-UNDO.

ASSIGN pcEstabelNormalizado = ""
       pcItemNormalizado    = ""
       pcCodTipoNormalizado = ""
       pcUnidadeNormalizada = ""
       plValido             = NO
       pcErro               = "ESTABELECIMENTO_INVALIDO"
       pcMensagem           = "Informe o estabelecimento.".

IF pcEstabelecimento = ? THEN RETURN.
cEstabel = TRIM(pcEstabelecimento, " ").
IF cEstabel = "" THEN RETURN.

ASSIGN pcErro     = "ITEM_INVALIDO"
       pcMensagem = "Informe o item.".
IF pcItem = ? THEN RETURN.
cItem = TRIM(pcItem, " ").
IF cItem = "" THEN RETURN.

ASSIGN pcErro     = "TIPO_INVALIDO"
       pcMensagem = "Informe um tipo com 2 ou 3 letras ASCII ou numeros.".
IF pcCodTipo = ? THEN RETURN.
cCodTipo = TRIM(pcCodTipo, " ").
IF LENGTH(cCodTipo, "CHARACTER") < 2 OR
   LENGTH(cCodTipo, "CHARACTER") > 3 THEN RETURN.

DO iPosicao = 1 TO LENGTH(cCodTipo, "CHARACTER"):
    iCaractere = ASC(SUBSTRING(cCodTipo, iPosicao, 1, "CHARACTER")).
    IF iCaractere >= 97 AND iCaractere <= 122 THEN DO:
        iCaractere = iCaractere - 32.
        SUBSTRING(cCodTipo, iPosicao, 1, "CHARACTER") = CHR(iCaractere).
    END.
    IF NOT ((iCaractere >= 65 AND iCaractere <= 90) OR
            (iCaractere >= 48 AND iCaractere <= 57)) THEN RETURN.
END.

ASSIGN pcErro     = "CAPACIDADE_INVALIDA"
       pcMensagem = "Informe uma capacidade maior que zero.".
IF pdCapacidade = ? OR pdCapacidade <= 0 THEN RETURN.

ASSIGN pcErro     = "UNIDADE_INVALIDA"
       pcMensagem = "Informe a unidade de estoque.".
IF pcUnidade = ? THEN RETURN.
cUnidade = TRIM(pcUnidade, " ").
IF cUnidade = "" THEN RETURN.

ASSIGN pcErro     = "SITUACAO_INVALIDA"
       pcMensagem = "Informe a situacao ativa ou inativa.".
IF plAtivo = ? THEN RETURN.

ASSIGN pcEstabelNormalizado = cEstabel
       pcItemNormalizado    = cItem
       pcCodTipoNormalizado = cCodTipo
       pcUnidadeNormalizada = cUnidade
       plValido             = YES
       pcErro               = ""
       pcMensagem           = "".

END PROCEDURE.

PROCEDURE salvarParametro:
/* ET-01F / DT-050. Cadastro integrado, atomico e idempotente. */
DEFINE INPUT  PARAMETER pcAcao             AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER piIdParam          AS INTEGER   NO-UNDO.
DEFINE INPUT  PARAMETER pcEstabelecimento  AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcItem             AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcCodTipo          AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pdCapacidade       AS DECIMAL   NO-UNDO.
DEFINE INPUT  PARAMETER pcUnidade          AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER plAtivo            AS LOGICAL   NO-UNDO.
DEFINE INPUT  PARAMETER pcLoteMigracao     AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pdtValidadeMigracao AS DATE      NO-UNDO.
DEFINE INPUT  PARAMETER piVersaoEsperada   AS INTEGER   NO-UNDO.
DEFINE INPUT  PARAMETER pcOrigem           AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcChaveIdempotente AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcHashChave        AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcHashConteudo     AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pcUsuario          AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER plAutorizado       AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso          AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER plRepeticao        AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER piIdResultante     AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER pcEstabelResultante AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcItemResultante   AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcTipoResultante   AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pdCapResultante    AS DECIMAL   NO-UNDO.
DEFINE OUTPUT PARAMETER pcUnResultante     AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plAtivoResultante  AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER piVersaoResultante AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER plExcluido         AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER piIdEvento         AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro             AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem         AS CHARACTER NO-UNDO.

DEFINE BUFFER bParam  FOR contr_emb_param.
DEFINE BUFFER bTipo   FOR contr_emb_bag.
DEFINE BUFFER bEvento FOR contr_emb_evento.
DEFINE BUFFER bAudit  FOR contr_emb_audit.
DEFINE BUFFER bEstab  FOR estabelec.
DEFINE BUFFER bItem   FOR mgcad.item.
DEFINE BUFFER bOutro  FOR contr_emb_param.
DEFINE BUFFER bEtiqueta FOR mgesp.contr_emb_etiqueta.
DEFINE BUFFER bOperItem FOR mgesp.contr_emb_oper_item.
DEFINE BUFFER bOper FOR mgesp.contr_emb_oper.

DEFINE VARIABLE cAcao          AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cEstabel       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cItem          AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cTipo          AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cUn            AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cOrigem        AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cChave         AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cHashChave     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cHashConteudo  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cUsuario       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cAntes         AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cDepois        AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cResultado     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cChaveRegistro AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lValido        AS LOGICAL     NO-UNDO.
DEFINE VARIABLE cErroVal       AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cMsgVal        AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iVersaoAntes   AS INTEGER     NO-UNDO.
DEFINE VARIABLE dCap           AS DECIMAL     NO-UNDO.
DEFINE VARIABLE hConversor AS HANDLE NO-UNDO.
DEFINE VARIABLE iDestino AS INTEGER NO-UNDO.
DEFINE VARIABLE iTipoOrigem AS INTEGER NO-UNDO.
DEFINE VARIABLE iTipoFinal AS INTEGER NO-UNDO.
DEFINE VARIABLE lConvertido AS LOGICAL NO-UNDO.
DEFINE VARIABLE lConversaoOk AS LOGICAL NO-UNDO.
DEFINE VARIABLE lEraAtivo AS LOGICAL NO-UNDO.
DEFINE VARIABLE dtAgora        AS DATETIME-TZ NO-UNDO.

ASSIGN plSucesso           = NO
       plRepeticao         = NO
       piIdResultante      = 0
       pcEstabelResultante = ""
       pcItemResultante    = ""
       pcTipoResultante    = ""
       pdCapResultante     = 0
       pcUnResultante      = ""
       plAtivoResultante   = ?
       piVersaoResultante  = 0
       plExcluido          = NO
       piIdEvento          = 0
       pcErro              = "SEM_PERMISSAO"
       pcMensagem          = "Operacao nao autorizada.".
IF plAutorizado = ? OR NOT plAutorizado THEN RETURN.

ASSIGN cAcao         = IF pcAcao = ? THEN "" ELSE CAPS(TRIM(pcAcao, " "))
       cOrigem       = IF pcOrigem = ? THEN "" ELSE CAPS(TRIM(pcOrigem, " "))
       cChave        = IF pcChaveIdempotente = ? THEN "" ELSE TRIM(pcChaveIdempotente, " ")
       cHashChave    = IF pcHashChave = ? THEN "" ELSE CAPS(TRIM(pcHashChave, " "))
       cHashConteudo = IF pcHashConteudo = ? THEN "" ELSE CAPS(TRIM(pcHashConteudo, " "))
       cUsuario      = IF pcUsuario = ? THEN "" ELSE TRIM(pcUsuario, " ")
       pcErro        = "CONTEXTO_INVALIDO"
       pcMensagem    = "Confira a acao e o contexto confiavel do comando.".
IF LOOKUP(cAcao, "INCLUIR,ALTERAR,INATIVAR,EXCLUIR") = 0 OR
   cOrigem = "" OR LENGTH(cOrigem) > 20 OR
   cChave = "" OR LENGTH(cChave) > 512 OR
   LENGTH(cHashChave) <> 64 OR LENGTH(cHashConteudo) <> 64 OR
   cUsuario = "" OR LENGTH(cUsuario) > 128 OR
   piIdParam = ? OR piVersaoEsperada = ? THEN RETURN.

RUN validarParametro(INPUT pcEstabelecimento, INPUT pcItem, INPUT pcCodTipo,
    INPUT pdCapacidade, INPUT pcUnidade,
    INPUT (IF cAcao = "INATIVAR" OR cAcao = "EXCLUIR" THEN NO ELSE plAtivo),
    OUTPUT cEstabel, OUTPUT cItem, OUTPUT cTipo, OUTPUT cUn,
    OUTPUT lValido, OUTPUT cErroVal, OUTPUT cMsgVal).
IF NOT lValido THEN DO:
    ASSIGN pcErro = cErroVal pcMensagem = cMsgVal.
    RETURN.
END.
ASSIGN dCap = pdCapacidade.

/* Recupera a resposta de uma chamada concluida antes de reler cadastros. */
FIND FIRST bEvento NO-LOCK WHERE bEvento.hash-chave = cHashChave NO-ERROR.
IF AVAILABLE bEvento THEN DO:
    IF bEvento.origem <> cOrigem OR bEvento.chave-evento <> cChave OR
       bEvento.hash-conteudo <> cHashConteudo OR
       bEvento.tipo-evento <> "CADASTRO_PARAMETRO" THEN DO:
        ASSIGN pcErro = "CONFLITO_IDEMPOTENCIA"
               pcMensagem = "A chave informada ja foi utilizada com outro conteudo.".
        RETURN.
    END.
    IF bEvento.situacao <> "CONCLUIDO" OR bEvento.resultado = ? THEN DO:
        ASSIGN pcErro = "COMANDO_EM_PROCESSAMENTO"
               pcMensagem = "O comando informado ainda nao possui resultado concluido.".
        RETURN.
    END.
    cResultado = bEvento.resultado.
    IF NUM-ENTRIES(cResultado, "|") <> 9 THEN DO:
        ASSIGN pcErro = "RESULTADO_INVALIDO"
               pcMensagem = "O resultado persistido do comando nao pode ser recuperado.".
        RETURN.
    END.
    ASSIGN piIdResultante      = INTEGER(ENTRY(1, cResultado, "|"))
           piVersaoResultante = INTEGER(ENTRY(2, cResultado, "|"))
           plAtivoResultante  = ENTRY(3, cResultado, "|") = "1"
           plExcluido         = ENTRY(4, cResultado, "|") = "1"
           pcEstabelResultante = ENTRY(5, cResultado, "|")
           pcItemResultante   = ENTRY(6, cResultado, "|")
           pcTipoResultante   = ENTRY(7, cResultado, "|")
           pcUnResultante     = ENTRY(8, cResultado, "|")
           pdCapResultante    = DECIMAL(ENTRY(9, cResultado, "|")) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN DO:
        ASSIGN pcErro = "RESULTADO_INVALIDO"
               pcMensagem = "O resultado persistido do comando nao pode ser recuperado.".
        RETURN.
    END.
    ASSIGN piIdEvento = bEvento.id-evento plSucesso = YES plRepeticao = YES
           pcErro = "" pcMensagem = "".
    RETURN.
END.

ASSIGN pcErro = "VERSAO_INVALIDA"
       pcMensagem = "A identidade ou versao esperada nao corresponde a acao.".
IF cAcao = "INCLUIR" AND (piIdParam <> 0 OR piVersaoEsperada <> 0) THEN RETURN.
IF cAcao <> "INCLUIR" AND (piIdParam <= 0 OR piVersaoEsperada <= 0) THEN RETURN.

FIND FIRST bEstab NO-LOCK WHERE bEstab.cod-estabel = cEstabel NO-ERROR.
IF NOT AVAILABLE bEstab THEN DO:
    ASSIGN pcErro = "ESTABELECIMENTO_NAO_ENCONTRADO"
           pcMensagem = "O estabelecimento informado nao foi encontrado.".
    RETURN.
END.
FIND FIRST bItem NO-LOCK WHERE bItem.it-codigo = cItem NO-ERROR.
IF NOT AVAILABLE bItem THEN DO:
    ASSIGN pcErro = "ITEM_NAO_ENCONTRADO"
           pcMensagem = "O item informado nao foi encontrado.".
    RETURN.
END.
IF bItem.un <> cUn THEN DO:
    ASSIGN pcErro = "UNIDADE_DIVERGENTE"
           pcMensagem = "A unidade informada difere da unidade de estoque do item.".
    RETURN.
END.
FIND FIRST bTipo NO-LOCK WHERE bTipo.cod-tipo = cTipo NO-ERROR.
IF NOT AVAILABLE bTipo THEN DO:
    ASSIGN pcErro = "TIPO_NAO_ENCONTRADO"
           pcMensagem = "O tipo informado nao foi encontrado.".
    RETURN.
END.
IF (cAcao = "INCLUIR" OR (cAcao = "ALTERAR" AND plAtivo)) AND
   NOT bTipo.ativo THEN DO:
    ASSIGN pcErro = "TIPO_INATIVO"
           pcMensagem = "O tipo informado esta inativo.".
    RETURN.
END.

parametrizacao:
DO TRANSACTION ON ERROR UNDO, THROW:
    /* Todos os comandos do mesmo item compartilham este bloqueio. */
    FIND FIRST bItem EXCLUSIVE-LOCK WHERE bItem.it-codigo = cItem NO-ERROR.
    IF NOT AVAILABLE bItem THEN DO:
        ASSIGN pcErro = "ITEM_NAO_ENCONTRADO"
               pcMensagem = "Nao foi possivel obter o item para a parametrizacao.".
        RETURN.
    END.
    /* Recupera a resposta de uma chamada concluida antes de reler cadastros. */
    FIND FIRST bEvento NO-LOCK WHERE bEvento.hash-chave = cHashChave NO-ERROR.
    IF AVAILABLE bEvento THEN DO:
        IF bEvento.origem <> cOrigem OR bEvento.chave-evento <> cChave OR
           bEvento.hash-conteudo <> cHashConteudo OR
           bEvento.tipo-evento <> "CADASTRO_PARAMETRO" THEN DO:
            ASSIGN pcErro = "CONFLITO_IDEMPOTENCIA"
                   pcMensagem = "A chave informada ja foi utilizada com outro conteudo.".
            RETURN.
        END.
        IF bEvento.situacao <> "CONCLUIDO" OR bEvento.resultado = ? THEN DO:
            ASSIGN pcErro = "COMANDO_EM_PROCESSAMENTO"
                   pcMensagem = "O comando informado ainda nao possui resultado concluido.".
            RETURN.
        END.
        cResultado = bEvento.resultado.
        IF NUM-ENTRIES(cResultado, "|") <> 9 THEN DO:
            ASSIGN pcErro = "RESULTADO_INVALIDO"
                   pcMensagem = "O resultado persistido do comando nao pode ser recuperado.".
            RETURN.
        END.
        ASSIGN piIdResultante      = INTEGER(ENTRY(1, cResultado, "|"))
               piVersaoResultante = INTEGER(ENTRY(2, cResultado, "|"))
               plAtivoResultante  = ENTRY(3, cResultado, "|") = "1"
               plExcluido         = ENTRY(4, cResultado, "|") = "1"
               pcEstabelResultante = ENTRY(5, cResultado, "|")
               pcItemResultante   = ENTRY(6, cResultado, "|")
               pcTipoResultante   = ENTRY(7, cResultado, "|")
               pcUnResultante     = ENTRY(8, cResultado, "|")
               pdCapResultante    = DECIMAL(ENTRY(9, cResultado, "|")) NO-ERROR.
        IF ERROR-STATUS:ERROR THEN DO:
            ASSIGN pcErro = "RESULTADO_INVALIDO"
                   pcMensagem = "O resultado persistido do comando nao pode ser recuperado.".
            RETURN.
        END.
        ASSIGN piIdEvento = bEvento.id-evento plSucesso = YES plRepeticao = YES
               pcErro = "" pcMensagem = "".
        RETURN.
    END.
    
    IF bItem.un <> cUn THEN DO:
        ASSIGN pcErro = "UNIDADE_DIVERGENTE"
               pcMensagem = "A unidade do item foi alterada por outra operacao.".
        RETURN.
    END.
    FIND FIRST bTipo SHARE-LOCK WHERE bTipo.cod-tipo = cTipo NO-ERROR.
    IF NOT AVAILABLE bTipo THEN DO:
        ASSIGN pcErro = "TIPO_NAO_ENCONTRADO" pcMensagem = "O tipo nao foi encontrado.".
        RETURN.
    END.
    IF (cAcao = "INCLUIR" OR cAcao = "ALTERAR") AND plAtivo AND NOT bTipo.ativo THEN DO:
        ASSIGN pcErro = "TIPO_INATIVO" pcMensagem = "O tipo informado esta inativo.".
        RETURN.
    END.
    IF bItem.tipo-con-est = ? THEN DO:
        ASSIGN pcErro = "TRANSICAO_NAO_SUPORTADA"
               pcMensagem = "O tipo de controle do item nao esta definido.".
        RETURN.
    END.
    ASSIGN iDestino = 0 lEraAtivo = NO.
    IF cAcao = "INCLUIR" THEN DO:
        FIND FIRST bParam EXCLUSIVE-LOCK
             WHERE bParam.cod-estabel = cEstabel AND bParam.it-codigo = cItem NO-ERROR.
        IF AVAILABLE bParam THEN DO:
            ASSIGN pcErro = "PARAMETRO_JA_EXISTE"
                   pcMensagem = "Ja existe parametrizacao para o estabelecimento e item.".
            RETURN.
        END.
        IF plAtivo THEN iDestino = 3.
    END.
    ELSE DO:
        FIND FIRST bParam EXCLUSIVE-LOCK WHERE bParam.id-param = piIdParam NO-ERROR.
        IF NOT AVAILABLE bParam THEN DO:
            ASSIGN pcErro = "PARAMETRO_NAO_ENCONTRADO"
                   pcMensagem = "A parametrizacao informada nao foi encontrada.".
            RETURN.
        END.
        IF bParam.cod-estabel <> cEstabel OR bParam.it-codigo <> cItem THEN DO:
            ASSIGN pcErro = "CHAVE_IMUTAVEL"
                   pcMensagem = "Estabelecimento e item nao podem ser alterados.".
            RETURN.
        END.
        IF bParam.versao <> piVersaoEsperada THEN DO:
            ASSIGN pcErro = "CONFLITO_VERSAO"
                   pcMensagem = "A parametrizacao foi alterada por outra operacao.".
            RETURN.
        END.
        ASSIGN lEraAtivo = bParam.ativo
               piIdResultante = bParam.id-param iVersaoAntes = bParam.versao
               cAntes = STRING(bParam.id-param) + "|" + STRING(bParam.versao) + "|" +
                        (IF bParam.ativo THEN "1" ELSE "0") + "|" + bParam.cod-estabel + "|" +
                        bParam.it-codigo + "|" + bParam.cod-tipo + "|" +
                        STRING(bParam.capacidade-emb) + "|" + bParam.un
               plAtivoResultante = IF cAcao = "INATIVAR" OR cAcao = "EXCLUIR" THEN NO ELSE plAtivo
               piVersaoResultante = bParam.versao + 1.
        IF cAcao = "INATIVAR" THEN ASSIGN cTipo = bParam.cod-tipo
            dCap = bParam.capacidade-emb cUn = bParam.un.
        IF cAcao <> "EXCLUIR" AND bParam.cod-tipo = cTipo AND
           bParam.capacidade-emb = dCap AND bParam.un = cUn AND
           bParam.ativo = plAtivoResultante THEN DO:
            ASSIGN pcErro = "SEM_ALTERACAO"
                   pcMensagem = "O comando nao altera os dados atuais da parametrizacao.".
            RETURN.
        END.
        IF plAtivoResultante THEN iDestino = 3.
        ELSE IF lEraAtivo AND NOT CAN-FIND(FIRST bOutro NO-LOCK
            WHERE bOutro.it-codigo = cItem AND bOutro.ativo
              AND bOutro.id-param <> bParam.id-param) THEN iDestino = 1.
    END.


    IF cAcao <> "INCLUIR" AND NOT plAtivoResultante AND lEraAtivo
       AND iDestino = 0 AND bItem.tipo-con-est <> 3 THEN DO:
        ASSIGN pcErro = "ITEM_CONTROLE_DIVERGENTE"
               pcMensagem = "Outro parametro permanece ativo, mas o item nao esta por lote; regularize a divergencia.".
        UNDO parametrizacao, LEAVE parametrizacao.
    END.
    /* Elegibilidade vale mesmo se o item foi alterado fora do fluxo. */
    IF iDestino = 1 THEN DO:
        IF CAN-FIND(FIRST bEtiqueta NO-LOCK WHERE bEtiqueta.it-codigo = cItem
            AND (bEtiqueta.situacao = "ATIVA" OR bEtiqueta.situacao = ?
                 OR LOOKUP(bEtiqueta.situacao, "ENCERRADA,CANCELADA,DESCARTADA") = 0
                 OR bEtiqueta.qtidade-atu = ? OR bEtiqueta.qtidade-atu <> 0
                 OR bEtiqueta.id-bag > 0)) THEN DO:
            ASSIGN pcErro = "CONTROLE_ESPECIFICO_ATIVO"
                   pcMensagem = "O item possui identidade, saldo ou vinculo especifico ainda ativo.".
            UNDO parametrizacao, LEAVE parametrizacao.
        END.
        FOR EACH bOperItem NO-LOCK WHERE bOperItem.it-codigo = cItem:
            FIND FIRST bOper NO-LOCK WHERE bOper.id-operacao = bOperItem.id-operacao NO-ERROR.
            IF NOT AVAILABLE bOper THEN DO:
                ASSIGN pcErro = "OPERACAO_CONCILIACAO_PENDENTE"
                       pcMensagem = "Uma linha especifica nao possui operacao conciliada.".
                UNDO parametrizacao, LEAVE parametrizacao.
            END.
            IF bOper.situacao = ? OR bOper.situacao <> "CANCELADA" THEN DO:
                ASSIGN pcErro = "OPERACAO_CONCILIACAO_PENDENTE"
                       pcMensagem = "Concilie as operacoes do item antes de retirar o ultimo parametro ativo.".
                UNDO parametrizacao, LEAVE parametrizacao.
            END.
        END.
    END.
    IF iDestino > 0 AND bItem.tipo-con-est <> iDestino THEN DO:
        RUN fontes/progress/contr-emb-conversao.p PERSISTENT SET hConversor.
        RUN converterControleItem IN hConversor(
            INPUT cItem, INPUT iDestino, INPUT pcLoteMigracao, INPUT pdtValidadeMigracao,
            OUTPUT TABLE ttEmbConversaoDiagnostico,
            OUTPUT iTipoOrigem, OUTPUT iTipoFinal, OUTPUT lConvertido,
            OUTPUT lConversaoOk, OUTPUT pcErro, OUTPUT pcMensagem).
        IF NOT lConversaoOk OR iTipoFinal <> iDestino THEN DO:
            IF pcErro = "" THEN ASSIGN pcErro = "TIPO_NAO_CONFIRMADO"
                pcMensagem = "A conversao nao confirmou o tipo de controle esperado.".
            UNDO parametrizacao, LEAVE parametrizacao.
        END.
    END.
    IF cAcao = "INCLUIR" THEN DO:
        ASSIGN dtAgora = NOW piIdResultante = NEXT-VALUE(CONTR_EMB_PARAM_SEQ, mgesp)
               iVersaoAntes = 0 cAntes = ? piVersaoResultante = 1
               plAtivoResultante = plAtivo.
        CREATE bParam.
        ASSIGN bParam.id-param = piIdResultante bParam.cod-estabel = cEstabel
               bParam.it-codigo = cItem bParam.cod-tipo = cTipo
               bParam.capacidade-emb = dCap bParam.un = cUn
               bParam.ativo = plAtivoResultante bParam.dt-inclusao = dtAgora
               bParam.usuario-inclusao = cUsuario bParam.dt-alteracao = dtAgora
               bParam.usuario-alteracao = cUsuario bParam.versao = 1.
    END.
    ELSE DO:
        dtAgora = NOW.
        IF cAcao = "EXCLUIR" THEN DO:
            ASSIGN cTipo = bParam.cod-tipo dCap = bParam.capacidade-emb
                   cUn = bParam.un plExcluido = YES.
            DELETE bParam.
        END.
        ELSE ASSIGN bParam.cod-tipo = cTipo bParam.capacidade-emb = dCap
                    bParam.un = cUn bParam.ativo = plAtivoResultante
                    bParam.dt-alteracao = dtAgora bParam.usuario-alteracao = cUsuario
                    bParam.versao = piVersaoResultante.
    END.

    ASSIGN pcEstabelResultante = cEstabel pcItemResultante = cItem
           pcTipoResultante = cTipo pdCapResultante = dCap
           pcUnResultante = cUn
           cDepois = STRING(piIdResultante) + "|" + STRING(piVersaoResultante) + "|" +
                     (IF plAtivoResultante THEN "1" ELSE "0") + "|" +
                     (IF plExcluido THEN "1" ELSE "0") + "|" + cEstabel + "|" + cItem + "|" +
                     cTipo + "|" + cUn + "|" + STRING(dCap)
           cResultado = cDepois cChaveRegistro = STRING(piIdResultante)
           piIdEvento = NEXT-VALUE(CONTR_EMB_EVENTO_SEQ, mgesp).
    CREATE bEvento.
    ASSIGN bEvento.id-evento = piIdEvento bEvento.origem = cOrigem
           bEvento.chave-evento = cChave bEvento.hash-chave = cHashChave
           bEvento.hash-conteudo = cHashConteudo bEvento.tipo-evento = "CADASTRO_PARAMETRO"
           bEvento.seq-ciclo = 1 bEvento.dt-evento = dtAgora bEvento.versao-contrato = 1
           bEvento.dados-evento = cDepois bEvento.situacao = "CONCLUIDO"
           bEvento.tentativas = 1 bEvento.dt-conclusao = dtAgora bEvento.resultado = cResultado
           bEvento.mensagem = "" bEvento.dt-inclusao = dtAgora bEvento.usuario-inclusao = cUsuario
           bEvento.dt-alteracao = dtAgora bEvento.usuario-alteracao = cUsuario bEvento.versao = 1.
    CREATE bAudit.
    ASSIGN bAudit.id-audit = NEXT-VALUE(CONTR_EMB_AUDIT_SEQ, mgesp)
           bAudit.id-evento = piIdEvento bAudit.nome-tabela = "CONTR_EMB_PARAM"
           bAudit.chave-registro = cChaveRegistro
           bAudit.acao = IF cAcao = "INCLUIR" THEN "INCLUSAO" ELSE IF cAcao = "EXCLUIR" THEN "EXCLUSAO" ELSE "ALTERACAO"
           bAudit.versao-ant = iVersaoAntes bAudit.versao-atu = piVersaoResultante
           bAudit.dados-ant = cAntes bAudit.dados-atu = IF plExcluido THEN ? ELSE cDepois
           bAudit.justificativa = IF cAcao = "INATIVAR" THEN "INATIVACAO" ELSE IF cAcao = "EXCLUIR" THEN "EXCLUSAO" ELSE ?
           bAudit.dt-registro = dtAgora bAudit.usuario = cUsuario.
    ASSIGN plSucesso = YES plRepeticao = NO pcErro = "" pcMensagem = "".
    CATCH eParametro AS Progress.Lang.Error:
        ASSIGN plSucesso = NO plRepeticao = NO piIdResultante = 0
               pcEstabelResultante = "" pcItemResultante = "" pcTipoResultante = ""
               pdCapResultante = 0 pcUnResultante = "" plAtivoResultante = ?
               piVersaoResultante = 0 plExcluido = NO piIdEvento = 0
               pcErro = "FALHA_PARAMETRIZACAO"
               pcMensagem = "Nao foi possivel concluir a parametrizacao; a transacao foi revertida.".
    END CATCH.
    FINALLY:
        IF VALID-HANDLE(hConversor) THEN DELETE PROCEDURE hConversor NO-ERROR.
        RELEASE bItem.
        RELEASE bParam.
        RELEASE bTipo.
        RELEASE bEvento.
        IF NOT plSucesso THEN ASSIGN plRepeticao = NO piIdResultante = 0
            pcEstabelResultante = "" pcItemResultante = "" pcTipoResultante = ""
            pdCapResultante = 0 pcUnResultante = "" plAtivoResultante = ?
            piVersaoResultante = 0 plExcluido = NO piIdEvento = 0.
    END FINALLY.
END.
END PROCEDURE.

PROCEDURE consultarTipos:
DEFINE INPUT PARAMETER plAutorizado AS LOGICAL NO-UNDO.
DEFINE INPUT PARAMETER pcCodigoDe AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcCodigoAte AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcDescricao AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcAposCodigo AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER plAtivo AS LOGICAL NO-UNDO.
DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbTipo.
DEFINE OUTPUT PARAMETER plTemMais AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcProximoCodigo AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bTipo FOR contr_emb_bag.
DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
DEFINE VARIABLE cUltimo AS CHARACTER NO-UNDO.

EMPTY TEMP-TABLE ttEmbTipo.
ASSIGN plTemMais = NO pcProximoCodigo = "" plSucesso = NO
       pcErro = "SEM_PERMISSAO" pcMensagem = "Consulta nao autorizada.".
IF plAutorizado = ? OR plAutorizado = NO THEN RETURN.

ASSIGN pcErro = "FILTRO_INVALIDO" pcMensagem = "Confira os filtros informados.".
IF pcCodigoDe = ? OR pcCodigoAte = ? OR pcDescricao = ? OR pcAposCodigo = ? THEN RETURN.
ASSIGN pcCodigoDe = CAPS(TRIM(pcCodigoDe, " "))
       pcCodigoAte = CAPS(TRIM(pcCodigoAte, " "))
       pcAposCodigo = CAPS(TRIM(pcAposCodigo, " "))
       pcDescricao = TRIM(pcDescricao, " ").
IF pcCodigoDe <> "" AND pcCodigoAte <> "" AND pcCodigoDe > pcCodigoAte THEN RETURN.
IF LENGTH(pcCodigoDe, "CHARACTER") > 3 OR LENGTH(pcCodigoAte, "CHARACTER") > 3 OR
   LENGTH(pcAposCodigo, "CHARACTER") > 3 OR LENGTH(pcDescricao, "CHARACTER") > 100 THEN RETURN.

ASSIGN pcErro = "LIMITE_INVALIDO" pcMensagem = "Informe um limite entre 1 e 100; zero usa 20.".
IF piLimite = ? OR piLimite = 0 THEN piLimite = 20.
IF piLimite < 1 OR piLimite > 100 THEN RETURN.

DO ON ERROR UNDO, THROW:
    FOR EACH bTipo NO-LOCK
        WHERE (pcCodigoDe = "" OR bTipo.cod-tipo >= pcCodigoDe)
          AND (pcCodigoAte = "" OR bTipo.cod-tipo <= pcCodigoAte)
          AND (pcAposCodigo = "" OR bTipo.cod-tipo > pcAposCodigo)
          AND (plAtivo = ? OR bTipo.ativo = plAtivo)
          AND (pcDescricao = "" OR INDEX(bTipo.desc-embalagem, pcDescricao) > 0)
        BY bTipo.cod-tipo:
        IF iQuantidade = piLimite THEN DO:
            ASSIGN plTemMais = YES pcProximoCodigo = cUltimo.
            LEAVE.
        END.
        CREATE ttEmbTipo.
        BUFFER-COPY bTipo TO ttEmbTipo.
        ASSIGN iQuantidade = iQuantidade + 1 cUltimo = bTipo.cod-tipo.
    END.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    CATCH oErro AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbTipo.
        ASSIGN plTemMais = NO pcProximoCodigo = "" plSucesso = NO
               pcErro = "FALHA_CONSULTA" pcMensagem = "Nao foi possivel concluir a consulta.".
        UNDO, THROW oErro.
    END CATCH.
END.

END PROCEDURE.

/* ET-05A / DT-066: leitura da ocorrencia, sem totais ou transicoes. */
PROCEDURE consultarBags:
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER pcEstabel AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piIdBag AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER pcFiltroLacre AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcCodTipo AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcSituacao AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pdtInicio AS DATE NO-UNDO.
DEFINE INPUT PARAMETER pdtFim AS DATE NO-UNDO.
DEFINE INPUT PARAMETER piAposId AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbBag.
DEFINE OUTPUT PARAMETER plTemMais AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piProximoId AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bBag FOR mgesp.contr_emb_bag_lacre.
DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
DEFINE VARIABLE iUltimo AS INTEGER NO-UNDO.
DEFINE VARIABLE iCaractere AS INTEGER NO-UNDO.

EMPTY TEMP-TABLE ttEmbBag.
ASSIGN plTemMais = NO piProximoId = 0 plSucesso = NO
       pcErro = "SEM_PERMISSAO" pcMensagem = "Consulta nao autorizada.".
IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN RETURN.
FOR EACH ttEmbEstabelPermitido:
    IF ttEmbEstabelPermitido.cod-estabel = ? OR
       TRIM(ttEmbEstabelPermitido.cod-estabel) = "" THEN RETURN.
END.
ASSIGN pcErro = "FILTRO_INVALIDO" pcMensagem = "Confira os filtros informados.".
IF pcEstabel = ? OR pcFiltroLacre = ? OR pcCodTipo = ? OR pcSituacao = ? THEN RETURN.
IF piIdBag = ? OR piIdBag < 0 OR piAposId = ? OR piAposId < 0 THEN RETURN.
ASSIGN pcEstabel = TRIM(pcEstabel) pcFiltroLacre = TRIM(pcFiltroLacre)
       pcCodTipo = CAPS(TRIM(pcCodTipo)) pcSituacao = CAPS(TRIM(pcSituacao)).
IF pcFiltroLacre <> "" AND (LENGTH(pcFiltroLacre) < 2 OR LENGTH(pcFiltroLacre) > 40) THEN RETURN.
IF pcCodTipo <> "" THEN DO:
    IF LENGTH(pcCodTipo) < 2 OR LENGTH(pcCodTipo) > 3 THEN RETURN.
    DO iCaractere = 1 TO LENGTH(pcCodTipo):
        IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", SUBSTRING(pcCodTipo,iCaractere,1)) = 0 THEN RETURN.
    END.
END.
IF pcSituacao <> "" AND
   LOOKUP(pcSituacao,"ABERTA,LACRADA,ENVIADA,DEVOLVIDA,ENCERRADA,CANCELADA") = 0 THEN RETURN.
IF pdtInicio <> ? AND pdtFim <> ? AND pdtInicio > pdtFim THEN RETURN.
ASSIGN pcErro = "LIMITE_INVALIDO" pcMensagem = "Informe um limite entre 1 e 20; zero usa 20.".
IF piLimite = ? THEN RETURN.
IF piLimite = 0 THEN piLimite = 20.
IF piLimite < 1 OR piLimite > 20 THEN RETURN.
IF pcEstabel <> "" AND NOT CAN-FIND(FIRST ttEmbEstabelPermitido
    WHERE ttEmbEstabelPermitido.cod-estabel = pcEstabel) THEN DO:
    ASSIGN pcErro = "SEM_PERMISSAO" pcMensagem = "Consulta nao autorizada.".
    RETURN.
END.
IF NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_MGESP_NAO_CONECTADO" pcMensagem = "Banco especifico nao conectado.".
    RETURN.
END.

DO ON ERROR UNDO, THROW:
    /* Autorizar ID antes dos demais filtros: nao revelar ocorrencia negada. */
    IF piIdBag > 0 THEN DO:
        ASSIGN pcErro = "BAG_NAO_DISPONIVEL" pcMensagem = "Bag nao disponivel para consulta.".
        IF NOT CAN-FIND(FIRST bBag WHERE bBag.id-bag = piIdBag) THEN RETURN.
        FIND FIRST bBag NO-LOCK WHERE bBag.id-bag = piIdBag NO-ERROR.
        IF ERROR-STATUS:ERROR OR ERROR-STATUS:NUM-MESSAGES > 0 THEN DO:
            ASSIGN pcErro = "FALHA_CONSULTA" pcMensagem = "Nao foi possivel concluir a consulta.".
            RETURN.
        END.
        ASSIGN pcErro = "BAG_NAO_DISPONIVEL" pcMensagem = "Bag nao disponivel para consulta.".
        IF NOT AVAILABLE bBag THEN RETURN.
        IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
            WHERE ttEmbEstabelPermitido.cod-estabel = bBag.cod-estabel) THEN RETURN.
        RELEASE bBag.
    END.
    FOR EACH bBag NO-LOCK
        WHERE bBag.id-bag > piAposId
          AND (piIdBag = 0 OR bBag.id-bag = piIdBag)
          AND (pcEstabel = "" OR bBag.cod-estabel = pcEstabel)
          AND (pcFiltroLacre = "" OR bBag.nro-lacre BEGINS pcFiltroLacre)
          AND (pcCodTipo = "" OR bBag.cod-tipo = pcCodTipo)
          AND (pcSituacao = "" OR bBag.situacao = pcSituacao)
          AND (pdtInicio = ? OR DATE(bBag.dt-inclusao) >= pdtInicio)
          AND (pdtFim = ? OR DATE(bBag.dt-inclusao) <= pdtFim)
        BY bBag.id-bag:
        IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
            WHERE ttEmbEstabelPermitido.cod-estabel = bBag.cod-estabel) THEN NEXT.
        IF iQuantidade = piLimite THEN DO:
            ASSIGN plTemMais = YES piProximoId = iUltimo.
            LEAVE.
        END.
        CREATE ttEmbBag.
        BUFFER-COPY bBag TO ttEmbBag.
        ASSIGN iQuantidade = iQuantidade + 1 iUltimo = bBag.id-bag.
    END.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    CATCH oErro AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbBag.
        ASSIGN plTemMais = NO piProximoId = 0 plSucesso = NO
               pcErro = "FALHA_CONSULTA" pcMensagem = "Nao foi possivel concluir a consulta.".
    END CATCH.
END.
END PROCEDURE.

PROCEDURE consultarConteudoBag:
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER piIdBag AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piAposId AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbEtiqueta.
DEFINE OUTPUT PARAMETER plTemMais AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piProximoId AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bBag FOR mgesp.contr_emb_bag_lacre.
DEFINE BUFFER bEtiqueta FOR mgesp.contr_emb_etiqueta.
DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
DEFINE VARIABLE iUltimo AS INTEGER NO-UNDO.

EMPTY TEMP-TABLE ttEmbEtiqueta.
ASSIGN plTemMais = NO piProximoId = 0 plSucesso = NO
       pcErro = "SEM_PERMISSAO" pcMensagem = "Consulta nao autorizada.".
IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN RETURN.
FOR EACH ttEmbEstabelPermitido:
    IF ttEmbEstabelPermitido.cod-estabel = ? OR
       TRIM(ttEmbEstabelPermitido.cod-estabel) = "" THEN RETURN.
END.
ASSIGN pcErro = "FILTRO_INVALIDO" pcMensagem = "Confira os filtros informados.".
IF piIdBag = ? OR piIdBag <= 0 OR piAposId = ? OR piAposId < 0 THEN RETURN.
ASSIGN pcErro = "LIMITE_INVALIDO" pcMensagem = "Informe um limite entre 1 e 20; zero usa 20.".
IF piLimite = ? THEN RETURN.
IF piLimite = 0 THEN piLimite = 20.
IF piLimite < 1 OR piLimite > 20 THEN RETURN.
IF NOT CONNECTED("mgesp") THEN DO:
    ASSIGN pcErro = "BANCO_MGESP_NAO_CONECTADO" pcMensagem = "Banco especifico nao conectado.".
    RETURN.
END.
DO ON ERROR UNDO, THROW:
    ASSIGN pcErro = "BAG_NAO_DISPONIVEL" pcMensagem = "Bag nao disponivel para consulta.".
    IF NOT CAN-FIND(FIRST bBag WHERE bBag.id-bag = piIdBag) THEN RETURN.
    FIND FIRST bBag NO-LOCK WHERE bBag.id-bag = piIdBag NO-ERROR.
    IF ERROR-STATUS:ERROR OR ERROR-STATUS:NUM-MESSAGES > 0 THEN DO:
        ASSIGN pcErro = "FALHA_CONSULTA" pcMensagem = "Nao foi possivel concluir a consulta.".
        RETURN.
    END.
    ASSIGN pcErro = "BAG_NAO_DISPONIVEL" pcMensagem = "Bag nao disponivel para consulta.".
    IF NOT AVAILABLE bBag THEN RETURN.
    IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
        WHERE ttEmbEstabelPermitido.cod-estabel = bBag.cod-estabel) THEN RETURN.
    FOR EACH bEtiqueta NO-LOCK
        WHERE bEtiqueta.id-bag = piIdBag AND bEtiqueta.id-etiqueta > piAposId
        BY bEtiqueta.id-etiqueta:
        IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
            WHERE ttEmbEstabelPermitido.cod-estabel = bEtiqueta.cod-estabel) THEN NEXT.
        IF iQuantidade = piLimite THEN DO:
            ASSIGN plTemMais = YES piProximoId = iUltimo.
            LEAVE.
        END.
        CREATE ttEmbEtiqueta.
        BUFFER-COPY bEtiqueta TO ttEmbEtiqueta.
        ASSIGN iQuantidade = iQuantidade + 1 iUltimo = bEtiqueta.id-etiqueta.
    END.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    CATCH oErro AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbEtiqueta.
        ASSIGN plTemMais = NO piProximoId = 0 plSucesso = NO
               pcErro = "FALHA_CONSULTA" pcMensagem = "Nao foi possivel concluir a consulta.".
    END CATCH.
END.
END PROCEDURE.

PROCEDURE consultarParametros:
DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
DEFINE INPUT PARAMETER pcEstabelDe AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcEstabelAte AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcItemDe AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcItemAte AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER plAtivo AS LOGICAL NO-UNDO.
DEFINE INPUT PARAMETER piAposId AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER piLimite AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbParametro.
DEFINE OUTPUT PARAMETER plTemMais AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER piProximoId AS INTEGER NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso AS LOGICAL NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem AS CHARACTER NO-UNDO.
DEFINE BUFFER bParametro FOR contr_emb_param.
DEFINE VARIABLE iQuantidade AS INTEGER NO-UNDO.
DEFINE VARIABLE iUltimo AS INTEGER NO-UNDO.

EMPTY TEMP-TABLE ttEmbParametro.
ASSIGN plTemMais = NO piProximoId = 0 plSucesso = NO
       pcErro = "SEM_PERMISSAO" pcMensagem = "Consulta nao autorizada.".
IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido) THEN RETURN.
FOR EACH ttEmbEstabelPermitido:
    IF ttEmbEstabelPermitido.cod-estabel = ? OR
       TRIM(ttEmbEstabelPermitido.cod-estabel) = "" THEN RETURN.
END.

ASSIGN pcErro = "FILTRO_INVALIDO" pcMensagem = "Confira os filtros informados.".
IF pcEstabelDe = ? OR pcEstabelAte = ? OR pcItemDe = ? OR pcItemAte = ? THEN RETURN.
IF pcEstabelDe <> "" AND pcEstabelAte <> "" AND pcEstabelDe > pcEstabelAte THEN RETURN.
IF pcItemDe <> "" AND pcItemAte <> "" AND pcItemDe > pcItemAte THEN RETURN.
IF piAposId = ? OR piAposId < 0 THEN RETURN.

ASSIGN pcErro = "LIMITE_INVALIDO" pcMensagem = "Informe um limite entre 1 e 100; zero usa 20.".
IF piLimite = ? OR piLimite = 0 THEN piLimite = 20.
IF piLimite < 1 OR piLimite > 100 THEN RETURN.

DO ON ERROR UNDO, THROW:
    FOR EACH bParametro NO-LOCK
        WHERE bParametro.id-param > piAposId
          AND (pcEstabelDe = "" OR bParametro.cod-estabel >= pcEstabelDe)
          AND (pcEstabelAte = "" OR bParametro.cod-estabel <= pcEstabelAte)
          AND (pcItemDe = "" OR bParametro.it-codigo >= pcItemDe)
          AND (pcItemAte = "" OR bParametro.it-codigo <= pcItemAte)
          AND (plAtivo = ? OR bParametro.ativo = plAtivo)
        BY bParametro.id-param:
        IF NOT CAN-FIND(FIRST ttEmbEstabelPermitido
            WHERE ttEmbEstabelPermitido.cod-estabel = bParametro.cod-estabel) THEN NEXT.
        IF iQuantidade = piLimite THEN DO:
            ASSIGN plTemMais = YES piProximoId = iUltimo.
            LEAVE.
        END.
        CREATE ttEmbParametro.
        BUFFER-COPY bParametro TO ttEmbParametro.
        ASSIGN iQuantidade = iQuantidade + 1 iUltimo = bParametro.id-param.
    END.
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    CATCH oErro AS Progress.Lang.Error:
        EMPTY TEMP-TABLE ttEmbParametro.
        ASSIGN plTemMais = NO piProximoId = 0 plSucesso = NO
               pcErro = "FALHA_CONSULTA" pcMensagem = "Nao foi possivel concluir a consulta.".
        UNDO, THROW oErro.
    END CATCH.
END.

END PROCEDURE.

