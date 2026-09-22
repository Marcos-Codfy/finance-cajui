# Cajui

App pessoal de controle financeiro, feito do zero: especificação, domínio em Dart puro, app Android em Flutter, servidor próprio numa VM, esteira de qualidade e deploy. Usuário único. Custo fixo **R$ 0,00 por mês**.

> O nome é do **cajuí** (*Anacardium humile*), o cajuzinho rasteiro do Cerrado tocantinense, que rebrota depois do fogo.

---

## O problema

Substituir uma planilha que funcionava — mas só funcionava porque alguém a alimentava à mão. O app automatiza a mesma lógica, com dois conceitos que quase nenhum app de finanças acerta:

- **Cartão de crédito é forma de pagamento, nunca despesa.** A compra conta no mês em que foi feita; a fatura é uma visão calculada, nunca um lançamento. Compra parcelada não mexe no orçamento variável: ela vira compromisso do bloco de dívidas, parcela a parcela.
- **Vale alimentação é outra moeda.** Nunca se soma ao dinheiro. Não existe, em lugar nenhum do código, um total que junte os dois — é garantido pelo compilador, e não por disciplina.

E um diferencial de uso: **compartilhar um comprovante de qualquer app do Android** → OCR no próprio aparelho → classificação → confirmação. Ou fotografar o cupom de papel direto do app.

## Como está montado

```
app/                  Flutter — Android é o app de uso; a web é modo consulta
server/               Dart + Shelf, compilado como executável único
packages/domain/      Dart puro: as regras. Roda igual no celular e no servidor
packages/api_contract/  DTOs, leitura estrita de JSON, catálogo de erros
packages/persistence/ registro de eventos cifrado, com cadeia de hash
packages/design_system/  tokens, componentes e uma gallery navegável
tool/                 verificadores próprios: tamanho, camadas, segredos, cobertura
docs/                 especificação, ADRs, modelo de ameaças, operação
```

**Arquitetura Limpa, feature-first.** As camadas só apontam para dentro, e isso **não é convenção: é reprovado por máquina**. Um verificador próprio, escrito com `package:analyzer`, barra o commit que importar de fora para dentro, passar de 300 linhas por arquivo, 30 por função, 3 níveis de aninhamento, declarar dois tipos públicos no mesmo arquivo, deixar um `TODO` solto ou escrever uma cor à mão numa tela.

**O domínio é Dart puro** — sem Flutter, sem `dart:io`. A mesma regra, a mesma conta e o mesmo teste valem no aparelho e no servidor. O servidor **revalida tudo** o que o app já validou: nunca se confia no cliente.

**Registro de eventos, e nada é apagado.** Corrigir acrescenta, cancelar acrescenta. Cada registro é cifrado com AES-256-GCM e encadeado por SHA-256, então dá para provar que ninguém mexeu no passado sem ter a chave.

## Segurança

Não há senha, e não há conta em servidor de terceiro.

- **A chave do aparelho nasce dentro do hardware e nunca sai.** No StrongBox do Galaxy S22. O servidor manda um desafio, o celular assina, e é a assinatura que prova quem é — nunca um "a biometria passou" vindo do app.
- **A biometria libera a chave**, com validade de um dia contada pelo próprio hardware. Trocar a digital cadastrada no aparelho invalida a chave.
- **A tela não vai para a miniatura do seletor de apps** nem se deixa fotografar.
- **A chave da IA existe só no servidor**, como credencial cifrada do systemd, presa àquela máquina. Nunca no app, nunca no bundle web, nunca no repositório — e há um verificador que varre a árvore **e o histórico inteiro** a cada commit e a cada PR.
- **Para a IA vai só texto, nunca imagem**, e com PII mascarada antes de sair. O comprovante é tratado como entrada hostil: o bloco de dados tem marcador aleatório, e há uma suíte de comprovantes maliciosos que tenta injeção de prompt.
- **A resposta da IA também é entrada não confiável**: esquema fechado, e **todo valor em reais precisa existir no contexto** — senão a resposta é descartada.

Modelo de ameaças em STRIDE com 31 ameaças, e um checklist ASVS nível 2 gerado do CSV oficial. Onde um controle **não** está implementado, está escrito que não está.

## Qualidade

| | |
|---|---|
| Testes | app 164 · domínio 194 · servidor 77 · design system 71 · gallery 8 · contrato 19 · persistência 25 · verificador 26 |
| Cobertura | domínio 94% · persistência 94% · servidor 92% · app 80% · design system 80% |
| Analisador | `very_good_analysis`, zero aviso |
| Verificador próprio | 526 arquivos, nenhum limite estourado |
| Lighthouse (web) | Acessibilidade **100** · Desempenho 60 — [por quê](docs/ops/lighthouse.md) |

Cada regra de negócio tem número (`RN-xxx`) e **um teste com o mesmo número**. Quando a especificação traz um exemplo numérico, o teste o reproduz centavo a centavo.

Todo texto que a pessoa lê vem de um catálogo de erros, e o código que o exibe é **gerado** desse catálogo. Uma lista de termos proibidos — "déficit", "estourou", exclamação — é aplicada por teste a todas as frases do app.

## O que deu errado, e o que isso ensinou

A parte mais honesta do projeto, e a mais útil de ler:

- **Três defeitos que 142 testes verdes não pegaram** e o primeiro uso num celular derrubou em minutos. O pior: o app lia o corpo de erro da API no lugar errado, então **nenhuma recusa do servidor chegava com o código certo** — e o teste não pegou porque o servidor de mentira imitava a suposição do cliente, não o servidor.
- **A compra parcelada contava inteira no mês da compra.** O domínio sempre soube fazer certo; a camada de cima somava sozinha em vez de perguntar. Era o conceito central do produto, quebrado.
- **A web nunca tinha rodado.** O cliente HTTP do `dart:io` estoura ao ser criado no navegador, e a raiz de composição o criava sempre: o app morria antes do primeiro quadro, calado.
- **Um compartilhamento ilegível matava o app na abertura** — a exceção escapava até o `configureFlutterEngine`. Um app hostil manda isso de propósito.
- **Uma ferramenta prometida numa ADR existia, estava testada, e nunca tinha sido ligada a um executável.**

Todos achados por auditoria adversarial ou por usar o app de verdade, e todos com teste que prende o caso. O registro do projeto foi corrigido onde ele afirmava mais do que o código fazia.

## Custo

**R$ 0,00 fixo.** VM gratuita na Oracle, TLS do Let's Encrypt, DNS dinâmico gratuito, repositório e esteira no GitHub, Vercel no plano Hobby, sons CC0, fontes livres.

O único custo variável é a IA: **cerca de R$ 0,60 por mês** no cenário de 120 lançamentos — [a conta está aqui](docs/ops/ai-cost-estimate.md), com o preço lido na fonte.

## Por onde começar a ler

| Quero entender… | Leia |
|---|---|
| as decisões e o porquê de cada uma | [`docs/architecture/adr/`](docs/architecture/) — 18 ADRs |
| as regras de negócio | [`docs/spec/rules/`](docs/spec/) |
| as ameaças e os controles | [`docs/security/threat-model.md`](docs/security/threat-model.md) |
| como operar o servidor | [`docs/ops/runbook.md`](docs/ops/runbook.md) |
| o que está feito e o que falta | [`PROGRESS.md`](PROGRESS.md) e [`BACKLOG.md`](BACKLOG.md) |
