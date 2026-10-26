(() => {
  if (window.__trava) return 'trava ja instalada';
  const original = window.chamarEmbalagens;
  window.__log = [];
  window.chamarEmbalagens = function (acao, parametros) {
    const p = JSON.parse(JSON.stringify(parametros || {}));
    const escrita = !/^consultar/.test(acao);
    if (escrita && String(p.codTipo || '').toUpperCase() === 'PL') {
      window.__log.push({ acao, p, bloqueado: true });
      return Promise.reject({ codigoErro: 'BLOQUEADO_PELO_TESTE', mensagem: 'PL protegido pelo teste' });
    }
    const item = { acao, p, t: new Date().toISOString() }; window.__log.push(item);
    return Promise.resolve(original.apply(this, arguments)).then(r => { item.r = r && { sucesso: r.sucesso, codigoErro: r.codigoErro, mensagem: r.mensagem, codTipo: r.codTipo, descricao: r.descricao, ativo: r.ativo, versao: r.versao, repeticao: r.repeticao, total: r.total }; return r; },
      e => { item.erro = e; throw e; });
  };
  window.__trava = true;
  return 'trava instalada; chamarEmbalagens original? ' + (typeof original);
})()
