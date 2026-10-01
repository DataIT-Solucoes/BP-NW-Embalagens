var widget_nw_embalagens = SuperWidget.extend({

    //aba atualmente selecionada
    abaAtual: 'tipos-embalagem',

    //método iniciado quando a widget é carregada
    init() {
        var self = this;
        this.$tabs = $('.nwe-tabs', this.DOM);
        this.moverIndicador();
        $(window).on('resize.nwe' + this.instanceId, function () { self.moverIndicador(); });
    },

    //BIND de eventos
    bindings: {
        local: {
            'tab': ['click_selecionarAba', 'keydown_navegarAbas']
        },
        global: {}
    },

    selecionarAba(htmlElement, event) {
        this.ativarAba($(htmlElement));
    },

    //setas/Home/End movem o foco entre as abas (padrão WAI-ARIA)
    navegarAbas(htmlElement, event) {
        var abas = this.$tabs.find('.nwe-tab');
        var i = abas.index(htmlElement);
        var destino = null;

        if (event.key === 'ArrowRight') destino = (i + 1) % abas.length;
        else if (event.key === 'ArrowLeft') destino = (i - 1 + abas.length) % abas.length;
        else if (event.key === 'Home') destino = 0;
        else if (event.key === 'End') destino = abas.length - 1;
        if (destino === null) return;

        event.preventDefault();
        this.ativarAba(abas.eq(destino));
        abas.eq(destino).trigger('focus');
    },

    ativarAba($aba) {
        this.$tabs.find('.nwe-tab')
            .removeClass('is-active').attr({ 'aria-selected': 'false', tabindex: '-1' });
        $aba.addClass('is-active').attr({ 'aria-selected': 'true', tabindex: '0' });
        this.abaAtual = $aba.data('aba');
        this.moverIndicador();
    },

    moverIndicador() {
        var $ativa = this.$tabs.find('.nwe-tab.is-active');
        if (!$ativa.length) return;
        this.$tabs.find('.nwe-tabs-indicador').css({
            width: $ativa.outerWidth() + 'px',
            transform: 'translateX(' + $ativa.position().left + 'px)'
        });
    }
});
