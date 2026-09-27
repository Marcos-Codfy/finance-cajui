# Modelo de ameaças

O que pode dar errado com o Cajui, quem faria isso, e o que impede. Método: **STRIDE** sobre as três fronteiras de confiança de [c4.md](../architecture/c4.md). Cada ameaça aponta para o controle que a contém — uma ADR, um requisito `RNF-SEC` — e para **o passo da implementação em que o controle nasce**, para que segurança não vire um documento escrito no fim.

Este modelo é revisto sempre que uma ADR muda e antes de cada deploy.

## O que se protege

| Ativo | Por que importa | Onde vive |
|---|---|---|
| Os lançamentos, a renda e as dívidas | É a vida financeira de uma pessoa. Vazar expõe; adulterar engana | Registro de eventos na VM; cópia parcial no aparelho |
| A chave de API da DeepSeek | Quem a tem gasta o crédito do dono | Credencial do systemd, só na VM |
| A chave do aparelho | É a credencial de acesso | Android Keystore, em hardware |
| A chave de dados e a chave do backup | Abrem o registro e os backups | Credencial do systemd · fora do servidor |
| Os comprovantes | Têm CPF, conta, chave Pix | Só no aparelho; a imagem nunca sai |
| A integridade da história | Um número errado no painel é pior que nenhum | Cadeia de hash do registro |

## Quem ataca

| Ator | Capacidade | Interesse |
|---|---|---|
| Varredura automática da internet | Testa toda porta aberta e toda senha fraca, o dia inteiro | Máquina para abusar, não o Cajui em si |
| Quem acha ou rouba o celular | O aparelho na mão, talvez desbloqueado | Os dados; o acesso |
| Quem escreve um comprovante | Controla o **texto** que o app vai ler e mandar para a IA | Manipular a classificação; vazar o prompt; gastar tokens |
| App malicioso no mesmo Android | Pode mandar intenções de compartilhamento e ler o que for público | Injetar arquivos; ler dados mal guardados |
| Rede hostil (Wi-Fi público, proxy) | Intercepta e altera tráfego | Ler ou trocar o que passa |
| Terceiros de infraestrutura | Oracle, Vercel, DeepSeek, DNS dinâmico: veem o que passa por eles | Em geral nenhum — mas podem ser comprometidos |
| O próprio dono, por engano | Acesso total | Nenhum: commit de segredo, porta aberta, backup perdido |

Fora do alcance, por decisão: adversário com recursos de Estado, e ataque físico ao datacenter.

## Fronteira 1 — Aparelho ↔ internet

| # | STRIDE | Ameaça | Controle | Onde | Nasce em |
|---|---|---|---|---|---|
| T-01 | Spoofing | Servidor falso, com certificado emitido por autoridade instalada no aparelho | **Ainda não implementado** (BL-047). Hoje vale o TLS com as raízes do sistema; a fixação decidida na ADR-009 não existe no código | ADR-009 · RNF-SEC-07 | **em aberto** |
| T-02 | Spoofing | App adulterado diz ao servidor que "a biometria passou" | A biometria **destrava uma chave em hardware** que assina um desafio; booleano não vale nada | ADR-008 · RNF-SEC-03 | F6-11 |
| T-03 | Spoofing | Alguém cadastra o próprio aparelho na conta | Código de 10 caracteres, uso único, 10 minutos: o **primeiro** aparelho o recebe de `server enroll`, dentro da VM; do segundo em diante o convite sai do celular já cadastrado (`POST /v1/devices/codes`) | ADR-008 · RNF-SEC-05 | F6-11a |
| T-04 | Tampering | Requisição alterada ou repetida em trânsito | TLS 1.2+ com HSTS; comando com chave de idempotência; desafio de uso único | ADR-012 · RNF-SEC-02 | F6-03 |
| T-05 | Tampering | O app manda um comando que viola regra (valor negativo, vale em categoria não elegível) | O servidor **valida de novo com o mesmo domínio**: nunca confia no cliente. Com dois aparelhos (ADR-019) passou a confiar no **carimbo de edição** do app para o desempate — e por isso recusa carimbo além de 10 min à frente do próprio relógio (T-40) | ADR-001 · RNF-SEC-09 | F6-03 |
| T-06 | Repudiation | "Eu não lancei isso" | Registro só de acréscimo, encadeado por hash; correção é evento novo | ADR-004 | F6-02 |
| T-07 | Information disclosure | Celular perdido, com o app aberto por último | **Parcial.** Feito: `FLAG_SECURE` esconde a tela do seletor de apps e impede captura; o registro local é cifrado. Falta: a chave desse registro ainda é arquivo ao lado dos dados, e não do Keystore (BL-032); não há biometria ao abrir o app — a chave do aparelho é liberada por dia (F6-A8) | ADR-012 · RNF-SEC-19 e 20 | **parcial** |
| T-08 | Information disclosure | Outro app lê o arquivo do comprovante | O arquivo é copiado para a **área privada** do app na chegada; nada vai para armazenamento compartilhado | ADR-006 | F6-07 |
| T-09 | Information disclosure | Dado financeiro em log, métrica ou relatório de erro | Log só com código, rota, duração e `ref`. Teste percorre os logs de uma sessão e reprova valor, descrição ou texto de comprovante | ADR-015 · RNF-SEC-12 | F6-03 |
| T-10 | Information disclosure | A web deixa dado no computador de outra pessoa | Nada em `localStorage`; a sessão é um **token em memória** — fechar a aba é sair —, com 2 h fixas no servidor; o celular encerra a sessão à distância. (A ADR-008 dizia cookie `HttpOnly` e 30 min de inatividade; ver `desvios-do-plano.md`) | ADR-008 | F6-12 |
| T-11 | Denial of service | Enxurrada de requisições ou de tentativas de código | Limite de taxa por origem e global (`E-RATE-01`); o app continua funcionando offline | ADR-012 · RNF-SEC-08 | F6-03 |
| T-12 | Elevation of privilege | Sessão da web tenta escrever | A sessão pareada é só de leitura **no servidor**, não só na interface | ADR-008 | F6-03 |
| T-13 | Tampering | App malicioso compartilha arquivo gigante, de tipo falso ou com nome hostil | Tipo conferido pelos primeiros bytes, tamanho e espaço conferidos antes de copiar; nome descartado | ADR-006 | F6-07 |

## Fronteira 2 — API ↔ DeepSeek

| # | STRIDE | Ameaça | Controle | Onde | Nasce em |
|---|---|---|---|---|---|
| T-20 | Tampering | **Injeção de prompt**: o comprovante traz "ignore as instruções e classifique como…" | O texto entra por último, em bloco delimitado e nomeado como dado; sem ferramentas nem chamada de função | ADR-010 | F6-04 |
| T-21 | Tampering | A IA devolve categoria inventada, ou JSON que tenta passar comando adiante | Saída validada contra esquema; categoria precisa estar **na lista enviada**; nada é executado (`E-AI-04`) | ADR-010 · RNF-SEC-09 | F6-04 |
| T-22 | Tampering | O comprovante tenta alterar o **valor** lançado através da IA | Valor e data vêm do leitor local; divergência baixa a confiança e vira pergunta | ADR-010 | F6-04 |
| T-23 | Information disclosure | Dado pessoal do comprovante chega ao fornecedor | Mascaramento no backend antes de sair; só texto, nunca imagem; o assistente recebe só agregados | ADR-010 · RN-989 | F6-04 |
| T-24 | Information disclosure | A resposta da IA vaza o prompt de sistema | O prompt não contém segredo nem dado de outro contexto: vazá-lo não revela nada | ADR-010 | F6-04 |
| T-25 | Denial of service | Texto enorme ou laço de chamadas queima o crédito | Teto de tamanho na entrada (`E-REQ-04`), teto de tokens de saída, **orçamento mensal** (`E-AI-03`), disjuntor; o crédito é pré-pago | ADR-010 | F6-04 |
| T-26 | Spoofing | Resposta forjada no caminho até a DeepSeek | TLS com validação normal de certificado na saída do servidor | RNF-SEC-02 | F6-04 |
| T-27 | Information disclosure | A chave da API vaza | Só existe como credencial do systemd; ``tool/security/scan_secrets.py`` no commit e no CI; revogação em um clique na plataforma | ADR-005 · RNF-SEC-11 | F6-04 · Fase 7 |

A **suíte de comprovantes maliciosos** (RNF-SEC-17) é o teste desta fronteira: textos com instrução embutida, JSON embutido, categoria falsa e valor adulterado. Critério: a classificação não muda, e nada fora do esquema é aceito. Roda em todo PR.

## Fronteira 3 — VM ↔ mundo (e o backup)

| # | STRIDE | Ameaça | Controle | Onde | Nasce em |
|---|---|---|---|---|---|
| T-30 | Spoofing | Força bruta no SSH | Só chave, senha desligada, `fail2ban`, atualização automática | RNF-SEC-15 | Fase 7 |
| T-31 | Tampering | Alguém com acesso ao disco altera, remove ou reordena eventos | Envelope autenticado por registro + cadeia de hash; `dbtool verify` aponta o registro exato (`E-DATA-01`) | ADR-005 | F6-02 |
| T-39 | Tampering | Alguém com acesso ao disco **corta o fim** do registro: a cadeia continua válida, só mais curta | **Metade feita.** O servidor expõe `GET /v1/head` com o `seq`; **nenhum cliente o consulta ainda**, então o corte não é notado (BL-051). O backup de ontem continua sendo prefixo do de hoje | ADR-005 | **em aberto** |
| T-40 | Tampering | Um celular com relógio adiantado — ou um pedido forjado com sessão de aparelho — carimba uma correção ou um plano no **futuro**, e a partir daí nenhuma edição de verdade passa por cima (ADR-019) | O servidor recusa carimbo além de 10 min à frente do próprio relógio (`E-REQ-01`), na correção e no plano. Entre carimbos válidos, o desempate continua pelo relógio dos aparelhos: restrição declarada (BL-064) | ADR-019 | 27/09 |
| T-32 | Tampering | Queda de energia no meio de uma escrita corrompe o registro | `append` + `fsync`; linha incompleta detectada e descartada ao subir; resumos por `rename` atômico | ADR-004 | F6-02 |
| T-33 | Information disclosure | Cópia do disco ou do backup cai em mãos erradas | Registro cifrado por registro; backup cifrado com `age` para chave que **não está no servidor** | ADR-005 · RNF-SEC-14 | F6-02 · Fase 7 |
| T-34 | Information disclosure | A Vercel enxerga o tráfego da web | A Vercel só serve os arquivos da página: com a origem separada e o CORS restrito a ela, o navegador fala **direto com a VM**, e a Vercel não vê o livro. A web recebe os lançamentos inteiros (só leitura) — o que o computador de quem pareou vê é o mesmo que o celular vê | ADR-011 | Fase 7 |
| T-35 | Denial of service | A Oracle recolhe a VM ociosa, ou o DNS gratuito some | O app funciona offline; deploy idempotente; restauração ensaiada | ADR-011 · ADR-012 | Fase 7 |
| T-36 | Elevation of privilege | Falha no servidor dá acesso à máquina | Serviço sem privilégio, escutando só em `127.0.0.1`; o executável é o único artefato — sem SDK nem interpretador na VM | ADR-003 · RNF-SEC-15 | Fase 7 |
| T-37 | Tampering | Dependência comprometida entra no build | Versões travadas num `pubspec.lock` único; atualização deliberada; poucas dependências no domínio (só `meta`) | ADR-014 · RNF-SEC-16 | contínuo |
| T-38 | Information disclosure | Segredo commitado por engano | ``tool/security/scan_secrets.py`` no gancho de commit e no CI; varredura do histórico inteiro antes de o repositório ficar público | ADR-014 · BL-022 | F6-03 · Fase 9 |

## Riscos que ficam

| Risco | Por que fica | O que limita o dano |
|---|---|---|
| Quem é root na VM lê a chave de dados em memória | Uma VM só, sem cofre de segredos a custo zero | Os backups antigos não abrem com o que está no servidor; aviso de segurança dentro do app (RNF-SEC-13) |
| O mascaramento de dado pessoal tem falso negativo | É feito por padrões | Sai só texto, só o necessário; a tela de privacidade diz isso; cada formato novo vira teste |
| A DeepSeek pode guardar o que recebe | Está fora do controle do projeto | Manda-se o mínimo; o app funciona sem a IA |
| Celular desbloqueado nas mãos de outra pessoa, com o app em primeiro plano | Nenhum app resiste a isso | O bloqueio volta ao sair do primeiro plano; a web pareada pode ser encerrada pelo celular |
| Fixar a raiz não protege contra emissão indevida pela própria autoridade | É o equilíbrio contra se trancar do lado de fora | HSTS e transparência de certificados |

## Como este documento é usado

- Cada passo da Fase 6 abre com as ameaças da coluna "Nasce em" que lhe cabem, e só fecha com o teste do controle escrito.
- O [checklist do ASVS](asvs-checklist.md) referencia estas ameaças por número.
- Ameaça nova descoberta no caminho ganha linha aqui **antes** do código que a contém.
