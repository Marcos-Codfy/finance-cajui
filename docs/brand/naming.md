# Nome

**Decisão (2026-09-19): Cajui.** Grafia de marca sem acento; em texto corrido, a fruta continua sendo "cajuí".

## Critérios

1. **Raiz no Cerrado do Tocantins** — coisa típica do dia a dia, com a simplicidade de uma fruta, e não um nome conceitual.
2. **Som de marca global** — 2 a 3 sílabas, sem acento na grafia de marca, sem dígrafo difícil, pronunciável por quem não fala português.
3. **Funciona na frase** — "abre o Cajui", "lança no Cajui".
4. **Domínio plausível** e **sem conflito óbvio de marca**, principalmente no setor financeiro.

Como o projeto tem custo fixo alvo de R$ 0, a disponibilidade de domínio entrou como critério de marca, não como compra: o app usa subdomínio gratuito.

## Como foi verificado

- **Domínios:** consulta RDAP direta nos registros — Verisign para `.com`, Google Registry para `.app`. Resposta `404` significa domínio livre; `200`, registrado. Data: 2026-09-18 e 2026-09-19.
- **Subdomínio gratuito:** requisição a `<nome>.vercel.app`; livre quando responde `404` com o cabeçalho `X-Vercel-Error: DEPLOYMENT_NOT_FOUND`.
- **Marca:** busca na web pelo nome combinado com "fintech", "app de finanças" e "banco digital". É uma triagem, não uma busca formal no INPI — suficiente para uso pessoal e portfólio, insuficiente para lançar produto comercial.

## Candidatos finais

| Nome | Origem | `.com` | `.app` | Compostos `.com` livres | Risco de marca |
|---|---|---|---|---|---|
| **Cajui** | Cajuzinho rasteiro do Cerrado (*Anacardium humile*), rebrota depois do fogo | registrado | **livre** | `getcajui`, `cajuiapp`, `usecajui` | Médio: som vizinho de "Caju", fintech de benefícios |
| Murici | Fruto de feira; "em tempo de murici, cada um cuida de si" | registrado | livre | `getmurici`, `muriciapp` | Baixo |
| Bacaba | Palmeira do norte do TO; vinho de bacaba | registrado | livre | `getbacaba`, `bacabaapp` | Baixo |
| Pequi | O fruto mais icônico de TO e GO | registrado | registrado | `getpequi`, `pequiapp` | Médio: saturado no comércio regional |
| Caja | Cajá do suco e do picolé; "caja" é caixa em espanhol | registrado | registrado | nenhum | Médio: termo genérico de banco em espanhol |
| Pitomba | Vendida em cacho nas ruas | registrado | livre | `getpitomba` | Baixo |
| Beiju | Café da manhã do sertão | registrado | livre | `getbeiju` | Baixo |
| Buriti | Palmeira das veredas e do Jalapão | registrado | registrado | `getburiti` | Médio: saturado |

Subdomínio gratuito verificado como livre: `cajui-app.vercel.app`.

## Descartados por conflito direto em finanças

| Nome | Conflito encontrado |
|---|---|
| Cumbuca | Fintech brasileira de contas compartilhadas e infraestrutura Pix |
| Mumbuca | Moeda social de Maricá (RJ) e o Banco Mumbuca |
| Caju | Fintech de benefícios corporativos e vale alimentação |
| Capim | Fintech de crédito para clínicas odontológicas |
| Tangerina | Tangerine Bank (Canadá) |
| Ema | App de finanças pessoais "Emma" |

Outros cortes: Ipe (lê como sigla), Guara (puxa para guaraná), Sucupira, Araticum, Cajazinho e Macaúba (quatro sílabas), Jalapão (o "ão" não viaja).

## Por que Cajui

- É fruta, é do Cerrado tocantinense, e quase ninguém de fora conhece — o nome chega sem bagagem.
- A planta é pequena, rasteira, resistente, e uma das primeiras a rebrotar depois da queimada. Para um app que precisa falar de dívida e de mês que não fecha sem provocar culpa, a metáfora já vem pronta: **todo mês rebrota**.
- `.app` e compostos `.com` livres, subdomínio gratuito livre.

## Risco assumido

O som é vizinho de "Caju", uma fintech de benefícios que atua justamente com vale alimentação. Para uso pessoal e portfólio isso não tem consequência. Se um dia o app virar produto comercial, o nome precisa passar por busca formal de marca (INPI, classes 9, 36 e 42) antes de qualquer lançamento — item a reabrir nesse cenário, não antes.

## Identificadores derivados

| Onde | Valor |
|---|---|
| Repositório | `cajui` |
| Pacote Android | `app.cajui` |
| Web | `cajui-app.vercel.app` |
