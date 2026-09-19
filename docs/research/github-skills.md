# GitHub Skills (e o que o plano Free entrega em repositório privado)

| Campo | Valor |
|---|---|
| Fonte | https://skills.github.com/ (hoje só redireciona para https://learn.github.com/skills) e os cursos em https://github.com/skills. Complemento normativo: https://docs.github.com (edição "Free, Pro & Team") e https://github.com/pricing |
| Versão lida | Organização `skills` com **52 repositórios**, listagem com última atualização em 2026-09-18. Cursos e documentação são conteúdo vivo, sem número de edição. Mudança de plataforma mais recente usada aqui: changelog de 2026-01-29 (runners arm64 em repositório privado) |
| Acesso | 2026-09-19 |

## Por que esta fonte importa para o Cajui

- O plano diz "merge por PR, CI obrigatório, Dependabot, secret scanning, CodeQL". Os cursos ensinam o fluxo, mas **quase tudo que impõe esse fluxo no servidor não existe em repositório privado de conta gratuita**. Esta pesquisa separa o que é hábito (dá para adotar hoje) do que é controle do GitHub (só quando o repositório abrir).
- O CI é a única autoridade de qualidade do projeto enquanto não houver regra de branch. Ele cabe em 2.000 minutos por mês ou não cabe; a conta precisa ser feita antes da Fase 6.
- O backend compila para linux/arm64. Desde janeiro de 2026 existe runner arm64 padrão em repositório privado, o que elimina emulação e runner próprio na VM de produção.
- O repositório vira público na fase final: nesse dia **todo o histórico** fica exposto. Varredura de segredos precisa existir desde já, por conta própria.

## O que se aplica

### Catálogo em 2026-09-19 (40 cursos ativos, 10 repositórios de ferramental, 2 arquivados)

| Grupo | Cursos (nome do repositório em `github.com/skills/`) |
|---|---|
| Fundamentos (6) | `introduction-to-git`, `introduction-to-github`, `communicate-using-markdown`, `github-pages`, `connect-the-dots`, `code-with-codespaces` |
| Colaboração e histórico (5) | `review-pull-requests`, `resolve-merge-conflicts`, `introduction-to-repository-management`, `release-based-workflow`, `change-commit-history` |
| GitHub Actions (7) | `hello-github-actions`, `test-with-actions`, `reusable-workflows`, `workflow-artifacts`, `publish-docker-images`, `write-javascript-actions`, `deploy-to-azure` |
| Segurança (5) | `secure-repository-supply-chain`, `introduction-to-secret-scanning`, `introduction-to-codeql`, `configure-codeql-language-matrix`, `secure-code-game` |
| Qualidade e migração (2) | `ship-with-quality`, `migrate-ado-repository` |
| Ferramentas de IA generativa da plataforma (15) | Quinze cursos sobre recursos de IA generativa do próprio GitHub; nomes omitidos por não terem relação com o fluxo Git/GitHub deste projeto |
| Ferramental e arquivados (12) | `exercise-toolkit`, `exercise-creator`, `exercise-template`, `action-*` (4), `releases`, `skills-for-emu`, `.github`; mais dois cursos arquivados |

### Cursos que mudam o jeito de trabalhar neste repositório

| Item da fonte | Onde toca o Cajui | Decisão |
|---|---|---|
| `review-pull-requests` (< 30 min): abrir PR, atribuir-se, revisar, sugerir e aplicar mudança, merge | Todo merge em `main`; com usuário único a revisão é autorrevisão no diff do PR | D-GHS-01, 02 |
| `resolve-merge-conflicts` (< 30 min): por que o conflito acontece; resolução no editor web | Topic branches longas (especificação e código em paralelo) | D-GHS-15 |
| `hello-github-actions` e `test-with-actions` (< 60 min): workflow de teste, cobertura, matriz, teste como bloqueio de merge | `.github/workflows/ci.yml` | D-GHS-05, 06, 20 |
| `reusable-workflows` (< 1 h): `workflow_call`, fluxo de permissões entre chamador e chamado | Monorepo com pub workspaces: mesmos passos para app, backend e pacotes | D-GHS-19 |
| `workflow-artifacts` (< 1 h): publicar relatório de cobertura, reaproveitar artefato de build entre jobs | Relatório de cobertura; binário arm64 passado de build para release | D-GHS-16 |
| `release-based-workflow` (< 1 h): release beta, branch de release, notas, hotfix | Versões do APK e do backend | D-GHS-12, 13 |
| `secure-repository-supply-chain` (< 1 h): grafo de dependências, alertas, security updates, version updates | `pubspec.lock`, Gradle do Android, actions | D-GHS-09 |
| `introduction-to-secret-scanning` (< 15 min): habilitar Secret Protection e push protection | Chave da DeepSeek, chave de cifra dos JSON, keystore Android, token da Vercel | D-GHS-08 (o recurso em si não está disponível, ver tabela abaixo) |
| `introduction-to-codeql` (< 30 min): habilitar code scanning | Análise estática | D-GHS-14 (não cobre Dart) |
| `change-commit-history` (< 1 h): remover conteúdo do histórico com BFG, `.gitignore` | Procedimento de segredo vazado | Ver `pro-git.md` D-GIT-19 (usa-se `git-filter-repo`, não BFG) |
| `introduction-to-repository-management` (< 1 h): rulesets, CODEOWNERS, templates, política de segurança | Arquivos de saúde do repositório | D-GHS-04, 18 |

### Plano Free em repositório privado de conta pessoal (conferido em docs.github.com)

| Recurso | Privado no Free? | Evidência lida | Alternativa gratuita |
|---|---|---|---|
| Protected branches | **Não** | "Protected branches are available in public repositories with GitHub Free [...] and in public and private repositories with GitHub Pro, Team, Enterprise" | D-GHS-03 |
| Rulesets | **Não** (push rulesets: só Team) | Mesmo texto de disponibilidade; página de planos lista o que falta no privado | D-GHS-03, 04 |
| Revisores obrigatórios, CODEOWNERS, draft PR | **Não** | Página de planos e tabela de preços ("Public repositories") | Checklist no template de PR |
| Environments, segredos por ambiente, aprovação de deploy | **Não** | "Organizations with GitHub Team and users with GitHub Pro can configure environments for private repositories" | D-GHS-11 |
| Secret scanning (alertas) | **Não** | Tipos suportados: público; privado só de organização com Secret Protection (Team/Enterprise) | D-GHS-08 |
| Push protection | **Não** | A de repositório exige Secret Protection; a "for users" vem ligada por padrão, mas só barra push para repositório **público** | D-GHS-08 |
| Code scanning / CodeQL, dependency review | **Não** | "Free for public repositories only" | D-GHS-14 |
| GitHub Code Quality (`ship-with-quality`) | **Não** | README: "not available on personal accounts" | Verificador próprio no CI |
| Pages, wikis, gráficos de insights | **Não** | Página de planos | Web vai para a Vercel; docs ficam em `docs/` |
| Dependabot alerts, security updates e version updates | **Sim** | "Available for all plans"; ecossistema `pub` com version e security updates, repositório privado suportado | D-GHS-09 |
| Grafo de dependências, SBOM, security policy, artifact attestations | **Sim** | Lista "available for all plans"; `pub` lê `pubspec.lock` (recomendado) e `pubspec.yaml` | D-GHS-09 |
| Actions | **Sim**: 2.000 min/mês, 500 MB de artefatos (compartilhados com Packages), 10 GB de cache por repositório | Página de billing; sem forma de pagamento, o uso é **bloqueado** ao esgotar a cota | D-GHS-06 |
| Runner Linux arm64 padrão | **Sim**: `ubuntu-24.04-arm`, `ubuntu-22.04-arm` (2 vCPU, 8 GB), debita a cota gratuita, US$ 0,005/min | Changelog 2026-01-29 e tabela de runners para repositório privado | D-GHS-07 |
| Releases | **Sim**: até 1.000 arquivos por release, cada um < 2 GiB, sem limite de tamanho total nem de banda | "About releases" | D-GHS-12 |

## Decisões

| ID | Decisão | Vira requisito em | Como se verifica |
|---|---|---|---|
| D-GHS-01 | Toda mudança entra em `main` por PR a partir de topic branch, mesmo com um único desenvolvedor. Revisão = autorrevisão no diff do PR com checklist do template marcado e CI verde. Não existe aprovação obrigatória no plano atual; o registro do PR é a evidência | Fase 2 RNF de processo; Fase 6 `.github/pull_request_template.md` | Job `main-guard` (D-GHS-03) confirma que todo commit de topo em `main` é merge de PR |
| D-GHS-02 | Método de merge: **merge commit**, com o título do PR em Conventional Commits (o merge da Fase 0 já saiu com título nesse padrão). "Rebase and merge" fica desabilitado: o GitHub recria os commits com SHA novo e **sem assinatura**. Squash só por exceção registrada no PR, porque apaga os commits atômicos de `main` | Fase 4 ADR de fluxo Git | Settings > General > Pull Requests mostra só os métodos permitidos; `git log --first-parent main` lista um commit por PR |
| D-GHS-03 | Controles compensatórios enquanto não há regra de branch: (a) hook `pre-push` recusa push direto, deleção e force em `main`; (b) job `main-guard` em `push` para `main` falha se o commit de topo não for merge de PR; (c) merge só depois do check único `ci-ok` verde. A lacuna entra no threat model como risco aceito | Fase 4 ADR; Fase 5 `threat-model.md`; Fase 6 `tool/hooks/` e workflow | Teste do hook em repositório temporário; PR de teste com commit direto simulado deixa `main-guard` vermelho |
| D-GHS-04 | No dia em que o repositório abrir: criar ruleset para `main` (exigir PR, exigir o status check `ci-ok`, bloquear force push, restringir deleção, exigir commits assinados) e ruleset para tags `v*` (restringir update e deleção). **Não** ligar "require linear history": é incompatível com merge commit | Fase 7 `runbook.md`, checklist "abertura do repositório" | Push direto de teste é rejeitado pelo servidor; ruleset aparece como Active |
| D-GHS-05 | `ci.yml` roda em `pull_request` e em `push` para `main`, sempre em `ubuntu-latest`: formatação, `dart analyze` (backend e pacotes puros), `flutter analyze` (app), testes com cobertura e piso mínimo, verificador de tamanho de arquivo e de função, gitleaks, validação de Conventional Commits em todos os commits do PR e recusa de `fixup!`/`squash!`/`amend!`/`wip` | Fase 2 RNF de qualidade; Fase 4 ADR de CI; Fase 6 workflow | Um PR de fixture por regra violada precisa falhar no job correspondente |
| D-GHS-06 | Orçamento de minutos: teto de 2.000/mês, meta de uso até 60%. Medidas: cancelar execução anterior do mesmo PR, pular build quando o PR só toca `docs/`, cache de dependências, nenhum runner Windows ou macOS (US$ 0,010 e US$ 0,062 por minuto contra US$ 0,006 do Linux x64), build Android, build web e job arm64 só em `main` e em tag. **Nunca cadastrar forma de pagamento**: com a cota esgotada o uso é bloqueado, que é a falha segura para custo R$ 0 | Fase 2 RNF de custo; Fase 7 runbook (conferência mensal) | Painel de billing do Actions abaixo de 1.200 min no fechamento do mês |
| D-GHS-07 | Binário do backend compilado em `ubuntu-24.04-arm` (runner padrão). Sem QEMU e **sem self-hosted runner na VM da Oracle**: a documentação de hardening alerta que runner próprio pode ser comprometido por quem consegue disparar workflow, e a VM é produção | Fase 4 ADR de build e deploy; Fase 7 `deploy.sh` consome o artefato | `file` no binário acusa aarch64; teste de fumaça roda no próprio runner arm |
| D-GHS-08 | Varredura de segredos por conta própria, em três camadas: gitleaks no hook `pre-commit` (conteúdo staged), gitleaks no CI com histórico completo (`fetch-depth: 0`), e execução agendada semanal. Usar o **binário** (licença MIT) com versão fixada e checksum conferido; a `gitleaks-action` tem licença própria desde a v2 (sem chave para conta pessoal, com chave para organização). `.gitleaks.toml` versionado; exceção só por `.gitleaksignore` revisado em PR | Fase 5 `threat-model.md` e `asvs-checklist.md`; Fase 6 hooks e workflow | Commit de teste com credencial falsa é barrado no hook e no CI |
| D-GHS-09 | `.github/dependabot.yml` com `pub` (raiz do workspace e cada pacote, se necessário), `github-actions` e `gradle`, frequência semanal e PRs agrupados. Alertas e security updates ligados. `pubspec.lock` versionado em todos os pacotes (é o manifesto recomendado para o grafo). PR do Dependabot passa pelo mesmo CI | Fase 4 ADR de cadeia de suprimentos; Fase 5 checklist; Fase 6 | Aba Security mostra Dependabot ativo; primeiro PR semanal aparece e roda o CI |
| D-GHS-10 | Hardening dos workflows: action de terceiro fixada por **SHA completo** com a versão em comentário; `permissions: contents: read` no topo e elevação por job; nada de `pull_request_target`; valor não confiável (título de PR, nome de branch) só entra em `run:` via variável de ambiente | Fase 5 threat model (pipeline); Fase 6 | Job de lint dos workflows falha se algum `uses:` não terminar em SHA de 40 caracteres |
| D-GHS-11 | Sem environments, segredo de repositório fica visível para qualquer workflow. Por isso: nenhum segredo em workflow disparado por PR; o deploy do backend **não guarda chave SSH no GitHub** (o `deploy.sh` roda da máquina do desenvolvedor, baixa o asset da release e confere o SHA-256); o único segredo previsto no Actions é o token da Vercel, com o menor escopo possível e rotação no runbook | Fase 5 threat model; Fase 7 `deploy.sh` e runbook | Revisão do bloco `on:` de todo workflow que referencia `secrets.`; lista de segredos do repositório tem um item |
| D-GHS-12 | Release = tag anotada e assinada `vMAJOR.MINOR.PATCH` em `main` que dispara `release.yml`: binário arm64 com SHA-256, APK e pacote web anexados à GitHub Release. Sem branch de release e sem beta (o curso ensina, é excesso para um alvo de deploy). Hotfix = topic branch a partir de `main` e nova tag PATCH | Fase 4 ADR de versionamento; Fase 7 runbook | `git tag -v` passa; a release tem os três assets e os checksums |
| D-GHS-13 | As notas automáticas de release se baseiam em **PRs e labels**, não em mensagens de commit. Cada PR recebe um label de tipo (`feat`, `fix`, `docs`, `security`, `chore`) e `.github/release.yml` define as categorias | Fase 6 (`release.yml` de notas, labels); Fase 7 runbook | Job `pr-meta` falha com título fora do padrão ou sem label de tipo |
| D-GHS-14 | CodeQL fica fora: é pago em repositório privado e **não analisa Dart** (linguagens: C/C++, C#, Go, Java/Kotlin, JavaScript/TypeScript, Python, Ruby, Rust, Swift e workflows do Actions). A análise estática do projeto é o analisador do Dart em modo estrito, lints e os verificadores próprios. Com o repositório público, ligar CodeQL só para `actions` | Fase 4 ADR de análise estática; Fase 5 `asvs-checklist.md` registra a limitação | `analysis_options.yaml` versionado; CI falha com aviso do analisador |
| D-GHS-15 | Conflito se resolve localmente, com rebase da topic branch sobre `origin/main`. O editor web do GitHub só para conflito trivial em Markdown: ele resolve apenas linhas concorrentes simples e "merges the entire base branch into the head branch", sujando a topic branch com um merge de `main` | Fase 4 guia de contribuição | CI recusa PR com commit de merge vindo de `main` |
| D-GHS-16 | Artefato de CI (relatório de cobertura) com retenção curta, porque os 500 MB são divididos com Packages. O que precisa durar vai como asset de release | Fase 6 workflows | Painel de armazenamento do Actions perto de zero entre execuções |
| D-GHS-17 | Os cursos escolhidos são feitos em repositórios **públicos** e descartáveis da conta pessoal: os READMEs avisam que cópia privada consome minutos. Ordem: `review-pull-requests`, `resolve-merge-conflicts`, `hello-github-actions`, `test-with-actions`, `reusable-workflows`, `workflow-artifacts`, `secure-repository-supply-chain`, `introduction-to-secret-scanning`, `release-based-workflow`, `change-commit-history`, `introduction-to-repository-management` | Não vira requisito; é preparação para a Fase 6 | Exercícios concluídos (último passo fechado pelo bot do curso) |
| D-GHS-18 | Arquivos de saúde do repositório: template de PR, `SECURITY.md`, `.gitignore`, `.gitattributes`. CODEOWNERS não entra: indisponível no plano e sem efeito com um único dono | Fase 6 | Arquivos presentes; template aparece ao abrir PR |
| D-GHS-19 | Um workflow reutilizável (`workflow_call`) com os passos de checagem Dart, chamado uma vez por pacote do workspace, em vez de copiar passos | Fase 4 ADR de CI; Fase 6 | Nenhum bloco de passos duplicado entre workflows |
| D-GHS-20 | Job final `ci-ok` que depende de todos os outros. Hoje é o único check que o script de merge consulta; amanhã é o único status check exigido pelo ruleset | Fase 6 | `ci-ok` só fica verde com todos os jobs verdes |

## O que não se aplica, e por que

- **Os 15 cursos sobre ferramentas de IA generativa da plataforma.** Não tratam de fluxo Git/GitHub e nenhuma decisão do Cajui depende deles. São 15 de 40 cursos: a fonte hoje é bem mais estreita para este projeto do que o nome sugere.
- `deploy-to-azure`, `migrate-ado-repository`: o projeto não usa Azure nem Azure DevOps.
- `github-pages`: Pages não existe em repositório privado no Free; a web vai para a Vercel.
- `publish-docker-images`: o backend roda como binário sob systemd, sem contêiner.
- `write-javascript-actions`: os verificadores próprios são scripts Dart ou shell chamados em `run:`; não há motivo para manter uma action em JavaScript.
- `configure-codeql-language-matrix`, `introduction-to-codeql`: CodeQL não suporta Dart (D-GHS-14).
- `ship-with-quality`: GitHub Code Quality só existe para organizações.
- `code-with-codespaces`: desenvolvimento local no Windows com toolchain Android; Codespaces não ajuda.
- `introduction-to-git`, `introduction-to-github`, `communicate-using-markdown`, `connect-the-dots`, `secure-code-game`: conteúdo básico ou treino genérico; opcionais.
- Observação sobre Flutter Web em canvas: **não se aplica a esta fonte**. Nada aqui toca renderização, HTML ou ARIA. O único contato com a web é o custo em minutos do build `--wasm` e de uma eventual auditoria Lighthouse no CI.

## Pontos de atenção

1. **O plano pressupõe controles que o plano gratuito não entrega em repositório privado.** "Merge por PR com CI obrigatório" é disciplina mais hooks locais, não imposição do servidor. GitHub Pro resolveria (branch protegida, rulesets, environments), mas fere o custo fixo R$ 0. `owasp-top-10.md` (D-TOP10-03) fala em "branch `main` protegida com checks obrigatórios" e "segredos do Actions por ambiente": as duas coisas só passam a valer com o repositório público e precisam ser reescritas como controle compensatório até lá.
2. **Zero proteção nativa contra segredo em repositório privado pessoal.** Nem alerta, nem push protection (a de usuário só cobre push para repositório público). O dia de abrir o repositório é o dia em que o histórico inteiro vaza junto: varredura de histórico completo com gitleaks e rotação de qualquer credencial duvidosa são pré-requisito da abertura.
3. **CodeQL não agrega nada ao código Dart**, privado ou público. Manter "CodeQL" no plano como se cobrisse o app é prometer o que a ferramenta não faz.
4. **Conventional Commits não alimentam as notas automáticas de release**; elas usam PRs e labels. Sem D-GHS-13 as notas saem como lista plana.
5. **Assinatura x método de merge.** "Rebase and merge" produz commits não assinados em `main`; squash destrói os commits atômicos; "require linear history" proíbe merge commit. Só merge commit preserva SHA, assinatura e atomicidade ao mesmo tempo.
6. **Fixar action por SHA reduz alertas**: a documentação diz que alertas do Dependabot para actions só saem para referência em versão semântica, não em SHA. Aceita-se a perda em troca da imutabilidade; a atualização fica por conta dos version updates (comportamento com SHA ainda a validar).
7. **Minutos**: build Android, build web em wasm, job arm64 e Lighthouse em todo PR estouram 2.000 min com folga. Daí a separação PR leve / `main` pesado de D-GHS-06. A cota é da **conta**, não do repositório: exercícios do Skills feitos em cópia privada comem o mesmo saldo.
8. **`pub` é ecossistema mantido pela comunidade** no Dependabot e o grafo não resolve dependências transitivas estáticas para ele. Comportamento com pub workspaces (um `pubspec.lock` na raiz) precisa de teste cedo; se falhar, a varredura OSV no CI vira o controle principal.
9. **O curso `change-commit-history` ensina BFG**, enquanto a documentação do GitHub e o Pro Git recomendam `git-filter-repo`. Vale o segundo.
10. O catálogo em `learn.github.com/skills` é renderizado no cliente e não pôde ser lido; a lista acima saiu da listagem de repositórios da organização, que é a fonte primária dos cursos.

## Páginas lidas

- https://skills.github.com/ — só o aviso de redirecionamento para learn.github.com/skills.
- https://github.com/skills — perfil da organização, 52 repositórios, cursos fixados.
- https://github.com/orgs/skills/repositories?type=all (páginas 1 e 2) — lista completa com descrição, tipo (template, arquivado) e data.
- https://github.com/skills/.github/blob/main/profile/README.md — aponta o catálogo para learn.github.com.
- READMEs lidos: `review-pull-requests`, `resolve-merge-conflicts`, `test-with-actions`, `release-based-workflow`, `secure-repository-supply-chain`, `introduction-to-secret-scanning`, `introduction-to-codeql`, `change-commit-history`, `introduction-to-repository-management`, `ship-with-quality`, `hello-github-actions`, `reusable-workflows`, `workflow-artifacts`, `introduction-to-git` — passos, duração, pré-requisitos e o aviso de que cópia privada consome minutos.
- https://docs.github.com/en/get-started/learning-about-github/githubs-plans — o que o Free inclui e o que falta em repositório privado.
- https://github.com/pricing — tabela comparativa ("Public repositories" nas linhas de regras, revisores, secret scanning, code scanning).
- https://docs.github.com/en/billing/concepts/product-billing/github-actions — 2.000 min, 500 MB, 10 GB de cache, preço por minuto por runner, bloqueio ao esgotar a cota.
- https://docs.github.com/en/actions/reference/runners/github-hosted-runners — tabelas de runners para repositório público e privado, incluindo arm64.
- https://github.blog/changelog/2026-01-29-arm64-standard-runners-are-now-available-in-private-repositories/ — arm64 padrão em privado, debitando a cota.
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches e `.../managing-a-branch-protection-rule` — lista de proteções.
- https://raw.githubusercontent.com/github/docs/main/data/reusables/gated-features/protected-branches.md e `.../repo-rules.md` e `.../secret-scanning.md` — texto exato de disponibilidade por plano.
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets, `.../creating-rulesets-for-a-repository`, `.../available-rules-for-rulesets` — regras disponíveis e push rulesets.
- https://docs.github.com/en/code-security/getting-started/github-security-features — o que é de todos os planos e o que é gratuito só em público.
- https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning e `.../about-push-protection` e `.../push-protection-for-users` — cobertura por tipo de repositório.
- https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories — `pub`, `github-actions`, `gradle`, `docker`.
- https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/dependency-graph-supported-package-ecosystems — `pub` via `pubspec.lock`; alerta de actions só com versão semântica.
- https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning-with-codeql — linguagens suportadas.
- https://docs.github.com/en/actions/reference/security/secure-use — hardening de workflows e riscos de self-hosted runner.
- https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments — environments em privado exigem Pro ou Team.
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/about-merge-methods-on-github — merge, squash e rebase.
- https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/resolving-a-merge-conflict-on-github — o editor web mescla a base inteira na head e só resolve conflito simples de linha.
- https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification — rebase and merge não é assinado.
- https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases e `.../automatically-generated-release-notes` — limites de assets; notas por PR e label.
- https://github.com/gitleaks/gitleaks e https://github.com/gitleaks/gitleaks-action — comandos, hook, licenças.

## Não verificado

- Catálogo em https://learn.github.com/skills: a página só entrega o cabeçalho sem JavaScript. Categorias oficiais e eventuais cursos hospedados fora da organização `skills` não foram conferidos.
- READMEs não abertos: os 15 cursos de IA generativa, `connect-the-dots`, `github-pages`, `code-with-codespaces`, `publish-docker-images`, `write-javascript-actions`, `deploy-to-azure`, `migrate-ado-repository`, `configure-codeql-language-matrix`, `secure-code-game`, `communicate-using-markdown`, `introduction-to-github` (só nome e descrição da listagem).
- Como a cota de 2.000 minutos é debitada por sistema operacional: a página de billing lida traz preço por minuto, não o multiplicador aplicado à cota.
- Sintaxe de `concurrency`, filtro `paths`, `retention-days`, prefixo de mensagem de commit do Dependabot e atualização de action fixada por SHA: citados como medida, não relidos hoje. Conferir na Fase 6.
- Dependabot com pub workspaces e tempo real de CI de um projeto Flutter neste plano: só medindo.
- Se assets de release contam em alguma cota de armazenamento: "About releases" não fala de cobrança.
- Deploy na Vercel a partir do Actions (token, escopo) pertence à pesquisa de hospedagem; aqui só se decidiu onde o segredo não deve ficar.
