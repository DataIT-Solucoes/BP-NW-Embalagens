<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Mulish:wght@400;600;700;800&display=swap">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/tabulator/6.4.0/css/tabulator_simple.min.css">

<div id="cadastro-embalagens_${instanceId}" class="super-widget wcm-widget-class fluig-style-guide cadastro-embalagens" data-params="cadastroEmbalagens.instance()">
    <div class="embalagens-cabecalho">
        <span class="embalagens-selo" aria-hidden="true"><span class="embalagens-selo-miolo"><i class="bi bi-boxes"></i></span></span>
        <div class="embalagens-cabecalho-texto">
            <h2 class="embalagens-cabecalho-titulo">Tipos de Embalagens</h2>
            <p class="embalagens-cabecalho-subtitulo">Cadastre, edite, inative e consulte os tipos de embalagem.</p>
        </div>
        <div class="embalagens-cabecalho-acoes">
            <button type="button" class="embalagens-botao embalagens-botao-destaque" data-novo disabled><i class="bi bi-plus-lg" aria-hidden="true"></i>Novo</button>
        </div>
    </div>
    <div class="embalagens-abas" role="tablist" aria-label="Seções">
        <button type="button" class="embalagens-aba is-active" role="tab" aria-selected="true" tabindex="0" data-aba="tipos-embalagem" data-tab><i class="bi bi-box-seam" aria-hidden="true"></i>Tipos de Embalagens</button>
        <span class="embalagens-indicador-aba" aria-hidden="true"></span>
    </div>
    <div class="embalagens-filtros" role="search" aria-label="Filtros">
        <div class="embalagens-campo">
            <label class="embalagens-campo-rotulo" for="embalagens-filtro-tipo-${instanceId}">Tipo de Embalagem</label>
            <div class="embalagens-campo-caixa">
                <i class="bi bi-search" aria-hidden="true"></i>
                <input type="text" id="embalagens-filtro-tipo-${instanceId}" class="form-control embalagens-campo-entrada" placeholder="Digite a sigla ou descrição" maxlength="100" autocomplete="off" aria-describedby="embalagens-filtro-tipo-dica-${instanceId}" data-filtro-tipo>
            </div>
            <p class="embalagens-campo-dica" id="embalagens-filtro-tipo-dica-${instanceId}">Digite ao menos 2 caracteres e selecione um tipo. Deixe vazio para buscar todos.</p>
        </div>
        <div class="embalagens-filtros-acoes">
            <button type="button" class="embalagens-botao embalagens-botao-destaque" data-buscar disabled><i class="bi bi-search" aria-hidden="true"></i>Buscar</button>
        </div>
    </div>
    <div class="embalagens-tabela" data-tabela></div>
    <script type="text/template" class="embalagens-tipo-sugestao-${instanceId}"><span>{{rotulo}}</span></script>

    <dialog class="embalagens-modal" aria-labelledby="embalagens-modal-titulo-${instanceId}" data-modal-novo>
        <form class="embalagens-modal-formulario" novalidate>
            <div class="embalagens-modal-cabecalho">
                <div>
                    <h3 class="embalagens-modal-titulo" id="embalagens-modal-titulo-${instanceId}" data-modal-titulo>Novo tipo de embalagem</h3>
                    <p class="embalagens-modal-subtitulo" data-modal-subtitulo>Preencha a descrição e a sigla para cadastrar.</p>
                </div>
                <button type="button" class="embalagens-modal-fechar" aria-label="Fechar" data-fechar-modal><i class="bi bi-x-lg" aria-hidden="true"></i></button>
            </div>

            <div class="embalagens-modal-corpo">
                <div class="embalagens-campo">
                    <label class="embalagens-campo-rotulo" for="embalagens-descricao-${instanceId}">Descrição</label>
                    <input type="text" id="embalagens-descricao-${instanceId}" name="descricao" class="embalagens-campo-entrada embalagens-campo-entrada-simples" placeholder="Ex.: Caixa" maxlength="100" autocomplete="off" required autofocus aria-describedby="embalagens-descricao-erro-${instanceId}">
                    <p class="embalagens-campo-erro" id="embalagens-descricao-erro-${instanceId}" data-erro="descricao"></p>
                </div>
                <div class="embalagens-campo">
                    <label class="embalagens-campo-rotulo" for="embalagens-sigla-cadastro-${instanceId}">Sigla</label>
                    <input type="text" id="embalagens-sigla-cadastro-${instanceId}" name="sigla" class="embalagens-campo-entrada embalagens-campo-entrada-simples embalagens-campo-entrada-sigla" placeholder="Ex.: CX" maxlength="3" autocomplete="off" required aria-describedby="embalagens-sigla-dica-${instanceId} embalagens-sigla-erro-${instanceId}">
                    <p class="embalagens-campo-dica" id="embalagens-sigla-dica-${instanceId}" data-sigla-dica>Até 3 caracteres.</p>
                    <p class="embalagens-campo-erro" id="embalagens-sigla-erro-${instanceId}" data-erro="sigla"></p>
                </div>
                <p class="embalagens-modal-alerta" role="alert" data-modal-alerta></p>
            </div>

            <div class="embalagens-modal-rodape">
                <button type="button" class="embalagens-botao embalagens-botao-contorno" data-fechar-modal>Cancelar</button>
                <button type="submit" class="embalagens-botao embalagens-botao-destaque"><i class="bi bi-check-lg" aria-hidden="true"></i><span data-modal-salvar>Salvar</span></button>
            </div>
        </form>
    </dialog>

    <dialog class="embalagens-modal" role="alertdialog" aria-labelledby="embalagens-excluir-titulo-${instanceId}" aria-describedby="embalagens-excluir-texto-${instanceId}" data-modal-excluir>
        <form class="embalagens-modal-formulario" novalidate>
            <div class="embalagens-modal-cabecalho">
                <div>
                    <h3 class="embalagens-modal-titulo" id="embalagens-excluir-titulo-${instanceId}">Excluir tipo de embalagem</h3>
                    <p class="embalagens-modal-subtitulo">Esta ação não pode ser desfeita.</p>
                </div>
                <button type="button" class="embalagens-modal-fechar" aria-label="Fechar" data-fechar-excluir><i class="bi bi-x-lg" aria-hidden="true"></i></button>
            </div>
            <div class="embalagens-modal-corpo">
                <p class="embalagens-modal-subtitulo" id="embalagens-excluir-texto-${instanceId}">Deseja excluir <strong data-excluir-item></strong>?</p>
                <p class="embalagens-modal-alerta" role="alert" data-excluir-alerta></p>
            </div>
            <div class="embalagens-modal-rodape">
                <button type="button" class="embalagens-botao embalagens-botao-contorno" autofocus data-fechar-excluir>Cancelar</button>
                <button type="submit" class="embalagens-botao embalagens-botao-perigo" data-confirmar-excluir><i class="bi bi-trash" aria-hidden="true"></i><span>Excluir</span></button>
            </div>
        </form>
    </dialog>
</div>
