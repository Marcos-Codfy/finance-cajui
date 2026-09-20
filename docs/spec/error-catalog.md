# Catálogo de erros

Todo erro que o Cajui pode mostrar está nesta página, com código, texto e saída. **Não existe erro genérico**: se uma falha não tem linha aqui, ela ainda não pode ser mostrada — primeiro ganha uma linha.

Este catálogo substitui os [códigos provisórios](use-cases.md#códigos-de-erro-provisórios) dos casos de uso. Os 36 códigos foram mantidos; entraram nove novos, marcados com ✚.

## Como ler

| Coluna | Significa |
|---|---|
| Código | `E-<ÁREA>-NN`. Estável: nunca muda de sentido nem é reaproveitado. Código aposentado fica na tabela, riscado |
| Quando | A condição exata que dispara o erro |
| Origem | `app` (detectado no aparelho, sem rede) · `api NNN` (resposta do backend, com o status HTTP) |
| Texto | O que a pessoa lê. Segue a fórmula do [guia de voz](../brand/voice-and-tone.md): o que aconteceu · o que significa · o que dá para fazer. `{chaves}` são valores preenchidos na hora |
| Saídas | As ações oferecidas, da principal para a secundária. Todo erro tem ao menos uma |

## Regras que valem para todos

1. **Específico, sempre.** Proibido em qualquer tela: "Algo deu errado", "Erro inesperado", "Ops!", "Tente novamente mais tarde" sem dizer o quê. A única classe vaga é `segurança`, de propósito (RNF-SEC-18), e mesmo ela diz o que fazer.
2. **Nenhuma mensagem atribui a falha à pessoa** (D-UX-22). "Digite um valor maior que zero", nunca "Você digitou um valor inválido".
3. **Diz o que foi preservado.** Se o erro interrompe algo, o texto afirma o que está a salvo: o comprovante guardado, o lançamento na fila, os dados no servidor.
4. **Erro não some sozinho** (RNF-A11Y-13). Erro de campo fica sob o campo até ser resolvido; erro de tela é um `CajuiNotice` persistente. Nada de balão temporizado.
5. **Nunca só cor, nunca só som.** O aviso tem ícone e texto; o som é `sound.notice`, a nota grave e macia — não existe som de erro. Tela de falta do mês não toca nada.
6. **O texto mora no app, não na API.** A API devolve o código e os valores; o app monta a frase a partir deste catálogo. Trocar uma redação é editar um lugar só, e a API nunca vaza texto técnico para a tela.
7. **O código aparece discreto**, em legenda sob o aviso ("Código E-CAPT-01"), só nas classes em que ajuda a procurar o motivo: `captura`, `sincronização`, `dados`, `servidor`, `app`.

## Classes

| Classe | Onde aparece | Intenção visual | Som | O app tenta de novo sozinho? |
|---|---|---|---|---|
| `validação` | Sob o campo, ao sair dele ou ao confirmar | `danger` no contorno e no texto do campo | — | Não se aplica |
| `regra` | Aviso na tela, junto da ação recusada | `attention` | `notice` | Não: depende de uma escolha |
| `captura` | Tela de captura inteira | `danger` | `notice` | Não |
| `rede` | Aviso no topo; o conteúdo guardado continua visível | `attention` | — | Sim, com recuo exponencial (2 s, 4 s, 8 s… até 5 min) e ao voltar a conexão |
| `sincronização` | Aviso no painel e em "Para conferir" | `attention` | `notice` | Conflito: uma vez, relendo o estado. Rejeição: não |
| `ia` | Aviso na tela que pediu a IA; o resto do app segue | `attention` ou `info` | — | Uma vez, depois cai nas regras locais |
| `limite` | Aviso com contagem regressiva | `attention` | — | Sim, quando o prazo informado vence |
| `segurança` | Tela de desbloqueio ou de pareamento | `attention` | — | Não |
| `dados` | Tela inteira, bloqueia escrita | `danger` | `notice` | Não: exige ação de manutenção |
| `aparelho` | Aviso na tela | `attention` | `notice` | Não |
| `servidor` | Aviso na tela; o conteúdo guardado continua visível | `danger` | — | Sim, até 3 vezes em leitura; nunca em escrita sem chave de idempotência |
| `app` | Tela inteira | `danger` | — | Não |

## Formato na API

Toda resposta de erro do backend tem este corpo, e nenhum outro:

```json
{
  "error": {
    "code": "E-VOUCHER-01",
    "class": "regra",
    "detail": { "balanceCents": 2260, "requestedCents": 3840 },
    "ref": "7f3a9c",
    "retryAfterSeconds": null
  }
}
```

- `code` e `class` vêm desta página. `detail` traz só os valores que o texto usa, já validados; nunca texto livre, nunca pilha de execução.
- `ref` identifica a ocorrência no registro do servidor. O registro guarda código, rota, duração e `ref` — **nunca valor, estabelecimento, categoria ou texto de comprovante** (RNF-SEC).
- `retryAfterSeconds` acompanha o cabeçalho `Retry-After` nas classes `limite` e `ia`.
- Resposta de erro sem `error.code` conhecido é tratada como `E-SRV-01`, com o `ref` se houver. O app nunca mostra o corpo cru.

## Lançamentos e vale

| Código | Quando | Origem | Texto | Saídas |
|---|---|---|---|---|
| `E-ENTRY-01` | A soma das linhas de pagamento difere do valor do lançamento | app · api 422 | As formas de pagamento somam {soma}, e a compra é de {valor}. Faltam {diferença} para fechar a conta. | Ajustar os valores · Colocar o resto em {forma} |
| `E-ENTRY-02` | Data da compra no futuro | app · api 422 | Esta data ainda não chegou. O Cajui registra o que já foi comprado; o que está por vir entra como compromisso no plano do mês. | Usar a data de hoje · Escolher outra data |
| `E-ENTRY-03` | Valor zero ou negativo | app · api 422 | Digite um valor maior que zero. Para registrar um dinheiro que voltou, use "Estorno" no lançamento original. | — (campo) |
| `E-ENTRY-04` | Estorno maior que o que resta do lançamento | app · api 422 | Este lançamento tem {restante} para estornar, e o estorno pedido é de {pedido}. | Estornar {restante} · Corrigir o valor |
| `E-VOUCHER-01` | Pagamento no vale maior que o saldo | app · api 422 | O vale tem {saldo}, e esta compra é de {valor}. Dá para pagar {saldo} no vale e o resto de outro jeito. | Dividir o pagamento · Trocar a forma de pagamento |
| `E-VOUCHER-02` | Categoria não elegível ao vale | app · api 422 | O vale alimentação só paga alimentação, e "{categoria}" está fora. | Trocar a forma de pagamento · Trocar a categoria |

## Cartão, orçamento e dívidas

| Código | Quando | Origem | Texto | Saídas |
|---|---|---|---|---|
| `E-CARD-01` | Dia de fechamento ou de vencimento fora de 1 a 31 | app · api 422 | O dia precisa ficar entre 1 e 31. Se o cartão fecha no último dia do mês, use 31: o Cajui ajusta nos meses mais curtos. | — (campo) |
| `E-CARD-02` | Tentativa de criar categoria que representa cartão ou fatura | app · api 422 | "{nome}" parece um cartão, e no Cajui cartão é forma de pagamento, não despesa. A categoria diz o que foi comprado; o cartão entra em "por onde pagou". | Cadastrar como cartão · Dar outro nome |
| `E-BUDG-01` | Faixa com mínimo maior que o máximo | app · api 422 | O mínimo ({mínimo}) ficou maior que o máximo ({máximo}). O Cajui planeja o mês pelo máximo, o pior caso. | Inverter os valores · Corrigir |
| `E-BUDG-02` | Fechar um mês que ainda não terminou | app · api 422 | {mês} ainda não terminou. Dá para fechar a partir de {data}. Até lá, os números são a projeção do mês. | Entendi |
| `E-BUDG-03` | Ajuste abaixo do mínimo da faixa | app · api 422 | {categoria} tem mínimo de {mínimo}, e o ajuste a deixaria em {resultado}. O mínimo é o que você disse que não dá para cortar. | Ajustar até {mínimo} · Rever a faixa |
| `E-BUDG-04` | Remanejamento maior que a folga da origem | app · api 422 | {origem} tem {folga} de folga, e o pedido é mover {pedido}. | Mover {folga} · Escolher outra origem |
| `E-DEBT-01` | Parcelas pagas maior que o total de parcelas | app · api 422 | A dívida tem {total} parcelas, e {pagas} aparecem como pagas. | — (campo) |

## Captura

Textos de [sharing-flow.md](sharing-flow.md#os-estados-da-tela), agora definitivos. Tudo aqui acontece no aparelho: a imagem nunca vai ao servidor.

| Código | Quando | Origem | Texto | Saídas |
|---|---|---|---|---|
| `E-CAPT-01` | A leitura não achou texto | app | Não consegui ler este comprovante: a imagem ficou escura ou pequena demais para o texto aparecer. O arquivo está guardado. | Tirar outra foto · Digitar os dados |
| `E-CAPT-02` | Tipo de arquivo que o app não lê | app | Este arquivo não é uma imagem, um PDF nem um texto. O Cajui lê JPEG, PNG, WebP, PDF e texto. | Escolher outro |
| `E-CAPT-03` | Arquivo acima de 15 MB | app | Este arquivo tem {tamanho} e o limite é 15 MB. Um print da tela do comprovante resolve. | Escolher outro |
| `E-CAPT-04` | PDF protegido por senha | app | Este PDF está protegido por senha, e o Cajui não abre arquivo protegido. Um print da página com o valor resolve. | Escolher outro · Digitar os dados |
| `E-CAPT-05` | O app de origem não liberou a leitura | app | O app de origem não liberou o arquivo. Tente compartilhar de novo, ou salve o comprovante na galeria e compartilhe de lá. | Entendi |
| `E-CAPT-06` | Sem espaço para guardar o arquivo | app | Não há espaço no aparelho para guardar o comprovante (faltam cerca de {falta}). Nada foi perdido: ele continua no app de origem. | Abrir armazenamento · Digitar os dados |
| `E-CAPT-07` ✚ | Uma página passou de 10 s na leitura (RNF-PERF-06) | app | Não consegui ler esta página a tempo. O comprovante está guardado. | Tentar de novo · Digitar o valor |

## Rede e sincronização

| Código | Quando | Origem | Texto | Saídas |
|---|---|---|---|---|
| `E-NET-01` | Sem conexão numa ação que só existe com rede (assistente, web) | app | Sem conexão agora. {recurso} só funciona com internet, porque a resposta vem do servidor. Seus números continuam no painel. | Tentar de novo |
| `E-NET-02` | O servidor não respondeu em 10 s | app | O servidor não respondeu a tempo. {preservado}. | Tentar de novo |
| `E-SYNC-01` | Um comando da fila offline foi rejeitado pelo servidor | api 422 | Um lançamento feito sem conexão não pôde ser enviado: {motivo}. Ele continua guardado no aparelho, em "Para conferir". | Abrir o lançamento |
| `E-SYNC-02` | Conflito de escrita: outro comando gravou primeiro | api 409 | Este item mudou em outro lugar enquanto você editava. Nada foi perdido: mostro a versão atual e o que você ia salvar. | Ver as duas versões · Manter a atual |

`{preservado}` de `E-NET-02` é obrigatório e depende da ação: "O lançamento ficou na fila e sobe sozinho", "Nada foi alterado", "A conversa continua aqui".

## IA

| Código | Quando | Origem | Texto | Saídas |
|---|---|---|---|---|
| `E-AI-01` | A IA não respondeu em 20 s, ou está fora do ar | api 503 | Na captura: A classificação automática está fora do ar. Usei as regras locais — confira a categoria antes de lançar. · No assistente: O assistente está fora do ar. Seus números continuam no painel, e lançar funciona normalmente. | Lançar · Conferir depois — ou — Perguntar de novo |
| `E-AI-02` | O serviço de IA limitou as requisições | api 429 | Muitas perguntas em pouco tempo. O serviço de IA pediu uma pausa; dá para perguntar de novo em {segundos} segundos. | (aguarda a contagem) |
| `E-AI-03` | Teto mensal de tokens atingido (RNF-AI-04) | api 403 | O uso da IA chegou ao teto de {mês}. A classificação segue pelas regras locais, e a conversa volta no dia 1º. | Rever o teto · Ver o consumo |
| `E-AI-04` | Resposta da IA fora do esquema | api 200, com aviso | A classificação automática devolveu algo que não deu para aproveitar. Usei as regras locais — confira a categoria antes de lançar. | Lançar · Conferir depois |

`E-AI-04` não derruba a requisição: o backend descarta a resposta, classifica pelas regras e responde 200 com `warnings: ["E-AI-04"]`. Saída de IA é entrada não confiável; nunca chega à tela sem passar pelo esquema.

## Segurança

Vagos de propósito (RNF-SEC-18): não revelam se o aparelho existe, se o token venceu ou se foi revogado.

| Código | Quando | Origem | Texto | Saídas |
|---|---|---|---|---|
| `E-AUTH-01` | Biometria indisponível no aparelho | app | Este aparelho não tem biometria configurada. O Cajui usa a biometria do Android para proteger seus dados. | Abrir as configurações do Android |
| `E-AUTH-02` | Biometria não reconhecida | app | Não reconheci. | Tentar de novo |
| `E-AUTH-03` | Sessão, aparelho ou pino recusado | api 401 · 403 | Não foi possível confirmar este aparelho. Seus dados continuam protegidos no servidor. | Entrar de novo |
| `E-AUTH-04` | Código de pareamento vencido, usado ou errado | api 401 | Este código não serve mais. Gere outro no app do celular, em Ajustes › Computador. | Digitar outro código |

## Limite, dados e aparelho

| Código | Quando | Origem | Texto | Saídas |
|---|---|---|---|---|
| `E-RATE-01` | Limite de taxa do servidor (RNF-API-04) | api 429 | Foram muitos pedidos em pouco tempo. Nada se perdeu. Dá para tentar de novo em {segundos} segundos. | (aguarda a contagem) |
| `E-DATA-01` | Cadeia do registro de eventos quebrada | api 503 | O registro dos seus dados tem um trecho que não confere, a partir do evento {número}. Parei de gravar para não piorar; ler continua funcionando. O último backup íntegro é de {data}. | Ver o roteiro de restauração |
| `E-DATA-02` | Resumo guardado e registro de eventos discordam | api 503 | Os totais guardados não batem com o histórico. Vou refazer os totais a partir do histórico, que é a fonte da verdade; leva cerca de {tempo}. | Refazer agora |
| `E-STORAGE-01` | Armazenamento do aparelho cheio | app | O aparelho está sem espaço, e não deu para guardar {item}. O que já estava salvo continua salvo. | Abrir armazenamento |

## Requisição e servidor

| Código | Quando | Origem | Texto | Saídas |
|---|---|---|---|---|
| `E-REQ-01` ✚ | Corpo da requisição fora do esquema | api 400 | O app enviou um pedido que o servidor não entendeu. É uma falha do app, não sua; o que você preencheu continua na tela. | Tentar de novo · Copiar o código |
| `E-REQ-02` ✚ | O item pedido não existe mais | api 404 | Este item não existe mais — pode ter sido apagado em outro aparelho. | Voltar para a lista |
| `E-REQ-03` ✚ | App antigo demais para a API (RNF-COMPAT-05) | api 426 | Esta versão do app ficou antiga para falar com o servidor. Seus lançamentos pendentes continuam guardados. Instale a versão {versão} para enviar. | Ver como atualizar |
| `E-REQ-04` ✚ | Texto enviado acima do limite da API | api 413 | Este comprovante tem texto demais para analisar de uma vez. Usei as regras locais — confira a categoria antes de lançar. | Lançar · Conferir depois |
| `E-SRV-01` | Erro interno do servidor | api 500 | O servidor falhou ao {ação}. Seus dados estão guardados; foi só esta consulta que não voltou. | Tentar de novo |
| `E-SRV-02` ✚ | Servidor reiniciando ou em atualização | api 503 | O servidor está reiniciando. Costuma levar menos de um minuto; o que você lançar agora fica na fila. | Tentar de novo |
| `E-SRV-03` ✚ | Último backup há mais de 36 h (RNF-REL-10) | api 200, no estado do sistema | O último backup foi há {tempo}. Seus dados seguem no servidor, sem cópia recente fora dele. | Ver o que aconteceu |
| `E-WEB-01` ✚ | A web não desenhou o primeiro quadro em 10 s (RNF-WEB-10) | app | Não consegui abrir o painel. O carregamento parou no meio. | Tentar de novo |
| `E-APP-01` ✚ | Exceção não prevista dentro do app | app | O Cajui encontrou uma falha que ainda não tem nome. O que estava salvo continua salvo{fila}. | Reabrir o app · Copiar o código |

`{ação}` de `E-SRV-01` é obrigatório: "montar esta tela", "salvar o lançamento", "fechar o mês". Sem ele a frase vira o erro genérico que este catálogo proíbe.

`E-APP-01` é a rede de segurança, não um destino. Cada ocorrência registra o tipo da exceção e o `ref` (sem dado financeiro), e **vira item do `BACKLOG.md`** para ganhar código próprio. Se ela aparecer duas vezes pelo mesmo motivo, o catálogo está incompleto.

## Como isto vira código

- `packages/api_contract` define `ErrorCode` (um enum, um valor por linha desta página) e `ErrorClass`. App e backend compartilham o pacote: código que não existe aqui não compila.
- O domínio devolve falhas tipadas (`Failure`), nunca lança exceção para regra de negócio. O backend traduz `Failure` em resposta HTTP; o app traduz em texto.
- O texto de cada código mora num único arquivo do app, ao lado do design system. Um teste percorre o enum e falha se algum código não tiver texto, saída e classe.
- Outro teste percorre todos os textos e reprova termo da lista proibida do guia de voz — a mesma lista que valida a saída da IA (RN-944).
- A gallery mostra os erros em uso nas telas de estado (captura, fatura, fechamento, assistente), com o código na nota de cada estado.

## Rastreabilidade

| Requisito | Onde é atendido |
|---|---|
| RNF-A11Y-13 — erro em texto, junto da ação, com sugestão; nunca temporizado | Regras 3 e 4; classes `validação` e demais |
| RNF-SEC-18 — erro de autenticação vago de propósito | Seção Segurança |
| RNF-COMPAT-05 — app antigo demais | `E-REQ-03` |
| RNF-PERF-06 e 08 — prazos de leitura e de IA | `E-CAPT-07`, `E-AI-01` |
| RNF-AI-04 — teto de tokens | `E-AI-03` |
| RNF-API-04 — limite de taxa | `E-RATE-01` |
| RNF-REL-03 e 10 — fila offline e backup | `E-SYNC-01`, `E-SRV-03` |
| RNF-WEB-10 — primeiro quadro da web | `E-WEB-01` |
| D-UX-22 — nenhuma mensagem atribui falha à pessoa | Regra 2 |
| RN-944 — lista única de termos proibidos | Seção "Como isto vira código" |
