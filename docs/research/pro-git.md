# Pro Git (2ª edição)

| Campo | Valor |
|---|---|
| Fonte | https://git-scm.com/book/pt-br/v2 (tradução pt-br) e https://git-scm.com/book/en/v2 (original) |
| Edição lida | **2ª edição (2014)**, Scott Chacon e Ben Straub, Apress, licença CC BY-NC-SA 3.0. Livro vivo: a página em inglês informa versão online **2.1.450** (a data dessa versão não aparece na página) |
| Idioma lido | **pt-br** em 2.6, 3.4, 3.6, 5.1, 5.2, 5.3, 7.1, 7.2, 7.3, 7.4, 7.6, 7.7, 7.8, 7.10, 8.1, 8.2, 8.3 e 8.4 (todas com o corpo traduzido, inclusive o aviso recente sobre `git-filter-repo`). **en** em 10.7 (Maintenance and Data Recovery) e, por conferência, 2.6 |
| Complementos | O livro não cobre `text`/`eol`, `--force-with-lease`, `--fixup`/`--autosquash`, `core.hooksPath` nem assinatura por SSH. Para isso foram lidas as páginas de manual em https://git-scm.com/docs, a documentação do GitHub, o README do `git-filter-repo` e a especificação Conventional Commits 1.0.0 |
| Acesso | 2026-09-19 |

## Por que esta fonte importa para o Cajui

- O projeto já decidiu branch por feature, merge por PR, commits atômicos e Conventional Commits. O livro dá o critério para o que o plano deixou em aberto: **quando reescrever histórico é seguro e quando é proibido**.
- O desenvolvimento é em Windows e o servidor é Linux arm64: fim de linha errado em `deploy.sh` ou em hook quebra deploy. O capítulo 8 e o manual de `gitattributes` resolvem isso no repositório, não na máquina.
- O repositório vai abrir no fim. Segredo que entrar no histórico hoje é vazamento amanhã; o procedimento de remoção precisa estar escrito antes de ser necessário.
- Em repositório privado de conta gratuita o GitHub não impõe regra de branch (ver `github-skills.md`). O capítulo 8.4 é claro: hook de cliente não é imposição. Isso define o papel de cada camada (hook = conveniência, CI = autoridade).

## O que se aplica

| Item da fonte | Onde toca o Cajui | Decisão |
|---|---|---|
| 3.4 Fluxos de branches: branches de longa duração são opcionais; topic branch é curta, de um assunto só, e tudo é local até o push | Modelo de branches do monorepo | D-GIT-01, 02 |
| 3.6 Rebase: "Não faça rebase de commits que existem fora do seu repositório e nos quais as pessoas possam ter baseado o trabalho delas"; recomendação final: limpar com rebase **antes** do push e nunca reescrever o que já foi enviado; `git pull --rebase` | Commits de trabalho em andamento reescritos antes do PR | D-GIT-09, 10, 11, 20 |
| 5.2 Diretrizes de commit: `git diff --check`, um conjunto lógico por commit, `git add --patch`, resumo de ~50 caracteres, linha em branco, corpo em ~72 colunas, modo imperativo | Commits atômicos e mensagens | D-GIT-03, 04, 05 |
| 5.2 Projeto com fork: nunca continuar trabalho em branch já rejeitada ou integrada; nova branch a partir de `origin/master` | Ciclo de vida da topic branch | D-GIT-02 |
| 5.3 Mantendo um projeto: `git log main..topic`, diff de três pontos, `rerere`, tag de release assinada, `git describe` para número de build, `git shortlog` | Revisão antes do PR, releases, versão exibida pelo app e pelo backend | D-GIT-18, 20, 22 |
| 2.6 Tags: "Geralmente é recomendado que você crie tags anotadas"; `git push` não envia tags; `--tags` envia leves e anotadas | Releases | D-GIT-18 |
| 7.1 Reflog: log **estritamente local**, guarda alguns meses, vazio logo após o clone | Recuperação de erro | D-GIT-13 |
| 7.2 Stage interativo: `git add -p` com dividir (`s`) e editar (`e`) hunk | Separar mudanças misturadas em commits atômicos | D-GIT-03 |
| 7.3 Stash e clean: `git stash push`, `-u`, `--keep-index`, `git stash branch`; `git clean -n` antes de `-f`; `-x` apaga também os ignorados | Troca de contexto entre especificação e código; arquivos locais ignorados (keystore, `.env`) | D-GIT-14 |
| 7.4 Assinatura: `git tag -s`, `git commit -S`, `git tag -v`, `git log --show-signature`, `commit.gpgsign` (só GPG) | Autenticidade de commits e de releases | D-GIT-17, 18 |
| 7.6 Reescrita: `--amend`, `rebase -i` (reword, edit, squash, fixup, drop, exec), dividir commit; `filter-branch` "não é mais a maneira recomendada", usar `git-filter-repo` | Limpeza antes do PR; segredo no histórico | D-GIT-09, 19 |
| 7.7 Reset desmistificado: três árvores; `--hard` é "um dos pouquíssimos casos em que o Git realmente destruirá dados" | Desfazer local | D-GIT-12 |
| 7.8 Desfazendo merges: `reset --hard HEAD~` só se ninguém mais tem o commit; em histórico compartilhado, `git revert -m 1`; para mesclar de novo é preciso reverter o revert | Rollback de PR já integrado em `main` | D-GIT-12 |
| 7.10 Bisect: `git bisect start/bad/good/reset` e `git bisect run <script>` (0 = bom, diferente de 0 = ruim) | Caça a regressão em regra de negócio (indicadores, vale alimentação) | D-GIT-15 |
| 8.1 Configuração: `commit.template`, `core.autocrlf`, `core.whitespace`, `receive.*` | Ambiente do desenvolvedor | D-GIT-16, 21 |
| 8.2 Atributos: `binary`, `diff=` com `textconv`, `export-ignore`, `merge=ours`; o capítulo **não** trata de `text`/`eol` | `.gitattributes` do monorepo | D-GIT-16 |
| 8.3 Hooks: "os hooks do lado do cliente **não** são copiados quando você clona"; `pre-commit`, `commit-msg`, `pre-rebase`, `pre-push`; servidor: `pre-receive`, `update`, `post-receive` | Validação local de Conventional Commits, formatação e segredos | D-GIT-06, 07, 08 |
| 8.4 Política de exemplo: formato de mensagem imposto no `update` do servidor; hooks de cliente só como ajuda e "você deve distribuir esses scripts de outra forma" | Quem é autoridade | D-GIT-08 |
| 10.7 Recuperação: `git reflog`, `git log -g`, `git branch recover-branch <sha>`, `git fsck --full` | Runbook de recuperação | D-GIT-13 |

## Decisões

| ID | Decisão | Vira requisito em | Como se verifica |
|---|---|---|---|
| D-GIT-01 | Uma única branch de longa duração, `main`, sempre estável e implantável. Sem `develop`: o livro diz que níveis de estabilidade ajudam em projeto grande e não são obrigatórios; com um desenvolvedor e um ambiente, seria cerimônia. Nome de topic branch: `<tipo>/<slug>` com os mesmos tipos dos commits (ex.: `docs/phase-1-research`, `feat/share-intent-ocr`) | Fase 4 ADR de fluxo Git e guia de contribuição | Hook `pre-push` e CI validam o nome por expressão regular |
| D-GIT-02 | Uma topic branch = um assunto = um PR. Integrada, é apagada (local e remota). Nunca retomar trabalho em branch já integrada: nova branch a partir de `origin/main` | Guia de contribuição (Fase 4) | Lista de branches remotas contém só `main` e PRs abertos |
| D-GIT-03 | Commit atômico: um conjunto lógico de mudança, que compila e passa nos testes sozinho. Mudanças misturadas no mesmo arquivo são separadas com `git add -p`. `git diff --cached --check` roda no `pre-commit` | Fase 2 RNF de processo; Fase 6 hook | Antes do PR: `git rebase -i --exec "<comando de teste>" origin/main` executa os testes em cada commit |
| D-GIT-04 | Mensagem: cabeçalho Conventional Commits em inglês, imperativo, **meta de 50 e limite rígido de 72 caracteres**; linha em branco; corpo em 72 colunas explicando o porquê. Onde o livro pede resumo com inicial maiúscula, vale a convenção já usada no repositório (descrição em minúscula depois do prefixo) | Guia de contribuição; `.gitmessage` | Hook `commit-msg` e job de CI sobre todos os commits do PR |
| D-GIT-05 | Tipos aceitos: `feat`, `fix` (os dois que a especificação exige), mais `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Escopo opcional = nome de feature ou pacote. Quebra de contrato com `!` ou rodapé `BREAKING CHANGE:`. `feat` sobe MINOR, `fix` sobe PATCH, quebra sobe MAJOR | Guia de contribuição; Fase 4 ADR de versionamento | Mesma expressão regular no hook e no CI: `^(tipos)(\([a-z0-9-]+\))?!?: .+` |
| D-GIT-06 | Hooks versionados em `tool/hooks/` e ativados por `git config core.hooksPath tool/hooks` (o manual `githooks` documenta a variável; o livro só fala de `.git/hooks`). Um script de preparo (`tool/setup-git`) aplica essa e as demais configurações. Hooks precisam do bit de execução e de LF | Fase 6 | `git config --get core.hooksPath` no script de verificação do ambiente; CI confere modo e fim de linha dos hooks |
| D-GIT-07 | Conteúdo dos hooks, todos rápidos: `pre-commit` (formatação dos `.dart` staged, `--check` de espaços, gitleaks no staged, limite de tamanho de arquivo); `commit-msg` (D-GIT-05); `pre-push` (recusa push, force e deleção em `main`; recusa tag `v*` leve; o manual informa que este hook **não** é contornado por `--no-verify`); `pre-rebase` (recusa rebase de commits já contidos em `origin/main`). Testes completos ficam no CI | Fase 6 | Teste automatizado de cada hook em repositório temporário |
| D-GIT-08 | Hook de servidor (`pre-receive`, `update`) **não existe no GitHub.com** para este projeto e `pre-commit`/`commit-msg` saem com `--no-verify`. Logo, tudo que o hook checa é repetido no CI, e o CI é a autoridade. A ausência de imposição no servidor enquanto o repositório for privado vai para o threat model como risco aceito | Fase 5 `threat-model.md` | Cada regra de hook tem um job equivalente em `ci.yml` |
| D-GIT-09 | Trabalho em andamento: commits livres na topic branch; correção de commit anterior com `git commit --fixup=<sha>` (ou `--fixup=reword:<sha>` para só a mensagem); antes de abrir o PR, `git rebase -i --autosquash origin/main` (`rebase.autoSquash true`). Antes de qualquer reescrita, `git branch backup/<nome>`. PR com assunto `fixup!`, `squash!`, `amend!` ou `wip` é recusado pelo CI | Guia de contribuição; Fase 6 CI | Job de CI sobre os assuntos dos commits do PR |
| D-GIT-10 | Push forçado só na própria topic branch e só como `git push --force-with-lease --force-if-includes` (alias `pushf`). `--force` puro é proibido. O manual avisa que o lease sem valor esperado é "trivialmente derrotado" por `fetch` em segundo plano: desligar auto-fetch da IDE ou manter `--force-if-includes` | Guia de contribuição | Alias presente no script de preparo; `pre-push` barra force em `main` |
| D-GIT-11 | **Nunca reescrever**: `main`; tags `v*` publicadas; commits já integrados; branch da qual outra branch ou outro clone dependa. Única exceção: remoção de segredo (D-GIT-19), com registro de incidente. Depois do PR aberto, a reescrita da topic branch continua permitida por ser de um único autor, mas o autosquash final é o último passo antes do merge | Fase 4 ADR de fluxo Git | `main-guard` e `pre-push` (ver `github-skills.md` D-GHS-03) |
| D-GIT-12 | Desfazer: em `main`, sempre `git revert`; PR integrado se desfaz com `git revert -m 1 <merge>` e, para reintegrar depois, **reverte-se o revert** antes do novo merge. Em trabalho local não publicado, `reset` (`--soft` e `--mixed` são seguros; `--hard` destrói o que não foi commitado) | Fase 7 `runbook.md` (rollback de release); guia de contribuição | Exercício de rollback em repositório de teste descrito no runbook |
| D-GIT-13 | Recuperação: `git reflog` ou `git log -g`, depois `git branch recover/<nome> <sha>`; sem reflog, `git fsck --full`. O reflog é local e temporário, **não é backup**: o backup do trabalho em andamento é o push da topic branch, e é por isso que o fluxo de D-GIT-09/10 existe | Fase 7 runbook | Procedimento ensaiado uma vez e anotado |
| D-GIT-14 | Stash só para troca rápida: `git stash push -u -m "<motivo>"`, e `git stash branch` se o stash não aplicar. Para interrupção longa, commit `wip` na branch (vai para o remoto; stash não vai). `git clean` sempre com `-n` antes; **nunca `-x` às cegas**: apaga keystore Android, `.env` e qualquer segredo local ignorado | Guia de contribuição | Revisão do guia; nenhum alias com `clean -fdx` |
| D-GIT-15 | Regressão se caça com `git bisect run tool/bisect.sh` (saída 0 = bom, diferente de 0 = ruim). Só funciona porque todo commit de `main` compila e passa nos testes (D-GIT-03, 09) | Guia de contribuição; Fase 6 `tool/bisect.sh` | Ensaio de bisect sobre um bug plantado |
| D-GIT-16 | `.gitattributes` é a fonte da verdade de fim de linha: `* text=auto eol=lf`, LF explícito para `.sh`, `.dart`, `.json`, `.yaml`, `.md`; CRLF para `.bat` e `.ps1`; imagens, fontes, áudio e PDF como `binary`. O arquivo atual já faz isso; acrescentar `*.jar`, `*.jks` e `*.keystore` como `binary` quando o projeto Android for criado. O atributo tem precedência sobre `core.autocrlf`, então nada depende da máquina. Mudou o arquivo: `git add --renormalize .` | Fase 4 ADR; Fase 6 no commit de scaffold | Job de CI com `git ls-files --eol` falha se houver CRLF em `.sh`, `.dart` ou hooks |
| D-GIT-17 | Commits e tags assinados com **chave SSH** (Git 2.34 ou mais novo): `gpg.format ssh`, `user.signingkey <caminho>.pub`, `commit.gpgsign true`, `tag.gpgSign true`. O livro só cobre GPG; a documentação do GitHub diz que SSH é o mais simples para indivíduo. A chave de assinatura é separada da chave de deploy | Fase 4 ADR; Fase 5 `asvs-checklist.md` | `git log --show-signature`; selo Verified no GitHub; exigência por ruleset quando o repositório abrir |
| D-GIT-18 | Release = tag **anotada e assinada**: `git tag -s vX.Y.Z -m "..."`, enviada uma a uma (`git push origin vX.Y.Z`), nunca `--tags` (envia também as leves). Tag publicada é imutável: release errada vira novo PATCH. `git describe` gera a versão de build exibida pelo app e por `--version` do backend | Fase 4 ADR de versionamento; Fase 7 runbook | `git cat-file -t vX.Y.Z` devolve `tag`; `git tag -v` passa |
| D-GIT-19 | Segredo no histórico: (1) **revogar e rotacionar primeiro**, que é o que de fato mitiga; (2) se ainda não houve push, `--amend` ou `rebase -i`; (3) se houve push: clone novo, `git filter-repo --sensitive-data-removal --invert-paths --path <arquivo>` ou `--replace-text`, `git push --force --mirror`, descartar e reclonar toda cópia antiga; (4) pedir ao suporte do GitHub a limpeza de cache e de referências de PR; (5) registrar o incidente. Efeitos: todos os SHA mudam, assinaturas caem, diffs de PR fechado se perdem. `filter-branch` e BFG não são usados | Fase 5 `threat-model.md` (resposta a incidente); Fase 7 runbook, seção "segredo vazado" | Ensaio em repositório descartável; gitleaks de histórico completo sem achados |
| D-GIT-20 | Configuração padrão do clone: `pull.rebase true`, `rerere.enabled true`, `merge.conflictstyle diff3`, `rebase.autoSquash true`. Topic branch se atualiza com `git rebase origin/main`, nunca com merge de `main` para dentro dela | `tool/setup-git` (Fase 6) | `git config --get` de cada chave no script de verificação |
| D-GIT-21 | `commit.template` aponta para `.gitmessage` versionado com o esqueleto do Conventional Commits e o lembrete dos limites de 50/72 | Fase 6 | Arquivo presente e configurado pelo script de preparo |
| D-GIT-22 | Autorrevisão antes do push: `git log origin/main..HEAD` para os commits e `git diff origin/main...HEAD` (três pontos) para o que a branch introduz | Template de PR (checklist) | Item marcado no PR |

## O que não se aplica, e por que

- **Branches de longa duração em níveis (`develop`, `next`, `pu`) e o fluxo ditador/tenentes (3.4, 5.1, 5.3):** equipe de uma pessoa, um ambiente de produção.
- **Fluxo com fork e gerente de integração, patches por e-mail (`format-patch`, `am`, `apply`, `request-pull`):** o PR na mesma origem cobre tudo.
- **Configuração de servidor (`receive.fsckObjects`, `receive.denyNonFastForwards`, `receive.denyDeletes`) e hooks de servidor (8.1, 8.3, 8.4):** o servidor é o GitHub.com; o equivalente são rulesets, indisponíveis hoje (ver `github-skills.md`).
- **ACL por diretório do exemplo 8.4:** não há segundo autor.
- **`filter-branch` (7.6, 10.7):** o próprio livro desaconselha; o roteiro de 10.7 (`rm -Rf .git/refs/original`, `gc`, `prune`) serve só como explicação do que o `git-filter-repo` faz.
- **GPG e rede de confiança (7.4):** substituídos por assinatura SSH.
- **Expansão de palavra-chave (`ident`, filtros smudge/clean) e `merge=ours` (8.2):** a versão vem de `git describe` no build; driver de merge por arquivo esconderia conflito em dado financeiro de fixture.
- **`textconv` para `.docx` e EXIF (8.2):** não há documento binário que mereça diff; imagens e áudio ficam como `binary`.
- **`git archive` com `export-ignore`/`export-subst` (5.3, 8.2):** os artefatos de release saem do CI, não de um tarball do repositório.
- **Submódulos, bundles, `replace`, armazenamento de credenciais (7.11 a 7.14):** monorepo com pub workspaces; autenticação por SSH.
- Observação sobre Flutter Web em canvas: **não se aplica a esta fonte**; nada no livro toca renderização, HTML ou ARIA.

## Pontos de atenção

1. **O livro sozinho não sustenta o fluxo do projeto.** `--force-with-lease`, `--fixup`/`--autosquash`, `core.hooksPath`, atributos `text`/`eol` e assinatura SSH não estão nele. Quem citar "Pro Git" como fonte dessas práticas cita errado; a fonte são as páginas de manual.
2. **A regra de ouro contradiz, ao pé da letra, o que o projeto faz.** O livro diz para nunca reescrever o que já foi enviado; o Cajui envia commits de trabalho e os reescreve antes do PR. É aceitável só porque ninguém baseia trabalho nessas branches. A exceção deixa de valer no momento em que houver um segundo clone ativo (outra máquina) ou uma branch empilhada sobre outra: aí `pull --rebase` e atenção redobrada, ou parar de reescrever.
3. **`--force-with-lease` não é rede de proteção completa.** Qualquer `fetch` automático atualiza a referência remota local e o lease passa mesmo sobrescrevendo trabalho que não foi visto. `--force-if-includes` reduz o problema; desligar auto-fetch elimina.
4. **Hook de cliente não é controle.** Não vem no clone, depende de `core.hooksPath` configurado e `--no-verify` pula `pre-commit` e `commit-msg`. Somado à falta de regra de branch no GitHub Free privado, a imposição real é o CI **depois** do push. Um segredo barrado só no CI já está no remoto: nesse caso vale D-GIT-19, não "apagar o commit".
5. **Conflito entre o livro e Conventional Commits:** o modelo do livro pede resumo com inicial maiúscula e até 50 caracteres; o prefixo `type(scope):` consome de 10 a 25. Por isso o limite rígido é 72 e 50 vira meta.
6. **`reset --hard` e `git clean -fdx` são os dois destruidores de dados.** O segundo é o mais perigoso aqui porque os segredos locais são justamente arquivos ignorados.
7. **Revert de merge tem pegadinha documentada:** depois de `revert -m 1`, um novo merge da mesma branch traz só o que veio depois; sem reverter o revert, metade da feature some em silêncio.
8. **`git-filter-repo` exige Git 2.36 ou mais novo e Python 3.6 ou mais novo** (a opção `--sensitive-data-removal` pede a versão 2.47 da ferramenta) e, por padrão, só roda em clone novo. Conferir na máquina Windows antes de precisar. Ele remove o remoto `origin` de propósito e invalida todas as assinaturas e tags.
9. **Squash e "rebase and merge" do GitHub recriam commits**: somem a assinatura do autor e, no squash, os commits atômicos. O esforço de D-GIT-03/09 só sobrevive com merge commit (ver `github-skills.md` D-GHS-02).
10. **Bisect e autosquash dependem um do outro:** um único commit quebrado em `main` obriga a pular commits no bisect. O `rebase --exec` de D-GIT-03 é o que garante isso, e custa tempo local, não minutos de CI.
11. **Windows:** bit de execução dos hooks e de `deploy.sh` não é preservado pelo sistema de arquivos; precisa ser gravado no índice do Git. O comando exato não foi relido hoje (ver "Não verificado").

## Páginas lidas

- https://git-scm.com/book/pt-br/v2 — sumário; edição; seções com título parcialmente em inglês; URL correta da seção 2.6.
- https://git-scm.com/book/en/v2 — edição, autores, licença, versão online 2.1.450.
- pt-br 2.6 https://git-scm.com/book/pt-br/v2/Fundamentos-do-Git-Criando-Tags — tag anotada recomendada; `--tags` envia leves e anotadas; `--follow-tags`.
- en 2.6 https://git-scm.com/book/en/v2/Git-Basics-Tagging — mesmo conteúdo, lido antes de achar a URL pt-br.
- pt-br 3.4 `.../Ramifica%c3%a7%c3%a3o-Branching-no-Git-Fluxos-de-Trabalho-de-Branches-Branching-Workflows` — branches longas opcionais; topic branches.
- pt-br 3.6 `.../Ramifica%c3%a7%c3%a3o-Branching-no-Git-Rebase-Rebasing` — regra de ouro; `pull --rebase`; recomendação final.
- pt-br 5.1 `.../Git-Distribu%c3%addo-Fluxos-de-Trabalho-Distribu%c3%addos` — três fluxos distribuídos.
- pt-br 5.2 `.../Git-Distribu%c3%addo-Contribuindo-com-um-Projeto` — diretrizes de commit, modelo de mensagem, equipe pequena, fork.
- pt-br 5.3 `.../Git-Distribu%c3%addo-Mantendo-um-Projeto` — diff de três pontos, rerere, tag assinada, `describe`, `archive`, `shortlog`.
- pt-br 7.1 `.../Ferramentas-do-Git-Sele%c3%a7%c3%a3o-de-Revis%c3%a3o` — reflog local e temporário; intervalos de dois e três pontos.
- pt-br 7.2 `.../Ferramentas-do-Git-%c3%81rea-de-Stage-Interativa` — `add -p` e demais comandos com `--patch`.
- pt-br 7.3 `.../Ferramentas-do-Git-Fazendo-Stash-e-Limpando` — `stash push`, `-u`, `stash branch`, avisos de `clean`.
- pt-br 7.4 `.../Ferramentas-do-Git-Assinando-Seu-Trabalho` — assinatura GPG de tags, commits e merges.
- pt-br 7.6 `.../Ferramentas-do-Git-Reescrevendo-o-Hist%c3%b3rico` — amend, `rebase -i`, dividir commit, aviso contra `filter-branch`.
- pt-br 7.7 `.../Ferramentas-do-Git-Reset-Desmistificado` — três árvores e tabela de segurança.
- pt-br 7.8 `.../Ferramentas-do-Git-Merging-Avan%c3%a7ado` — desfazer merge com reset ou revert; reverter o revert.
- pt-br 7.10 `.../Ferramentas-do-Git-Depurando-com-Git` — blame e bisect automatizado.
- pt-br 8.1 `.../Customizando-o-Git-Configura%c3%a7%c3%a3o-do-Git` — `commit.template`, `core.autocrlf`, `core.whitespace`, `receive.*`.
- pt-br 8.2 `.../Customizando-o-Git-Atributos-do-Git` — `binary`, `textconv`, filtros, `export-*`, `merge=ours`.
- pt-br 8.3 `.../Customizando-o-Git-Hooks-do-Git` — hooks de cliente e de servidor; não são clonados.
- pt-br 8.4 `.../Customizando-o-Git-Uma-Pol%c3%adtica-de-Exemplo-Imposta-pelo-Git` — imposição no servidor, ajuda no cliente.
- en 10.7 https://git-scm.com/book/en/v2/Git-Internals-Maintenance-and-Data-Recovery — recuperação por reflog e `fsck`; remoção de objetos.
- https://git-scm.com/docs/gitattributes — `text=auto`, `eol`, macro `binary`, `--renormalize`, precedência sobre `core.autocrlf`; não há driver de diff embutido para Dart.
- https://git-scm.com/docs/githooks — `core.hooksPath`, argumentos e entrada do `pre-push`, quais hooks `--no-verify` pula.
- https://git-scm.com/docs/git-push — `--force-with-lease`, aviso sobre fetch em segundo plano, `--force-if-includes`.
- https://git-scm.com/docs/git-rebase — `--autosquash`, `rebase.autoSquash`, `--exec`, `--update-refs`, aviso sobre rebase de branch compartilhada.
- https://git-scm.com/docs/git-commit — `--fixup`, `--fixup=amend:`/`reword:`, `--squash`, `-S`, `--no-verify`.
- https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository — roteiro oficial com `git-filter-repo`, efeitos colaterais e suporte.
- https://github.com/newren/git-filter-repo — requisitos, exigência de clone novo, por que não `filter-branch` nem BFG.
- https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key e `.../about-commit-signature-verification` — assinatura SSH (Git 2.34+), estados de verificação.
- https://www.conventionalcommits.org/en/v1.0.0/ — estrutura, tipos obrigatórios e sugeridos, relação com SemVer, `revert`.

## Não verificado

- URL pt-br de 2.6 com "Fundamentos-de-Git" devolveu 404; a correta ("Fundamentos-do-Git") foi achada no sumário e lida.
- Data de publicação da versão online 2.1.450: não aparece nas páginas lidas.
- Capítulo 6 (GitHub), 3.5 (branches remotos), 7.5, 7.9 e 7.11 a 7.14: não lidos; fora do pedido. `rerere` foi visto só pelo resumo em 5.3.
- Código de saída 125 (pular commit) no `bisect run`: o capítulo 7.10 não menciona e o manual de `git-bisect` não foi aberto.
- Comando para gravar o bit de execução no índice em Windows e o mecanismo de verificação local de assinatura SSH (`allowedSignersFile`): não relidos hoje; conferir na Fase 6.
- Exigência de cadastrar a chave SSH no GitHub como "signing key": a página lida não trouxe esse trecho; conferir ao configurar.
- Inexistência de hooks de servidor no GitHub.com: afirmada por conhecimento do serviço (hooks `pre-receive` são recurso do Enterprise Server), sem página lida hoje.
