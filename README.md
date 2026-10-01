# widget_nw_embalagens — Tipos de Embalagens

Widget WCM do Fluig (Branco Peres) para cadastrar, editar, excluir e consultar tipos de embalagem.
Publicado no servidor de teste em `/portal/p/1/cadastro_de_embalagens`.

> **Estado atual:** os dados são **mockados** (`NWE_DADOS_MOCK` no JS). Tudo que se cadastra, edita ou exclui
> fica só na tela e some ao recarregar a página. Ainda não há dataset nem serviço REST definido.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `src/main/resources/view.ftl` | HTML da tela: cabeçalho, aba, filtros, container da tabela e os dois modais (`<dialog>`) |
| `src/main/webapp/resources/js/widget_nw_embalagens.js` | SuperWidget com toda a lógica (tabela, filtros, modais) e os dados mockados |
| `src/main/webapp/resources/css/widget_nw_embalagens.css` | Estilos e paleta de cores |
| `src/main/resources/application.info` | Registra o JS e o CSS acima (índices 1 e 2) |

## Dependências externas (CDN)

O Fluig já carrega jQuery 3.6.3, Bootstrap 3.4.1 e o Style Guide. Além disso, a tela usa:

| Biblioteca | Onde é carregada | Para quê |
|---|---|---|
| Bootstrap Icons 1.11.3 (jsDelivr) | `<link>` no `view.ftl` | Todos os ícones (`bi bi-*`) |
| Mulish (Google Fonts) | `<link>` no `view.ftl` | Fonte da tela |
| Tabulator 6.4.0 — CSS (cdnjs) | `<link>` no `view.ftl` | Tema base da tabela |
| Tabulator 6.4.0 — JS (cdnjs) | carregado pelo JS em `carregarTabulator()` | Tabela (ordenação, paginação, filtro) |

Sem acesso à internet: ícones e fonte não aparecem, e no lugar da tabela surge a mensagem
"Não foi possível carregar a tabela...".

## Fluxo da tela

```
Página abre
  └─ init()
       ├─ posiciona a barrinha da aba (de novo quando a fonte Mulish termina de carregar)
       ├─ carregarTabulator() ──► montarTabela() com NWE_DADOS_MOCK
       ├─ prepararModalNovo()     (eventos do modal de cadastro/edição)
       └─ prepararModalExcluir()  (eventos da confirmação de exclusão)

Usuário ─┬─ digita filtros + Buscar (ou Enter) ─► buscar() ─► filtra a tabela
         ├─ Novo ─────────────► abrirModalNovo() ─┐
         ├─ lápis da linha ───► abrirModalEditar() ┴► abrirModalCadastro() ─► Salvar ─► salvarNovo()
         └─ lixeira da linha ─► abrirModalExcluir() ─► Excluir ─► confirmarExclusao()
```

### 1. Carregamento
- O Fluig instancia o widget a partir de `data-params="widget_nw_embalagens.instance()"` e chama `init()`.
- `this.DOM` é o jQuery da div do widget (confirmado no servidor de teste). Todo seletor é feito dentro dele,
  então duas instâncias na mesma página não se misturam.
- O script do Tabulator é baixado uma única vez por página (`nweTabulatorPromise`), mesmo com várias instâncias.

### 2. Tabela
- Colunas: **Descrição** (ordenável), **Sigla** (ordenável, mostrada como etiqueta) e **Ações** (lápis e lixeira).
- Começa ordenada por Descrição, crescente, com 10 linhas por página e o contador "Mostrando X–Y de Z".
- A coluna Ações não ordena; a seta do cabeçalho dela é só visual (CSS `.nwe-col-acoes`), para manter o padrão.
- Os cliques no lápis e na lixeira chegam por `cellClick` da coluna Ações, que identifica o botão por `data-acao`.

### 3. Filtros
- Campos **Tipo Embalagem** e **Sigla**. A busca roda no botão **Buscar** ou com **Enter** em qualquer campo.
- `buscar()` filtra pelas duas colunas ao mesmo tempo (o texto precisa estar contido no valor),
  ignorando maiúsculas e acentos (`normalizar()`). Com os dois campos vazios, o filtro é removido.

### 4. Cadastro e edição (mesmo modal)
- **Novo** abre o modal vazio ("Novo tipo de embalagem"). O **lápis** abre o mesmo modal preenchido
  ("Editar tipo de embalagem", botão "Salvar alterações"). Quem decide o modo é `abrirModalCadastro(linha)`:
  `linha = null` é cadastro; uma linha do Tabulator é edição (guardada em `linhaEditando`).
- **Validação** (`salvarNovo()`): Descrição e Sigla obrigatórias; Sigla com no máximo 2 caracteres
  (o campo também tem `maxlength="2"`). O erro aparece embaixo do campo e some quando a pessoa volta a digitar.
- **Salvar** fecha o modal e então adiciona a linha (`addRow`) ou atualiza a existente (`update`),
  reaplica a ordenação atual e leva a tabela até a página da linha, que brilha em amarelo por ~2 s.
- **Fechar** pelo X, Cancelar, Esc ou clique fora sempre limpa o formulário. A limpeza acontece em três pontos
  (ao fechar pelos botões, no evento `close` e ao abrir), porque o `close` do `<dialog>` é assíncrono e o Chrome
  não o dispara com a aba em segundo plano.

### 5. Exclusão
- A **lixeira** abre uma confirmação com o nome e a sigla do item; o foco começa em **Cancelar**.
- **Excluir** chama `confirmarExclusao()`, que remove a linha da tabela.

## Onde ligar o backend

Os pontos estão marcados com `MOCK` no JS:

| Ponto | Hoje | Trocar por |
|---|---|---|
| `NWE_DADOS_MOCK` / `montarTabela()` | array fixo de 22 itens | consulta ao dataset/REST de tipos de embalagem |
| `salvarNovo()` | `addRow` / `update` só na tela | gravação no backend; atualizar a tabela só depois da resposta |
| `confirmarExclusao()` | `delete` só na tela | exclusão no backend |

Ainda **a definir**: dataset/serviço, campos reais (ex.: código/id do registro), se a sigla pode repetir e se
deve ser gravada em maiúsculas.

## Visual

- **Paleta oficial Branco Peres** (variáveis no topo do CSS): verde institucional `#006B35` (ação principal,
  foco, seleção), verde névoa `#E5EDE3` (fundo de seleção), marfim `#F7F5EE` (superfícies), carvão `#20201E`
  (texto), vermelho `#ED1C24` (só ação destrutiva; erros em `#C4161C` por contraste) e amarelo solar
  `#FFD200` (brilho da linha nova). Não usar cores fora dela.
- Modais são `<dialog>` nativos, **não** o `FLUIGC.modal`.

## Pegadinhas para quem for mexer

- **Especificidade:** todo seletor do CSS começa com `.fluig-style-guide.nwe`. Sem isso, regras do Style Guide
  como `.fluig-style-guide header` e `.fluig-style-guide h2` vencem e desmontam o layout.
- **Tabulator:** a classe `.tabulator` vai na **própria** div `.nwe-tabela`; por isso os seletores são
  `.nwe-tabela.tabulator` (sem espaço). As setas inativas precisam de `[aria-sort="none"] .tabulator-col-content`
  no seletor para vencer o tema do Tabulator.
- **Textos da paginação:** o Tabulator insere os textos de `langs.pagination` como HTML; é assim que as setas
  viram ícones.
- **Encoding:** `.js`, `.ftl`, `.css` e `application.info` em UTF-8 sem BOM e CRLF.
