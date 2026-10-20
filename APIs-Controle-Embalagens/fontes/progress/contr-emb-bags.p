/* DT123/DT125/DT134: conteudo, metadados e transicoes atomicas da Bag. */
USING Progress.Json.ObjectModel.*.
BLOCK-LEVEL ON ERROR UNDO, THROW.
{fontes/progress/contr-emb.i}
DEFINE TEMP-TABLE ttSelecaoBag NO-UNDO
    FIELD etiqueta AS INTEGER
    FIELD versao AS INTEGER
    INDEX pk IS PRIMARY UNIQUE etiqueta.

FUNCTION bTexto RETURNS CHARACTER (INPUT p AS JsonObject, INPUT nome AS CHARACTER, INPUT padrao AS CHARACTER):
    DEFINE VARIABLE c AS CHARACTER NO-UNDO.
    IF NOT p:Has(nome) THEN RETURN padrao.
    c = p:GetCharacter(nome) NO-ERROR.
    IF ERROR-STATUS:ERROR OR c = ? THEN RETURN ?.
    RETURN TRIM(c).
END FUNCTION.
FUNCTION bNumero RETURNS INTEGER (INPUT p AS JsonObject, INPUT nome AS CHARACTER):
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    n = p:GetInteger(nome) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN RETURN ?.
    RETURN n.
END FUNCTION.
FUNCTION bId RETURNS INTEGER (INPUT c AS CHARACTER):
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    IF c = ? OR c = "" OR LENGTH(c) > 10 THEN RETURN ?.
    DO i = 1 TO LENGTH(c):
        IF INDEX("0123456789",SUBSTRING(c,i,1)) = 0 THEN RETURN ?.
    END.
    n = INTEGER(c) NO-ERROR.
    IF ERROR-STATUS:ERROR OR n = ? OR n <= 0 OR STRING(n) <> c THEN RETURN ?.
    RETURN n.
END FUNCTION.
FUNCTION bParte RETURNS CHARACTER (INPUT c AS CHARACTER):
    RETURN STRING(LENGTH(c)) + ":" + c.
END FUNCTION.
FUNCTION bFalha RETURNS JsonObject (INPUT codigo AS CHARACTER):
    DEFINE VARIABLE o AS JsonObject NO-UNDO.
    o = NEW JsonObject().
    o:Add("sucesso",NO). o:Add("codigoErro",codigo).
    o:Add("mensagem","Confira contexto, versoes e elegibilidade da Bag e das embalagens.").
    RETURN o.
END FUNCTION.
FUNCTION bPermissao RETURNS LOGICAL (INPUT estab AS CHARACTER):
    DEFINE BUFFER bPerm FOR ttEmbEstabelPermitido.
    IF estab = ? OR estab = "" THEN RETURN NO.
    IF NOT CAN-FIND(FIRST bPerm) THEN RETURN NO.
    FOR EACH bPerm:
        IF bPerm.cod-estabel = ? OR TRIM(bPerm.cod-estabel) = "" THEN RETURN NO.
    END.
    RETURN CAN-FIND(FIRST bPerm WHERE bPerm.cod-estabel = estab).
END FUNCTION.

/* Fotografia minima: somente dados operacionais, nunca o pedido integral. */
FUNCTION bFoto RETURNS JsonObject (INPUT estado AS CHARACTER, INPUT v AS INTEGER,
    INPUT lacre AS CHARACTER, INPUT dtLacre AS DATETIME-TZ, INPUT destino AS CHARACTER,
    INPUT motorista AS CHARACTER, INPUT dtEnvio AS DATETIME-TZ):
    DEFINE VARIABLE o AS JsonObject NO-UNDO.
    o = NEW JsonObject().
    o:Add("situacao",estado). o:Add("versao",v). o:Add("nroLacre",lacre).
    o:Add("dtLacre",dtLacre). o:Add("destino",destino).
    o:Add("motorista",motorista). o:Add("dtEnvio",dtEnvio).
    RETURN o.
END FUNCTION.

/* Consulta somente o resultado original; nao reexecuta regra de negocio. */
PROCEDURE repetirBag:
    DEFINE INPUT PARAMETER chave AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER identidade AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER conteudo AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER estab AS CHARACTER NO-UNDO.
    DEFINE OUTPUT PARAMETER encontrado AS LOGICAL NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    DEFINE BUFFER bEv FOR mgesp.contr_emb_evento.
    DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
    DEFINE VARIABLE texto AS LONGCHAR NO-UNDO.
    FIX-CODEPAGE(texto) = "UTF-8".
    encontrado = NO.
    FIND FIRST bEv NO-LOCK WHERE bEv.hash-chave = chave NO-ERROR.
    IF NOT AVAILABLE bEv THEN RETURN.
    encontrado = YES.
    resposta = bFalha("CONFLITO_IDEMPOTENCIA").
    IF bEv.origem <> "MANUT_BAG" OR bEv.chave-evento <> identidade OR
       bEv.hash-conteudo <> conteudo OR bEv.cod-estabel <> estab THEN RETURN.
    resposta = bFalha("EVENTO_NAO_CONCLUIDO").
    IF bEv.situacao <> "CONCLUIDO" OR bEv.resultado = ? THEN RETURN.
    DO ON ERROR UNDO, THROW:
        ASSIGN parser = NEW ObjectModelParser() texto = bEv.resultado
            resposta = CAST(parser:Parse(texto),JsonObject).
        resposta:Set("repeticao",YES).
        CATCH falha AS Progress.Lang.Error:
            resposta = bFalha("FALHA_BAG").
        END CATCH.
    END.
END PROCEDURE.

PROCEDURE executarComandoBag:
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER p AS JsonObject NO-UNDO.
    DEFINE INPUT PARAMETER acao AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    DEFINE BUFFER bBag FOR mgesp.contr_emb_bag_lacre.
    DEFINE BUFFER bTipo FOR mgesp.contr_emb_bag.
    DEFINE BUFFER bEt FOR mgesp.contr_emb_etiqueta.
    DEFINE BUFFER bGer FOR mgesp.contr_emb_evento.
    DEFINE BUFFER bEv FOR mgesp.contr_emb_evento.
    DEFINE BUFFER bAu FOR mgesp.contr_emb_audit.
    DEFINE BUFFER bEst FOR mgcad.estabelec.
    DEFINE VARIABLE usuario AS CHARACTER NO-UNDO.
    DEFINE VARIABLE estab AS CHARACTER NO-UNDO.
    DEFINE VARIABLE tipo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE chave AS CHARACTER NO-UNDO.
    DEFINE VARIABLE motivo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE identidade AS CHARACTER NO-UNDO.
    DEFINE VARIABLE canonico AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hashChave AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hashConteudo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE erro AS CHARACTER NO-UNDO.
    DEFINE VARIABLE modulo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hRastro AS HANDLE NO-UNDO.
    DEFINE VARIABLE lista AS JsonArray NO-UNDO.
    DEFINE VARIABLE linha AS JsonObject NO-UNDO.
    DEFINE VARIABLE texto AS LONGCHAR NO-UNDO.
    DEFINE VARIABLE idBag AS INTEGER NO-UNDO.
    DEFINE VARIABLE versao AS INTEGER NO-UNDO.
    DEFINE VARIABLE anterior AS INTEGER NO-UNDO.
    DEFINE VARIABLE etiqueta AS INTEGER NO-UNDO.
    DEFINE VARIABLE ve AS INTEGER NO-UNDO.
    DEFINE VARIABLE i AS INTEGER NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE movimento AS INTEGER NO-UNDO.
    DEFINE VARIABLE novaVersao AS INTEGER NO-UNDO.
    DEFINE VARIABLE repeticao AS LOGICAL NO-UNDO.
    DEFINE VARIABLE sucesso AS LOGICAL NO-UNDO.
    DEFINE VARIABLE mensagem AS CHARACTER NO-UNDO.
    DEFINE VARIABLE agora AS DATETIME-TZ NO-UNDO.
    DEFINE VARIABLE transicao AS LOGICAL NO-UNDO.
    DEFINE VARIABLE lacre AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE destino AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE motorista AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE situacaoAnterior AS CHARACTER NO-UNDO.
    DEFINE VARIABLE conteudoBag AS LOGICAL NO-UNDO.
    DEFINE VARIABLE temDestino AS LOGICAL NO-UNDO.
    DEFINE VARIABLE temMotorista AS LOGICAL NO-UNDO.
    DEFINE VARIABLE temLacre AS LOGICAL NO-UNDO.
    DEFINE VARIABLE nomes AS CHARACTER EXTENT NO-UNDO.
    DEFINE VARIABLE campo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE valorAntes AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE valorDepois AS CHARACTER CASE-SENSITIVE NO-UNDO.
    DEFINE VARIABLE antes AS JsonObject NO-UNDO.
    DEFINE VARIABLE depois AS JsonObject NO-UNDO.
    DEFINE VARIABLE fotografia AS JsonObject NO-UNDO.
    DEFINE VARIABLE auditAntes AS JsonObject NO-UNDO.
    DEFINE VARIABLE auditDepois AS JsonObject NO-UNDO.
    DEFINE VARIABLE camposAlterados AS INTEGER NO-UNDO.
    FIX-CODEPAGE(texto) = "UTF-8".
    EMPTY TEMP-TABLE ttSelecaoBag.
    resposta = bFalha("COMANDO_INVALIDO").
    IF p = ? OR acao = ? OR LOOKUP(acao,"ABRIR,INCLUIR,RETIRAR,LACRAR,ENVIAR,EDITAR,CANCELAR,REABRIR") = 0 THEN RETURN.
    ASSIGN usuario = bTexto(p,"usuario","") estab = bTexto(p,"codEstabel","")
        chave = bTexto(p,"chaveIdempotente","") motivo = bTexto(p,"justificativa","").
    IF usuario = ? OR usuario = "" OR LENGTH(usuario) > 128 OR
       chave = ? OR LENGTH(chave) < 1 OR LENGTH(chave) > 64 OR
       motivo = ? OR LENGTH(motivo) > 1000 THEN RETURN.
    DO i = 1 TO LENGTH(chave):
        IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-",SUBSTRING(chave,i,1)) = 0 THEN RETURN.
    END.
    IF NOT bPermissao(estab) THEN DO: resposta = bFalha("SEM_PERMISSAO"). RETURN. END.
    ASSIGN conteudoBag = LOOKUP(acao,"INCLUIR,RETIRAR") > 0
        temDestino = p:Has("destino") temMotorista = p:Has("motorista") temLacre = p:Has("nroLacre").
    IF acao = "EDITAR" THEN DO:
        nomes = p:GetNames().
        DO i = 1 TO EXTENT(nomes):
            IF LOOKUP(nomes[i],"usuario,estabelecimentosPermitidos,codEstabel,idBag,versao,chaveIdempotente,justificativa,acao,destino,motorista,nroLacre") = 0 THEN DO:
                resposta = bFalha("PARAMETRO_NAO_PERMITIDO"). RETURN.
            END.
        END.
        IF (NOT temDestino AND NOT temMotorista AND NOT temLacre) OR
            (p:Has("acao") AND bTexto(p,"acao","") <> "EDITAR") THEN RETURN.
    END.
    IF LOOKUP(acao,"EDITAR,CANCELAR,REABRIR,ABRIR") > 0 AND p:Has("etiquetas") THEN RETURN.
    IF acao = "ABRIR" AND temLacre THEN DO: resposta = bFalha("LACRE_NAO_PERMITIDO"). RETURN. END.
    IF LOOKUP(acao,"CANCELAR,REABRIR") > 0 THEN DO:
        IF temDestino OR temMotorista OR temLacre OR p:Has("codTipo") THEN DO:
            resposta = bFalha("PARAMETRO_NAO_PERMITIDO"). RETURN.
        END.
        IF motivo = "" THEN DO: resposta = bFalha("JUSTIFICATIVA_OBRIGATORIA"). RETURN. END.
    END.
    IF LOOKUP(acao,"ABRIR,EDITAR") > 0 THEN DO:
        IF temDestino THEN DO:
            destino = bTexto(p,"destino","").
            IF destino = ? OR LENGTH(destino) > 80 THEN DO: resposta = bFalha("DESTINO_INVALIDO"). RETURN. END.
        END.
        IF temMotorista THEN DO:
            motorista = bTexto(p,"motorista","").
            IF motorista = ? OR LENGTH(motorista) > 100 THEN DO: resposta = bFalha("MOTORISTA_INVALIDO"). RETURN. END.
        END.
        IF temLacre THEN DO:
            lacre = bTexto(p,"nroLacre","").
            IF lacre = ? OR LENGTH(lacre) < 1 OR LENGTH(lacre) > 40 THEN DO: resposta = bFalha("LACRE_INVALIDO"). RETURN. END.
        END.
    END.
    transicao = LOOKUP(acao,"LACRAR,ENVIAR") > 0.
    IF transicao THEN DO:
        IF p:Has("etiquetas") THEN RETURN.
        IF acao = "LACRAR" THEN DO:
            lacre = bTexto(p,"nroLacre","").
            IF lacre = ? OR LENGTH(lacre) < 1 OR LENGTH(lacre) > 40 THEN DO:
                resposta = bFalha("LACRE_INVALIDO"). RETURN.
            END.
        END.
        ELSE DO:
            ASSIGN destino = bTexto(p,"destino","") motorista = bTexto(p,"motorista","").
            IF destino = ? OR LENGTH(destino) < 1 OR LENGTH(destino) > 80 THEN DO:
                resposta = bFalha("DESTINO_INVALIDO"). RETURN.
            END.
            IF motorista = ? OR LENGTH(motorista) < 1 OR LENGTH(motorista) > 100 THEN DO:
                resposta = bFalha("MOTORISTA_INVALIDO"). RETURN.
            END.
        END.
    END.
    IF acao = "ABRIR" THEN DO:
        tipo = bTexto(p,"codTipo","").
        IF tipo = ? OR LENGTH(tipo) < 2 OR LENGTH(tipo) > 3 THEN RETURN.
        DO i = 1 TO LENGTH(tipo):
            IF INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",SUBSTRING(tipo,i,1)) = 0 THEN RETURN.
        END.
        ASSIGN tipo = CAPS(tipo) idBag = 0 versao = 0.
    END.
    ELSE DO:
        ASSIGN idBag = bId(bTexto(p,"idBag","")) versao = bNumero(p,"versao").
        IF idBag = ? OR versao = ? OR versao <= 0 THEN RETURN.
        IF conteudoBag THEN DO:
            lista = p:GetJsonArray("etiquetas") NO-ERROR.
            IF ERROR-STATUS:ERROR OR lista = ? THEN RETURN.
            IF lista:Length < 1 OR lista:Length > 100 THEN RETURN.
            DO i = 1 TO lista:Length:
                linha = lista:GetJsonObject(i) NO-ERROR.
                IF ERROR-STATUS:ERROR OR linha = ? THEN RETURN.
                ASSIGN etiqueta = bId(bTexto(linha,"idEtiqueta","")) ve = bNumero(linha,"versao").
                IF etiqueta = ? OR ve = ? OR ve <= 0 THEN RETURN.
                IF CAN-FIND(FIRST ttSelecaoBag WHERE ttSelecaoBag.etiqueta = etiqueta) THEN RETURN.
                CREATE ttSelecaoBag.
                ASSIGN ttSelecaoBag.etiqueta = etiqueta ttSelecaoBag.versao = ve n = n + 1.
            END.
        END. /* selecao de conteudo */
    END.
    ASSIGN identidade = bParte(estab) + bParte(usuario) + bParte(chave)
        canonico = identidade + bParte(acao) + bParte(STRING(idBag)) + bParte(STRING(versao)) + bParte(tipo) + bParte(motivo).
    IF transicao THEN canonico = canonico + bParte(lacre) + bParte(destino) + bParte(motorista).
    /* Mantem hashes DT123/125 antigos quando nenhum campo novo foi enviado. */
    IF acao = "EDITAR" OR (acao = "ABRIR" AND (temDestino OR temMotorista)) THEN
        canonico = canonico + bParte("DT134") + bParte(IF temDestino THEN "1" ELSE "0") + bParte(destino)
            + bParte(IF temMotorista THEN "1" ELSE "0") + bParte(motorista) + bParte(IF temLacre THEN "1" ELSE "0") + bParte(lacre).
    /* Autorizar entidades antes de devolver resultado original, sem exigir
       versao/vinculo atuais para o retry de um comando ja concluido. */
    IF acao <> "ABRIR" THEN DO:
        FIND FIRST bBag NO-LOCK WHERE bBag.id-bag = idBag AND bBag.cod-estabel = estab NO-ERROR.
        IF NOT AVAILABLE bBag THEN DO: resposta = bFalha("BAG_NAO_DISPONIVEL"). RETURN. END.
        FOR EACH ttSelecaoBag BY ttSelecaoBag.etiqueta:
            FIND FIRST bEt NO-LOCK WHERE bEt.id-etiqueta = ttSelecaoBag.etiqueta NO-ERROR.
            IF NOT AVAILABLE bEt THEN DO: resposta = bFalha("ETIQUETA_NAO_ELEGIVEL"). RETURN. END.
            IF NOT bPermissao(bEt.cod-estabel) THEN DO: resposta = bFalha("SEM_PERMISSAO"). RETURN. END.
            canonico = canonico + bParte(STRING(ttSelecaoBag.etiqueta)) + bParte(STRING(ttSelecaoBag.versao)).
        END.
    END.
    ASSIGN hashChave = HEX-ENCODE(MESSAGE-DIGEST("SHA-256","MANUT_BAG|" + identidade))
        hashConteudo = HEX-ENCODE(MESSAGE-DIGEST("SHA-256",canonico)).
    RUN repetirBag(hashChave,identidade,hashConteudo,estab,OUTPUT repeticao,OUTPUT resposta).
    IF repeticao THEN RETURN.
    comando:
    DO TRANSACTION ON ERROR UNDO, THROW:
        agora = NOW.
        /* Indice unico arbitra solicitacoes simultaneas com a mesma chave. */
        CREATE bEv.
        ASSIGN bEv.id-evento = NEXT-VALUE(CONTR_EMB_EVENTO_ID_SEQ,mgesp)
            bEv.origem = "MANUT_BAG" bEv.chave-evento = identidade bEv.hash-chave = hashChave
            bEv.hash-conteudo = hashConteudo bEv.tipo-evento = IF acao = "ABRIR" THEN "ABERTURA_BAG" ELSE IF acao = "INCLUIR" THEN "INCLUSAO_BAG" ELSE IF acao = "RETIRAR" THEN "RETIRADA_BAG" ELSE IF acao = "LACRAR" THEN "LACRACAO_BAG" ELSE IF acao = "ENVIAR" THEN "ENVIO_BAG" ELSE IF acao = "EDITAR" THEN "EDICAO_BAG" ELSE IF acao = "CANCELAR" THEN "CANCELAMENTO_BAG" ELSE "REABERTURA_BAG"
            bEv.id-operacao = ? bEv.id-evento-origem = ? bEv.seq-ciclo = 1
            bEv.dt-evento = agora bEv.versao-contrato = 1 bEv.cod-estabel = estab
            bEv.tipo-docto = ? bEv.chave-docto = ? bEv.hash-docto = ? bEv.cod-emitente = ?
            bEv.cgc-emitente = ? bEv.serie = ? bEv.nro-docto = ? bEv.chave-acesso = ?
            bEv.nat-operacao = ? bEv.dt-emissao = ? bEv.situacao = "PROCESSANDO"
            bEv.tentativas = 1 bEv.dt-proxima-tent = ? bEv.token-execucao = ? bEv.dt-expira-exec = ?
            bEv.dt-conclusao = ? bEv.mensagem = "" bEv.dt-inclusao = agora bEv.dt-alteracao = agora
            bEv.usuario-inclusao = usuario bEv.usuario-alteracao = usuario bEv.versao = 1 bEv.dados-evento = "".
        VALIDATE bEv.
        IF acao = "ABRIR" THEN DO:
            IF NOT CAN-FIND(FIRST bEst WHERE bEst.cod-estabel = estab) THEN
                UNDO comando, THROW NEW Progress.Lang.AppError("ESTABELECIMENTO_NAO_ENCONTRADO",0).
            FIND FIRST bTipo WHERE bTipo.cod-tipo = tipo SHARE-LOCK NO-WAIT NO-ERROR.
            IF LOCKED bTipo THEN UNDO comando, THROW NEW Progress.Lang.AppError("TIPO_BLOQUEADO",0).
            IF NOT AVAILABLE bTipo THEN UNDO comando, THROW NEW Progress.Lang.AppError("TIPO_NAO_ENCONTRADO",0).
            IF bTipo.ativo = ? OR bTipo.ativo <> YES THEN UNDO comando, THROW NEW Progress.Lang.AppError("TIPO_INATIVO",0).
            CREATE bBag.
            ASSIGN idBag = NEXT-VALUE(CONTR_EMB_BAG_LACRE_ID_SEQ,mgesp)
                bBag.id-bag = idBag bBag.cod-tipo = tipo bBag.cod-estabel = estab bBag.cod-depos = ?
                bBag.nro-lacre = ? bBag.situacao = "ABERTA" bBag.dt-lacre = ? bBag.dt-envio = ? bBag.dt-devolucao = ?
                bBag.tipo-destino = ? bBag.cod-estabel-dest = ? bBag.cod-emitente-dest = ?
                bBag.origem-local-dest = ? bBag.cod-local-dest = ? bBag.motorista = ? bBag.id-bag-anterior = ?
                bBag.dt-inclusao = agora bBag.usuario-inclusao = usuario bBag.dt-alteracao = agora
                bBag.usuario-alteracao = usuario bBag.versao = 1 anterior = 0.
        END.
        ELSE DO:
            FIND FIRST bBag WHERE bBag.id-bag = idBag EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
            IF LOCKED bBag THEN UNDO comando, THROW NEW Progress.Lang.AppError("BAG_BLOQUEADA",0).
            IF NOT AVAILABLE bBag THEN UNDO comando, THROW NEW Progress.Lang.AppError("BAG_NAO_DISPONIVEL",0).
            IF bBag.cod-estabel = ? OR bBag.cod-estabel <> estab THEN UNDO comando, THROW NEW Progress.Lang.AppError("BAG_NAO_DISPONIVEL",0).
            IF bBag.versao = ? OR bBag.versao <> versao THEN UNDO comando, THROW NEW Progress.Lang.AppError("CONFLITO_VERSAO",0).
            IF acao = "ENVIAR" THEN DO:
                IF bBag.situacao = ? OR bBag.situacao <> "LACRADA" THEN UNDO comando, THROW NEW Progress.Lang.AppError("BAG_NAO_LACRADA",0).
                IF bBag.nro-lacre = ? OR TRIM(bBag.nro-lacre) = "" THEN UNDO comando, THROW NEW Progress.Lang.AppError("LACRE_INVALIDO",0).
            END.
            ELSE IF acao = "REABRIR" THEN DO:
                IF bBag.situacao = ? OR bBag.situacao <> "LACRADA" THEN UNDO comando, THROW NEW Progress.Lang.AppError("BAG_NAO_LACRADA",0).
            END.
            ELSE IF acao = "EDITAR" THEN DO:
                IF bBag.situacao = ? OR LOOKUP(bBag.situacao,"ABERTA,LACRADA") = 0 THEN UNDO comando, THROW NEW Progress.Lang.AppError("BAG_NAO_EDITAVEL",0).
                IF bBag.situacao = "ABERTA" AND temLacre THEN UNDO comando, THROW NEW Progress.Lang.AppError("LACRE_NAO_PERMITIDO",0).
                IF temLacre AND lacre <> bBag.nro-lacre AND motivo = "" THEN UNDO comando, THROW NEW Progress.Lang.AppError("JUSTIFICATIVA_OBRIGATORIA",0).
            END.
            ELSE IF bBag.situacao = ? OR bBag.situacao <> "ABERTA" THEN UNDO comando, THROW NEW Progress.Lang.AppError("BAG_NAO_ABERTA",0).
            situacaoAnterior = bBag.situacao.
            antes = bFoto(bBag.situacao,bBag.versao,bBag.nro-lacre,bBag.dt-lacre,bBag.cod-local-dest,bBag.motorista,bBag.dt-envio).
            /* O evento recebe o lacre vigente ANTES de REABRIR limpar a projecao. */
            fotografia = NEW JsonObject().
            fotografia:Add("contrato","DT134"). fotografia:Add("idBag",STRING(idBag)).
            fotografia:Add("acao",acao). fotografia:Add("anterior",antes).
            texto = fotografia:GetJsonText(). bEv.dados-evento = STRING(texto).
            IF transicao THEN DO:
                /* Conteudo integral, obtido apos serializar comandos pela Bag. */
                FOR EACH bEt NO-LOCK WHERE bEt.id-bag = idBag BY bEt.id-etiqueta:
                    CREATE ttSelecaoBag.
                    ASSIGN ttSelecaoBag.etiqueta = bEt.id-etiqueta ttSelecaoBag.versao = bEt.versao n = n + 1.
                END.
                IF n = 0 THEN UNDO comando, THROW NEW Progress.Lang.AppError("BAG_VAZIA",0).
            END.
            IF NOT transicao AND NOT conteudoBag THEN DO:
                FOR EACH bEt NO-LOCK WHERE bEt.id-bag = idBag: n = n + 1. END.
                IF acao = "CANCELAR" AND n > 0 THEN UNDO comando, THROW NEW Progress.Lang.AppError("BAG_NAO_VAZIA",0).
            END.
            IF acao = "RETIRAR" AND motivo = "" THEN UNDO comando, THROW NEW Progress.Lang.AppError("JUSTIFICATIVA_OBRIGATORIA",0).
            ASSIGN tipo = bBag.cod-tipo anterior = bBag.versao i = 0.
            IF transicao OR conteudoBag THEN DO:
                modulo = SEARCH("esp/api/v1/contr-emb-rastreio.r").
                IF modulo = ? THEN UNDO comando, THROW NEW Progress.Lang.AppError("RASTREIO_NAO_LOCALIZADO",0).
                RUN VALUE(modulo) PERSISTENT SET hRastro.
            END.
            FOR EACH ttSelecaoBag BY ttSelecaoBag.etiqueta:
                FIND FIRST bEt WHERE bEt.id-etiqueta = ttSelecaoBag.etiqueta EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
                IF LOCKED bEt THEN UNDO comando, THROW NEW Progress.Lang.AppError("ETIQUETA_BLOQUEADA",0).
                IF NOT AVAILABLE bEt THEN UNDO comando, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_ELEGIVEL",0).
                IF NOT bPermissao(bEt.cod-estabel) THEN UNDO comando, THROW NEW Progress.Lang.AppError("SEM_PERMISSAO",0).
                IF bEt.versao = ? OR bEt.versao <> ttSelecaoBag.versao THEN UNDO comando, THROW NEW Progress.Lang.AppError("CONFLITO_VERSAO",0).
                IF bEt.cod-estabel = ? OR bEt.cod-estabel <> estab OR bEt.tipo-controle = ? OR bEt.tipo-controle <> "EMBALAGEM" OR
                   bEt.situacao = ? OR bEt.situacao <> "ATIVA" OR bEt.tipo-local = ? OR bEt.tipo-local <> "ESTAB" OR
                   bEt.qtidade-atu = ? OR bEt.qtidade-atu <> 0 OR tipo = ? OR bEt.cod-tipo = ? OR
                   bEt.cod-tipo <> tipo OR bEt.id-movto-ult = ? OR bEt.id-movto-ult <= 0 THEN
                    UNDO comando, THROW NEW Progress.Lang.AppError("ETIQUETA_NAO_ELEGIVEL",0).
                FIND FIRST bGer NO-LOCK WHERE bGer.id-evento = bEt.id-evento-geracao NO-ERROR.
                IF NOT AVAILABLE bGer THEN UNDO comando, THROW NEW Progress.Lang.AppError("GERACAO_NAO_CONFIRMADA",0).
                IF bGer.situacao = ? OR bGer.situacao <> "CONCLUIDO" THEN UNDO comando, THROW NEW Progress.Lang.AppError("GERACAO_NAO_CONFIRMADA",0).
                IF acao = "INCLUIR" AND bEt.id-bag <> ? THEN UNDO comando, THROW NEW Progress.Lang.AppError("ETIQUETA_JA_VINCULADA",0).
                IF acao <> "INCLUIR" AND (bEt.id-bag = ? OR bEt.id-bag <> idBag) THEN UNDO comando, THROW NEW Progress.Lang.AppError("VINCULO_DIVERGENTE",0).
                IF acao = "LACRAR" THEN NEXT.
                EMPTY TEMP-TABLE ttEmbMovimentoComando.
                CREATE ttEmbMovimentoComando.
                ASSIGN i = i + 1 ttEmbMovimentoComando.id-evento = bEv.id-evento
                    ttEmbMovimentoComando.sequencia = i ttEmbMovimentoComando.id-etiqueta = bEt.id-etiqueta
                    ttEmbMovimentoComando.id-item-evento = 0 ttEmbMovimentoComando.id-item-oper = 0
                    ttEmbMovimentoComando.id-movto-origem = 0
                    ttEmbMovimentoComando.origem-movto-erp = ? ttEmbMovimentoComando.chave-movto-erp = ?
                    ttEmbMovimentoComando.versao-etiqueta-esperada = bEt.versao
                    ttEmbMovimentoComando.id-movto-ant-esperado = bEt.id-movto-ult
                    ttEmbMovimentoComando.id-bag-relac = idBag
                    ttEmbMovimentoComando.id-bag-destino = IF acao = "RETIRAR" THEN 0 ELSE idBag
                    ttEmbMovimentoComando.tipo-movto = IF acao = "ENVIAR" THEN "DESCARTE_ENVIO_BAG" ELSE bEv.tipo-evento ttEmbMovimentoComando.dt-movto = agora
                    ttEmbMovimentoComando.quantidade = 0 ttEmbMovimentoComando.qtidade-atu = 0
                    ttEmbMovimentoComando.un = bEt.un ttEmbMovimentoComando.situacao-atu = IF acao = "ENVIAR" THEN "DESCARTADA" ELSE bEt.situacao
                    ttEmbMovimentoComando.cod-estabel-dest = bEt.cod-estabel ttEmbMovimentoComando.cod-depos-dest = bEt.cod-depos
                    ttEmbMovimentoComando.cod-localiz-dest = bEt.cod-localiz ttEmbMovimentoComando.tipo-local-dest = bEt.tipo-local
                    ttEmbMovimentoComando.cod-emitente-dest = bEt.cod-emitente-posse
                    ttEmbMovimentoComando.origem-local-ext-dest = bEt.origem-local-ext
                    ttEmbMovimentoComando.cod-local-ext-dest = bEt.cod-local-ext
                    ttEmbMovimentoComando.justificativa = motivo ttEmbMovimentoComando.usuario = usuario.
                RUN aplicarMovimento IN hRastro(INPUT TABLE ttEmbMovimentoComando,YES,
                    OUTPUT sucesso,OUTPUT repeticao,OUTPUT movimento,OUTPUT novaVersao,OUTPUT erro,OUTPUT mensagem).
                IF NOT sucesso THEN UNDO comando, THROW NEW Progress.Lang.AppError(erro,0).
            END.
            IF acao = "LACRAR" THEN ASSIGN bBag.nro-lacre = lacre bBag.dt-lacre = agora bBag.situacao = "LACRADA".
            IF acao = "ENVIAR" THEN ASSIGN bBag.tipo-destino = "LOCAL" bBag.origem-local-dest = "MANUAL"
                bBag.cod-local-dest = destino bBag.motorista = motorista bBag.situacao = "ENVIADA" bBag.dt-envio = agora
                bBag.cod-estabel-dest = ? bBag.cod-emitente-dest = ?.
            IF acao = "REABRIR" THEN ASSIGN bBag.situacao = "ABERTA" bBag.nro-lacre = ? bBag.dt-lacre = ?.
            IF acao = "CANCELAR" THEN bBag.situacao = "CANCELADA".
            ASSIGN bBag.versao = bBag.versao + 1 bBag.dt-alteracao = agora bBag.usuario-alteracao = usuario.
        END.
        IF LOOKUP(acao,"ABRIR,EDITAR") > 0 THEN DO:
            IF temDestino THEN ASSIGN bBag.cod-local-dest = IF destino = "" THEN ? ELSE destino
                bBag.tipo-destino = IF destino = "" THEN ? ELSE "LOCAL"
                bBag.origem-local-dest = IF destino = "" THEN ? ELSE "MANUAL"
                bBag.cod-estabel-dest = ? bBag.cod-emitente-dest = ?.
            IF temMotorista THEN bBag.motorista = IF motorista = "" THEN ? ELSE motorista.
            IF acao = "EDITAR" AND temLacre THEN bBag.nro-lacre = lacre.
        END.
        depois = bFoto(bBag.situacao,bBag.versao,bBag.nro-lacre,bBag.dt-lacre,bBag.cod-local-dest,bBag.motorista,bBag.dt-envio).
        auditAntes = NEW JsonObject(). auditDepois = NEW JsonObject().
        DO i = 1 TO 6:
            campo = ENTRY(i,"situacao,nroLacre,dtLacre,destino,motorista,dtEnvio").
            valorDepois = bTexto(depois,campo,"").
            valorAntes = IF anterior = 0 THEN ? ELSE bTexto(antes,campo,"").
            IF anterior = 0 OR valorAntes <> valorDepois THEN DO:
                auditAntes:Add(campo,valorAntes). auditDepois:Add(campo,valorDepois).
                camposAlterados = camposAlterados + 1.
            END.
        END.
        IF acao = "EDITAR" AND camposAlterados = 0 THEN UNDO comando, THROW NEW Progress.Lang.AppError("SEM_ALTERACAO",0).
        CREATE bAu.
        ASSIGN bAu.id-audit = NEXT-VALUE(CONTR_EMB_AUDIT_ID_SEQ,mgesp) bAu.id-evento = bEv.id-evento
            bAu.nome-tabela = "contr_emb_bag_lacre" bAu.chave-registro = STRING(idBag)
            bAu.acao = IF acao = "ABRIR" THEN "INCLUSAO" ELSE "ALTERACAO"
            bAu.versao-ant = anterior bAu.versao-atu = bBag.versao
            bAu.dados-ant = IF anterior = 0 THEN "" ELSE STRING(auditAntes:GetJsonText())
            bAu.dados-atu = "DT123|" + acao + "|" + STRING(n) + "|" + tipo + "|" + STRING(auditDepois:GetJsonText())
            bAu.justificativa = motivo bAu.dt-registro = agora bAu.usuario = usuario.
        resposta = NEW JsonObject().
        resposta:Add("sucesso",YES). resposta:Add("codigoErro",""). resposta:Add("mensagem","").
        resposta:Add("repeticao",NO). resposta:Add("idBag",STRING(idBag)). resposta:Add("versao",bBag.versao).
        resposta:Add("idEvento",STRING(bEv.id-evento)). resposta:Add("idRegistro",STRING(bAu.id-audit)).
        resposta:Add("acao",acao). resposta:Add("qtdEtiquetas",n).
        IF transicao OR LOOKUP(acao,"ABRIR,EDITAR,CANCELAR,REABRIR") > 0 THEN DO:
            resposta:Add("situacao",bBag.situacao). resposta:Add("nroLacre",bBag.nro-lacre).
            resposta:Add("destino",bBag.cod-local-dest). resposta:Add("motorista",bBag.motorista).
            resposta:Add("dtLacre",bBag.dt-lacre). resposta:Add("dtEnvio",bBag.dt-envio).
        END.
        IF anterior > 0 THEN resposta:Add("estadoAnterior",antes).
        texto = resposta:GetJsonText().
        IF fotografia = ? THEN DO:
            fotografia = NEW JsonObject(). fotografia:Add("contrato","DT134").
            fotografia:Add("idBag",STRING(idBag)). fotografia:Add("acao",acao).
        END.
        fotografia:Add("atual",depois).
        IF LENGTH(texto,"RAW") > 4000 OR LENGTH(fotografia:GetJsonText(),"RAW") > 4000 OR
            LENGTH(bAu.dados-ant,"RAW") > 4000 OR LENGTH(bAu.dados-atu,"RAW") > 4000 THEN
            UNDO comando, THROW NEW Progress.Lang.AppError("FALHA_BAG",0).
        ASSIGN bEv.resultado = STRING(texto) bEv.dados-evento = STRING(fotografia:GetJsonText())
            bEv.situacao = "CONCLUIDO" bEv.dt-conclusao = agora.
        /* Resultado imutavel conserva tambem os textos manuais para o historico. */
        VALIDATE bBag. VALIDATE bAu. VALIDATE bEv.
        CATCH falha AS Progress.Lang.Error:
            erro = IF falha:NumMessages > 0 THEN falha:GetMessage(1) ELSE "FALHA_BAG".
            IF LOOKUP(erro,"ESTABELECIMENTO_NAO_ENCONTRADO,TIPO_NAO_ENCONTRADO,TIPO_INATIVO,TIPO_BLOQUEADO,BAG_NAO_DISPONIVEL,BAG_BLOQUEADA,BAG_NAO_ABERTA,ETIQUETA_BLOQUEADA,CONFLITO_VERSAO,SEM_PERMISSAO,JUSTIFICATIVA_OBRIGATORIA,ETIQUETA_NAO_ELEGIVEL,GERACAO_NAO_CONFIRMADA,ETIQUETA_JA_VINCULADA,VINCULO_DIVERGENTE,RASTREIO_NAO_LOCALIZADO,BAG_NAO_LACRADA,BAG_VAZIA,LACRE_INVALIDO,BAG_NAO_EDITAVEL,LACRE_NAO_PERMITIDO,BAG_NAO_VAZIA,SEM_ALTERACAO") = 0 THEN erro = "FALHA_BAG".
            resposta = bFalha(erro).
        END CATCH.
        FINALLY:
            IF VALID-HANDLE(hRastro) THEN DELETE PROCEDURE hRastro NO-ERROR.
        END FINALLY.
    END.
    /* Colisao concorrente na criacao: reler apos rollback local. */
    IF resposta:GetLogical("sucesso") = NO THEN DO:
        RUN repetirBag(hashChave,identidade,hashConteudo,estab,OUTPUT repeticao,OUTPUT linha).
        IF repeticao THEN resposta = linha.
    END.
END PROCEDURE.

PROCEDURE consultarBagOperacional:
    DEFINE INPUT PARAMETER TABLE FOR ttEmbEstabelPermitido.
    DEFINE INPUT PARAMETER idBag AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER modo AS CHARACTER NO-UNDO.
    DEFINE INPUT PARAMETER apos AS INTEGER NO-UNDO.
    DEFINE INPUT PARAMETER limite AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER resposta AS JsonObject NO-UNDO.
    DEFINE BUFFER bBag FOR mgesp.contr_emb_bag_lacre.
    DEFINE BUFFER bEt FOR mgesp.contr_emb_etiqueta.
    DEFINE BUFFER bGer FOR mgesp.contr_emb_evento.
    DEFINE BUFFER bAu FOR mgesp.contr_emb_audit.
    DEFINE BUFFER bEv FOR mgesp.contr_emb_evento.
    DEFINE VARIABLE dados AS JsonArray NO-UNDO.
    DEFINE VARIABLE linha AS JsonObject NO-UNDO.
    DEFINE VARIABLE n AS INTEGER NO-UNDO.
    DEFINE VARIABLE ultimo AS INTEGER NO-UNDO.
    DEFINE VARIABLE mais AS LOGICAL NO-UNDO.
    DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
    DEFINE VARIABLE original AS JsonObject NO-UNDO.
    DEFINE VARIABLE snapshotTexto AS LONGCHAR NO-UNDO.
    FIX-CODEPAGE(snapshotTexto) = "UTF-8".
    resposta = bFalha("FILTRO_INVALIDO").
    IF idBag = ? OR idBag <= 0 OR apos = ? OR apos < 0 OR LOOKUP(modo,"ELEGIVEIS,HISTORICO") = 0 THEN RETURN.
    IF limite = ? OR limite < 1 OR limite > 20 THEN DO: resposta = bFalha("LIMITE_INVALIDO"). RETURN. END.
    resposta = bFalha("BAG_NAO_DISPONIVEL").
    FIND FIRST bBag NO-LOCK WHERE bBag.id-bag = idBag NO-ERROR.
    IF NOT AVAILABLE bBag THEN RETURN.
    IF NOT bPermissao(bBag.cod-estabel) THEN RETURN.
    DO ON ERROR UNDO, THROW:
        dados = NEW JsonArray().
        IF modo = "ELEGIVEIS" THEN DO:
            IF bBag.situacao = ? OR bBag.situacao <> "ABERTA" THEN DO: resposta = bFalha("BAG_NAO_ABERTA"). RETURN. END.
            FOR EACH bEt NO-LOCK WHERE bEt.cod-estabel = bBag.cod-estabel AND bEt.cod-tipo = bBag.cod-tipo
                AND bEt.id-etiqueta > apos AND bEt.tipo-controle = "EMBALAGEM" AND bEt.situacao = "ATIVA"
                AND bEt.tipo-local = "ESTAB" AND bEt.qtidade-atu = 0 AND bEt.id-bag = ? BY bEt.id-etiqueta:
                IF bEt.id-movto-ult = ? THEN NEXT.
                FIND FIRST bGer NO-LOCK WHERE bGer.id-evento = bEt.id-evento-geracao NO-ERROR.
                IF NOT AVAILABLE bGer THEN NEXT.
                IF bGer.situacao = ? OR bGer.situacao <> "CONCLUIDO" THEN NEXT.
                IF n = limite THEN DO: mais = YES. LEAVE. END.
                linha = NEW JsonObject().
                linha:Add("idEtiqueta",STRING(bEt.id-etiqueta)). linha:Add("codEtiqueta",bEt.cod-etiqueta).
                linha:Add("item",bEt.it-codigo). linha:Add("codTipo",bEt.cod-tipo).
                linha:Add("lote",bEt.lote). linha:Add("validade",bEt.dt-vali-lote).
                linha:Add("unidade",bEt.un). linha:Add("capacidade",bEt.capacidade-emb).
                linha:Add("quantidadeAtual",bEt.qtidade-atu). linha:Add("versao",bEt.versao).
                dados:Add(linha).
                ASSIGN n = n + 1 ultimo = bEt.id-etiqueta.
            END.
        END.
        ELSE DO:
            FOR EACH bAu NO-LOCK WHERE bAu.nome-tabela = "contr_emb_bag_lacre" AND bAu.chave-registro = STRING(idBag)
                AND bAu.id-audit > apos BY bAu.id-audit:
                IF bAu.dados-atu = ? OR NOT bAu.dados-atu BEGINS "DT123|" THEN NEXT.
                FIND FIRST bEv NO-LOCK WHERE bEv.id-evento = bAu.id-evento NO-ERROR.
                IF NOT AVAILABLE bEv THEN NEXT.
                IF bEv.origem <> "MANUT_BAG" OR bEv.situacao <> "CONCLUIDO" OR NOT bPermissao(bEv.cod-estabel) THEN NEXT.
                IF n = limite THEN DO: mais = YES. LEAVE. END.
                linha = NEW JsonObject().
                linha:Add("idRegistro",STRING(bAu.id-audit)). linha:Add("idEvento",STRING(bEv.id-evento)).
                linha:Add("acao",ENTRY(2,bAu.dados-atu,"|")). linha:Add("ocorrencia",bEv.tipo-evento).
                linha:Add("qtdEtiquetas",INTEGER(ENTRY(3,bAu.dados-atu,"|"))).
                linha:Add("dataRegistro",bAu.dt-registro). linha:Add("usuario",bAu.usuario).
                linha:Add("justificativa",bAu.justificativa). linha:Add("versaoAnterior",bAu.versao-ant).
                linha:Add("versaoAtual",bAu.versao-atu).
                IF bEv.resultado <> ? AND bEv.resultado <> "" THEN DO:
                    ASSIGN snapshotTexto = bEv.resultado parser = NEW ObjectModelParser()
                        original = CAST(parser:Parse(snapshotTexto),JsonObject).
                    IF original:Has("situacao") THEN DO:
                        linha:Add("situacao",original:GetCharacter("situacao")).
                        linha:Add("nroLacre",original:GetCharacter("nroLacre")).
                        linha:Add("destino",original:GetCharacter("destino")).
                        linha:Add("motorista",original:GetCharacter("motorista")).
                        linha:Add("dtLacre",original:GetCharacter("dtLacre")).
                        linha:Add("dtEnvio",original:GetCharacter("dtEnvio")).
                    END.
                    IF original:Has("estadoAnterior") THEN
                        linha:Add("estadoAnterior",original:GetJsonObject("estadoAnterior")).
                END.
                dados:Add(linha).
                ASSIGN n = n + 1 ultimo = bAu.id-audit.
            END.
        END.
        resposta = NEW JsonObject().
        resposta:Add("sucesso",YES). resposta:Add("codigoErro",""). resposta:Add("mensagem","").
        resposta:Add("idBag",STRING(idBag)). resposta:Add("versao",bBag.versao).
        resposta:Add("dados",dados). resposta:Add("total",n). resposta:Add("temMais",mais).
        resposta:Add("proximoId",IF mais THEN STRING(ultimo) ELSE "0").
        CATCH falha AS Progress.Lang.Error:
            resposta = bFalha("FALHA_CONSULTA").
        END CATCH.
    END.
END PROCEDURE.
