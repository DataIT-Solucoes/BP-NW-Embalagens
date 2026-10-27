---
description: Entrega as alterações pendentes do widget (testes, .war, commit e push) com a mensagem informada
argument-hint: "texto da mensagem de commit"
---

Entregar as alterações pendentes deste widget com a mensagem: $ARGUMENTS

1. Rodar `git status --short` e montar a lista de arquivos alterados, novos ou apagados. Tirar da lista o que nunca entra no
   commit: `target/`, `cheli/`, `debug.log`, `*.bak`. Se não sobrar arquivo, avisar e parar.
2. Prefixo da mensagem: se `$ARGUMENTS` já começar com um prefixo aceito (`FIX`, `FEAT`, `REFACTOR`, `PERF`, `STYLE`, `DOCS`, `TEST`, `CHORE`, `CI`, `BUILD`,
   `REVERT`, `SECURITY`, seguido de `: `), usar como está. Senão, escolher pelo tipo dos arquivos: algum em `src/` → `FIX: `; só `.md`/`CLAUDE.md`/`README.md` → `DOCS: `; só `testes/` → `TEST: `; outros (script, `.claude/`) → `CHORE: `.
   Se `$ARGUMENTS` vier vazio, **não perguntar**: montar a mensagem a partir do `git diff` (prefixo pelo tipo dos arquivos, ou `FEAT: ` se
   houver funcionalidade nova; texto curto em português resumindo o que mudou) e seguir.
3. Se algum arquivo de `src/main/webapp/resources/js/` ou `testes/` estiver na lista, rodar `npm test` (transporte). Se alguma suíte não terminar com `FALHAS=0`, mostrar a saída e parar.
4. Rodar uma vez, a partir da pasta do widget:
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/entregar.ps1 -Mensagem "<PREFIXO: texto>" <arquivos...>`
5. Responder com a mensagem usada, os arquivos, o resultado dos testes, o hash do commit e o resultado do push/.war, como o
   script informar. Se o script falhar, mostrar o erro e não tentar contornar.
