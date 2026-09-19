# OWASP Top 10

| Campo | Valor |
|---|---|
| Fonte | https://owasp.org/www-project-top-ten/ (documentação da edição em https://top10.owasp.org/2025/) |
| Edição lida | **OWASP Top 10:2025**, 8ª edição, status **final** ("We have released the OWASP Top 10:2025 (Final)", README do repositório OWASP/Top10). A página do projeto diz: "The most current released version is the OWASP Top 10 2025". Dia exato de publicação não aparece nas páginas lidas |
| Acesso | 2026-09-19 |

## Por que esta fonte importa para o Cajui

- É a lista de risco que todo revisor de portfólio conhece; o threat model da Fase 5 precisa citar a edição **2025**, não a 2021 (a numeração mudou: quem escrever "A03 Injection" está errado, agora é A05).
- A edição 2025 trouxe duas categorias que batem direto no plano: **A03 Software Supply Chain Failures** (pub.dev, GitHub Actions, build na Vercel) e **A10 Mishandling of Exceptional Conditions** (persistência em arquivo com escrita atômica, fallback quando a DeepSeek cai).
- SSRF foi absorvido por A01 e a página de A05 empurra prompt injection para fora do Top 10 web, apontando para o LLM Top 10. Ou seja: o Top 10 sozinho **não cobre** o OCR-para-IA nem o app Android. Por isso a seção "Fontes complementares".
- O Top 10 é documento de conscientização, não checklist verificável. O checklist do Cajui é o ASVS (ver `owasp-asvs.md`); aqui saem as decisões de desenho por categoria.

## O que se aplica

Superfícies: **API** (Shelf atrás do Caddy), **Android**, **Web** (build estático na Vercel), **IA** (DeepSeek), **Dados** (JSON no servidor), **Infra** (SSH, Caddy, systemd, CI).

| Item da fonte | Onde toca o Cajui | Decisão |
|---|---|---|
| **A01 Broken Access Control** — negar por padrão, mecanismo único de controle, minimizar CORS, rate limit, invalidar sessão no servidor, testar controle de acesso. Inclui SSRF (CWE-918) e CSRF (CWE-352) | API: toda rota. Web: origem diferente da API, logo CORS é obrigatório. IA: backend faz chamada de saída | D-TOP10-01 |
| **A02 Security Misconfiguration** — hardening repetível e automatizado, instalação mínima, cabeçalhos de segurança, erro sem stack trace, verificação automática da configuração, credenciais de vida curta em vez de chave estática. CWE-526 (informação sensível em variável de ambiente) está mapeado aqui | Infra: Caddy, systemd, firewall, SSH. Web: cabeçalhos na Vercel. API: mensagens de erro | D-TOP10-02 |
| **A03 Software Supply Chain Failures** — SBOM, dependências transitivas, monitorar CVE/OSV, fontes oficiais, versões fixadas, CI/CD endurecido (MFA, branch protegida, segredos por ambiente, builds assinados) | Pacotes pub (app e backend), GitHub Actions, build na Vercel, ML Kit, binário do Caddy, pacotes do SO | D-TOP10-03 |
| **A04 Cryptographic Failures** — TLS >= 1.2 com forward secrecy, HSTS, criptografia **autenticada**, IV nunca reutilizado, CSPRNG, chave fora do código, validar certificado, sem cache de resposta sensível, KDF adaptativa para senha | Dados: criptografia em repouso dos JSON e do backup. API: TLS no Caddy. IA: cliente HTTPS da DeepSeek. Android: token no secure storage | D-TOP10-04 |
| **A05 Injection** — separar dado de comando, API segura sem interpretador, validação positiva no servidor. A página remete prompt injection ao LLM01:2025 | API: sem SQL, mas há caminho de arquivo, log, JSON e regex. IA: texto de OCR vira prompt. Web: `index.html` de shell | D-TOP10-05 |
| **A06 Insecure Design** — threat modeling, casos de abuso em teste, checagem de plausibilidade em todas as camadas, limites de negócio | Domínio: vale alimentação só abate alimentação; cartão não é despesa; orçamento de tokens | D-TOP10-06 |
| **A07 Authentication Failures** — MFA, sem credencial padrão, atraso progressivo em falha, mesma mensagem para toda falha, ID de sessão de alta entropia, nunca na URL, invalidar em logout/ociosidade/tempo absoluto, validar `aud`/`iss` se JWT | Android: biometria + token curto. Web: **caminho de login não definido no plano**. API: endpoint de pareamento de dispositivo | D-TOP10-07 |
| **A08 Software or Data Integrity Failures** — assinatura/verificação de integridade, repositórios confiáveis, revisão de mudança, não aceitar dado serializado sem verificação | Dados: log de eventos, snapshots, índice, backup. Android: APK assinado. Web: recursos carregados de terceiros | D-TOP10-08 |
| **A09 Security Logging and Alerting Failures** — logar login, falha de acesso e falha de validação; não logar PII (CWE-532); codificar contra log injection (CWE-117); trilha append-only; "log só local, sem backup" é listado como falha; alerta com limiar | API: logs do Shelf e do Caddy. Infra: journald. Regra do plano "logs sem dado financeiro" | D-TOP10-09 |
| **A10 Mishandling of Exceptional Conditions** — tratar erro onde ocorre, **fail closed** com rollback completo, limites em tudo ("nothing should be limitless"), handler global, tratamento centralizado, não vazar detalhe (CWE-209), não falhar aberto (CWE-636) | Dados: gravação em 3 artefatos (log, índice, snapshot). IA: timeout e fallback por regras. API: catálogo de erros | D-TOP10-10 |

## Decisões

| ID | Decisão | Vira requisito em | Como se verifica |
|---|---|---|---|
| D-TOP10-01 | API nega por padrão: um único middleware de autenticação/autorização na raiz do pipeline Shelf; rota pública só por lista explícita (saúde e pareamento). CORS com **uma origem fixa** (`https://cajui-app.vercel.app`), sem curinga e sem `*.vercel.app` (URLs de preview não entram). Sessão web é **somente leitura no servidor**, não por esconder botão. Backend só chama host de saída configurado (DeepSeek); nunca URL vinda de entrada (SSRF) | Fase 2 RNF; Fase 4 ADR de API; Fase 5 threat model | Teste de integração que percorre a tabela de rotas e exige 401 sem token e 403 em escrita com sessão web; teste de CORS com origem estranha |
| D-TOP10-02 | Hardening reproduzível: `scripts/deploy.sh` idempotente aplica firewall, unit systemd endurecida (usuário dedicado, sem privilégios novos, FS somente leitura fora do diretório de dados), Caddyfile versionado. Cabeçalhos de segurança em dois lugares: Caddy (API) e `vercel.json` (web). Erro nunca devolve stack trace. Segredo não fica em unit file legível nem em repositório; arquivo de ambiente 0600 do usuário do serviço é o piso (ver atenção 2) | Fase 4 ADR de deploy; Fase 7 `deploy.sh` e runbook | Script de verificação pós-deploy: portas abertas = 80/443/22, cabeçalhos presentes, `ssh` sem senha, resposta 500 sem detalhe interno. Roda no CI contra staging ou manual pelo runbook |
| D-TOP10-03 | `pubspec.lock` versionado em todos os pacotes do workspace; atualização de dependência só por PR; varredura de vulnerabilidade (base OSV) e SBOM CycloneDX gerados no CI; actions de terceiros fixadas por SHA; conta GitHub com MFA, branch `main` protegida com checks obrigatórios; segredos do Actions por ambiente; atualização automática de segurança do SO na VM | Fase 4 ADR de CI/CD; Fase 5 checklist; Fase 6 workflow | Job de CI falha com vulnerabilidade conhecida acima do limiar definido; artefato SBOM anexado ao build; revisão das regras de branch no runbook |
| D-TOP10-04 | Criptografia em repouso com **AEAD** (AES-256-GCM ou ChaCha20-Poly1305), nonce único por operação de cifra, cabeçalho de arquivo com versão de algoritmo e ID de chave. Chave fora do diretório de dados e **fora do backup dos dados**. Aleatoriedade só de CSPRNG. Cliente HTTP da DeepSeek valida certificado, sem callback de exceção. HSTS na API. Respostas da API com `Cache-Control: no-store` | Fase 2 RNF; Fase 4 ADR de persistência e de criptografia | Teste unitário: alterar 1 byte do arquivo cifrado tem de falhar na leitura; teste que dois writes geram nonces diferentes; varredura externa de TLS; grep de CI proibindo `Random()` em código de segurança |
| D-TOP10-05 | Nenhuma chamada de shell com dado de entrada. Caminho de arquivo construído só a partir de valor interno validado (ex.: `AAAA-MM`), nunca de string do cliente. Validação por schema com lista de permitidos em toda entrada, inclusive texto de OCR (tamanho máximo, normalização Unicode). Regex nunca montada com entrada. `index.html` não interpola dado dinâmico | Fase 2 RN/RNF de validação; Fase 6 | Testes com payloads `../`, CRLF, JSON aninhado gigante, texto de 1 MB; lint proibindo `Process.run` fora de módulo autorizado |
| D-TOP10-06 | Threat model cobre os quatro fluxos críticos: pareamento, compartilhar-OCR-IA-lançamento, gravação em arquivo, consulta web. Cada RN de domínio ganha ao menos um caso de **abuso** em teste (valor negativo, data absurda, VA abatendo categoria não alimentar, cartão contado como despesa) | Fase 2 `docs/spec/`; Fase 5 `threat-model.md` | Revisão do threat model por fluxo; suíte de testes de abuso rastreada por ID de RN |
| D-TOP10-07 | Token de sessão opaco de alta entropia, só em cabeçalho, nunca em URL; expiração por ociosidade e absoluta; revogação no servidor. Endpoint de pareamento e de login com atraso progressivo + rate limit e resposta idêntica para toda falha. **Definir na Fase 4 o caminho de autenticação da web** (hoje inexistente no plano) com força equivalente ao do Android | Fase 2 RNF; Fase 4 ADR de autenticação | Teste de força bruta simulado dispara bloqueio; teste de token expirado e revogado; inspeção de logs e URLs sem token |
| D-TOP10-08 | Log de eventos com verificação de integridade por registro (AEAD já cobre adulteração; adicionar encadeamento por hash do registro anterior para detectar remoção/reordenação). Validação de schema na leitura (já no plano) trata arquivo em disco como não confiável. Backup só vale depois de **teste de restauração**. APK assinado com chave fora do repositório. Web não carrega código de terceiro em runtime (CanvasKit servido do próprio build, a confirmar na pesquisa de Flutter Web) | Fase 4 ADR de persistência; Fase 7 runbook | Teste: remover/reordenar linha do log faz a carga falhar fechado; ensaio de restauração documentado; aba de rede do navegador sem domínio externo além da API |
| D-TOP10-09 | Log estruturado (JSON por linha) com eventos de segurança: autenticação (sucesso e falha), acesso negado, falha de validação, rate limit, estouro de orçamento de tokens, falha de integridade. **Proibido** em log: valor, descrição de lançamento, texto de OCR, prompt, resposta da IA, token. Campos de entrada codificados antes de logar. Logs entram no backup diário fora da VM. Alerta mínimo: contador de falhas acima de limiar gera aviso visível no painel | Fase 2 RNF; Fase 5 threat model; Fase 7 runbook | Teste que injeta valor-sentinela em requisição e falha se aparecer no log; teste de CRLF em campo logado; ensaio de alerta no runbook |
| D-TOP10-10 | Gravação multi-artefato com ordem definida e recuperação na inicialização (log é a verdade; índice e snapshot são reconstruíveis). Erro no meio = nada confirmado ao cliente. Lock liberado em `finally`. Middleware global converte exceção não tratada em erro genérico com código do catálogo. Limites explícitos: tamanho do corpo, tamanho do texto de OCR, tempo da chamada à DeepSeek, tokens por dia. Falha da IA cai no fallback por regras, **sem pular validação** | Fase 3 `error-catalog.md`; Fase 4 ADR de persistência; Fase 6 | Teste de falha injetada entre cada passo da gravação; teste de kill -9 durante escrita seguido de boot; teste de timeout da DeepSeek |
| D-TOP10-11 | IA sem agência: a DeepSeek só **propõe** lançamento estruturado; nada é gravado sem validação de schema + confirmação do usuário. Texto de OCR entra delimitado e rotulado como conteúdo externo. Saída da IA validada por código determinístico contra schema fechado; números que viram indicador são **recalculados** pelo backend, nunca copiados da IA. Prompt de sistema sem segredo | Fase 2 RN de IA; Fase 5 threat model (LLM01, LLM05, LLM06, LLM07, LLM09) | Suíte de notas fiscais adversariais ("ignore as instruções...") tem de resultar em lançamento válido ou rejeição, nunca em ação fora do schema |
| D-TOP10-12 | Orçamento de tokens é controle de segurança (LLM10, "denial of wallet"): limite por requisição, por dia e por mês, aplicado **antes** da chamada; estouro degrada para o fallback por regras | Fase 2 RNF; Fase 6 | Teste que esgota o contador e verifica que nenhuma chamada externa sai |
| D-TOP10-13 | App Android segue o Mobile Top 10 2024 como lista de risco e o MASVS como checklist (ver `owasp-asvs.md`): nenhuma chave de API no APK (M1); alvo de compartilhamento valida MIME, tamanho e origem do conteúdo antes do OCR (M4); arquivo recebido e imagem temporária apagados após extração (M9); `allowBackup` desligado e só a activity de compartilhamento exportada (M8) | Fase 4 ADR mobile; Fase 5 checklist mobile | Inspeção do `AndroidManifest.xml` no CI; busca por segredo no APK; teste manual de compartilhamento com arquivo malformado |

## Fontes complementares

**OWASP Top 10 for LLM Applications 2025** (genai.owasp.org). Itens: LLM01 Prompt Injection, LLM02 Sensitive Information Disclosure, LLM03 Supply Chain, LLM04 Data and Model Poisoning, LLM05 Improper Output Handling, LLM06 Excessive Agency, LLM07 System Prompt Leakage, LLM08 Vector and Embedding Weaknesses, LLM09 Misinformation, LLM10 Unbounded Consumption.

- Aplicam-se: LLM01 (o risco do Cajui é o **indireto**: nota fiscal ou PDF com texto malicioso), LLM02 (redação de PII antes do envio), LLM05, LLM06, LLM07, LLM09, LLM10. Cobertos por D-TOP10-11 e D-TOP10-12.
- A página do LLM01 admite que não se sabe se existe prevenção à prova de falha. Consequência de desenho: assumir que a injeção **vai funcionar** e garantir que o pior resultado seja uma proposta errada que o usuário rejeita.
- Mitigações do LLM01 que viram regra: restringir comportamento no prompt de sistema; formato de saída definido e validado por código; filtro de entrada e saída; privilégio mínimo; aprovação humana para ação de risco; segregar conteúdo externo; teste adversarial.
- LLM05 manda tratar a resposta do modelo como entrada de usuário e seguir o ASVS para validação. Casa com o plano.
- Não se aplicam: LLM04 e LLM08 (sem fine-tuning, sem RAG, sem embeddings). LLM03 só no sentido de a DeepSeek ser fornecedor único; o fallback por regras é a mitigação.

**OWASP Mobile Top 10 2024** (final). Itens: M1 Improper Credential Usage, M2 Inadequate Supply Chain Security, M3 Insecure Authentication/Authorization, M4 Insufficient Input/Output Validation, M5 Insecure Communication, M6 Inadequate Privacy Controls, M7 Insufficient Binary Protections, M8 Security Misconfiguration, M9 Insecure Data Storage, M10 Insufficient Cryptography.

- Mais relevantes: M1, M3 (biometria local não é autenticação perante o servidor, ver `owasp-asvs.md`), M4 (intent de compartilhamento é entrada hostil), M5 (pinning), M8, M9.
- M7 tem prioridade baixa: app de usuário único, fora de loja. Ofuscação do build release é suficiente.

## O que não se aplica, e por que

- **SQL/ORM/LDAP/XPath injection (A05)**: não há banco nem diretório. O equivalente no Cajui é caminho de arquivo e prompt.
- **XSS clássico (A05, CWE-79)**: Flutter Web desenha em canvas e não injeta HTML a partir de dado. O risco residual fica no `index.html` de shell (que é estático) e em qualquer uso futuro de `HtmlElementView` ou link aberto a partir de dado, que deve ser proibido por regra.
- **Senha fraca, credential stuffing, rotação de senha (A07)**: só se aplicam se o caminho de login da web vier a usar senha. Se usar, o bloco inteiro volta a valer.
- **Segregação de tenants (A06) e controle por papel (A01)**: usuário único. Sobra a distinção sessão Android (escrita) x sessão web (leitura).
- **Separação de funções e rollout em estágios (A03)**: desenvolvedor único e uma VM. Compensação: PR obrigatório com CI, deploy com rollback documentado.
- **HSM e preparação pós-quântica (A04)**: incompatíveis com R$ 0 e fora de proporção. Registrar como risco aceito.
- **SOC, playbooks, análise comportamental (A09)** e a página "Establishing a Modern Application Security Program": voltadas a organização. Aproveita-se só a ideia de varredura de segredos, SCA e análise estática no CI.
- **Desserialização de objeto (A08, CWE-502)**: JSON em Dart não instancia tipo arbitrário. O que sobra é validar schema e rejeitar campo desconhecido.

## Pontos de atenção

1. **Numeração mudou.** 2021 para 2025: Misconfiguration subiu de 5 para 2; Crypto caiu de 2 para 4; Injection de 3 para 5; Insecure Design de 4 para 6; SSRF deixou de ser categoria. Qualquer documento do projeto que cite código de categoria precisa do sufixo `:2025`.
2. **Segredo em variável de ambiente é tensão real com a fonte.** A02 mapeia CWE-526 e recomenda credencial de vida curta em vez de chave estática em configuração. A chave da DeepSeek é estática por natureza. O plano ("segredos em variável de ambiente") é o piso aceitável, não o ideal; o ASVS 13.3.1 é ainda mais duro (ver `owasp-asvs.md`). Decidir na Fase 4 e registrar exceção.
3. **A autenticação da web não existe no plano.** Biometria + token atrelado ao dispositivo descreve só o Android. O painel web fica em URL pública da Vercel. Sem caminho definido, A01 e A07 ficam abertos. É o maior buraco encontrado.
4. **"Log só local" e backup na mesma VM são falhas listadas em A09.** O plano fala em backup diário com rotação, mas não diz **para onde**. Backup no mesmo disco não protege contra perda da instância (a Oracle pode recuperar instâncias Always Free ociosas). Precisa de destino externo a custo zero, cifrado no cliente.
5. **Log append-only + criptografia em repouso não combinam de graça.** Não dá para "anexar" a um arquivo cifrado com AEAD como um todo. Ou cada registro é um envelope cifrado próprio (nonce por linha), ou o log é reescrito a cada evento (caro e frágil). Decidir no ADR de persistência antes de codificar.
6. **CORS é inevitável** (web em `vercel.app`, API em outro host) e A01 pede para minimizá-lo. Alternativa a avaliar: rewrite da Vercel para a API, tornando tudo mesma origem, o que também simplifica cookie e CSRF. Custo: tráfego da API passa pela cota do plano Hobby.
7. **CSP estrita pode quebrar o Flutter Web.** Build `--wasm` com CanvasKit/skwasm precisa de permissão de execução de WebAssembly e, por padrão, pode buscar o CanvasKit em CDN externa. Não é assunto do Top 10; registrar para a pesquisa de Flutter Web e testar a CSP cedo.
8. **Certificate pinning + Let's Encrypt.** Fora do escopo da fonte, mas ameaça o plano: se o pin for no certificado folha e a chave for regenerada a cada renovação, o app para de conectar sozinho. Pin em chave pública com chave reutilizada, ou pin na CA, e sempre com pin de reserva. Tratar no ADR mobile.
9. **Alerta para usuário único.** A09 mudou de "Monitoring" para "Alerting" de propósito. Alerta que ninguém recebe não conta. O mínimo viável é aviso dentro do próprio app; e-mail/push gratuito é opcional.
10. **A10 é onde persistência em arquivo mais erra.** O cenário 3 da página (transação interrompida no meio sem rollback) é exatamente a gravação log + índice + snapshot. `temp + rename` garante atomicidade de **um** arquivo, não dos três.

## Páginas lidas

- https://owasp.org/www-project-top-ten/ — confirma 2025 como edição vigente; links para documentação e repositório.
- https://top10.owasp.org/2025 (destino do redirecionamento de owasp.org/Top10/2025/) — lista das 10 categorias com códigos.
- https://top10.owasp.org/2025/0x00_2025-Introduction/ — mudanças em relação a 2021, metodologia (589 CWEs, cerca de 175 mil CVEs, 8 categorias por dados + 2 por pesquisa com a comunidade).
- https://github.com/OWASP/Top10 — status "Final" da edição 2025.
- https://top10.owasp.org/2025/A01_2025-Broken_Access_Control/ — prevenção; SSRF e CSRF no mapeamento.
- https://top10.owasp.org/2025/A02_2025-Security_Misconfiguration/ — prevenção; CWE-526 e CWE-489.
- https://top10.owasp.org/2025/A03_2025-Software_Supply_Chain_Failures/ — SBOM, endurecimento de CI/CD, incidentes citados.
- https://top10.owasp.org/2025/A04_2025-Cryptographic_Failures/ — TLS, HSTS, AEAD, IV, KDF, PQC.
- https://top10.owasp.org/2025/A05_2025-Injection/ — prevenção; remissão ao LLM01:2025.
- https://top10.owasp.org/2025/A06_2025-Insecure_Design/ — threat modeling, plausibilidade, casos de abuso.
- https://top10.owasp.org/2025/A07_2025-Authentication_Failures/ — MFA, atraso progressivo, sessão, claims de JWT.
- https://top10.owasp.org/2025/A08_2025-Software_or_Data_Integrity_Failures/ — diferença para A03; assinatura e desserialização.
- https://top10.owasp.org/2025/A09_2025-Security_Logging_and_Alerting_Failures/ — o que logar, CWE-117, CWE-532, log só local como falha.
- https://top10.owasp.org/2025/A10_2025-Mishandling_of_Exceptional_Conditions/ — fail closed, limites, handler global, cenários.
- https://top10.owasp.org/2025/0x03_2025-Establishing_a_Modern_Application_Security_Program/ — programa de AppSec organizacional (quase todo não aplicável).
- https://genai.owasp.org/llm-top-10/ — lista LLM01 a LLM10, edição 2025.
- https://genai.owasp.org/llmrisk/llm01-prompt-injection/ — direta x indireta; 7 mitigações; ausência de prevenção garantida.
- https://genai.owasp.org/llmrisk/llm052025-improper-output-handling/ — saída do modelo como entrada não confiável; remissão ao ASVS.
- https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/ — "denial of wallet", limites e quotas.
- https://owasp.org/www-project-mobile-top-10/ — confirma edição 2024 final (a lista não veio no corpo da página).
- https://raw.githubusercontent.com/OWASP/www-project-mobile-top-10/master/index.md — lista M1 a M10 de 2024.

## Não verificado

- Data exata (dia/mês) da publicação final do Top 10:2025: não consta nas páginas lidas.
- Páginas individuais dos riscos do Mobile Top 10 (`/2023-risks/...`): os endereços tentados devolveram 404. Só a lista de nomes foi lida; o conteúdo de prevenção de cada M não foi.
- Páginas individuais de LLM02, LLM06, LLM07 e LLM09: só a descrição curta da página de entrada foi lida.
- As páginas foram lidas por extração de conteúdo; trechos entre aspas são os devolvidos pela extração e devem ser conferidos no original antes de citação formal no threat model.
- Afirmações sobre Flutter Web (origem do CanvasKit, CSP), Vercel (rewrites, previews, cota), Oracle (recuperação de instância ociosa) e renovação de chave pelo Caddy vêm de conhecimento prévio, não desta fonte; pertencem às pesquisas específicas dessas tecnologias.
