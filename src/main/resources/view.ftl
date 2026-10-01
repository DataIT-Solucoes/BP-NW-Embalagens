<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Mulish:wght@400;600;700;800&display=swap">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/tabulator/6.4.0/css/tabulator_simple.min.css">

<div id="widget_nw_embalagens_${instanceId}" class="super-widget wcm-widget-class fluig-style-guide nwe" data-params="widget_nw_embalagens.instance()">
    <div class="nwe-cabecalho">
        <span class="nwe-selo" aria-hidden="true"><span class="nwe-selo-miolo"><i class="bi bi-boxes"></i></span></span>
        <div class="nwe-cabecalho-texto">
            <h2 class="nwe-cabecalho-titulo">Tipos de Embalagens</h2>
            <p class="nwe-cabecalho-subtitulo">Cadastre, edite, exclua e consulte os tipos de embalagem.</p>
        </div>
        <div class="nwe-cabecalho-acoes">
            <button type="button" class="nwe-btn nwe-btn-destaque" data-novo><i class="bi bi-plus-lg" aria-hidden="true"></i>Novo</button>
        </div>
    </div>
    <div class="nwe-tabs" role="tablist" aria-label="Seções">
        <button type="button" class="nwe-tab is-active" role="tab" aria-selected="true" tabindex="0" data-aba="tipos-embalagem" data-tab><i class="bi bi-box-seam" aria-hidden="true"></i>Tipos de Embalagens</button>
        <span class="nwe-tabs-indicador" aria-hidden="true"></span>
    </div>
    <div class="nwe-filtros" role="search" aria-label="Filtros">
        <div class="nwe-campo">
            <label class="nwe-campo-rotulo" for="nwe-filtro-tipo-${instanceId}">Tipo Embalagem</label>
            <div class="nwe-campo-caixa">
                <i class="bi bi-search" aria-hidden="true"></i>
                <input type="text" id="nwe-filtro-tipo-${instanceId}" class="nwe-campo-input" placeholder="Buscar por tipo de embalagem" autocomplete="off" data-filtro-tipo>
            </div>
        </div>
        <div class="nwe-campo nwe-campo-curto">
            <label class="nwe-campo-rotulo" for="nwe-filtro-sigla-${instanceId}">Sigla</label>
            <div class="nwe-campo-caixa">
                <i class="bi bi-hash" aria-hidden="true"></i>
                <input type="text" id="nwe-filtro-sigla-${instanceId}" class="nwe-campo-input" placeholder="Buscar por sigla" autocomplete="off" data-filtro-sigla>
            </div>
        </div>
        <div class="nwe-filtros-acoes">
            <button type="button" class="nwe-btn nwe-btn-contorno" data-buscar><i class="bi bi-search" aria-hidden="true"></i>Buscar</button>
        </div>
    </div>
    <div class="nwe-tabela" data-tabela></div>
</div>
