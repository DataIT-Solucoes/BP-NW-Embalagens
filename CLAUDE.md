# widget_nw_embalagens

> Regras gerais (versões, SuperWidget, Style Guide): `CLAUDE.md` da raiz do repositório. Aqui fica só o que é deste widget.
> Preencher só com o que o usuário informou ou o que está nos fontes. O que não se sabe fica "a definir".

## Objetivo
a definir

## Identificação
- `application.code`: `widget_nw_embalagens`
- Título (`application.title`): `widget_nw_embalagens` (valor gerado pela extensão)
- Versão: `0.1.0` · categoria `SYSTEM` · `application.uiwidget=true` · `application.mobileapp=false`
- Context-root: `/widget_nw_embalagens`
- Onde é usado (página/comunidade do Fluig): a definir

## Estado atual (2026-10-01)
Esqueleto gerado pela fluig-vscode-extension, sem lógica:
- `view.ftl` e `edit.ftl`: só o container `widget_nw_embalagens_${instanceId}` com `data-params="widget_nw_embalagens.instance()"`, vazio.
- JS: `init()` e `executeAction()` vazios, variáveis de exemplo `variavelNumerica` / `variavelCaracter`, binding de exemplo `'execute': ['click_executeAction']` (não há elemento `data-execute` no HTML).
- CSS e os 4 `.properties` vazios.

## Recursos declarados no `application.info`
| Índice | Tipo | Valor |
|---|---|---|
| 1 | js | `/resources/js/widget_nw_embalagens.js` |
| 2 | css | `/resources/css/widget_nw_embalagens.css` |

Próximo índice livre: 3

## Dados
- Datasets: a definir
- Serviços REST: a definir
- Campos/colunas usados: a definir

## Parâmetros de configuração (`edit.ftl`)
a definir

## Regras de negócio
a definir

## Pendências / decisões em aberto
- Definir objetivo, dados e telas do widget.
