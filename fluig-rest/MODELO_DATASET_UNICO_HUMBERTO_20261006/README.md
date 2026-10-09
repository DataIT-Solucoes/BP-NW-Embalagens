# Humberto — Dataset único de embalagens

Abra **esta pasta inteira no Work**, não apenas o JavaScript. Comece pelo PROMPT_PARA_WORK.md e pelo guia docs/entregas/DATASET_UNICO_FLUIG_20261006.md.

O Dataset central **dsNwEmbalagens** inclui as24ações REST atuais, inclusive todos os REST de tipos (consulta, inclusão, alteração/inativação e apoio). Reutiliza **DATASUL_REST_HOMOLOG**, confirmado no Dataset de tipos enviado. Nenhuma credencial está no pacote.

## O que adaptar

1. Preencher NW_CONFIG.regras com grupos reais, ações e estabelecimentos autorizados no servidor. O modelo nega acesso enquanto a política estiver vazia; não usar permissão recebida do navegador.
2. Publicar fontes/fluig/datasets/dsNwEmbalagens.js como Dataset customizado dsNwEmbalagens, sem sincronização. Não substituir o dsNwEmbalagensTipos funcionando.
3. Incluir fontes/fluig/componentes/chamar-embalagens.js na Widget e migrar chamadas para ação + parâmetros. Retorno novo é uma linha com resultadoJson, não uma linha por tipo.
4. Consultas trazem uma página. Habilitar escritas na configuração de TESTE quando integrar os comandos e conferir params/PATCH/arrays no serviço instalado. A permissão específica continua obrigatória.

## Testar no computador de desenvolvimento

Com Node.js já disponível, execute **npm test**. Não há dependências a instalar; os testes não conectam a Fluig/Datasul/banco. Não é homologação do servidor.

Arquivos Progress e baseline estão aqui como referências dos contratos existentes. **Não publicar esta pasta no Datasul, não compilar ABL nem alterar hooks para instalar o modelo JavaScript.** Dataset de tipos recebido está preservado em referencias/fluig, sem modificações.

Consulte ACOES_DATASET.json para os24nomes/métodos/rotas/campos/cursores. MANIFESTO.json identifica as cópias entregues. Não há ZIP novo ou .r.
