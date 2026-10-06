/* Contrato compartilhado do backend Progress do Controle de Embalagens.
   Somente temp-tables e estruturas comuns; nenhuma regra de negocio. */
/* E04: selecao recebida da PI depois da criacao confirmada do wt-docto.
   Quantidade representa a embalagem inteira neste recorte de transferencia. */
DEFINE TEMP-TABLE ttEmbSelecaoSaida NO-UNDO
    FIELD id-etiqueta LIKE contr_emb_etiqueta.id-etiqueta
    FIELD quantidade LIKE contr_emb_oper_item.quantidade
    INDEX etiqueta id-etiqueta.

/* Projecao de leitura. Nao cria estrutura fisica. Modelo v1.7 / ET-01B. */
DEFINE TEMP-TABLE ttEmbTipo NO-UNDO
    FIELD cod-tipo          LIKE contr_emb_bag.cod-tipo
    FIELD desc-embalagem    LIKE contr_emb_bag.desc-embalagem
    FIELD ativo            LIKE contr_emb_bag.ativo
    FIELD dt-inclusao      LIKE contr_emb_bag.dt-inclusao
    FIELD usuario-inclusao LIKE contr_emb_bag.usuario-inclusao
    FIELD dt-alteracao     LIKE contr_emb_bag.dt-alteracao
    FIELD usuario-alteracao LIKE contr_emb_bag.usuario-alteracao
    FIELD versao           LIKE contr_emb_bag.versao
    INDEX pk IS PRIMARY UNIQUE cod-tipo.

/* Projecoes transitorias. Permissoes vem do adaptador confiavel, nao do JSON. */
DEFINE TEMP-TABLE ttEmbEstabelPermitido NO-UNDO
    FIELD cod-estabel LIKE contr_emb_param.cod-estabel
    INDEX pk IS PRIMARY UNIQUE cod-estabel.

DEFINE TEMP-TABLE ttEmbParametro NO-UNDO
    FIELD id-param         LIKE contr_emb_param.id-param
    FIELD cod-estabel      LIKE contr_emb_param.cod-estabel
    FIELD it-codigo        LIKE contr_emb_param.it-codigo
    FIELD cod-tipo         LIKE contr_emb_param.cod-tipo
    FIELD capacidade-emb   LIKE contr_emb_param.capacidade-emb
    FIELD un               LIKE contr_emb_param.un
    FIELD ativo            LIKE contr_emb_param.ativo
    FIELD dt-inclusao      LIKE contr_emb_param.dt-inclusao
    FIELD usuario-inclusao LIKE contr_emb_param.usuario-inclusao
    FIELD dt-alteracao     LIKE contr_emb_param.dt-alteracao
    FIELD usuario-alteracao LIKE contr_emb_param.usuario-alteracao
    FIELD versao           LIKE contr_emb_param.versao
    INDEX pk IS PRIMARY UNIQUE id-param.

/* ET-05A: projecao da ocorrencia, sem estrutura fisica ou totalizacao. */
DEFINE TEMP-TABLE ttEmbBag NO-UNDO
    FIELD id-bag LIKE contr_emb_bag_lacre.id-bag
    FIELD cod-tipo LIKE contr_emb_bag_lacre.cod-tipo
    FIELD cod-estabel LIKE contr_emb_bag_lacre.cod-estabel
    FIELD cod-depos LIKE contr_emb_bag_lacre.cod-depos
    FIELD nro-lacre LIKE contr_emb_bag_lacre.nro-lacre
    FIELD situacao LIKE contr_emb_bag_lacre.situacao
    FIELD dt-lacre LIKE contr_emb_bag_lacre.dt-lacre
    FIELD dt-envio LIKE contr_emb_bag_lacre.dt-envio
    FIELD dt-devolucao LIKE contr_emb_bag_lacre.dt-devolucao
    FIELD tipo-destino LIKE contr_emb_bag_lacre.tipo-destino
    FIELD cod-estabel-dest LIKE contr_emb_bag_lacre.cod-estabel-dest
    FIELD cod-emitente-dest LIKE contr_emb_bag_lacre.cod-emitente-dest
    FIELD origem-local-dest LIKE contr_emb_bag_lacre.origem-local-dest
    FIELD cod-local-dest LIKE contr_emb_bag_lacre.cod-local-dest
    FIELD motorista LIKE contr_emb_bag_lacre.motorista
    FIELD id-bag-anterior LIKE contr_emb_bag_lacre.id-bag-anterior
    FIELD dt-inclusao LIKE contr_emb_bag_lacre.dt-inclusao
    FIELD dt-alteracao LIKE contr_emb_bag_lacre.dt-alteracao
    FIELD versao LIKE contr_emb_bag_lacre.versao
    INDEX pk IS PRIMARY UNIQUE id-bag.

/* Apoios de leitura DT-064; cadastro funcional em mgcad, nunca no holder. */
DEFINE TEMP-TABLE ttEmbEstabelecimento NO-UNDO
    FIELD codigo LIKE mgcad.estabelec.cod-estabel
    FIELD descricao LIKE mgcad.estabelec.nome
    INDEX pk IS PRIMARY UNIQUE codigo.
DEFINE TEMP-TABLE ttEmbItem NO-UNDO
    FIELD codigo LIKE mgcad.item.it-codigo
    FIELD descricao LIKE mgcad.item.desc-item
    FIELD un LIKE mgcad.item.un
    FIELD tipo-controle-estoque LIKE mgcad.item.tipo-con-est
    INDEX pk IS PRIMARY UNIQUE codigo.

/* Projecao atual da identidade individual ou do PRE de transicao. */
DEFINE TEMP-TABLE ttEmbEtiqueta NO-UNDO
    FIELD id-etiqueta         LIKE contr_emb_etiqueta.id-etiqueta
    FIELD cod-etiqueta        LIKE contr_emb_etiqueta.cod-etiqueta
    FIELD tipo-controle       LIKE contr_emb_etiqueta.tipo-controle
    FIELD id-pre-origem       LIKE contr_emb_etiqueta.id-pre-origem
    FIELD id-evento-geracao   LIKE contr_emb_etiqueta.id-evento-geracao
    FIELD id-item-evento      LIKE contr_emb_etiqueta.id-item-evento
    FIELD seq-geracao         LIKE contr_emb_etiqueta.seq-geracao
    FIELD it-codigo           LIKE contr_emb_etiqueta.it-codigo
    FIELD cod-tipo            LIKE contr_emb_etiqueta.cod-tipo
    FIELD lote                LIKE contr_emb_etiqueta.lote
    FIELD dt-vali-lote        LIKE contr_emb_etiqueta.dt-vali-lote
    FIELD un                  LIKE contr_emb_etiqueta.un
    FIELD capacidade-emb      LIKE contr_emb_etiqueta.capacidade-emb
    FIELD qtidade-ini         LIKE contr_emb_etiqueta.qtidade-ini
    FIELD qtidade-atu         LIKE contr_emb_etiqueta.qtidade-atu
    FIELD cod-estabel         LIKE contr_emb_etiqueta.cod-estabel
    FIELD cod-depos           LIKE contr_emb_etiqueta.cod-depos
    FIELD cod-localiz         LIKE contr_emb_etiqueta.cod-localiz
    FIELD tipo-local          LIKE contr_emb_etiqueta.tipo-local
    FIELD cod-emitente-posse  LIKE contr_emb_etiqueta.cod-emitente-posse
    FIELD origem-local-ext    LIKE contr_emb_etiqueta.origem-local-ext
    FIELD cod-local-ext       LIKE contr_emb_etiqueta.cod-local-ext
    FIELD id-bag              LIKE contr_emb_etiqueta.id-bag
    FIELD situacao            LIKE contr_emb_etiqueta.situacao
    FIELD id-movto-ult        LIKE contr_emb_etiqueta.id-movto-ult
    FIELD dt-inclusao         LIKE contr_emb_etiqueta.dt-inclusao
    FIELD usuario-inclusao    LIKE contr_emb_etiqueta.usuario-inclusao
    FIELD dt-alteracao        LIKE contr_emb_etiqueta.dt-alteracao
    FIELD usuario-alteracao   LIKE contr_emb_etiqueta.usuario-alteracao
    FIELD versao              LIKE contr_emb_etiqueta.versao
    INDEX pk IS PRIMARY UNIQUE id-etiqueta.

/* GER-04: cabecalho funcional da geracao. Nao expoe hashes, token de
   processamento nem o payload tecnico persistido no evento. */
DEFINE TEMP-TABLE ttEmbGeracao NO-UNDO
    FIELD id-evento         LIKE contr_emb_evento.id-evento
    FIELD origem            LIKE contr_emb_evento.origem
    FIELD tipo-evento       LIKE contr_emb_evento.tipo-evento
    FIELD id-operacao       LIKE contr_emb_evento.id-operacao
    FIELD id-evento-origem  LIKE contr_emb_evento.id-evento-origem
    FIELD seq-ciclo         LIKE contr_emb_evento.seq-ciclo
    FIELD dt-evento         LIKE contr_emb_evento.dt-evento
    FIELD versao-contrato   LIKE contr_emb_evento.versao-contrato
    FIELD tipo-docto        LIKE contr_emb_evento.tipo-docto
    FIELD chave-docto       LIKE contr_emb_evento.chave-docto
    FIELD cod-estabel       LIKE contr_emb_evento.cod-estabel
    FIELD cod-emitente      LIKE contr_emb_evento.cod-emitente
    FIELD cgc-emitente      LIKE contr_emb_evento.cgc-emitente
    FIELD serie             LIKE contr_emb_evento.serie
    FIELD nro-docto         LIKE contr_emb_evento.nro-docto
    FIELD chave-acesso      LIKE contr_emb_evento.chave-acesso
    FIELD nat-operacao      LIKE contr_emb_evento.nat-operacao
    FIELD dt-emissao        LIKE contr_emb_evento.dt-emissao
    FIELD situacao          LIKE contr_emb_evento.situacao
    FIELD tentativas        LIKE contr_emb_evento.tentativas
    FIELD dt-conclusao      LIKE contr_emb_evento.dt-conclusao
    FIELD resultado         LIKE contr_emb_evento.resultado
    FIELD mensagem          LIKE contr_emb_evento.mensagem
    FIELD dt-inclusao       LIKE contr_emb_evento.dt-inclusao
    FIELD usuario-inclusao  LIKE contr_emb_evento.usuario-inclusao
    FIELD dt-alteracao      LIKE contr_emb_evento.dt-alteracao
    FIELD usuario-alteracao LIKE contr_emb_evento.usuario-alteracao
    FIELD versao            LIKE contr_emb_evento.versao
    INDEX pk IS PRIMARY UNIQUE id-evento.

/* GER-04: memoria de calculo por item/lote do evento. */
DEFINE TEMP-TABLE ttEmbGeracaoItem NO-UNDO
    FIELD id-item-evento    LIKE contr_emb_evento_item.id-item-evento
    FIELD id-evento         LIKE contr_emb_evento_item.id-evento
    FIELD sequencia         LIKE contr_emb_evento_item.sequencia
    FIELD seq-lote          LIKE contr_emb_evento_item.seq-lote
    FIELD it-codigo         LIKE contr_emb_evento_item.it-codigo
    FIELD cod-item-origem   LIKE contr_emb_evento_item.cod-item-origem
    FIELD lote              LIKE contr_emb_evento_item.lote
    FIELD dt-vali-lote      LIKE contr_emb_evento_item.dt-vali-lote
    FIELD qt-origem         LIKE contr_emb_evento_item.qt-origem
    FIELD un-origem         LIKE contr_emb_evento_item.un-origem
    FIELD fator-conversao   LIKE contr_emb_evento_item.fator-conversao
    FIELD quantidade        LIKE contr_emb_evento_item.quantidade
    FIELD un                LIKE contr_emb_evento_item.un
    FIELD cod-depos         LIKE contr_emb_evento_item.cod-depos
    FIELD id-param-origem   LIKE contr_emb_evento_item.id-param-origem
    FIELD versao-param      LIKE contr_emb_evento_item.versao-param
    FIELD cod-tipo          LIKE contr_emb_evento_item.cod-tipo
    FIELD capacidade-emb    LIKE contr_emb_evento_item.capacidade-emb
    FIELD qtd-etiquetas     LIKE contr_emb_evento_item.qtd-etiquetas
    FIELD qt-residuo        LIKE contr_emb_evento_item.qt-residuo
    FIELD situacao-item     LIKE contr_emb_evento_item.situacao-item
    FIELD mensagem          LIKE contr_emb_evento_item.mensagem
    FIELD versao            LIKE contr_emb_evento_item.versao
    INDEX pk IS PRIMARY UNIQUE id-item-evento
    INDEX evento id-evento sequencia seq-lote.

/* GER-04: fotografia de nascimento. A posicao/situacao atual continua sendo
   responsabilidade de consultarEtiquetas e nao e repetida nesta projecao. */
DEFINE TEMP-TABLE ttEmbEtiquetaGerada NO-UNDO
    FIELD id-etiqueta       LIKE contr_emb_etiqueta.id-etiqueta
    FIELD cod-etiqueta      LIKE contr_emb_etiqueta.cod-etiqueta
    FIELD tipo-controle     LIKE contr_emb_etiqueta.tipo-controle
    FIELD id-evento-geracao LIKE contr_emb_etiqueta.id-evento-geracao
    FIELD id-item-evento    LIKE contr_emb_etiqueta.id-item-evento
    FIELD seq-geracao       LIKE contr_emb_etiqueta.seq-geracao
    FIELD it-codigo         LIKE contr_emb_etiqueta.it-codigo
    FIELD cod-tipo          LIKE contr_emb_etiqueta.cod-tipo
    FIELD lote              LIKE contr_emb_etiqueta.lote
    FIELD dt-vali-lote      LIKE contr_emb_etiqueta.dt-vali-lote
    FIELD un                LIKE contr_emb_etiqueta.un
    FIELD capacidade-emb    LIKE contr_emb_etiqueta.capacidade-emb
    FIELD qtidade-ini       LIKE contr_emb_etiqueta.qtidade-ini
    FIELD dt-inclusao       LIKE contr_emb_etiqueta.dt-inclusao
    FIELD usuario-inclusao  LIKE contr_emb_etiqueta.usuario-inclusao
    INDEX pk IS PRIMARY UNIQUE id-etiqueta
    INDEX geracao id-evento-geracao id-etiqueta.

/* ET-02 / DT-076: fotografia canonica preparada pelo produtor do evento.
   Nao contem estado de processamento; registrarEvento controla esse estado. */
DEFINE TEMP-TABLE ttEmbEventoComando NO-UNDO
    FIELD origem            LIKE contr_emb_evento.origem
    FIELD chave-evento      LIKE contr_emb_evento.chave-evento
    FIELD hash-chave        LIKE contr_emb_evento.hash-chave
    FIELD hash-conteudo     LIKE contr_emb_evento.hash-conteudo
    FIELD tipo-evento       LIKE contr_emb_evento.tipo-evento
    FIELD id-operacao       LIKE contr_emb_evento.id-operacao
    FIELD id-evento-origem  LIKE contr_emb_evento.id-evento-origem
    FIELD seq-ciclo         LIKE contr_emb_evento.seq-ciclo
    FIELD dt-evento         LIKE contr_emb_evento.dt-evento
    FIELD versao-contrato   LIKE contr_emb_evento.versao-contrato
    FIELD tipo-docto        LIKE contr_emb_evento.tipo-docto
    FIELD chave-docto       LIKE contr_emb_evento.chave-docto
    FIELD hash-docto        LIKE contr_emb_evento.hash-docto
    FIELD cod-estabel       LIKE contr_emb_evento.cod-estabel
    FIELD cod-emitente      LIKE contr_emb_evento.cod-emitente
    FIELD cgc-emitente      LIKE contr_emb_evento.cgc-emitente
    FIELD serie             LIKE contr_emb_evento.serie
    FIELD nro-docto         LIKE contr_emb_evento.nro-docto
    FIELD chave-acesso      LIKE contr_emb_evento.chave-acesso
    FIELD nat-operacao      LIKE contr_emb_evento.nat-operacao
    FIELD dt-emissao        LIKE contr_emb_evento.dt-emissao
    FIELD dados-evento      LIKE contr_emb_evento.dados-evento
    FIELD usuario           LIKE contr_emb_evento.usuario-inclusao.

/* ET-02 / DT-076: comando comum ja classificado pelo produtor do fluxo.
   Zero nos IDs opcionais significa ausencia; nenhum efeito ERP e inferido aqui. */
DEFINE TEMP-TABLE ttEmbMovimentoComando NO-UNDO
    FIELD id-evento                  LIKE contr_emb_movto.id-evento
    FIELD sequencia                  LIKE contr_emb_movto.sequencia
    FIELD id-etiqueta                LIKE contr_emb_movto.id-etiqueta
    FIELD id-item-evento             LIKE contr_emb_movto.id-item-evento
    FIELD id-item-oper               LIKE contr_emb_movto.id-item-oper
    FIELD id-movto-ant-esperado      LIKE contr_emb_movto.id-movto-ant
    FIELD id-bag-relac               LIKE contr_emb_movto.id-bag-relac
    FIELD id-bag-destino             LIKE contr_emb_etiqueta.id-bag
    FIELD id-movto-origem            LIKE contr_emb_movto.id-movto-origem
    FIELD tipo-movto                 LIKE contr_emb_movto.tipo-movto
    FIELD dt-movto                   LIKE contr_emb_movto.dt-movto
    FIELD un                         LIKE contr_emb_movto.un
    FIELD quantidade                 LIKE contr_emb_movto.quantidade
    FIELD qtidade-atu                LIKE contr_emb_movto.qtidade-atu
    FIELD situacao-atu               LIKE contr_emb_movto.situacao-atu
    FIELD cod-estabel-dest           LIKE contr_emb_movto.cod-estabel-dest
    FIELD cod-depos-dest             LIKE contr_emb_movto.cod-depos-dest
    FIELD cod-localiz-dest           LIKE contr_emb_movto.cod-localiz-dest
    FIELD tipo-local-dest            LIKE contr_emb_movto.tipo-local-dest
    FIELD cod-emitente-dest          LIKE contr_emb_movto.cod-emitente-dest
    FIELD origem-local-ext-dest      LIKE contr_emb_movto.origem-local-ext-dest
    FIELD cod-local-ext-dest         LIKE contr_emb_movto.cod-local-ext-dest
    FIELD origem-movto-erp           LIKE contr_emb_movto.origem-movto-erp
    FIELD chave-movto-erp            LIKE contr_emb_movto.chave-movto-erp
    FIELD justificativa              LIKE contr_emb_movto.justificativa
    FIELD versao-etiqueta-esperada   LIKE contr_emb_etiqueta.versao
    FIELD usuario                    LIKE contr_emb_movto.usuario.

/* GER-02: fotografia recebida do adaptador interno. O adaptador fornece a
   ocorrencia fiscal confirmada; esta estrutura nao representa uma chamada
   livre da interface e nao persiste dados por si so. */
DEFINE TEMP-TABLE ttEmbGeracaoLinha NO-UNDO
    FIELD sequencia         LIKE contr_emb_evento_item.sequencia
    FIELD seq-lote          LIKE contr_emb_evento_item.seq-lote
    FIELD cod-estabel       LIKE contr_emb_evento.cod-estabel
    FIELD it-codigo         LIKE contr_emb_evento_item.it-codigo
    FIELD cod-item-origem   LIKE contr_emb_evento_item.cod-item-origem
    FIELD lote              LIKE contr_emb_evento_item.lote
    FIELD dt-vali-lote      LIKE contr_emb_evento_item.dt-vali-lote
    FIELD qt-origem         LIKE contr_emb_evento_item.qt-origem
    FIELD un-origem         LIKE contr_emb_evento_item.un-origem
    FIELD cod-depos         LIKE contr_emb_evento_item.cod-depos
    INDEX ocorrencia sequencia seq-lote.

/* GER-02/GER-03: calculo validado e fotografia do parametro vigente. A
   estrutura e consumida somente pelo servico interno de geracao. */
DEFINE TEMP-TABLE ttEmbGeracaoValidada NO-UNDO
    FIELD sequencia         LIKE contr_emb_evento_item.sequencia
    FIELD seq-lote          LIKE contr_emb_evento_item.seq-lote
    FIELD cod-estabel       LIKE contr_emb_evento.cod-estabel
    FIELD it-codigo         LIKE contr_emb_evento_item.it-codigo
    FIELD cod-item-origem   LIKE contr_emb_evento_item.cod-item-origem
    FIELD lote              LIKE contr_emb_evento_item.lote
    FIELD dt-vali-lote      LIKE contr_emb_evento_item.dt-vali-lote
    FIELD qt-origem         LIKE contr_emb_evento_item.qt-origem
    FIELD un-origem         LIKE contr_emb_evento_item.un-origem
    FIELD fator-conversao   LIKE contr_emb_evento_item.fator-conversao
    FIELD quantidade        LIKE contr_emb_evento_item.quantidade
    FIELD un                LIKE contr_emb_evento_item.un
    FIELD cod-depos         LIKE contr_emb_evento_item.cod-depos
    FIELD id-param-origem   LIKE contr_emb_evento_item.id-param-origem
    FIELD versao-param      LIKE contr_emb_evento_item.versao-param
    FIELD cod-tipo          LIKE contr_emb_evento_item.cod-tipo
    FIELD capacidade-emb    LIKE contr_emb_evento_item.capacidade-emb
    FIELD qtd-etiquetas     LIKE contr_emb_evento_item.qtd-etiquetas
    FIELD qt-residuo        LIKE contr_emb_evento_item.qt-residuo
    FIELD situacao-item     LIKE contr_emb_evento_item.situacao-item
    FIELD mensagem          LIKE contr_emb_evento_item.mensagem
    INDEX ocorrencia IS PRIMARY UNIQUE sequencia seq-lote.



/* DT-072: projecao transitoria; nenhuma tabela fisica nova. */
DEFINE TEMP-TABLE ttEmbFamilia NO-UNDO
    FIELD codigo LIKE mgcad.familia.fm-codigo
    FIELD descricao LIKE mgcad.familia.descricao
    INDEX pk IS PRIMARY UNIQUE codigo.

/* Consulta paginada de embalagens da entrada escolhida; projecao sem persistencia. */
DEFINE TEMP-TABLE ttEmbDevolucaoSelecao NO-UNDO
    FIELD id-etiqueta LIKE contr_emb_etiqueta.id-etiqueta
    FIELD versao LIKE contr_emb_etiqueta.versao
    FIELD quantidade LIKE contr_emb_oper_item.quantidade
    INDEX etiqueta id-etiqueta.

DEFINE TEMP-TABLE ttEmbDevolucaoLinha NO-UNDO
    FIELD sequencia-origem LIKE contr_emb_evento_item.sequencia
    FIELD seq-wt-it-docto AS INTEGER
    FIELD it-codigo LIKE contr_emb_etiqueta.it-codigo
    FIELD lote LIKE contr_emb_etiqueta.lote
    FIELD dt-vali-lote LIKE contr_emb_etiqueta.dt-vali-lote
    FIELD un LIKE contr_emb_etiqueta.un
    FIELD cod-depos LIKE contr_emb_etiqueta.cod-depos
    FIELD cod-localiz LIKE contr_emb_etiqueta.cod-localiz
    FIELD quantidade LIKE contr_emb_oper_item.quantidade
    INDEX grupo IS PRIMARY UNIQUE sequencia-origem it-codigo lote
        dt-vali-lote un cod-depos cod-localiz.

DEFINE TEMP-TABLE ttEmbOrigemDevolucao NO-UNDO
    FIELD id-etiqueta LIKE contr_emb_etiqueta.id-etiqueta
    FIELD cod-etiqueta LIKE contr_emb_etiqueta.cod-etiqueta
    FIELD id-evento-origem LIKE contr_emb_evento.id-evento
    FIELD id-movto-origem LIKE contr_emb_movto.id-movto
    FIELD sequencia-origem LIKE contr_emb_evento_item.sequencia
    FIELD it-codigo LIKE contr_emb_etiqueta.it-codigo
    FIELD lote LIKE contr_emb_etiqueta.lote
    FIELD dt-vali-lote LIKE contr_emb_etiqueta.dt-vali-lote
    FIELD un LIKE contr_emb_etiqueta.un
    FIELD cod-depos LIKE contr_emb_etiqueta.cod-depos
    FIELD cod-localiz LIKE contr_emb_etiqueta.cod-localiz
    FIELD quantidade-origem LIKE contr_emb_movto.quantidade
    FIELD quantidade-atual LIKE contr_emb_etiqueta.qtidade-atu
    FIELD disponivel-linha LIKE contr_emb_oper_item.quantidade
    FIELD versao-etiqueta LIKE contr_emb_etiqueta.versao
    FIELD pode-selecionar AS LOGICAL
    FIELD motivo AS CHARACTER
    INDEX pk IS PRIMARY UNIQUE id-etiqueta.
