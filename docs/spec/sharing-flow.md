# Fluxo de compartilhamento

O requisito crítico do produto: tocar em **Compartilhar** num comprovante, extrato, print ou PDF, em **qualquer app do Android**, e encontrar o Cajui na lista de destinos. É o que acaba com a digitação.

As regras estão em [rules/capture-and-classification.md](rules/capture-and-classification.md) (RN-7xx); este documento mostra o fluxo, a tela de confirmação e o texto de cada estado. O fluxo existe só no Android: na web não há Web Share Target confiável nem OCR local (D-MDN, `mdn-web-docs.md`).

## O fluxo

```mermaid
flowchart TD
    A[Compartilhar em outro app] --> B{Tipo e tamanho válidos?<br/>RN-701 a RN-704}
    B -- não --> B1[Arquivo inválido<br/>diz o motivo e o que é aceito]
    B -- sim --> C[Grava o original no aparelho<br/>RN-720]
    C --> D{Já vi este arquivo?<br/>RN-725}
    D -- sim --> D1[Avisa e oferece abrir o lançamento]
    D -- não --> E[Lê o texto no aparelho<br/>camada de texto do PDF ou OCR<br/>RN-710 a RN-713]
    E --> F{Texto legível?<br/>RN-714}
    F -- não --> F1[Oferece outra foto ou digitar,<br/>com o comprovante anexado]
    F -- sim --> G[Classificador por regras no aparelho<br/>regra aprendida e regras fixas<br/>RN-750 a RN-759]
    G --> H[Mascara dados pessoais<br/>RN-730 a RN-734]
    H --> I{Há rede e IA disponível?}
    I -- não --> K
    I -- sim --> J[Backend mascara de novo e consulta a IA<br/>texto como dado delimitado<br/>saída validada por esquema<br/>RN-770 a RN-778]
    J --> K[Monta a proposta<br/>confiança por campo<br/>RN-740 a RN-746]
    K --> L{Tipo do documento}
    L -- pagamento de fatura --> L1[Tela de liquidação<br/>RN-343 · RN-756]
    L -- recebimento --> L2[Tela de recebimento de renda<br/>RN-758]
    L -- despesa --> M{Alguma dúvida?<br/>RN-760}
    M -- sim --> N[Pergunta em português claro<br/>RN-761 · RN-762]
    N --> O
    M -- não --> O[Tela de confirmação]
    O --> P{Confirmar}
    P -- corrigiu a categoria --> Q[Cria regra aprendida, com desfazer<br/>RN-763]
    Q --> R
    P -- confirmou --> R[Grava o lançamento e o comprovante<br/>uma operação, uma chave de idempotência<br/>RN-722]
    P -- conferir depois --> S[Fica em "Para conferir"<br/>RN-721 · RN-783]
    P -- descartar --> T[Apaga o arquivo local, não grava nada<br/>RN-723]
    R --> U[Envia o original ao servidor quando houver rede<br/>RN-724]
```

Três garantias atravessam o fluxo inteiro:

| Garantia | Regra |
|---|---|
| **A imagem nunca sai rumo à IA.** Só o texto extraído, já com dados pessoais mascarados | RN-710 · RN-730 |
| **Nada é gravado sem passar pela confirmação** e por um toque do usuário | RN-795 |
| **O app nunca deixa de lançar por causa da IA ou da rede** | RN-780 · RN-784 |

## A tela de confirmação

Uma tela só. O valor é o maior elemento; cada campo mostra de onde veio e com que certeza.

| Campo | O que mostra | Comportamento |
|---|---|---|
| **Valor** | Em destaque, na tipografia de número-manchete | Tocar edita. Em compra paga com cartão ou dinheiro, mostra o efeito imediato: "limite da semana: R$ 236 → R$ 150" (D-UX-05) |
| **O que foi** | Descrição curta, até 60 caracteres (RN-775) | Editável |
| **Data da compra** | Data lida, ou "hoje · ontem · outra data" sem pré-seleção se não houve leitura (RN-748) | Rejeita data futura (RN-206) |
| **Categoria** | Conforme a zona de confiança (abaixo) | O bloco aparece ao lado, derivado da categoria (RN-202), nunca editável à parte |
| **Por onde foi pago** | Forma de pagamento proposta; cartão identificado pelo final | "Dividir pagamento" abre a segunda linha — o caso do vale que acaba (RN-122) |
| **Parcelas** | Aparece se houver leitura de "10x" ou se a forma for cartão de crédito (RN-755) | Mostra a parcela **e** o total comprometido (RN-313) |
| **Repete todo mês?** | Aparece se a proposta casou com um fixo em aberto (RN-749) | "É o aluguel de setembro" liga o lançamento à ocorrência |
| **Fora do padrão** | Chave, desligada por padrão | Ao ligar, mostra o acumulado do ano (RN-241) |
| **Comprovante** | Miniatura do original | "Ver o que foi lido" mostra o texto extraído e o texto exatamente como foi enviado, com os marcadores (RN-735) |

### As três zonas de confiança

A zona é calculada por código, não pela IA (RN-742); os limiares são configuráveis (RN-743).

| Zona | Como a categoria aparece | Sinal visível |
|---|---|---|
| **Alta** | Preenchida num chip editável; troca em um toque | Rótulo "confiança alta" + ícone de três pontos cheios |
| **Média** | Dois ou três candidatos, **nenhum** pré-selecionado | "Fiquei entre estas" + dois pontos cheios |
| **Baixa**, ou IA fora do ar | Campo vazio com seletor, sem palpite | "Não consegui identificar" + um ponto cheio |

A confiança nunca é comunicada só por cor: leva rótulo em texto e ícone (RN-671).

## Quando o app pergunta

Na zona baixa, ou quando os candidatos da zona média são de blocos diferentes (RN-760), o app pergunta antes de mostrar a confirmação. A pergunta vem de modelo fixo do app — nenhum texto livre da IA vira pergunta (RN-761).

> **Fiquei em dúvida entre transporte e alimentação.** O que foi essa compra de R$ 23,90 no Posto Cajueiro?
>
> `Transporte` · `Alimentação` · `Outra coisa…`

A resposta pode ser um toque ou uma descrição livre ("foi um lanche na conveniência"). Em seguida:

> **Vou lembrar: Posto Cajueiro é alimentação.** `Desfazer`

A regra aprendida passa a rodar antes da IA (RN-750), mas a proposta continua passando pela confirmação (RN-765). Se um dia o usuário corrigir uma proposta que veio dessa regra, ela é removida sem criar outra: o estabelecimento tem mais de um uso, e o app volta a perguntar (RN-766).

## Os estados da tela

Texto real de cada estado, no [guia de voz](../brand/voice-and-tone.md). Os códigos `E-CAPT-NN` são provisórios; o catálogo de erros é escrito na Fase 3.

| Estado | O que aparece | Ações |
|---|---|---|
| **Recebendo** | "Guardando o comprovante…" | — |
| **Lendo** | "Lendo o comprovante no seu aparelho." Linha de varredura no ritmo real da leitura; em PDF, "página 2 de 4" | Cancelar |
| **Classificando** | "Identificando o que foi comprado…" Valor e data já aparecem se as regras leram | Preencher à mão |
| **Confirmando** | A tela de confirmação | Lançar · Conferir depois · Descartar |
| **Perguntando** | A pergunta de esclarecimento | Candidatos · Outra coisa |
| **Sem rede** | "Sem conexão agora. Li o comprovante aqui mesmo e preenchi o que deu; a categoria fica com você. O lançamento sobe sozinho quando a rede voltar." | Lançar · Conferir depois |
| **IA fora do ar** | "A classificação automática está fora do ar. Usei as regras locais — confira a categoria antes de lançar." | Lançar · Conferir depois |
| **Sem texto legível** `E-CAPT-01` | "Não consegui ler este comprovante: a imagem ficou escura ou pequena demais para o texto aparecer. O arquivo está guardado." | Tirar outra foto · Digitar os dados |
| **Arquivo inválido** `E-CAPT-02` | "Este arquivo não é uma imagem, um PDF nem um texto. O Cajui lê JPEG, PNG, WebP, PDF e texto." | Escolher outro |
| **Arquivo grande demais** `E-CAPT-03` | "Este arquivo tem 22 MB e o limite é 15 MB. Um print da tela do comprovante resolve." | Escolher outro |
| **PDF com senha** `E-CAPT-04` | "Este PDF está protegido por senha, e o Cajui não abre arquivo protegido. Um print da página com o valor resolve." | Escolher outro · Digitar os dados |
| **Arquivo repetido** | "Este comprovante já virou um lançamento em 12/09: Mercado Boa Compra, R$ 186,40." | Abrir o lançamento · Lançar mesmo assim |
| **Parece repetido** | "Já existe um lançamento de R$ 8,50 na Padaria Central hoje. É outro?" | É outro, lançar · É o mesmo, descartar |
| **Vários arquivos** | "3 comprovantes para conferir · 1 de 3" | Um por vez, na ordem recebida (RN-705) |
| **Extrato com várias movimentações** | "Encontrei 12 movimentações neste extrato. Confira uma a uma, ou pule as que não interessam." | Confirmar · Pular (RN-707) |
| **Sem permissão de leitura** `E-CAPT-05` | "O app de origem não liberou o arquivo. Tente compartilhar de novo, ou salve o comprovante na galeria e compartilhe de lá." | Entendi |
| **Armazenamento cheio** `E-CAPT-06` | "Não há espaço no aparelho para guardar o comprovante (faltam cerca de 4 MB). Nada foi perdido: ele continua no app de origem." | Abrir armazenamento · Digitar os dados |

## O primeiro compartilhamento

Antes da primeira captura, uma tela curta ajusta a expectativa (D-UX-10, Kocielnik2019):

1. **O que é lido.** "O Cajui lê o comprovante no seu aparelho. Só o texto sai daqui, e com CPF, conta e chave Pix mascarados. A imagem nunca é enviada à IA."
2. **Um acerto e um erro.** Um exemplo em que a categoria veio certa, outro em que o app ficou em dúvida e perguntou.
3. **Tudo é editável.** "Nada é lançado sem você conferir."
4. **Quando perguntar.** Três posições: perguntar sempre · só na dúvida (padrão) · preencher e eu reviso (RN-745).

## "Para conferir"

Capturas ainda não confirmadas vivem só no aparelho, numa lista com contagem visível no painel (RN-721). Nenhuma delas conta em indicador. Quando a rede volta, o app completa com a IA as propostas que foram montadas sem ela, antes de mostrá-las de novo (RN-783).
