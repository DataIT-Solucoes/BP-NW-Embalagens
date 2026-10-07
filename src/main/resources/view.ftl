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
            <label class="nwe-campo-rotulo" for="nwe-filtro-tipo-${instanceId}">Tipo de Embalagem</label>
            <div class="nwe-campo-caixa">
                <i class="bi bi-search" aria-hidden="true"></i>
                <input type="text" id="nwe-filtro-tipo-${instanceId}" class="form-control nwe-campo-input" placeholder="Digite a sigla ou descrição" maxlength="100" autocomplete="off" aria-describedby="nwe-filtro-tipo-dica-${instanceId}" data-filtro-tipo>
            </div>
            <p class="nwe-campo-dica" id="nwe-filtro-tipo-dica-${instanceId}">Digite ao menos 2 caracteres e selecione um tipo. Deixe vazio para buscar todos.</p>
        </div>
        <div class="nwe-filtros-acoes">
            <button type="button" class="nwe-btn nwe-btn-destaque" data-buscar disabled><i class="bi bi-search" aria-hidden="true"></i>Buscar</button>
        </div>
    </div>
    <div class="nwe-tabela" data-tabela></div>
    <script type="text/template" class="nwe-tipo-sugestao-${instanceId}"><span>{{rotulo}}</span></script>

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
                    <input type="text" id="nwe-novo-sigla-${instanceId}" name="sigla" class="nwe-campo-input nwe-campo-input-simples nwe-campo-input-sigla" placeholder="Ex.: CX" maxlength="3" autocomplete="off" required aria-describedby="nwe-novo-sigla-dica-${instanceId} nwe-novo-sigla-erro-${instanceId}">
                    <p class="nwe-campo-dica" id="nwe-novo-sigla-dica-${instanceId}" data-sigla-dica>Até 3 caracteres.</p>
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

    <dialog class="nwe-modal" role="alertdialog" aria-labelledby="nwe-excluir-titulo-${instanceId}" aria-describedby="nwe-excluir-texto-${instanceId}" data-modal-excluir>
        <form class="nwe-modal-form" novalidate>
            <div class="nwe-modal-cabecalho">
                <div>
                    <h3 class="nwe-modal-titulo" id="nwe-excluir-titulo-${instanceId}">Excluir tipo de embalagem</h3>
                    <p class="nwe-modal-subtitulo">Esta ação não pode ser desfeita.</p>
                </div>
                <button type="button" class="nwe-modal-fechar" aria-label="Fechar" data-fechar-excluir><i class="bi bi-x-lg" aria-hidden="true"></i></button>
            </div>
            <div class="nwe-modal-corpo">
                <p class="nwe-modal-subtitulo" id="nwe-excluir-texto-${instanceId}">Deseja excluir <strong data-excluir-item></strong>?</p>
                <p class="nwe-modal-alerta" role="alert" data-excluir-alerta></p>
            </div>
            <div class="nwe-modal-rodape">
                <button type="button" class="nwe-btn nwe-btn-contorno" autofocus data-fechar-excluir>Cancelar</button>
                <button type="submit" class="nwe-btn nwe-btn-perigo" data-confirmar-excluir><i class="bi bi-trash" aria-hidden="true"></i><span>Excluir</span></button>
            </div>
        </form>
    </dialog>
</div>
