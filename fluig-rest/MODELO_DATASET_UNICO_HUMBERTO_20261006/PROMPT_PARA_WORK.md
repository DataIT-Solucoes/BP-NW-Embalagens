# Pedido para o Work do Humberto

Adapte o modelo nesta pasta para integrar as telas Fluig de Controle de Embalagens da Branco Peres em TESTE. Leia primeiro README.md, docs/entregas/DATASET_UNICO_FLUIG_20261006.md e ACOES_DATASET.json. Os fontes completos do Dataset e do transporte Widget estão em fontes/fluig. Execute npm test antes e depois das alterações; não precisa npm install.

Já existe comunicação funcional por dsNwEmbalagensTipos usando DATASUL_REST_HOMOLOG, getAuthorizeClientService e invoke. Fonte recebido está em referencias/fluig. Não recrie autenticação/serviço, não coloque senha/token no código e não altere o Dataset funcionando durante a migração.

Objetivo: um Dataset customizado dsNwEmbalagens com24ações fechadas, incluindo GET/POST/PATCH de tipos e apoio de tipos. A Widget envia acao e parametros JSON via filterFields no endpoint /api/public/ecm/dataset/search. O Dataset retorna uma linha, com resultadoJson contendo o envelope da API; o helper chamarEmbalagens devolve esse envelope. Não confundir limit1 de transporte com limite20 de negócio. Migrar tipos para resultado.dados mantendo tratamento de erro/vazio/versão/cursor.

Trabalho pendente de instalação: configurar códigos REAIS de grupos e estabelecimentos em NW_CONFIG.regras, conferir os campos do Dataset interno colleagueGroup e publicar o Dataset/recursos da Widget. Se os grupos já estiverem definidos no projeto Fluig, reutilize-os; se não estiverem, deixe essa configuração claramente indicada sem inventar grupos/estabelecimentos ou permitir acesso irrestrito. Usuário/empresa são WKUser/WKCompany; permissões vêm do servidor por ação. Nunca aceitar do Widget endpoint, método, headers, usuário, empresa, grupo ou estabelecimentosPermitidos. Não somar estabelecimentos de permissões de ações diferentes.

POST/PATCH estão implementados no modelo, inicialmente desabilitados na configuração. Habilite em TESTE conforme configurar/integrar comandos, mantendo grupos por ação. params transporta JSON/arrays/booleanos/decimais pelo serviço autorizado. Não gerar chave automaticamente em retry e não repetir comandos automaticamente. Reutilizar mesma chave/conteúdo da intenção; preparação de WT incerta pode consultar consultarResultadoOperacao. O Dataset nunca efetiva/cancela NF nem movimenta estoque; isso pertence ao Datasul/ABL.

Uma página por consulta. Preservar diferenças entre dados, geracao/itens/etiquetas e respostas de comando, além de IDs e zeros documentais. Autocomplete min2caracteres/debounce350ms/teto20; não baixar todos os cadastros. Schema cadastral vigente usa idParam/versao numéricos no corpo; seleções operacionais usam idEtiqueta/versao textuais. Consulte os contratos incluídos; não uniformize tipos silenciosamente.

Integre primeiro a tela de tipos já existente e siga pelas telas prontas. Não refaça testes fiscais aprovados nem compile/altere ABL por este trabalho. Os arquivos Progress são referências de rotas/contratos; modelo foi testado localmente, não publicado no Fluig. Recebimentos fiscais T04, mutações de Bags, apoios ainda ausentes, GATEC e anulação permanecem fora das24ações; não inventar endpoints para eles.

Ao entregar, informe fontes alterados, configuração pendente real e como chamar a tela. Registre resultados novos pontualmente. Não parar em um plano se os arquivos/telas disponíveis já permitem implementar a integração.
