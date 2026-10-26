// node cdp.cjs eval "<expressao JS>"   |  node cdp.cjs shot arquivo.png  |  node cdp.cjs evalfile arquivo.js
// Fala com a aba do Fluig no Chrome aberto com --remote-debugging-port=9333.
const fs = require('node:fs');
const [, , cmd, arg] = process.argv;
(async () => {
    const lista = await (await fetch('http://127.0.0.1:9333/json/list')).json();
    const aba = lista.find(t => t.type === 'page' && /fluig-web-teste/.test(t.url));
    if (!aba) throw new Error('Aba do Fluig nao encontrada');
    const ws = new WebSocket(aba.webSocketDebuggerUrl);
    await new Promise((ok, erro) => { ws.onopen = ok; ws.onerror = erro; });
    let id = 0; const pend = {};
    ws.onmessage = m => { const d = JSON.parse(m.data); if (d.id && pend[d.id]) { pend[d.id](d); delete pend[d.id]; } };
    const send = (method, params = {}) => new Promise(ok => { pend[++id] = ok; ws.send(JSON.stringify({ id, method, params })); });
    let saida;
    await send('Page.bringToFront');
    if (cmd === 'type' || cmd === 'key') {
        // node cdp.cjs type "<seletor>" "<texto>"  |  node cdp.cjs key "<seletor>" Enter|Backspace|ArrowDown|Escape
        const texto = process.argv[4];
        const foco = await send('Runtime.evaluate', { expression: '(()=>{const e=document.querySelector(' + JSON.stringify(arg) + '); if(!e) return false; e.focus(); return document.activeElement===e;})()', returnByValue: true });
        if (!foco.result.result.value) throw new Error('nao focou ' + arg);
        const teclas = { Enter: [13, String.fromCharCode(13)], Backspace: [8, ''], ArrowDown: [40, ''], Escape: [27, ''], Tab: [9, ''] };
        const lista = cmd === 'key' ? [texto] : Array.from(texto);
        for (const ch of lista) {
            const esp = teclas[ch];
            const base = esp ? { key: ch, code: ch, windowsVirtualKeyCode: esp[0], nativeVirtualKeyCode: esp[0] } : { key: ch, text: ch, unmodifiedText: ch };
            await send('Input.dispatchKeyEvent', { type: esp && !esp[1] ? 'rawKeyDown' : 'keyDown', ...base, ...(esp && esp[1] ? { text: esp[1] } : {}) });
            await send('Input.dispatchKeyEvent', { type: 'keyUp', ...base });
            await new Promise(r => setTimeout(r, 80));
        }
        saida = 'ok ' + cmd;
    } else if (cmd === 'wait') {
        // node cdp.cjs wait "<expressao verdadeira quando pronto>" [segundos]
        const limite = Date.now() + 1000 * Number(process.argv[4] || 30);
        for (;;) {
            const r = await send('Runtime.evaluate', { expression: arg, returnByValue: true });
            if (r.result.result && r.result.result.value) { saida = 'ok wait'; break; }
            if (Date.now() > limite) { saida = 'TIMEOUT wait: ' + arg; break; }
            await new Promise(x => setTimeout(x, 200));
        }
    } else if (cmd === 'front') { saida = 'ok front'; } else if (cmd === 'shot') {
        const r = await send('Page.captureScreenshot', { format: 'png' });
        fs.writeFileSync(arg, Buffer.from(r.result.data, 'base64')); saida = 'ok ' + arg;
    } else {
        const expr = cmd === 'evalfile' ? fs.readFileSync(arg, 'utf8') : arg;
        const r = await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true, userGesture: true });
        saida = r.result.exceptionDetails ? 'EXCECAO: ' + JSON.stringify(r.result.exceptionDetails).slice(0, 1500) : r.result.result.value;
    }
    console.log(typeof saida === 'string' ? saida : JSON.stringify(saida, null, 1));
    ws.close();
})().catch(e => { console.error(e.message); process.exitCode = 1; });
