<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Mulish:wght@400;600;700;800&display=swap">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/tabulator/6.4.0/css/tabulator_simple.min.css">

<div id="widget_nw_embalagens_${instanceId}" class="super-widget wcm-widget-class fluig-style-guide nwe" data-params="widget_nw_embalagens.instance()">
    <div class="nwe-cabecalho">
        <span class="nwe-selo" aria-hidden="true"><span class="nwe-selo-miolo"><i class="bi bi-boxes"></i></span></span>
        <div class="nwe-cabecalho-texto">
            <h2 class="nwe-cabecalho-titulo">Tipos de Embalagens</h2>
            <p class="nwe-cabecalho-subtitulo">Cadastre, edite, inative e consulte os tipos de embalagem.</p>
        </div>
        <div class="nwe-cabecalho-acoes">
            <button type="button" class="nwe-btn nwe-btn-destaque" data-novo disabled><i class="bi bi-plus-lg" aria-hidden="true"></i>Novo</button>
        </div>
    </div>
    <div class="nwe-tabs" role="tablist" aria-label="Seções">
        <button type="button" class="nwe-tab is-active" role="tab" aria-selected="true" tabindex="0" data-aba="tipos-embalagem" data-tab><i class="bi bi-box-seam" aria-hidden="true"></i>Tipos de Embalagens</button>
        <span class="nwe-tabs-indicador" aria-hidden="true"></span>
    </div>
    <div class="nwe-filtros" role="search" aria-label="Filtros">
        <div class="nwe-campo">
            <label class="nwe-campo-rotulo" for="nwe-filtro-tipo-${instanceId}">Tipo/Sigla Embalagem</label>
            <div class="nwe-campo-caixa">
                <i class="bi bi-search" aria-hidden="true"></i>
                <input type="text" id="nwe-filtro-tipo-${instanceId}" class="nwe-campo-input" placeholder="Buscar por tipo de embalagem ou sigla" maxlength="100" autocomplete="off" data-filtro-tipo>
            </div>
        </div>
        <div class="nwe-filtros-acoes">
            <button type="button" class="nwe-btn nwe-btn-contorno" data-buscar disabled><i class="bi bi-search" aria-hidden="true"></i>Buscar</button>
        </div>
    </div>
    <div class="nwe-tabela" data-tabela></div>

    <dialog class="nwe-modal" aria-labelledby="nwe-modal-titulo-${instanceId}" data-modal-novo>
        <form class="nwe-modal-form" novalidate>
            <div class="nwe-modal-cabecalho">
                <div>
                    <h3 class="nwe-modal-titulo" id="nwe-modal-titulo-${instanceId}" data-modal-titulo>Novo tipo de embalagem</h3>
                    <p class="nwe-modal-subtitulo" data-modal-subtitulo>Preencha a descrição e a sigla para cadastrar.</p>
                </div>
                <button type="button" class="nwe-modal-fechar" aria-label="Fechar" data-fechar-modal><i class="bi bi-x-lg" aria-hidden="true"></i></button>
            </div>

            <div class="nwe-modal-corpo">
                <div class="nwe-campo">
                    <label class="nwe-campo-rotulo" for="nwe-novo-descricao-${instanceId}">Descrição</label>
                    <input type="text" id="nwe-novo-descricao-${instanceId}" name="descricao" class="nwe-campo-input nwe-campo-input-simples" placeholder="Ex.: Caixa" maxlength="100" autocomplete="off" required autofocus aria-describedby="nwe-novo-descricao-erro-${instanceId}">
                    <p class="nwe-campo-erro" id="nwe-novo-descricao-erro-${instanceId}" data-erro="descricao"></p>
                </div>
                <div class="nwe-campo">
                    <label class="nwe-campo-rotulo" for="nwe-novo-sigla-${instanceId}">Sigla</label>
                    <input type="text" id="nwe-novo-sigla-${instanceId}" name="sigla" class="nwe-campo-input nwe-campo-input-simples nwe-campo-input-sigla" placeholder="Ex.: CX" maxlength="2" autocomplete="off" required aria-describedby="nwe-novo-sigla-dica-${instanceId} nwe-novo-sigla-erro-${instanceId}">
                    <p class="nwe-campo-dica" id="nwe-novo-sigla-dica-${instanceId}" data-sigla-dica>Até 2 caracteres.</p>
                    <p class="nwe-campo-erro" id="nwe-novo-sigla-erro-${instanceId}" data-erro="sigla"></p>
                </div>
                <p class="nwe-modal-alerta" role="alert" data-modal-alerta></p>
            </div>

            <div class="nwe-modal-rodape">
                <button type="button" class="nwe-btn nwe-btn-contorno" data-fechar-modal>Cancelar</button>
                <button type="submit" class="nwe-btn nwe-btn-destaque"><i class="bi bi-check-lg" aria-hidden="true"></i><span data-modal-salvar>Salvar</span></button>
            </div>
        </form>
    </dialog>

    <dialog class="nwe-modal nwe-modal-pequeno" role="alertdialog" aria-labelledby="nwe-situacao-titulo-${instanceId}" aria-describedby="nwe-situacao-texto-${instanceId}" data-modal-situacao>
        <div class="nwe-modal-confirmacao">
            <span class="nwe-confirmacao-icone" aria-hidden="true"><i class="bi bi-slash-circle" data-situacao-icone></i></span>
            <h3 class="nwe-modal-titulo" id="nwe-situacao-titulo-${instanceId}" data-situacao-titulo>Inativar tipo de embalagem?</h3>
            <p class="nwe-modal-subtitulo" id="nwe-situacao-texto-${instanceId}">O tipo <strong data-situacao-item></strong><span data-situacao-efeito></span></p>
            <p class="nwe-modal-alerta" role="alert" data-situacao-alerta></p>
        </div>
        <div class="nwe-modal-rodape">
            <button type="button" class="nwe-btn nwe-btn-contorno" autofocus data-fechar-situacao>Cancelar</button>
            <button type="button" class="nwe-btn nwe-btn-perigo" data-confirmar-situacao><span data-situacao-botao>Inativar</span></button>
        </div>
    </dialog>
</div>
