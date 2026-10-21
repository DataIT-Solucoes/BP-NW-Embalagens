# widget_nw_embalagens

> Regras gerais (versões, SuperWidget, Style Guide, padrão `nw`): `CLAUDE.md` da raiz do repositório. Aqui fica só o que é deste widget.
> Preencher só com o que o usuário informou ou o que está nos fontes. O que não se sabe fica "a definir".
> O `CLAUDE.md` desta pasta só importa este arquivo (`@AGENTS.md`). Skill local: `.claude/skills/fluig-branco-peres/`
> (cópia igual nos 4 widgets).

## Onde está cada coisa (ler só o do assunto)
| Arquivo | Conteúdo |
|---|---|
| `docs/decisoes.md` | Decisões e correções do usuário (dados, tela, forma de trabalho). **Ler antes de mudar comportamento ou texto.** |
| `docs/pendencias.md` | Perguntas em aberto, propostas não aprovadas e o que falta confirmar no Fluig de TESTE |
| `docs/referencias-backend.md` | Contrato do Dataset (ações, parâmetros, campos), fontes da verdade, testes e build |
| `docs/tela-e-codigo.md` | Tela, modais e colunas, arquitetura do JS e **mapa das funções do JS**. O fonte manda |
| `README.md` | Visão geral para pessoas (GitHub). **Não precisa ler para trabalhar**: o conteúdo está aqui e em `docs/` |

Histórico e estado do trabalho: `git log`.

## Objetivo
Tela **Tipos de Embalagens** do Controle de Embalagens (Datasul): consulta, cadastro, edição da descrição e inativação/reativação.
O fonte também oferece exclusão; aprovação e homologação dela não confirmadas.

## Identificação
- `application.code` e título (`application.title`): `widget_nw_embalagens`
- **Fora do padrão da raiz** (ver `docs/pendencias.md`): container `cadastro-embalagens_${instanceId}`, SuperWidget `cadastroEmbalagens`,
  escopo CSS `.fluig-style-guide.cadastro-embalagens` com classes `embalagens-*` (não `nwe`).
- Onde é usado: página `/portal/p/1/cadastro_de_embalagens` do Fluig de TESTE (registro antigo; publicação atual não confirmada)
- Repositório: `https://github.com/DataIT-Solucoes/BP-NW-Embalagens`, branch **`main`**.

## Recursos declarados no `application.info`
| Índice | Tipo | Valor |
|---|---|---|
| 1 | js | `/resources/js/widget_nw_embalagens.js` |
| 2 | css | `/resources/css/widget_nw_embalagens.css` |

Próximo índice livre: 3

## Parâmetros de configuração (`edit.ftl`)
Nenhum (`edit.ftl` como gerado).

## Dados (essencial; detalhes em `docs/referencias-backend.md`)
- Dataset `dsNwEmbalagens`, chamado por `chamarEmbalagens`. O publicado no Fluig é sempre o `dsNwEmbalagens.js` do GitHub
  **`DataIT-Solucoes/BP-NW-DATASET`**: ler esse arquivo antes de usar ação, parâmetro ou campo. `datasets/` é cópia local
  (com alterações do usuário não commitadas: não incluir em commit). Não editar o Dataset sem pedido.
- Ações usadas: `consultarTipos`, `consultarTiposApoio`, `incluirTipo`, `alterarTipo` (editar, inativar/reativar e excluir).
- `versao` vai como número; códigos não são convertidos em número.

## Regras de negócio
- Sigla de 2 a 3 letras/números, **imutável na edição**; descrição obrigatória, até 100. Origem da mudança do limite histórico de 2: não confirmada.
- Editar exige descrição diferente da atual. Situação muda só com a confirmação do servidor.
- **Idempotência**: a mesma intenção reaproveita a chave; falha incerta exige conferir (Buscar) antes de tentar de novo; nunca repetir
  comando automaticamente nem gerar chave nova para a mesma intenção.
- Loading global (overlay dentro do widget + toast info "Carregando...") no carregamento inicial e ao Buscar; spinner no lugar do
  interruptor ao ativar/inativar (`docs/decisoes.md`).

## Forma de trabalho (pedidos do usuário)
Depois de **qualquer** ajuste, inclusive só em `.md`, **uma chamada só**:
```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/entregar.ps1 -Mensagem "FIX: Texto" <arquivos...>
```
- Confere BOM e quebra de linha misturada nos fontes de `src/`; se algum arquivo estiver em `src/`, roda `node --check` e gera
  `target/widget_nw_embalagens.war` (`pack-widget.ps1`; Ctrl+F7 no VSCode faz o mesmo). Só `.md`: pula os dois.
- Mudou JS ou Dataset: rodar `npm test` antes (testes simulados; não comprovam o Fluig).
- Commit **só dos arquivos informados** (nunca `target/`; apagado/renomeado: passar o caminho antigo também), em português,
  **sem coautor** e **sempre com prefixo**: `DOCS: Texto` (`.md`, `AGENTS.md`, `docs/`), `FIX: Texto` (código em `src/`),
  `CHORE: Texto` (manutenção, build, renomear sem mudar conteúdo). Nunca incluir `cheli/`, `fluig-rest/` nem pastas de referência.
- Push no branch atual e conferência do remoto (`git ls-remote`). `-Simular` faz tudo menos commit e push.
- Importar no Fluig (Painel de Controle → Desenvolvimento → Widgets): feito pelo usuário.

Ao fim da tarefa, atualizar **só** o arquivo de `docs/` afetado: decisão nova → `decisoes.md`; pergunta ou proposta → `pendencias.md`
(resolvida: tirar de lá); levantamento no backend → `referencias-backend.md`; mudança de comportamento da tela → `tela-e-codigo.md`.
O `README.md` só muda quando a visão geral mudar.
