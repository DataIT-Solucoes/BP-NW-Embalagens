// Testes locais com dublês: não conectam ao Fluig, PASOE nem banco.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
// Confere o contrato REST esperado, sem depender da copia de referencia nao versionada.
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'datasets/dsNwEmbalagens.js'), 'utf8');
let total = 0;
const test = (name, fn) => { fn(); total++; console.log('OK ' + name); };
const page = (dados = [], more = false, cursor = '', codigo = false) => ({
    sucesso:true,codigoErro:'',mensagem:'',dados,total:dados.length,temMais:more,
    [codigo?'proximoCodigo':'proximoId']:cursor
});
function setup(result = page(), status = '200') {
    const calls = [], logs = [];
    const state = { result, status, fail:false, user:'usuario-teste', company:'empresa-teste', group:'grupo-teste', groupUser:null };
    const context = { JSON, Object, Math, Number, String, Error, isFinite, encodeURIComponent,
        getValue: k => k==='WKUser'?state.user:k==='WKCompany'?state.company:'',
        log: { warn:s=>logs.push(s) }, ConstraintType:{MUST:1},
        DatasetBuilder:{newDataset:()=>({columns:[],values:[],addColumn(n){this.columns.push(n);},addRow(row){this.values.push(row);}})},
        DatasetFactory:{ createConstraint:(name,initial,final,type)=>({name,initial,final,type}),
            getDataset(name, fields, cs) {
                assert.equal(name, 'colleagueGroup');
                assert.equal(cs.length, 2);
                return {rowsCount:1,getValue(i,k) {
                    if(k==='colleagueGroupPK.companyId')return state.company;
                    if(k==='colleagueGroupPK.colleagueId')return state.groupUser || state.user;
                    return state.group;
                }};
            }},
        fluigAPI:{getAuthorizeClientService:()=>({invoke(raw) {
            calls.push(JSON.parse(raw)); if(state.fail)throw Error('Authorization: Bearer SEGREDO');
            return {getHttpStatusResult:()=>state.status,getResult:()=>typeof state.result==='string'?state.result:JSON.stringify(state.result)};
        }})}
    };
    vm.createContext(context);vm.runInContext(source,context);
    context.NW_CONFIG.regras=[{grupo:state.group,acoes:Object.keys(context.NW_ACOES),estabelecimentos:['ORIGEM','DESTINO']}];
    const run = (acao, p = {}, extra = []) => {
        const constraint = (name,value)=>({getFieldName:()=>name,getInitialValue:()=>value,getFinalValue:()=>value});
        const ds = context.createDataset(null,[constraint('acao',acao),constraint('parametros',typeof p==='string'?p:JSON.stringify(p)),...extra],null);
        assert.equal(ds.values.length,1);
        const row=Object.fromEntries(ds.columns.map((k,i)=>[k,ds.values[0][i]]));
        return { row, result:JSON.parse(row.resultadoJson) };
    };
    return {context,state,calls,logs,run};
}
test('acoes cobrem o contrato REST e preservam alias apoiarTipos',()=>{
    const h=setup();
    // Contrato recebido para o Dataset central: 24 rotas, mais o alias de apoio.
    const native = [
        'get /tipos', 'post /tipos', 'patch /tipos',
        'get /parametros', 'post /parametros', 'patch /parametros',
        'get /etiquetas', 'get /apoios/estabelecimentos', 'get /apoios/itens',
        'get /apoios/tipos', 'get /apoios/familias', 'get /bags',
        'get /conteudo-bag', 'get /dados-impressao', 'get /geracoes',
        'get /operacoes/natureza', 'get /operacoes/embalagens-origem',
        'get /operacoes', 'get /operacoes/resultado', 'get /operacoes/itens',
        'get /operacoes/eventos', 'post /operacoes/transferencias',
        'post /operacoes/remessas', 'post /operacoes/devolucoes'
    ].sort();
    assert.equal(Object.keys(h.context.NW_ACOES).length,25);
    assert.deepEqual(JSON.parse(JSON.stringify(h.context.NW_ACOES.consultarTiposApoio)), JSON.parse(JSON.stringify(h.context.NW_ACOES.apoiarTipos)));
    assert.deepEqual(Object.entries(h.context.NW_ACOES).filter(([nome]) => nome !== 'apoiarTipos').map(([, a])=>a.metodo+' '+a.rota).sort(),native);
});
test('apoio de tipos: alias autorizado usa GET e aceita todos somente em apoios/tipos',()=>{
    const h=setup(page([{codigo:'CX',descricao:'CAIXA',ativo:false,versao:3}],false,'',true));
    const r=h.run('consultarTiposApoio',{filtro:'ca',ativo:'todos',limite:20});
    assert.equal(r.result.sucesso,true); assert.equal(h.calls.length,1);
    assert.equal(h.calls[0].method,'get');
    assert.match(h.calls[0].endpoint,/\/apoios\/tipos\?/);
    assert.match(h.calls[0].endpoint,/ativo=todos/); assert.match(h.calls[0].endpoint,/filtro=ca/);
    assert.equal(r.result.dados[0].codigo,'CX');
    assert.equal(h.run('consultarTipos',{ativo:'todos'}).result.codigoErro,'PARAMETROS_INVALIDOS');
    assert.equal(h.calls.length,1);
});
test('constraints escalares sem final aceitas, faixas e repeticoes recusadas',()=>{
    const h=setup(page([],false,'',true));
    const c=(name,initial,final)=>({getFieldName:()=>name,getInitialValue:()=>initial,getFinalValue:()=>final});
    let ds=h.context.createDataset(null,[c('acao','consultarTipos',null),c('parametros','{}',null)],null);
    assert.equal(ds.values[0][1],'true');
    ds=h.context.createDataset(null,[c('acao','consultarTipos','consultarEtiquetas')],null);assert.equal(ds.values[0][1],'false');
    ds=h.context.createDataset(null,[c('acao','consultarTipos',null),c('acao','consultarTipos',null)],null);assert.equal(ds.values[0][1],'false');
});
test('tipos consulta uma pagina, preserva cursor, usuario e servico funcionais',()=>{
    const h=setup(page([{codTipo:'PL',versao:1}],true,'PL',true));
    const r=h.run('consultarTipos',{limite:1,descricao:'a&b'});
    assert.equal(r.result.temMais,true);assert.equal(r.row.proximoCursor,'PL');
    assert.equal(h.calls.length,1);assert.equal(h.calls[0].serviceCode,'DATASUL_REST_HOMOLOG');
    assert.match(h.calls[0].endpoint,/descricao=a%26b/);assert.match(h.calls[0].endpoint,/usuario=usuario-teste/);
});
test('vazio valido conserva uma linha de sucesso com dados vazios',()=>{
    const h=setup(page([],false,'',true));const r=h.run('consultarTipos');
    assert.equal(r.row.sucesso,'true');assert.deepEqual(r.result.dados,[]);
});
test('sem politica, contexto ou grupo correspondente nega sem chamar REST',()=>{
    let h=setup();h.context.NW_CONFIG.regras=[];assert.equal(h.run('consultarTipos').result.codigoErro,'AUTORIZACAO_NAO_CONFIGURADA');assert.equal(h.calls.length,0);
    h=setup();h.state.company='';assert.equal(h.run('consultarTipos').result.codigoErro,'CONTEXTO_INVALIDO');assert.equal(h.calls.length,0);
    h=setup();h.state.groupUser='outra-pessoa';assert.equal(h.run('consultarTipos').result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,0);
});
test('identidade, lista de permitidos e endpoint do cliente sao recusados',()=>{
    for(const name of ['usuario','WKUser','companyId','estabelecimentosPermitidos','endpoint','method','headers','__proto__']) {
        const h=setup();const p=JSON.parse('{"'+name+'":"forjado"}');
        assert.equal(h.run('consultarTipos',p).result.codigoErro,'CAMPO_NAO_PERMITIDO');assert.equal(h.calls.length,0);
    }
    const h=setup();assert.equal(h.run('constructor').result.codigoErro,'ACAO_INVALIDA');
});
test('permissoes de outra acao nao ampliam os estabelecimentos desta',()=>{
    const h=setup();h.context.NW_CONFIG.regras=[
        {grupo:'grupo-teste',acoes:['consultarOperacoes'],estabelecimentos:['ORIGEM']},
        {grupo:'grupo-teste',acoes:['apoiarItens'],estabelecimentos:['DESTINO']}
    ];
    assert.equal(h.run('consultarOperacoes',{codEstabel:'DESTINO'}).result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,0);
    assert.equal(h.run('consultarOperacoes',{codEstabel:'ORIGEM'}).result.sucesso,true);
    assert.doesNotMatch(h.calls[0].endpoint,/estabelecimentoPermitido=DESTINO/);
});
test('apoios limitados a20 e filtro de pelo menos dois caracteres',()=>{
    const h=setup();assert.equal(h.run('apoiarItens',{codEstabel:'ORIGEM',filtro:'ab',limite:21}).result.codigoErro,'LIMITE_INVALIDO');
    assert.equal(h.run('apoiarTipos',{filtro:'a'}).result.codigoErro,'FILTRO_INVALIDO');assert.equal(h.calls.length,0);
});
test('IDs e zeros documentais chegam intactos a query',()=>{
    const h=setup();h.run('consultarEmbalagensOrigem',{codEstabel:'ORIGEM',natureza:'NAT',emitenteOrigem:'123',serieOrigem:'001',numeroOrigem:'000123',naturezaOrigem:'ORIG',limite:20});
    assert.match(h.calls[0].endpoint,/numeroOrigem=000123/);assert.match(h.calls[0].endpoint,/serieOrigem=001/);
});
test('geracoes preserva geracao/itens/etiquetas em vez de presumir dados',()=>{
    const h=setup({sucesso:true,codigoErro:'',mensagem:'',geracao:{idEvento:'123'},itens:[{item:'001'}],etiquetas:[],total:0,temMais:false,proximoId:''});
    const r=h.run('consultarGeracao',{idEvento:'123'});assert.equal(r.result.geracao.idEvento,'123');assert.ok(!('dados' in r.result));
});
test('natureza preserva classificacao na colecao dados sem exigir limite',()=>{
    const h=setup(page([{natureza:'NAT',codEstabel:'ORIGEM',fluxo:'TRANSFERENCIA',ramoPadrao:'DIRETO',exigeOrigem:false,editaQuantidade:false,editaPreco:true}],false,'',true));
    assert.equal(h.run('classificarNatureza',{codEstabel:'ORIGEM',natureza:'NAT'}).result.dados[0].ramoPadrao,'DIRETO');
});
test('temMais sem cursor, cursor repetido/regressivo e total divergente recusados',()=>{
    const cases=[page([{idOperacao:'20'}],true,''),page([{idOperacao:'20'}],true,'10'),page([{idOperacao:'20'}],true,'9'),{...page([]),total:3}];
    for(const r of cases){const h=setup(r);assert.equal(h.run('consultarOperacoes',{codEstabel:'ORIGEM',aposId:'10'}).result.sucesso,false);}
});
test('HTTP falho, status ausente, JSON invalido e corpo vazio nao viram sucesso',()=>{
    for(const [result,status] of [[page(),'500'],[page(),''],['{','200'],['','200']]) {
        const h=setup(result,status);assert.equal(h.run('consultarTipos').result.sucesso,false);assert.equal(h.calls.length,1);
    }
});
test('erro de negocio preserva codigo sem vazar detalhes sensiveis',()=>{
    const h=setup({sucesso:false,codigoErro:'SEM_PERMISSAO',mensagem:'Authorization: Bearer segredo'});
    const r=h.run('consultarTipos');assert.equal(r.result.codigoErro,'SEM_PERMISSAO');assert.doesNotMatch(JSON.stringify(r),/segredo|Bearer/);
});
test('escritas desabilitadas por configuracao, sem tocar Dataset tipos existente',()=>{
    const h=setup();h.context.NW_CONFIG.escritasHabilitadas=false;assert.equal(h.run('incluirTipo',{codTipo:'PL',descricao:'PLASTICO',ativo:true,chaveIdempotente:'intencao-1'}).result.codigoErro,'ESCRITA_DESABILITADA');assert.equal(h.calls.length,0);
});
test('POST tipo, PATCH tipo e parametros usam corpo JSON e preservam versao numerica',()=>{
    for(const [acao,p,method] of [
        ['incluirTipo',{codTipo:'PL',descricao:'PLASTICO',ativo:true,versao:0,chaveIdempotente:'chave'},'post'],
        ['alterarTipo',{codTipo:'PL',descricao:'PLASTICO',ativo:false,versao:3,acao:'INATIVAR',chaveIdempotente:'chave'},'patch'],
        ['alterarParametro',{idParam:10,codEstabel:'ORIGEM',item:'001',codTipo:'PL',capacidade:20,unidade:'LT',ativo:false,versao:3,acao:'INATIVAR',chaveIdempotente:'chave'},'patch']
    ]) {
        const h=setup({sucesso:true,codigoErro:'',mensagem:'',repeticao:false,versao:4});h.context.NW_CONFIG.escritasHabilitadas=true;
        assert.equal(h.run(acao,p).result.sucesso,true);assert.equal(h.calls[0].method,method);assert.equal(h.calls[0].params.usuario,'usuario-teste');
        assert.equal(h.calls[0].params.versao,p.versao);assert.ok(h.calls[0].options.mediaType==='application/json');
        if(p.codEstabel)assert.deepEqual(h.calls[0].params.estabelecimentosPermitidos,['DESTINO','ORIGEM']);
    }
});
const command={codEstabel:'ORIGEM',codEstabelDestino:'DESTINO',natureza:'NAT',serie:'001',valorItem:1,chaveIdempotente:'mesma-intencao',selecao:[{idEtiqueta:'123',versao:'2',quantidade:10}]};
test('comando preserva chave/IDs, devolve WT e repeticao sem retry',()=>{
    const h=setup({sucesso:true,codigoErro:'',mensagem:'',wt:'456',idOperacao:'789',repeticao:true,dados:[],total:0});h.context.NW_CONFIG.escritasHabilitadas=true;
    const r=h.run('criarTransferencia',command);assert.equal(r.result.wt,'456');assert.equal(r.result.repeticao,true);assert.equal(h.calls.length,1);
    assert.equal(h.calls[0].params.selecao[0].idEtiqueta,'123');assert.equal(h.calls[0].params.chaveIdempotente,'mesma-intencao');
});
test('timeout apos comando nao repete e nao expoe excecao',()=>{
    const h=setup();h.context.NW_CONFIG.escritasHabilitadas=true;h.state.fail=true;
    const r=h.run('criarTransferencia',command);assert.equal(h.calls.length,1);assert.equal(r.result.sucesso,false);
    assert.match(r.result.mensagem,/nao gere chave nova/);assert.doesNotMatch(JSON.stringify(r)+h.logs.join(''),/SEGREDO|Bearer/);
});
test('destino nao autorizado, selecao duplicada/numerica e campos extras negam antes do POST',()=>{
    for(const c of [{...command,codEstabelDestino:'FORA'}, {...command,selecao:[command.selecao[0],command.selecao[0]]},
        {...command,selecao:[{idEtiqueta:123,versao:'2',quantidade:10}]}, {...command,selecao:[{...command.selecao[0],usuario:'forjado'}]}]) {
        const h=setup();h.context.NW_CONFIG.escritasHabilitadas=true;assert.equal(h.run('criarTransferencia',c).result.sucesso,false);assert.equal(h.calls.length,0);
    }
});
test('resultado de devolucao exige origem completa e conserva a chave',()=>{
    const h=setup();assert.equal(h.run('consultarResultadoOperacao',{codEstabel:'ORIGEM',ramo:'DEVOLUCAO',chaveIdempotente:'chave'}).result.codigoErro,'PARAMETRO_OBRIGATORIO');
    assert.equal(h.calls.length,0);
});
test('resposta com campos sensiveis e profundidade excessiva e recusada',()=>{
    for(const r of [{...page(),token:'segredo'},{...page(),dados:[{headers:{Authorization:'segredo'}}],total:1}]) {
        const h=setup(r);const out=h.run('consultarTipos');assert.equal(out.result.codigoErro,'RESPOSTA_INVALIDA');assert.doesNotMatch(JSON.stringify(out),/segredo/);
    }
});
// --- Configuracao TESTE do projeto ---
test('projeto: regra TESTE DefaultGroup-1 so com tipos e escritas so de tipos',()=>{
    const ctx={};vm.createContext(ctx);vm.runInContext(source,ctx);
    assert.equal(ctx.NW_CONFIG.regras.length,1);assert.equal(ctx.NW_CONFIG.regras[0].grupo,'DefaultGroup-1');
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[0].acoes),['consultarTipos','consultarTiposApoio','incluirTipo','alterarTipo']);
    assert.deepEqual(Array.from(ctx.NW_CONFIG.regras[0].estabelecimentos),[]);
    assert.deepEqual(Array.from(ctx.NW_CONFIG.escritasHabilitadas),['incluirTipo','alterarTipo']);
    assert.equal(ctx.NW_CONFIG.serviceCode,'DATASUL_REST_HOMOLOG');
});
test('projeto: comando fora da lista habilitada nega sem chamar REST, mesmo com grupo autorizado',()=>{
    const param={codEstabel:'ORIGEM',item:'001',codTipo:'PL',capacidade:20,unidade:'LT',ativo:true,chaveIdempotente:'k'};
    for(const [acao,p] of [['incluirParametro',param],['criarTransferencia',command]]) {
        const h=setup();assert.equal(h.run(acao,p).result.codigoErro,'ESCRITA_DESABILITADA');assert.equal(h.calls.length,0);
    }
    const h=setup({sucesso:true,codigoErro:'',mensagem:'',repeticao:false,codTipo:'PL',descricao:'PLASTICO',ativo:true,versao:1,idEvento:'1'});
    assert.equal(h.run('incluirTipo',{codTipo:'PL',descricao:'PLASTICO',ativo:true,versao:0,chaveIdempotente:'k'}).result.sucesso,true);assert.equal(h.calls.length,1);
});
test('projeto: lista habilitada nao substitui permissao por grupo/acao',()=>{
    const h=setup();h.context.NW_CONFIG.regras=[{grupo:'grupo-teste',acoes:['consultarTipos'],estabelecimentos:[]}];
    assert.equal(h.run('incluirTipo',{codTipo:'PL',descricao:'PLASTICO',ativo:true,versao:0,chaveIdempotente:'k'}).result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,0);
});
test('projeto: colleagueGroup com colunas curtas (como na API REST do TESTE) autoriza; identidade divergente nega',()=>{
    let h=setup(page([],false,'',true));
    h.context.DatasetFactory.getDataset=()=>({rowsCount:2,getValue(i,k){
        const linha=[{companyId:'empresa-teste',colleagueId:'usuario-teste',groupId:'grupo-teste'},{companyId:'empresa-teste',colleagueId:'outra-pessoa',groupId:'grupo-admin'}][i];
        return k.indexOf('colleagueGroupPK.')===0?null:linha[k];
    }});
    assert.equal(h.run('consultarTipos').result.sucesso,true);assert.equal(h.calls.length,1);
    h.context.NW_CONFIG.regras=[{grupo:'grupo-admin',acoes:['consultarTipos'],estabelecimentos:[]}];
    assert.equal(h.run('consultarTipos').result.codigoErro,'SEM_PERMISSAO');assert.equal(h.calls.length,1);
});
test('projeto: constraint sqlLimit do Fluig e ignorada; outra desconhecida e recusada com o nome',()=>{
    const h=setup(page([],false,'',true));
    const c=(name,value)=>({getFieldName:()=>name,getInitialValue:()=>value,getFinalValue:()=>value});
    let ds=h.context.createDataset(null,[c('acao','consultarTipos'),c('parametros','{}'),c('sqlLimit','1')],null);
    assert.equal(ds.values[0][1],'true');assert.equal(h.calls.length,1);assert.doesNotMatch(h.calls[0].endpoint,/sqlLimit/);
    ds=h.context.createDataset(null,[c('acao','consultarTipos'),c('parametros','{}'),c('outraCoisa','x')],null);
    assert.equal(ds.values[0][1],'false');assert.match(ds.values[0][3],/outraCoisa/);assert.equal(h.calls.length,1);
});
console.log('DATASET_UNICO|CENARIOS='+total+'|FALHAS=0|FLUIG_REAL=nao');
