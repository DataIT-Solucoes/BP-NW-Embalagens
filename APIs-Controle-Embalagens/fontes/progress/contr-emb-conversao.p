/* Conversao backend do tipo de controle de estoque.
   DT-059: CDAPIITEM altera o item; as rotinas internas tratam o historico
   conforme os caminhos comprovados nos fontes do CE0111.

   DT-068: chamado por salvarParametro na mesma unidade de trabalho.
   Integracao requer nova compilacao e rollback ET-01F em TESTE. */
BLOCK-LEVEL ON ERROR UNDO, THROW.

{utp/ut-glob.i}
{fontes/progress/contr-emb-conversao.i}
/* Contrato local usado apenas para chamar CDAPIITEM na conversao.
   Estrutura comprovada no legado da instalacao; validar por compilacao e execucao em TESTE. */

DEFINE TEMP-TABLE RowErrors     NO-UNDO 
FIELD ErrorSequence        AS INTEGER 
FIELD ErrorNumber          AS INTEGER 
FIELD ErrorDescription     AS CHARACTER 
FIELD ErrorParameters      AS CHARACTER 
FIELD ErrorType            AS CHARACTER 
FIELD ErrorHelp             AS CHARACTER 
FIELD ErrorSubType         AS CHARACTER.

DEFINE TEMP-TABLE ttItem 
FIELD it-codigo                     AS CHARACTER                              
FIELD descricao-1                   AS CHARACTER                              
FIELD descricao-2                   AS CHARACTER                              
FIELD un                            AS CHARACTER                              
FIELD compr-fabric                  AS INTEGER                                
FIELD ge-codigo                     AS INTEGER                                
FIELD fm-codigo                     AS CHARACTER                              
FIELD data-implant                  AS DATE                                   
FIELD data-liberac                  AS DATE                                   
FIELD path                          AS CHARACTER                              
FIELD codigo-refer                  AS CHARACTER                              
FIELD inform-compl                  AS CHARACTER                              
FIELD niv-mais-bai                  AS INTEGER                                
FIELD loc-unica                     AS LOGICAL                                
FIELD tipo-con-est                  AS INTEGER                                
FIELD deposito-pad                  AS CHARACTER                              
FIELD ciclo-contag                  AS INTEGER                                
FIELD data-ult-con                  AS DATE                                   
FIELD variac-acum                   AS DECIMAL                                
FIELD curva-abc                     AS LOGICAL                                
FIELD data-ult-ent                  AS DATE                                   
FIELD data-ult-sai                  AS DATE                                   
FIELD data-base                     AS DATE                                   
FIELD data-ult-rep                  AS DATE                                   
FIELD cod-obsoleto                  AS INTEGER                                
FIELD consumo-prev                  AS DECIMAL                                
FIELD consumo-aad                   AS DECIMAL                                
FIELD cod-comprado                  AS CHARACTER                              
FIELD demanda                       AS INTEGER                                
FIELD emissao-ord                   AS INTEGER                                
FIELD classif-abc                   AS INTEGER                                
FIELD politica                      AS INTEGER                                
FIELD periodo-fixo                  AS INTEGER                                
FIELD tempo-segur                   AS INTEGER                                
FIELD quant-segur                   AS DECIMAL                                
FIELD res-int-comp                  AS INTEGER                                
FIELD res-for-comp                  AS INTEGER                                
FIELD res-cq-comp                   AS INTEGER                                
FIELD ressup-fabri                  AS INTEGER                                
FIELD res-cq-fabri                  AS INTEGER                                
FIELD lote-multipl                  AS DECIMAL                                
FIELD tipo-lote-ec                  AS INTEGER                                
FIELD lote-economi                  AS DECIMAL                                
FIELD fator-refugo                  AS DECIMAL                                
FIELD quant-perda                   AS DECIMAL                                
FIELD classe-repro                  AS INTEGER                                
FIELD contr-qualid                  AS LOGICAL                                
FIELD class-fiscal                  AS CHARACTER                              
FIELD aliquota-ipi                  AS DECIMAL                                
FIELD codigo-orig                   AS INTEGER                                
FIELD cd-trib-icm                   AS INTEGER                                
FIELD cd-trib-ipi                   AS INTEGER                                
FIELD peso-liquido                  AS DECIMAL                                
FIELD fator-conver                  AS DECIMAL                                
FIELD tipo-desc-nt                  AS INTEGER                                
FIELD baixa-estoq                   AS LOGICAL                                
FIELD moeda-padrao                  AS INTEGER                                
FIELD preco-base                    AS DECIMAL                                
FIELD preco-ul-ent                  AS DECIMAL                                
FIELD preco-repos                   AS DECIMAL                                
FIELD cd-planejado                  AS CHARACTER                              
FIELD nr-linha                      AS INTEGER                                
FIELD tipo-requis                   AS INTEGER                                
FIELD cap-est-fabr                  AS DECIMAL                                
FIELD tipo-contr                    AS INTEGER                                
FIELD tipo-est-seg                  AS INTEGER                                
FIELD dt-ult-ben                    AS DATE                                   
FIELD ft-conversao                  AS DECIMAL                                
FIELD dec-ftcon                     AS INTEGER                                
FIELD pm-ja-calc                    AS LOGICAL                                
FIELD fraciona                      AS LOGICAL                                
FIELD reporte-mob                   AS INTEGER                                
FIELD ind-item-fat                  AS LOGICAL                                
FIELD peso-bruto                    AS DECIMAL                                
FIELD cd-trib-iss                   AS INTEGER                                
FIELD aliquota-ISS                  AS DECIMAL                                
FIELD ind-imp-desc                  AS INTEGER                                
FIELD ind-ipi-dife                  AS LOGICAL                                
FIELD lote-minimo                   AS DECIMAL                                
FIELD ind-inf-qtf                   AS LOGICAL                                
FIELD vl-mat-ant                    AS DECIMAL                                
FIELD vl-mob-ant                    AS DECIMAL                                
FIELD responsavel                   AS CHARACTER                              
FIELD usuario-alt                   AS CHARACTER                              
FIELD data-obsol                    AS DATE                                   
FIELD usuario-obsol                 AS CHARACTER                              
FIELD criticidade                   AS INTEGER                                
FIELD horiz-fixo                    AS INTEGER                                
FIELD horiz-liber                   AS INTEGER                                
FIELD lote-mulven                   AS DECIMAL                                
FIELD cod-servico                   AS INTEGER                                
FIELD comprim                       AS DECIMAL                                
FIELD largura                       AS DECIMAL                                
FIELD altura                        AS DECIMAL                                
FIELD qt-max-ordem                  AS DECIMAL                                
FIELD perm-saldo-neg                AS INTEGER                                
FIELD dt-pr-fisc                    AS DATE                                   
FIELD preco-fiscal                  AS DECIMAL                                
FIELD ct-codigo                     AS CHARACTER                              
FIELD sc-codigo                     AS CHARACTER                              
FIELD pr-sem-tx                     AS DECIMAL                                
FIELD div-ordem                     AS INTEGER                                
FIELD cod-estabel                   AS CHARACTER                              
FIELD cod-produto                   AS CHARACTER                              
FIELD fm-cod-com                    AS CHARACTER                              
FIELD ft-conv-fmcoml                AS DECIMAL                                
FIELD volume                        AS DECIMAL                                
FIELD desc-nacional                 AS CHARACTER                              
FIELD desc-inter                    AS CHARACTER                              
FIELD ind-especifico                AS LOGICAL                                
FIELD per-min-luc                   AS DECIMAL                                
FIELD ind-backorder                 AS LOGICAL                                
FIELD rep-prod                      AS INTEGER                                
FIELD cd-formula                    AS INTEGER                                
FIELD cd-origem                     AS INTEGER                                
FIELD tp-cons-prev                  AS DECIMAL                                
FIELD tp-aloc-lote                  AS INTEGER                                
FIELD tp-desp-padrao                AS INTEGER                                
FIELD id-grade                      AS LOGICAL                                
FIELD nat-despesa                   AS INTEGER                                
FIELD tp-adm-lote                   AS INTEGER                                
FIELD per-rest-icms                 AS DECIMAL                                
FIELD niv-rest-icms                 AS CHARACTER                              
FIELD concentracao                  AS DECIMAL                                
FIELD rendimento                    AS DECIMAL                                
FIELD nivel                         AS INTEGER                                
FIELD tipo-insp                     AS INTEGER                                
FIELD perc-nqa                      AS DECIMAL                                
FIELD per-rest-fora                 AS DECIMAL                                
FIELD niv-rest-fora                 AS CHARACTER                              
FIELD nr-item-dcr                   AS INTEGER                                
FIELD tx-importacao                 AS DECIMAL                                
FIELD prioridade                    AS INTEGER                                
FIELD tipo-sched                    AS INTEGER                                
FIELD atu-conf                      AS LOGICAL                                
FIELD isencao-import                AS INTEGER                                
FIELD resumo-mp                     AS INTEGER                                
FIELD ind-serv-mat                  AS INTEGER                                
FIELD cod-refer                     AS CHARACTER                              
FIELD niv-mps                       AS INTEGER                                
FIELD calc-cons-prev                AS INTEGER                                
FIELD var-transf                    AS DECIMAL                                
FIELD var-rep                       AS DECIMAL                                
FIELD var-req-maior                 AS DECIMAL                                
FIELD var-req-menor                 AS DECIMAL                                
FIELD de-codigo-prin                AS CHARACTER                              
FIELD contr-plan                    AS INTEGER                                
FIELD calc-lead-time                AS INTEGER                                
FIELD dec-conv-fmcoml               AS INTEGER                                
FIELD fase-medio                    AS INTEGER                                
FIELD cod-auxiliar                  AS CHARACTER                              
FIELD var-mob-maior                 AS DECIMAL                                
FIELD var-mob-menor                 AS DECIMAL                                
FIELD it-demanda                    AS CHARACTER                              
FIELD perc-demanda                  AS DECIMAL                                
FIELD cd-folh-lote                  AS CHARACTER                              
FIELD cd-folh-item                  AS CHARACTER                              
FIELD valor-ipi-beb                 AS DECIMAL                                
FIELD esp-beb                       AS INTEGER                                
FIELD enquad-beb                    AS INTEGER                                
FIELD tipo-recip-beb                AS INTEGER                                
FIELD capac-recip-beb               AS INTEGER                                
FIELD rot-quant                     AS LOGICAL                                
FIELD rot-revis                     AS LOGICAL                                
FIELD rot-refer                     AS LOGICAL                                
FIELD alt-refer                     AS LOGICAL                                
FIELD tipo-atp                      AS INTEGER                                
FIELD fator-reaj-icms               AS DECIMAL                                
FIELD incentivado                   AS LOGICAL                                
FIELD prefixo-lote                  AS CHARACTER                              
FIELD Nr-ult-peca                   AS INTEGER                                
FIELD tp-lote-minimo                AS LOGICAL                                
FIELD tp-lote-multiplo              AS LOGICAL                                
FIELD tp-lote-econom                AS LOGICAL                                
FIELD quant-pacote                  AS DECIMAL                                
FIELD conta-aplicacao               AS CHARACTER                              
FIELD ct-aplicacao                  AS CHARACTER                              
FIELD sc-aplicacao                  AS CHARACTER                              
FIELD cod-localiz                   AS CHARACTER                              
FIELD sit-aloc                      AS INTEGER                                
FIELD cd-tag                        AS CHARACTER                              
FIELD cod-tax                       AS INTEGER                                
FIELD cod-tax-serv                  AS INTEGER                                
FIELD desc-item                     AS CHARACTER                              
FIELD narrativa                     AS CHARACTER                              
FIELD log-carac-tec                 AS LOGICAL                                
FIELD cod-lista-destino             AS CHARACTER                              
FIELD log-atualiz-via-mmp           AS LOGICAL                                
FIELD vl-var-max                    AS DECIMAL                                
FIELD vl-var-min                    AS DECIMAL                                
FIELD qt-var-max                    AS DECIMAL                                
FIELD qt-var-min                    AS DECIMAL                                
FIELD reporte-ggf                   AS INTEGER                                
FIELD cod-imagem                    AS CHARACTER                              
FIELD cd-referencia                 AS CHARACTER                              
FIELD conv-tempo-seg                AS LOGICAL                                
FIELD char-1                        AS CHARACTER                              
FIELD char-2                        AS CHARACTER                              
FIELD dec-1                         AS DECIMAL                                
FIELD dec-2                         AS DECIMAL                                
FIELD INT-1                         AS INTEGER                                
FIELD int-2                         AS INTEGER                                
FIELD log-1                         AS LOGICAL                                
FIELD log-2                         AS LOGICAL                                
FIELD data-1                        AS DATE                                   
FIELD data-2                        AS DATE                                   
FIELD ind-confprodcom               AS LOGICAL                                
FIELD nivel-apr-requis              AS INTEGER                                
FIELD nivel-apr-solic               AS INTEGER                                
FIELD nivel-apr-manut               AS INTEGER                                
FIELD nivel-apr-compra              AS INTEGER                                
FIELD ind-prev-demanda              AS INTEGER                                
FIELD ind-calc-meta                 AS INTEGER                                
FIELD val-fator-custo-dis           AS DECIMAL                                
FIELD qtd-refer-custo-dis           AS DECIMAL                                
FIELD qtd-batch-padrao              AS DECIMAL                                
FIELD log-utiliza-batch-padrao      AS LOGICAL                                
FIELD ind-quotas                    AS LOGICAL                                
FIELD nr-pontos-quotas              AS INTEGER                                
FIELD check-sum                     AS CHARACTER                              
FIELD num-id-item                   AS INTEGER                                
FIELD ind-refugo                    AS INTEGER                                
FIELD log-necessita-li              AS LOGICAL                                
FIELD dias-estoq-aloc               AS CHARACTER                              
FIELD pto-repos                     AS DECIMAL                                
FIELD aliquota-ii                   AS DECIMAL                                
FIELD cod-trib-ii                   AS INTEGER                                
FIELD geracao-ordem                 AS INTEGER                                
FIELD cons-produto                  AS LOGICAL                                
FIELD cons-saldo                    AS LOGICAL                                
FIELD mp-restrit                    AS LOGICAL                                
FIELD qtde-max                      AS DECIMAL                                
FIELD qtde-fixa                     AS DECIMAL                                
FIELD lote-repos                    AS DECIMAL                                
FIELD cons-consumo                  AS LOGICAL                                
FIELD cod-malha                     AS CHARACTER                              
FIELD cod-pulmao                    AS CHARACTER                              
FIELD politica-aps                  AS INTEGER                                
FIELD tipo-formula                  AS INTEGER                                
FIELD per-ppm                       AS DECIMAL                                
FIELD cod-tab-preco-aps             AS CHARACTER                              
FIELD cod-pulmao-proces             AS CHARACTER                              
FIELD log-tax-produc                AS LOGICAL                                
FIELD log-control-estoq-refugo      AS LOGICAL                                
FIELD log-refugo-preco-fisc         AS LOGICAL                                
FIELD cod-item-refugo               AS CHARACTER                              
FIELD val-relac-refugo-item         AS DECIMAL                                
FIELD log-multi-malha               AS LOGICAL                                
FIELD cod-destaq                    AS INTEGER                                
FIELD dsl-destaq                    AS CHARACTER                              
FIELD cod-unid-negoc                AS CHARACTER                              
FIELD idi-classif-item              AS INTEGER                                
FIELD log-consid-aloc-ativid        AS LOGICAL                                
FIELD val-overlap                   AS DECIMAL                                
FIELD log-programac-sfc             AS LOGICAL                                
FIELD cod-dcr-item                  AS CHARACTER                              
FIELD log-orig-ext                  AS LOGICAL                                
FIELD log-altera-valid-lote         AS LOGICAL                                
FIELD log-inspec-lote               AS LOGICAL                                
FIELD reab-estoq                    AS CHARACTER                              
FIELD tp-item                       AS CHARACTER
FIELD tp-ressup                     LIKE item-mat.tp-ressup
FIELD cd-freq                       LIKE item-mat.cd-freq
FIELD lim-var-qtd                   LIKE item-mat.lim-var-qtd                 
FIELD lim-var-valor                 LIKE item-mat.lim-var-valor               
FIELD var-val-re-maior              LIKE item-mat.var-val-re-maior            
FIELD var-qtd-re                    LIKE item-mat.var-qtd-re                  
FIELD cod-grp-compra                LIKE item-mat.cod-grp-compra              
FIELD cod-ean                       LIKE item-mat.cod-ean                     
FIELD variacao-perm                 LIKE item-mat.variacao-perm               
FIELD ponto-encomenda               LIKE item-mat.ponto-encomenda             
FIELD ind-cons-prv                  LIKE item-mat.ind-cons-prv                
FIELD lote-per-max                  LIKE item-mat.lote-per-max                
FIELD val-lim-absor                 LIKE item-mat.val-lim-absor               
FIELD fator-ponder                  LIKE item-mat.fator-ponder                
FIELD crit-cc                       LIKE item-mat.crit-cc                     
FIELD crit-ce                       LIKE item-mat.crit-ce                     
FIELD data-pr-fisc                  LIKE item-uni-estab.data-pr-fisc          
FIELD cod-fat-ponder                LIKE item-mat.cod-fat-ponder              
FIELD altera-conta                  LIKE item-mat.altera-conta                
FIELD idi-tip-apurac-ipi            LIKE it-doc-fisc.idi-tip-apurac-ipi       
FIELD cod-familia-impto             LIKE item-mat.cod-familia-impto           
FIELD cdn-sefazsp                   LIKE item-dist.cdn-sefazsp                
FIELD log-combust                   LIKE item-dist.log-combust                
FIELD idi-forma-calc-pis            LIKE item-dist.idi-forma-calc-pis         
FIELD val-unit-pis                  LIKE item-dist.val-unit-pis               
FIELD val-unit-cofins               LIKE item-dist.val-unit-cofins            
FIELD cdd-perc-retenc-pis           LIKE item-dist.cdd-perc-retenc-pis        
FIELD cdd-perc-retenc-cofins        LIKE item-dist.cdd-perc-retenc-cofins     
FIELD log-orig-retenc-pis           LIKE item-dist.log-orig-retenc-pis        
FIELD log-orig-retenc-cofins        LIKE item-dist.log-orig-retenc-cofins     
FIELD idi-forma-calc-cofins         LIKE item-dist.idi-forma-calc-cofins      
FIELD log-orig-retenc-csll          LIKE item-dist.log-orig-retenc-csll       
FIELD cdd-perc-retenc-csll          LIKE item-dist.cdd-perc-retenc-csll       
FIELD vli-capac-vol                 LIKE item-dist.vli-capac-vol              
FIELD idi-classif-bebida            LIKE item-dist.idi-classif-bebida         
FIELD idi-enquad-ipi                AS CHARACTER                              
FIELD prioridade-aprov              LIKE item-uni-estab.prioridade-aprov      
FIELD prior-mrp                     LIKE item-uni-estab.prior-mrp             
FIELD qt-min-res-fabr               LIKE item-uni-estab.qt-min-res-fabr       
FIELD res-min-fabri                 LIKE item-uni-estab.res-min-fabri         
FIELD var-tempo-res-fabr            LIKE item-uni-estab.var-tempo-res-fabr    
FIELD var-qtd-res-fabr              LIKE item-uni-estab.var-qtd-res-fabr      
FIELD cod-estab-gestor              LIKE item-uni-estab.cod-estab-gestor      
FIELD metodo-custeio                LIKE item-uni-estab.metodo-custeio        
FIELD dat-cust-padr-impltad         LIKE item-uni-estab.dat-cust-padr-impltad 
FIELD log-cust-padr-impltad         LIKE item-uni-estab.log-cust-padr-impltad 
FIELD ind-lista-csp                 LIKE item-uni-estab.ind-lista-csp         
FIELD cod-estabel-uni               LIKE item-uni-estab.cod-estabel           
FIELD log-suspens-impto-import      LIKE item-mat.log-suspens-impto-import    
FIELD log-suspens-ipi-import        LIKE item-mat.log-suspens-ipi-import      
FIELD cdn-fabrican                  LIKE item-mat.cdn-fabrican                
FIELD cdn-pais-orig                 LIKE item-mat.cdn-pais-orig               
FIELD val-tax-basic-seguro          LIKE item-mat.val-tax-basic-seguro        
FIELD val-tax-impto-seguro          LIKE item-mat.val-tax-impto-seguro        
FIELD idi-tributac-pis              LIKE item-mat.idi-tributac-pis            
FIELD val-unit-vol-pis              LIKE item-mat.val-unit-vol-pis            
FIELD val-aliq-ext-pis              LIKE item-mat.val-aliq-ext-pis            
FIELD idi-tributac-cofins           LIKE item-mat.idi-tributac-cofins         
FIELD val-unit-vol-cofins           LIKE item-mat.val-unit-vol-cofins         
FIELD val-aliq-ext-cofins           LIKE item-mat.val-aliq-ext-cofins         
FIELD val-base-pis-substto          LIKE item-mat.val-base-pis-substto        
FIELD val-base-cofins-substto       LIKE item-mat.val-base-cofins-substto     
FIELD ind-lista-mrp                 AS INTEGER                                
FIELD descricao1                    AS CHARACTER                              
FIELD log-aloc-neg                  AS LOGICAL                                
FIELD cod-workflow                  AS CHARACTER
FIELD r-rowid			            AS ROWID.

DEFINE BUFFER item             FOR mgcad.item.
DEFINE BUFFER bSaldoColisao    FOR saldo-estoq.
DEFINE BUFFER b-saldo-est      FOR saldo-estoq.
DEFINE BUFFER b2-saldo-est     FOR saldo-estoq.
DEFINE BUFFER b-invent         FOR inventario.
DEFINE BUFFER b2-invent        FOR inventario.
DEFINE BUFFER b-item-doc-est   FOR item-doc-est.
DEFINE BUFFER b-rat-lote       FOR rat-lote.
DEFINE BUFFER b-it-dep-fat     FOR it-dep-fat.
DEFINE BUFFER b2-it-dep-fat    FOR it-dep-fat.
DEFINE BUFFER b-fat-ser-lote   FOR fat-ser-lote.
DEFINE BUFFER b2-fat-ser-lote  FOR fat-ser-lote.

/* DT-063: prefixo funcional das agrupadoras do faturamento legado. */
FUNCTION referenciaFaturamento RETURNS LOGICAL
    (INPUT pcReferencia AS CHARACTER):
    IF pcReferencia = ? THEN RETURN NO.
    RETURN pcReferencia BEGINS "F".
END FUNCTION.

/* Quantidades desconhecidas nao podem ser somadas, inclusive nas F. */
FUNCTION campoQuantidadeDesconhecida RETURNS CHARACTER
    (INPUT phSaldo AS HANDLE):
    DEFINE VARIABLE iCampo AS INTEGER NO-UNDO.
    DEFINE VARIABLE hCampo AS HANDLE NO-UNDO.
    DO iCampo = 1 TO NUM-ENTRIES(
        "qtidade-atu,qtidade-ini,qtidade-fin,qt-alocada,qt-aloc-prod,qt-aloc-ped"):
        hCampo = phSaldo:BUFFER-FIELD(ENTRY(iCampo,
            "qtidade-atu,qtidade-ini,qtidade-fin,qt-alocada,qt-aloc-prod,qt-aloc-ped")).
        IF hCampo:BUFFER-VALUE = ? THEN RETURN hCampo:NAME.
    END.
    RETURN "".
END FUNCTION.

/* DT-065: verificar somente o que impede a soma/preservacao da validade.
   Demais atributos ficam na sobrevivente; nao exigir igualdade de todos
   os campos nem inferir regras TOTVS para fabricacao/registro zero. */
FUNCTION campoSaldoIncompativel RETURNS CHARACTER
    (INPUT phPrimeiro AS HANDLE, INPUT phSegundo AS HANDLE):
    DEFINE VARIABLE cCampo AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hValidadePrimeira AS HANDLE NO-UNDO.
    DEFINE VARIABLE hValidadeSegunda AS HANDLE NO-UNDO.
    DEFINE VARIABLE dtPrimeira AS DATE NO-UNDO.
    DEFINE VARIABLE dtSegunda AS DATE NO-UNDO.

    cCampo = campoQuantidadeDesconhecida(phPrimeiro).
    IF cCampo <> "" THEN RETURN cCampo.
    cCampo = campoQuantidadeDesconhecida(phSegundo).
    IF cCampo <> "" THEN RETURN cCampo.

    ASSIGN hValidadePrimeira = phPrimeiro:BUFFER-FIELD("dt-vali-lote")
           hValidadeSegunda  = phSegundo:BUFFER-FIELD("dt-vali-lote")
           dtPrimeira = hValidadePrimeira:BUFFER-VALUE
           dtSegunda  = hValidadeSegunda:BUFFER-VALUE.
    /* Limitacao propria ate comprovar coexistencia na chave fisica.
       Nunca fundir validades diferentes para retirar a referencia. */
    IF dtPrimeira = ? THEN DO:
        IF dtSegunda <> ? THEN RETURN "dt-vali-lote".
    END.
    ELSE IF dtSegunda = ? OR dtPrimeira <> dtSegunda THEN RETURN "dt-vali-lote".
    RETURN "".
END FUNCTION.

PROCEDURE registrarDiagnostico:
DEFINE INPUT PARAMETER pcTabela     AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piQuantidade AS INTEGER   NO-UNDO.
DEFINE INPUT PARAMETER pcTratamento AS CHARACTER NO-UNDO.

CREATE ttEmbConversaoDiagnostico.
ASSIGN ttEmbConversaoDiagnostico.nome-tabela = pcTabela
       ttEmbConversaoDiagnostico.quantidade  = piQuantidade
       ttEmbConversaoDiagnostico.tratamento  = pcTratamento.
END PROCEDURE.

PROCEDURE analisarConversao:
DEFINE INPUT  PARAMETER pcItem             AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER piTipoDestino      AS INTEGER   NO-UNDO.
DEFINE INPUT  PARAMETER pcLoteMigracao     AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pdtValidadeMigracao AS DATE     NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbConversaoDiagnostico.
DEFINE OUTPUT PARAMETER piTipoOrigem       AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER piColisoesSaldo    AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso          AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro             AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem         AS CHARACTER NO-UNDO.

DEFINE VARIABLE cItem       AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLote       AS CHARACTER NO-UNDO.
DEFINE VARIABLE iQuantidade AS INTEGER   NO-UNDO.
DEFINE VARIABLE cCampoIncompativel AS CHARACTER NO-UNDO.
DEFINE VARIABLE cImpedimentoSaldo AS CHARACTER NO-UNDO.
DEFINE VARIABLE iSaldoFaturamento AS INTEGER NO-UNDO.

EMPTY TEMP-TABLE ttEmbConversaoDiagnostico.
ASSIGN cItem            = IF pcItem = ? THEN "" ELSE TRIM(pcItem, " ")
       cLote            = IF pcLoteMigracao = ? THEN "" ELSE TRIM(pcLoteMigracao, " ")
       piTipoOrigem     = 0
       piColisoesSaldo  = 0
       plSucesso        = NO
       pcErro           = "ITEM_NAO_ENCONTRADO"
       pcMensagem       = "O item informado nao foi encontrado.".

IF cItem = "" THEN RETURN.
FIND FIRST item NO-LOCK
     WHERE item.it-codigo = cItem
     USE-INDEX codigo NO-ERROR.
IF NOT AVAILABLE item THEN RETURN.
piTipoOrigem = item.tipo-con-est.

/* DT-065: repetir o tipo atual nao altera item/historico. Nao exigir
   pre-condicoes de uma mutacao quando nenhuma mutacao sera feita. */
IF piTipoOrigem = piTipoDestino THEN DO:
    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    RETURN.
END.

ASSIGN pcErro     = "ITEM_POLITICA_CONFIGURADA"
       pcMensagem = "O tipo de controle nao pode ser alterado para item com politica configurada.".
IF item.politica = 5 THEN RETURN.

ASSIGN pcErro     = "TRANSICAO_NAO_SUPORTADA"
       pcMensagem = "A conversao aceita somente Serial para Lote, Referencia para Lote ou Lote para Serial.".
IF NOT ((piTipoOrigem = 1 AND piTipoDestino = 3) OR
        (piTipoOrigem = 4 AND piTipoDestino = 3) OR
        (piTipoOrigem = 3 AND piTipoDestino = 1) OR
        piTipoOrigem = piTipoDestino) THEN RETURN.

IF piTipoOrigem = 1 AND piTipoDestino = 3 THEN DO:
    ASSIGN pcErro     = "LOTE_MIGRACAO_NAO_INFORMADO"
           pcMensagem = "Informe o lote que classificara o historico anterior do item.".
    IF cLote = "" THEN RETURN.

    ASSIGN pcErro     = "VALIDADE_MIGRACAO_INVALIDA"
           pcMensagem = "Informe validade igual ou posterior a data atual para o lote de migracao.".
    IF pdtValidadeMigracao = ? OR pdtValidadeMigracao < TODAY THEN RETURN.
END.

/* Mesma protecao aplicada pelo CE0111 ao converter para Serial. */
IF piTipoDestino = 1 THEN DO:
    FOR EACH item-uni-estab FIELDS(cod-estabel metodo-custeio)
        WHERE item-uni-estab.it-codigo      = cItem
          AND item-uni-estab.metodo-custeio = 6 NO-LOCK:
        IF CAN-FIND(FIRST estab-mat NO-LOCK
                    WHERE estab-mat.cod-estabel = item-uni-estab.cod-estabel
                      AND estab-mat.usa-on-line) THEN DO:
            ASSIGN pcErro     = "CUSTO_ESPECIFICO_INCOMPATIVEL"
                   pcMensagem = "O controle Serial e incompativel com custo especifico on-line para o item.".
            RETURN.
        END.
    END.
END.

FIND FIRST param-global NO-LOCK NO-ERROR.
IF NOT AVAILABLE param-global THEN DO:
    ASSIGN pcErro = "PARAM_GLOBAL_NAO_ENCONTRADO"
           pcMensagem = "Nao foi possivel identificar os modulos ativos do Datasul.".
    RETURN.
END.

ASSIGN iQuantidade = 0.
FOR EACH saldo-estoq NO-LOCK
    WHERE saldo-estoq.it-codigo = cItem:
    iQuantidade = iQuantidade + 1.
    IF piTipoOrigem = 4 AND piTipoDestino = 3 THEN DO:
        IF referenciaFaturamento(saldo-estoq.cod-refer) THEN
            iSaldoFaturamento = iSaldoFaturamento + 1.
        cCampoIncompativel = campoQuantidadeDesconhecida(BUFFER saldo-estoq:HANDLE).
        IF cCampoIncompativel <> "" AND cImpedimentoSaldo = "" THEN
            cImpedimentoSaldo = cCampoIncompativel.
        IF CAN-FIND(FIRST bSaldoColisao NO-LOCK
                    WHERE bSaldoColisao.cod-estabel = saldo-estoq.cod-estabel
                      AND bSaldoColisao.cod-depos = saldo-estoq.cod-depos
                      AND bSaldoColisao.cod-localiz = saldo-estoq.cod-localiz
                      AND bSaldoColisao.it-codigo = saldo-estoq.it-codigo
                      AND bSaldoColisao.lote = saldo-estoq.lote
                      AND bSaldoColisao.cod-refer <> saldo-estoq.cod-refer
                      AND ROWID(bSaldoColisao) <> ROWID(saldo-estoq)) THEN
            piColisoesSaldo = piColisoesSaldo + 1.
        /* DT-065: cada quantidade ja foi conferida na linha de origem.
           Nao carregar todos os pares; basta detectar validade distinta. */
        IF cImpedimentoSaldo = "" AND CAN-FIND(FIRST bSaldoColisao NO-LOCK
            WHERE bSaldoColisao.cod-estabel = saldo-estoq.cod-estabel
              AND bSaldoColisao.cod-depos = saldo-estoq.cod-depos
              AND bSaldoColisao.cod-localiz = saldo-estoq.cod-localiz
              AND bSaldoColisao.it-codigo = saldo-estoq.it-codigo
              AND bSaldoColisao.lote = saldo-estoq.lote
              AND ROWID(bSaldoColisao) <> ROWID(saldo-estoq)
              AND (bSaldoColisao.dt-vali-lote <> saldo-estoq.dt-vali-lote
                OR (bSaldoColisao.dt-vali-lote = ? AND saldo-estoq.dt-vali-lote <> ?)
                OR (bSaldoColisao.dt-vali-lote <> ? AND saldo-estoq.dt-vali-lote = ?))) THEN
            cImpedimentoSaldo = "dt-vali-lote".
    END.
END.
RUN registrarDiagnostico("saldo-estoq", iQuantidade,
    IF piTipoOrigem = 4 AND piTipoDestino = 3 THEN "CONSOLIDAR_TODAS_E_LIMPAR_REFERENCIA" ELSE "CONSOLIDAR_E_ATRIBUIR").
IF piTipoOrigem = 4 AND piTipoDestino = 3 THEN DO:
    RUN registrarDiagnostico("saldo-estoq-operacional", iQuantidade - iSaldoFaturamento,
                            "CONSOLIDAR_E_LIMPAR_REFERENCIA").
    RUN registrarDiagnostico("saldo-estoq-faturamento", iSaldoFaturamento,
                            "SOMAR_E_ABSORVER_NO_MESMO_GRUPO").
END.

ASSIGN iQuantidade = 0.
FOR EACH inventario NO-LOCK WHERE inventario.it-codigo = cItem:
    iQuantidade = iQuantidade + 1.
END.
RUN registrarDiagnostico("inventario", iQuantidade,
    IF piTipoOrigem = 4 AND piTipoDestino = 3 THEN "SEM_ALTERACAO" ELSE "CONSOLIDAR_E_ATRIBUIR").

ASSIGN iQuantidade = 0.
FOR EACH movto-estoq NO-LOCK WHERE movto-estoq.it-codigo = cItem:
    iQuantidade = iQuantidade + 1.
END.
RUN registrarDiagnostico("movto-estoq", iQuantidade, "ATUALIZAR_CONTROLE").

ASSIGN iQuantidade = 0.
FOR EACH saldo-terc NO-LOCK WHERE saldo-terc.it-codigo = cItem:
    iQuantidade = iQuantidade + 1.
END.
RUN registrarDiagnostico("saldo-terc", iQuantidade, "ATUALIZAR_CONTROLE").

ASSIGN iQuantidade = 0.
FOR EACH item-doc-est NO-LOCK WHERE item-doc-est.it-codigo = cItem:
    iQuantidade = iQuantidade + 1.
END.
RUN registrarDiagnostico("item-doc-est", iQuantidade, "ATUALIZAR_CONTROLE").

ASSIGN iQuantidade = 0.
FOR EACH it-nota-fisc NO-LOCK WHERE it-nota-fisc.it-codigo = cItem:
    iQuantidade = iQuantidade + 1.
END.
RUN registrarDiagnostico("it-nota-fisc", iQuantidade, "ATUALIZAR_CONTROLE").

ASSIGN iQuantidade = 0.
FOR EACH it-dep-fat NO-LOCK WHERE it-dep-fat.it-codigo = cItem:
    iQuantidade = iQuantidade + 1.
END.
RUN registrarDiagnostico("it-dep-fat", iQuantidade, "CONSOLIDAR_E_ATRIBUIR").

ASSIGN iQuantidade = 0.
FOR EACH ped-saldo NO-LOCK WHERE ped-saldo.it-codigo = cItem:
    iQuantidade = iQuantidade + 1.
END.
RUN registrarDiagnostico("ped-saldo", iQuantidade,
    IF piTipoOrigem = 4 AND piTipoDestino = 3 THEN "LIMPAR_REFERENCIA_E_LOTE" ELSE "ATUALIZAR_CONTROLE").

IF cImpedimentoSaldo <> "" THEN DO:
    ASSIGN pcErro = IF cImpedimentoSaldo = "dt-vali-lote"
                    THEN "COLISAO_VALIDADE_LOTE" ELSE "COLISAO_CAMPOS_SALDO"
           pcMensagem = "Saldos da mesma posicao/lote nao podem ser consolidados: campo "
                        + cImpedimentoSaldo + " incompativel.".
    RETURN.
END.

ASSIGN plSucesso  = YES
       pcErro     = ""
       pcMensagem = "".
END PROCEDURE.

PROCEDURE alterarTipoPelaCdApiItem:
DEFINE INPUT  PARAMETER pcItem        AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER piTipoDestino AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso     AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro        AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem    AS CHARACTER NO-UNDO.

DEFINE VARIABLE hCdApiItem AS HANDLE  NO-UNDO.
DEFINE VARIABLE lAtualiza  AS LOGICAL NO-UNDO INITIAL YES.

EMPTY TEMP-TABLE ttItem.
EMPTY TEMP-TABLE RowErrors.
ASSIGN plSucesso = NO pcErro = "CDAPIITEM_RECUSOU"
       pcMensagem = "A API padrao recusou a alteracao do item.".

FIND FIRST item NO-LOCK
     WHERE item.it-codigo = pcItem
     USE-INDEX codigo NO-ERROR.
IF NOT AVAILABLE item THEN DO:
    ASSIGN pcErro = "ITEM_NAO_ENCONTRADO"
           pcMensagem = "O item informado nao foi encontrado.".
    RETURN.
END.

FIND FIRST item-mat OF item NO-LOCK NO-ERROR.
FIND FIRST item-dist OF item NO-LOCK NO-ERROR.
FIND FIRST it-doc-fisc OF item NO-LOCK NO-ERROR.

CREATE ttItem.
IF AVAILABLE item-mat THEN BUFFER-COPY item-mat TO ttItem.
IF AVAILABLE item-dist THEN BUFFER-COPY item-dist TO ttItem.
IF AVAILABLE it-doc-fisc THEN BUFFER-COPY it-doc-fisc TO ttItem.
BUFFER-COPY item TO ttItem.
ttItem.tipo-con-est = piTipoDestino.

DO ON ERROR UNDO, THROW:
    RUN cdp/cdapiitem.p PERSISTENT SET hCdApiItem NO-ERROR.
    IF ERROR-STATUS:ERROR OR ERROR-STATUS:NUM-MESSAGES > 0 OR
       NOT VALID-HANDLE(hCdApiItem) THEN DO:
        ASSIGN pcErro = "FALHA_ABRIR_CDAPIITEM"
               pcMensagem = IF ERROR-STATUS:NUM-MESSAGES > 0
                            THEN ERROR-STATUS:GET-MESSAGE(1)
                            ELSE "Nao foi possivel iniciar a API padrao do item.".
        RETURN.
    END.

    RUN setTTItem IN hCdApiItem (INPUT TABLE ttItem) NO-ERROR.
    IF ERROR-STATUS:ERROR OR ERROR-STATUS:NUM-MESSAGES > 0 THEN DO:
        ASSIGN pcErro = "FALHA_SET_TTITEM"
               pcMensagem = IF ERROR-STATUS:NUM-MESSAGES > 0
                            THEN ERROR-STATUS:GET-MESSAGE(1)
                            ELSE "A API padrao nao recebeu os dados do item.".
        RETURN.
    END.

    RUN validateSaveImplantacao IN hCdApiItem
        (INPUT TABLE ttItem,
         INPUT lAtualiza,
         OUTPUT TABLE RowErrors) NO-ERROR.
    IF ERROR-STATUS:ERROR OR ERROR-STATUS:NUM-MESSAGES > 0 THEN DO:
        ASSIGN pcErro = "FALHA_VALIDAR_CDAPIITEM"
               pcMensagem = IF ERROR-STATUS:NUM-MESSAGES > 0
                            THEN ERROR-STATUS:GET-MESSAGE(1)
                            ELSE "A API padrao falhou ao validar ou gravar o item.".
        RETURN.
    END.

    FIND FIRST RowErrors NO-LOCK NO-ERROR.
    IF AVAILABLE RowErrors THEN DO:
        ASSIGN pcMensagem = IF RowErrors.ErrorDescription = ? OR
                                  TRIM(RowErrors.ErrorDescription, " ") = ""
                             THEN "A API padrao recusou a alteracao do item."
                             ELSE RowErrors.ErrorDescription.
        RETURN.
    END.

    ASSIGN plSucesso = YES pcErro = "" pcMensagem = "".
    FINALLY:
        IF VALID-HANDLE(hCdApiItem) THEN DELETE PROCEDURE hCdApiItem NO-ERROR.
    END FINALLY.
END.
END PROCEDURE.

PROCEDURE atualizarHistorico:
DEFINE INPUT PARAMETER pcItem         AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER piTipoOrigem   AS INTEGER   NO-UNDO.
DEFINE INPUT PARAMETER piTipoDestino  AS INTEGER   NO-UNDO.
DEFINE INPUT PARAMETER pcLote         AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pcReferencia   AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER pdtValidade    AS DATE      NO-UNDO.

DEFINE VARIABLE i-cont AS INTEGER NO-UNDO.
DEFINE VARIABLE cCampoIncompativel AS CHARACTER NO-UNDO.

FIND FIRST item NO-LOCK
     WHERE item.it-codigo = pcItem
     USE-INDEX codigo NO-ERROR.
IF NOT AVAILABLE item THEN
    RETURN ERROR "Item indisponivel durante a atualizacao do historico.".

FIND FIRST param-global NO-LOCK NO-ERROR.
IF NOT AVAILABLE param-global THEN
    RETURN ERROR "Parametros globais indisponiveis durante a conversao.".

IF piTipoOrigem = 4 AND piTipoDestino = 3 THEN DO:
    /* Adaptacao backend das regras comprovadas no CE0111.
   Nao possui dependencia de frame, Viewer ou acompanhamento visual.
   Limpa somente os vinculos cod-refer do item; nao exclui nem altera
   o cadastro mestre da referencia. */

/********************************************************************************
**
**   Include: CE0111.i2 - Atualiza Cod-Refer
**                        Movimentos, Producao, Documentos, Ficha-CQ e Saldo-Terc
**
********************************************************************************/
disable triggers for load of saldo-estoq.
disable triggers for load of inventario.
disable triggers for load of fat-ser-lote.
disable triggers for load of it-dep-fat.

for each movto-estoq use-index item-data
    where movto-estoq.it-codigo = item.it-codigo exclusive-lock:
    assign movto-estoq.cod-refer = pcReferencia.
end.

if param-global.modulo-cp then do:

   for each ord-prod use-index item
       where ord-prod.it-codigo = item.it-codigo exclusive-lock:
       assign ord-prod.cod-refer = pcReferencia.
   end.
   for each rep-prod use-index item-dat
      where rep-prod.it-codigo = item.it-codigo exclusive-lock:
      assign rep-prod.cod-refer = pcReferencia.
   end.
end.


for each item-doc-est no-lock
    where item-doc-est.it-codigo = item.it-codigo:
    find b-item-doc-est
        where rowid(b-item-doc-est) = rowid(item-doc-est) exclusive-lock.
    assign b-item-doc-est.cod-refer = pcReferencia.
    if (item.tipo-con-est = 4 or item.tipo-con-est = 3)
    and piTipoDestino = 2 then
        assign b-item-doc-est.dt-vali-lote = pdtValidade.
    if   item.tipo-con-est = 2
    and (piTipoDestino = 3
    or   piTipoDestino = 4) then
        assign b-item-doc-est.dt-vali-lote = pdtValidade.
end.

/* O schema holder desta instalacao nao possui o indice alternativo "item".
   Sem USE-INDEX, o otimizador usa o indice valido disponivel sem mudar o filtro. */
for each saldo-terc
    where saldo-terc.it-codigo = item.it-codigo exclusive-lock:
    assign saldo-terc.cod-refer = pcReferencia.
end.
for each componente use-index item
    where componente.it-codigo = item.it-codigo exclusive-lock:
    assign componente.cod-refer = pcReferencia.
end.

/* Altera??es RMA */


/* rma-item */
for each rma-item 
    where rma-item.cod-item = item.it-codigo exclusive-lock:
    assign rma-item.cod-refer = pcReferencia.
end.

/* rma-it-dep */
for each rma-it-dep 
    where rma-it-dep.cod-item = item.it-codigo exclusive-lock:
    assign rma-it-dep.cod-refer = pcReferencia.
    
    if (piTipoOrigem = 4 or piTipoOrigem = 3)
    and piTipoDestino = 2 then
        assign rma-it-dep.dat-valid-lote = pdtValidade.
    
    if  piTipoOrigem = 2
    and (piTipoDestino = 3
    or   piTipoDestino = 4) then
        assign rma-it-dep.dat-valid-lote = pdtValidade.
end.

/* rma-it-troca */

for each rma-it-troca 
    where rma-it-troca.cod-item = item.it-codigo exclusive-lock:
    assign rma-it-troca.cod-refer = pcReferencia.
end.

/* item-doc-est-troca */
for each item-doc-est-troca 
    where item-doc-est-troca.cod-item = item.it-codigo exclusive-lock:
    assign item-doc-est-troca.cod-refer = pcReferencia.
end.       

/* Fim Altera??es RMA */

if  param-global.modulo-cc then do:
    for each ordem-compra  use-index item
        where ordem-compra.it-codigo = item.it-codigo exclusive-lock:
        assign ordem-compra.cod-refer = pcReferencia.
    end.
    for each prazo-compra use-index item
        where prazo-compra.it-codigo = item.it-codigo exclusive-lock:
        assign prazo-compra.cod-refer = pcReferencia.
    end.
end.


/* DT-061: consolidacao propria; nunca mistura localizacao/lote/validade.
   Excluir as linhas absorvidas antes de limpar a referencia evita a colisao
   com uma linha que ja possua cod-refer vazio. O bloco externo faz rollback. */
for each saldo-estoq
    where saldo-estoq.it-codigo = item.it-codigo
      and not (saldo-estoq.cod-refer begins "F") exclusive-lock:
    for each b-saldo-est
        where b-saldo-est.cod-estabel = saldo-estoq.cod-estabel
          and b-saldo-est.cod-depos   = saldo-estoq.cod-depos
          and b-saldo-est.cod-localiz = saldo-estoq.cod-localiz
          and b-saldo-est.it-codigo   = saldo-estoq.it-codigo
          and b-saldo-est.lote        = saldo-estoq.lote
          and rowid(b-saldo-est) <> rowid(saldo-estoq) exclusive-lock:
        cCampoIncompativel = campoSaldoIncompativel(
            BUFFER saldo-estoq:HANDLE, BUFFER b-saldo-est:HANDLE).
        if cCampoIncompativel <> "" then
            return error "Consolidacao recusada: campo " + cCampoIncompativel + " incompativel.".
        assign saldo-estoq.qtidade-atu  = saldo-estoq.qtidade-atu + b-saldo-est.qtidade-atu
               saldo-estoq.qtidade-ini  = saldo-estoq.qtidade-ini + b-saldo-est.qtidade-ini
               saldo-estoq.qtidade-fin  = saldo-estoq.qtidade-fin + b-saldo-est.qtidade-fin
               saldo-estoq.qt-alocada   = saldo-estoq.qt-alocada + b-saldo-est.qt-alocada
               saldo-estoq.qt-aloc-prod = saldo-estoq.qt-aloc-prod + b-saldo-est.qt-aloc-prod
               saldo-estoq.qt-aloc-ped = saldo-estoq.qt-aloc-ped + b-saldo-est.qt-aloc-ped.
        if b-saldo-est.data-ult-ent <> ? and
           (saldo-estoq.data-ult-ent = ? or b-saldo-est.data-ult-ent > saldo-estoq.data-ult-ent) then
            saldo-estoq.data-ult-ent = b-saldo-est.data-ult-ent.
        if b-saldo-est.dt-ul-contag <> ? and
           (saldo-estoq.dt-ul-contag = ? or b-saldo-est.dt-ul-contag > saldo-estoq.dt-ul-contag) then
            saldo-estoq.dt-ul-contag = b-saldo-est.dt-ul-contag.
        delete b-saldo-est.
    end.
    assign saldo-estoq.cod-refer = pcReferencia.
end.

/* DT-063: grupos apenas F tambem preservam toda quantidade. Conservar
   uma linha original e absorver duplicadas antes de limpar a referencia. */
for each saldo-estoq
    where saldo-estoq.it-codigo = item.it-codigo
      and saldo-estoq.cod-refer begins "F" exclusive-lock:
    for each b-saldo-est
        where b-saldo-est.it-codigo = saldo-estoq.it-codigo
          and b-saldo-est.cod-estabel = saldo-estoq.cod-estabel
          and b-saldo-est.cod-depos = saldo-estoq.cod-depos
          and b-saldo-est.cod-localiz = saldo-estoq.cod-localiz
          and b-saldo-est.lote = saldo-estoq.lote
          and b-saldo-est.cod-refer begins "F"
          and rowid(b-saldo-est) <> rowid(saldo-estoq) exclusive-lock:
        cCampoIncompativel = campoSaldoIncompativel(
            BUFFER saldo-estoq:HANDLE, BUFFER b-saldo-est:HANDLE).
        if cCampoIncompativel <> "" then
            return error "Consolidacao F recusada: campo " + cCampoIncompativel + " incompativel.".
        assign saldo-estoq.qtidade-atu = saldo-estoq.qtidade-atu + b-saldo-est.qtidade-atu
               saldo-estoq.qtidade-ini = saldo-estoq.qtidade-ini + b-saldo-est.qtidade-ini
               saldo-estoq.qtidade-fin = saldo-estoq.qtidade-fin + b-saldo-est.qtidade-fin
               saldo-estoq.qt-alocada = saldo-estoq.qt-alocada + b-saldo-est.qt-alocada
               saldo-estoq.qt-aloc-prod = saldo-estoq.qt-aloc-prod + b-saldo-est.qt-aloc-prod
               saldo-estoq.qt-aloc-ped = saldo-estoq.qt-aloc-ped + b-saldo-est.qt-aloc-ped.
        if b-saldo-est.data-ult-ent <> ? and
           (saldo-estoq.data-ult-ent = ? or b-saldo-est.data-ult-ent > saldo-estoq.data-ult-ent) then
            saldo-estoq.data-ult-ent = b-saldo-est.data-ult-ent.
        if b-saldo-est.dt-ul-contag <> ? and
           (saldo-estoq.dt-ul-contag = ? or b-saldo-est.dt-ul-contag > saldo-estoq.dt-ul-contag) then
            saldo-estoq.dt-ul-contag = b-saldo-est.dt-ul-contag.
        delete b-saldo-est.
    end.
    assign saldo-estoq.cod-refer = pcReferencia.
end.
/* fim do include */
END.
ELSE DO:
    /* Adaptacao backend das regras comprovadas no CE0111.
   Nao possui dependencia de frame, Viewer ou acompanhamento visual. */

/********************************************************************************
**
**   Include: CE0111.i - Atualiza Movimentos, Producao, Documentos e Ficha-CQ
**
********************************************************************************/
disable triggers for load of saldo-estoq.
disable triggers for load of inventario.
disable triggers for load of fat-ser-lote.
disable triggers for load of it-dep-fat.
 

for each movto-estoq use-index item-data
    where movto-estoq.it-codigo  = item.it-codigo exclusive-lock:
    assign movto-estoq.lote      = pcLote
           movto-estoq.cod-refer = pcReferencia.
end.
for each movto-mat use-index onde-usou
    where movto-mat.it-codigo = item.it-codigo exclusive-lock:
    assign movto-mat.lote     = pcLote.
end.
for each saldo-terc
    where saldo-terc.it-codigo  = item.it-codigo exclusive-lock:
    assign saldo-terc.lote      = pcLote
           saldo-terc.cod-refer = pcReferencia.
end.

for each componente use-index item
    where componente.it-codigo  = item.it-codigo exclusive-lock:
    assign componente.lote      = pcLote
           componente.cod-refer = pcReferencia.
end.

if  param-global.modulo-cp then do:

    for each ord-prod use-index item
        where ord-prod.it-codigo   = item.it-codigo exclusive-lock:
        assign ord-prod.lote-serie = pcLote
               ord-prod.cod-refer  = pcReferencia.
    end.
    for each reservas use-index data
        where reservas.it-codigo   = item.it-codigo exclusive-lock:
        assign reservas.lote-serie = pcLote
               reservas.cod-refer  = pcReferencia. 
    end.
    for each aloca-reserva use-index saldo
        where aloca-reserva.it-codigo   = item.it-codigo exclusive-lock:
        assign aloca-reserva.lote-serie = pcLote.
        &IF DEFINED (bf_man_sfc_lc) &THEN

        assign aloca-reserva.cod-refer  = pcReferencia. 
        &ENDIF  
    end.
    for each rep-prod use-index item-dat
       where rep-prod.it-codigo = item.it-codigo exclusive-lock:
       assign rep-prod.lote-serie   = pcLote
              rep-prod.cod-refer    = pcReferencia
              rep-prod.dt-vali-lote = pdtValidade.
    end.
end.


for each item-doc-est
    where item-doc-est.it-codigo = item.it-codigo no-lock:
    find b-item-doc-est where rowid(b-item-doc-est) = rowid(item-doc-est)
         exclusive-lock.
    assign b-item-doc-est.lote         = pcLote
           b-item-doc-est.cod-refer    = pcReferencia
           b-item-doc-est.dt-vali-lote = pdtValidade.
end.

for each rat-lote
    where rat-lote.it-codigo = item.it-codigo no-lock:
    find b-rat-lote where rowid(b-rat-lote) = rowid(rat-lote)
         exclusive-lock.
    assign b-rat-lote.lote         = pcLote
           /*b-rat-lote.cod-refer    = pcReferencia*/
           b-rat-lote.dt-vali-lote = pdtValidade.
end.

for each ficha-cq use-index item-ficha
    where ficha-cq.it-codigo = item.it-codigo exclusive-lock:
    assign ficha-cq.lote = pcLote.
end.

/* Altera??es RMA */
&IF DEFINED(bf_mat_versao_ems) &THEN 
  &IF "{&bf_mat_versao_ems}" >= "2.042" &THEN
        
        /* rma-item */
        for each rma-item 
            where rma-item.cod-item = item.it-codigo exclusive-lock:
            assign rma-item.cod-refer = pcReferencia.
        end.
        
        /* rma-it-dep */
        for each rma-it-dep 
            where rma-it-dep.cod-item = item.it-codigo exclusive-lock:
            assign rma-it-dep.lote              = pcLote
                   rma-it-dep.cod-refer         = pcReferencia
                   rma-it-dep.dat-valid-lote    = pdtValidade.
        end.
        
        /* rma-it-troca */
        for each rma-it-troca 
            where rma-it-troca.cod-item = item.it-codigo exclusive-lock:
            assign rma-it-troca.cod-refer = pcReferencia.
        end.
        
        /* item-doc-est-troca */
        for each item-doc-est-troca 
            where item-doc-est-troca.cod-item = item.it-codigo exclusive-lock:
            assign item-doc-est-troca.cod-refer = pcReferencia.
        end.
        
        /* Fim Altera??es RMA */
  &ENDIF
&ENDIF

if  param-global.modulo-cc then do:

    for each ordem-compra USE-INDEX item
       where ordem-compra.it-codigo = item.it-codigo exclusive-lock:
       assign ordem-compra.cod-refer = pcReferencia.
    end.
    for each prazo-compra use-index item
       where prazo-compra.it-codigo = item.it-codigo exclusive-lock:
       assign prazo-compra.cod-refer = pcReferencia.
    end.
end.


for each saldo-estoq use-index item
    where saldo-estoq.it-codigo = item.it-codigo exclusive-lock:
    for each b-saldo-est use-index estabel-dep no-lock
        where b-saldo-est.cod-estabel = saldo-estoq.cod-estabel
        and   b-saldo-est.cod-depos   = saldo-estoq.cod-depos
        and   b-saldo-est.cod-localiz = saldo-estoq.cod-localiz
        and   b-saldo-est.it-codigo   = saldo-estoq.it-codigo
        and   rowid(b-saldo-est)     <> rowid(saldo-estoq):
        assign saldo-estoq.qtidade-atu = saldo-estoq.qtidade-atu
                                       + b-saldo-est.qtidade-atu
               saldo-estoq.qtidade-ini = saldo-estoq.qtidade-ini
                                       + b-saldo-est.qtidade-ini
               saldo-estoq.qtidade-fin = saldo-estoq.qtidade-fin
                                       + b-saldo-est.qtidade-fin
               saldo-estoq.qt-alocada = saldo-estoq.qt-alocada
                                      + b-saldo-est.qt-alocada
               saldo-estoq.qt-aloc-prod = saldo-estoq.qt-aloc-prod
                                        + b-saldo-est.qt-aloc-prod.
        if  b-saldo-est.data-ult-ent > saldo-estoq.data-ult-ent then
            assign saldo-estoq.data-ult-ent = b-saldo-est.data-ult-ent.
        if  b-saldo-est.dt-ul-contag > saldo-estoq.dt-ul-contag then
            assign saldo-estoq.dt-ul-contag = b-saldo-est.dt-ul-contag.
        find b2-saldo-est
            where rowid(b2-saldo-est) = rowid(b-saldo-est) exclusive-lock.
        delete b2-saldo-est validate(true,"").
    end.
    assign saldo-estoq.lote         = pcLote
           saldo-estoq.cod-refer    = pcReferencia
           saldo-estoq.dt-vali-lote = pdtValidade.
end.


for each inventario use-index item
    
    where inventario.it-codigo = item.it-codigo exclusive-lock:
    for each b-invent
        where b-invent.dt-saldo    = inventario.dt-saldo
        and   b-invent.cod-estabel = inventario.cod-estabel
        and   b-invent.cod-depos   = inventario.cod-depos
        and   b-invent.cod-localiz = inventario.cod-localiz
        and   b-invent.it-codigo   = inventario.it-codigo
        and   rowid(b-invent)     <> rowid(inventario) no-lock:
        assign inventario.qtidade-atu  = inventario.qtidade-atu
                                       + b-invent.qtidade-atu
               inventario.valor-contab = inventario.valor-contab
                                       + b-invent.valor-contab
               inventario.valor-final  = inventario.valor-final
                                       + b-invent.valor-final.
        do  i-cont = 1 to 3:
            assign inventario.val-apurado[i-cont] =
                         inventario.val-apurado[i-cont]
                         + b-invent.val-apurado[i-cont]
                   inventario.valor-mat-m[i-cont] =
                         inventario.valor-mat-m[i-cont]
                         + b-invent.valor-mat-m[i-cont]
                   inventario.valor-mat-o[i-cont] =
                         inventario.valor-mat-o[i-cont]
                         + b-invent.valor-mat-o[i-cont]
                   inventario.valor-mat-p[i-cont] =
                         inventario.valor-mat-p[i-cont]
                         + b-invent.valor-mat-p[i-cont]
                   inventario.valor-mob-m[i-cont] =
                         inventario.valor-mob-m[i-cont]
                         + b-invent.valor-mob-m[i-cont]
                   inventario.valor-mob-o[i-cont] =
                         inventario.valor-mob-o[i-cont]
                         + b-invent.valor-mob-o[i-cont]
                   inventario.valor-mob-p[i-cont] =
                         inventario.valor-mob-p[i-cont]
                         + b-invent.valor-mob-p[i-cont]
                   inventario.valor-ggf-m[i-cont] =
                         inventario.valor-ggf-m[i-cont]
                         + b-invent.valor-ggf-m[i-cont]
                   inventario.valor-ggf-o[i-cont] =
                         inventario.valor-ggf-o[i-cont]
                         + b-invent.valor-ggf-o[i-cont]
                   inventario.valor-ggf-p[i-cont] =
                         inventario.valor-ggf-p[i-cont]
                         + b-invent.valor-ggf-p[i-cont].
        end.
        if  b-invent.dt-atualiza > inventario.dt-atualiza then
            assign inventario.dt-atualiza = b-invent.dt-atualiza.
        if  b-invent.dt-ult-entra > inventario.dt-ult-entra then
            assign inventario.dt-ult-entra = b-invent.dt-ult-entra.
        if  b-invent.dt-ult-saida > inventario.dt-ult-saida then
            assign inventario.dt-ult-saida = b-invent.dt-ult-saida.
        find b2-invent
            where rowid(b2-invent) = rowid(b-invent) exclusive-lock.
        delete b2-invent validate(true,"").
    end.
    assign inventario.lote = pcLote.
end.

/* fim include */
END.

/* Adaptacao backend das regras comprovadas no CE0111.
   Nao possui dependencia de frame, Viewer ou acompanhamento visual. */

/********************************************************************************
**
**   Include: CE0111.i3 - Alterando o Modulo de Faturamento
**
********************************************************************************/

disable triggers for load of fat-ser-lote.
disable triggers for load of it-dep-fat.

if  param-global.modulo-ft then do:


    for each  it-nota-fisc exclusive-lock
        where it-nota-fisc.it-codigo = item.it-codigo:

        assign it-nota-fisc.tipo-con-est = piTipoDestino
               it-nota-fisc.cod-refer    = pcReferencia.

        for each fat-ser-lote exclusive-lock
            where fat-ser-lote.cod-estabel = it-nota-fisc.cod-estabel
            and   fat-ser-lote.serie       = it-nota-fisc.serie
            and   fat-ser-lote.nr-nota-fis = it-nota-fisc.nr-nota-fis
            and   fat-ser-lote.nr-seq-fat  = it-nota-fisc.nr-seq-fat:

            for each b-fat-ser-lote no-lock
                where b-fat-ser-lote.cod-estabel = fat-ser-lote.cod-estabel
                and   b-fat-ser-lote.serie       = fat-ser-lote.serie
                and   b-fat-ser-lote.nr-nota-fis = fat-ser-lote.nr-nota-fis
                and   b-fat-ser-lote.nr-seq-fat  = fat-ser-lote.nr-seq-fat
                and   b-fat-ser-lote.cod-depos   = fat-ser-lote.cod-depos
                and   b-fat-ser-lote.cod-localiz = fat-ser-lote.cod-localiz
                and   rowid(b-fat-ser-lote)     <> rowid(fat-ser-lote):

                do  i-cont = 1 to 2:
                    assign fat-ser-lote.qt-baixada[i-cont]
                               = fat-ser-lote.qt-baixada[i-cont]
                               + b-fat-ser-lote.qt-baixada[i-cont].
                end.

                find b2-fat-ser-lote
                    where rowid(b2-fat-ser-lote) = rowid(b-fat-ser-lote)
                    exclusive-lock.
                delete b2-fat-ser-lote validate(true,"").
            end.

            if  item.tipo-con-est > 1
            and pcLote <> "" then 
                assign fat-ser-lote.nr-serlote = pcLote.
            if  item.tipo-con-est = 1 then
                assign fat-ser-lote.nr-serlote = "".

        end.        
    end.

    for each it-dep-fat
        where it-dep-fat.it-codigo    = item.it-codigo exclusive-lock:

        for each b-it-dep-fat no-lock
            where b-it-dep-fat.nr-embarque  = it-dep-fat.nr-embarque
            and   b-it-dep-fat.nr-resumo    = it-dep-fat.nr-resumo
            and   b-it-dep-fat.nome-abrev   = it-dep-fat.nome-abrev
            and   b-it-dep-fat.nr-pedcli    = it-dep-fat.nr-pedcli
            and   b-it-dep-fat.it-codigo    = it-dep-fat.it-codigo
            and   b-it-dep-fat.cod-depos    = it-dep-fat.cod-depos
            and   b-it-dep-fat.cod-localiz  = it-dep-fat.cod-localiz
            and   b-it-dep-fat.nr-sequencia = it-dep-fat.nr-sequencia
/*            and   b-it-dep-fat.cod-refer    = it-dep-fat.cod-refer  */
            and   b-it-dep-fat.cod-estabel  = it-dep-fat.cod-estabel
            and   b-it-dep-fat.nr-entrega   = it-dep-fat.nr-entrega
            and   rowid (b-it-dep-fat)    <> rowid (it-dep-fat):

            assign it-dep-fat.qt-alocada = it-dep-fat.qt-alocada
                                         + b-it-dep-fat.qt-alocada.
            find b2-it-dep-fat
                where rowid(b2-it-dep-fat) = rowid(b-it-dep-fat)
                exclusive-lock no-error.
            delete b2-it-dep-fat validate(true,"").
        end.

        if  item.tipo-con-est > 1
        and pcLote <> "" then 
            assign it-dep-fat.nr-serlote = pcLote. /* a variavel pcLote terah conteudo qdo o item for 2, 3 ou 4.
                   Quando trocado de 2 ou 3 para 4 o pcLote fica em branco para que o lote nao seja alterado */

        if  item.tipo-con-est = 1 then
            assign it-dep-fat.nr-serlote = "".



        &IF DEFINED(BF_DIS_VERSAO_EMS) &THEN

          &IF "{&BF_DIS_VERSAO_EMS}" >= "2.02" &THEN

            assign it-dep-fat.cod-refer = pcReferencia.

          &ENDIF

        &ELSE
            assign it-dep-fat.char-1 = pcReferencia.

        &endif

    end.

    for each it-pre-fat
        where it-pre-fat.it-codigo    = item.it-codigo exclusive-lock:      

        &IF DEFINED(BF_DIS_VERSAO_EMS) &THEN

          &IF "{&BF_DIS_VERSAO_EMS}" >= "2.02" &THEN

            assign it-pre-fat.cod-refer = pcReferencia.

          &ENDIF

        &ELSE
            assign it-pre-fat.char-1 = pcReferencia.

        &endif.

    end.

end.

/* fim include */
/* Adaptacao backend das regras comprovadas no CE0111.
   Nao possui dependencia de frame, Viewer ou acompanhamento visual. */

/*****************************************************************************
**
**      CEP/CE0111.I4 - Atualiza Cod-Refer:
**                      Ped-item, Ped-ent, Ped-saldo.
**
*****************************************************************************/
if param-global.modulo-pd then do:
   for each ped-item use-index contrato
      where ped-item.it-codigo = item.it-codigo exclusive-lock:
       assign ped-item.cod-refer = pcReferencia.
   end.
   
   for each ped-ent use-index it-codigo
      where ped-ent.it-codigo  = item.it-codigo exclusive-lock:
       assign ped-ent.cod-refer = pcReferencia.
   end.

   for each ped-saldo use-index ch-item
      where ped-saldo.it-codigo = item.it-codigo exclusive-lock:
       assign ped-saldo.cod-refer = pcReferencia
              ped-saldo.lote      = pcLote.
   end.
end.


/* FIM */
END PROCEDURE.

PROCEDURE converterControleItem:
DEFINE INPUT  PARAMETER pcItem              AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER piTipoDestino       AS INTEGER   NO-UNDO.
DEFINE INPUT  PARAMETER pcLoteMigracao      AS CHARACTER NO-UNDO.
DEFINE INPUT  PARAMETER pdtValidadeMigracao AS DATE      NO-UNDO.
DEFINE OUTPUT PARAMETER TABLE FOR ttEmbConversaoDiagnostico.
DEFINE OUTPUT PARAMETER piTipoOrigem        AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER piTipoFinal         AS INTEGER   NO-UNDO.
DEFINE OUTPUT PARAMETER plAlterou            AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER plSucesso           AS LOGICAL   NO-UNDO.
DEFINE OUTPUT PARAMETER pcErro              AS CHARACTER NO-UNDO.
DEFINE OUTPUT PARAMETER pcMensagem          AS CHARACTER NO-UNDO.

DEFINE VARIABLE iColisoes  AS INTEGER   NO-UNDO.
DEFINE VARIABLE lValido    AS LOGICAL   NO-UNDO.
DEFINE VARIABLE lCdApi     AS LOGICAL   NO-UNDO.
DEFINE VARIABLE cErro      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cMensagem  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cItem      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLote      AS CHARACTER NO-UNDO.
DEFINE VARIABLE cReferencia AS CHARACTER NO-UNDO.
DEFINE VARIABLE dtValidade AS DATE      NO-UNDO.

ASSIGN cItem       = IF pcItem = ? THEN "" ELSE TRIM(pcItem, " ")
       cLote       = IF piTipoDestino = 3
                     THEN (IF pcLoteMigracao = ? THEN "" ELSE TRIM(pcLoteMigracao, " "))
                     ELSE ""
       cReferencia = ""
       dtValidade  = IF piTipoDestino = 3 THEN pdtValidadeMigracao ELSE ?
       piTipoOrigem = 0 piTipoFinal = 0 plAlterou = NO plSucesso = NO
       pcErro = "FALHA_CONVERSAO" pcMensagem = "Nao foi possivel concluir a conversao do item.".

RUN analisarConversao(INPUT cItem, INPUT piTipoDestino,
    INPUT cLote, INPUT dtValidade,
    OUTPUT TABLE ttEmbConversaoDiagnostico,
    OUTPUT piTipoOrigem, OUTPUT iColisoes,
    OUTPUT lValido, OUTPUT cErro, OUTPUT cMensagem).
IF NOT lValido THEN DO:
    ASSIGN pcErro = cErro pcMensagem = cMensagem.
    RETURN.
END.

/* Referencia -> Lote nao recebe lote/validade de migracao. O CE0111 limpa
   esses campos da tela, preserva os lotes existentes onde previsto e limpa
   explicitamente ped-saldo.lote. */
IF piTipoOrigem = 4 AND piTipoDestino = 3 THEN
    ASSIGN cLote = "" dtValidade = ?.

IF piTipoOrigem = piTipoDestino THEN DO:
    ASSIGN piTipoFinal = piTipoDestino plSucesso = YES
           pcErro = "" pcMensagem = "".
    RETURN.
END.

conversao:
DO TRANSACTION ON ERROR UNDO conversao, LEAVE conversao:
    RUN alterarTipoPelaCdApiItem(INPUT cItem, INPUT piTipoDestino,
        OUTPUT lCdApi, OUTPUT cErro, OUTPUT cMensagem) NO-ERROR.
    IF ERROR-STATUS:ERROR OR ERROR-STATUS:NUM-MESSAGES > 0 THEN DO:
        ASSIGN pcErro     = "FALHA_CDAPIITEM"
               pcMensagem = IF ERROR-STATUS:NUM-MESSAGES > 0
                            THEN ERROR-STATUS:GET-MESSAGE(1)
                            ELSE "Falha nao detalhada ao executar a API padrao do item.".
        UNDO conversao, LEAVE conversao.
    END.
    IF NOT lCdApi THEN DO:
        ASSIGN pcErro = cErro pcMensagem = cMensagem.
        UNDO conversao, LEAVE conversao.
    END.

    RUN atualizarHistorico(INPUT cItem, INPUT piTipoOrigem,
        INPUT piTipoDestino, INPUT cLote, INPUT cReferencia, INPUT dtValidade) NO-ERROR.
    IF ERROR-STATUS:ERROR OR ERROR-STATUS:NUM-MESSAGES > 0 THEN DO:
        ASSIGN pcErro     = "FALHA_ATUALIZACAO_HISTORICO"
               pcMensagem = IF ERROR-STATUS:NUM-MESSAGES > 0
                            THEN ERROR-STATUS:GET-MESSAGE(1)
                            ELSE "Falha nao detalhada ao atualizar o historico do item.".
        UNDO conversao, LEAVE conversao.
    END.

    FIND FIRST item NO-LOCK
         WHERE item.it-codigo = cItem
         USE-INDEX codigo NO-ERROR.
    IF NOT AVAILABLE item OR item.tipo-con-est <> piTipoDestino THEN DO:
        ASSIGN pcErro = "TIPO_NAO_CONFIRMADO"
               pcMensagem = "A API padrao nao confirmou o tipo de controle solicitado.".
        UNDO conversao, LEAVE conversao.
    END.

    ASSIGN piTipoFinal = item.tipo-con-est
           plAlterou   = YES
           plSucesso   = YES
           pcErro      = ""
           pcMensagem  = "".
END.
END PROCEDURE.
