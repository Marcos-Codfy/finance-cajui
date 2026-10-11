# ADR-025 — As notificações do banco lançam sozinhas; o widget e o aviso de domingo

**Estado:** aceita · 11/10/2026 — por pedido do dono ("Quando chegar 'Compra aprovada R$ 45,90 MERCADO X' ou 'Pix enviado', o Cajui lança na hora e avisa: 'Lancei R$ 45,90 em Mercado. Desfazer?'. Sem foto e sem abrir o app."; "Widget na tela inicial do celular, com o valor que ainda dá para gastar e um botão de foto"; "No domingo vem uma notificação: 3 gastos ficaram sem categoria, confere em 1 minuto?")
**Substitui em parte:** RN-795 e RN-796 de [capture-and-classification.md](../../spec/rules/capture-and-classification.md), só para o que vem da notificação do banco, como anotado na RN-786
**Relacionada:** [ADR-004](ADR-004-registro-de-eventos-em-json.md) (o registro de um escritor só) · [ADR-006](ADR-006-receber-compartilhamento.md) (o texto compartilhado, por onde o toque entra) · [ADR-017](ADR-017-fotografar-comprovante.md) (a câmera que o widget abre) · [ADR-021](ADR-021-assistente-que-age.md) (o Desfazer ao lado do que foi lançado)

## Contexto

O app ficou difícil de usar: cada gasto pedia abrir o Cajui, fotografar ou digitar, e conferir. Quase toda compra, porém, já é avisada pelo banco no instante em que acontece — e o aviso traz valor, lugar e cartão. O Android deixa um app ler as notificações dos outros, se a pessoa liberar numa tela do sistema.

Três coisas tornam isto delicado:

- **O leitor enxerga tudo.** Conversa, código de acesso, e-mail. O Cajui só pode olhar para os bancos.
- **Lançar sem conferir** contradiz a RN-795 (nada vira lançamento sem um toque) e a RN-796 (não existe categoria de reserva). O dono decidiu que, aqui, o Desfazer e a revisão de domingo fazem o papel da conferência.
- **O registro cifrado tem um escritor só** (ADR-004): as linhas são encadeadas por hash, e o estado vive na memória de quem abriu. Com o app fechado, quem lê a notificação é outro motor do Flutter — e dois motores gravando juntos quebrariam a cadeia.

## Decisão

1. **Lista fechada de bancos.** O leitor (`BankNotificationListener`) descarta, sem ler, o que não vem de um pacote da lista: Nubank, Mercado Pago, Neon, PicPay, Inter, Itaú, Caixa (e Caixa Tem), Banco do Brasil, Santander, C6, Bradesco, Google Wallet e Samsung Wallet. A lista mora no domínio (`BankApp`) e em `BankApps.kt`; um teste do app confere que são a mesma.
2. **O domínio lê, o Android só entrega.** Do lado nativo saem pacote, título, texto (o expandido, quando há) e a hora. A leitura é do domínio (`BankNotificationParser`), em Dart puro e testada com textos fictícios de cada banco: devolve a movimentação — compra no crédito ou no débito, Pix enviado ou recebido, boleto pago, transferência enviada ou recebida — com valor, com quem foi, os quatro dígitos do cartão e as parcelas; ou `null`. **Na dúvida, `null`**: propaganda, saldo, fatura (inclusive o pagamento dela, que não é gasto — RN-340), código de acesso, alerta de limite, compra negada, estorno, agendamento.
3. **O que lança sozinho (RN-786):** compra no débito, Pix e transferência enviados, boleto pago, e compra no crédito quando o cartão é inequívoco — o nome do cartão cadastrado traz os quatro dígitos da notificação, ou é o único com o nome do banco que avisou (RN-789). A categoria sai do mesmo classificador da captura, com as regras aprendidas, e da IA do servidor quando há chave (com 12 segundos de teto; depois, as regras). Sem palpite, Outros. A origem do lançamento é `notification`, e o aviso diz "Lancei R$ 45,90 em Mercado Bom Preço — Mercado · Roxinho" com o botão **Desfazer**.
4. **O que pede um toque (RN-788):** dinheiro que entrou (nunca é despesa), compra no crédito sem cartão reconhecível e compra parcelada (as parcelas saem do cartão e de quem confirma — RN-311). O aviso diz "Entrou R$ 150,00 de Fulano. Toque para registrar", e o toque entrega ao app um **texto compartilhado** montado no formato que as regras do comprovante já leem: abre a conferência de sempre, que já sabe levar Pix recebido à tela de recebimento.
5. **O que fica quieto:** a mesma notificação de novo (a chave do lançamento é derivada dela, e o lado nativo ainda guarda as 300 últimas já vistas); o que já está no livro com o mesmo valor no mesmo dia — o comprovante também compartilhado, ou a carteira e o banco avisando a mesma compra; e a carteira cujo cartão nem os dígitos identificam: quem lança é o aviso do próprio banco, que chega junto.
6. **Uma fila só, em arquivo.** O leitor grava cada aviso em `bank-notices/queue.jsonl`, na pasta privada do app; o Desfazer entra na mesma fila, depois do lançamento que desfaz. Um item só sai depois que o Dart diz que tratou: se o processo cair no meio, ele volta na próxima vez, e a chave derivada impede o lançamento duplo. O texto fica em claro só enquanto espera; depois de tratado, o que sobra é o lançamento, no registro cifrado.
7. **Um escritor por vez.** O `NoticeRouter`, na thread principal, decide: com o app aberto, avisa o motor dele pelo canal `app.cajui/notifications`; fechado, sobe um motor sem janela que roda `notificationMain` (em `main.dart`) com a mesma raiz de composição, trata a fila, atualiza o widget e avisa que terminou. Se o app abre no meio, a rodada é avisada para parar na próxima notificação, e o app **espera** ela terminar antes de abrir o registro (`BackgroundRun.waitIdle`, até 15 s); a rodada que não parar em 8 s é encerrada — a linha pela metade é cortada na próxima abertura, e o item é tratado pelo app. Uma rodada dura no máximo 60 s, e a que termina com itens sobrando tenta uma vez mais, e só.
8. **Ligar é dar o acesso.** Não há chave própria: a linha "Lançar pelas notificações do banco", em Ajustes, diz em uma frase o que acontece e se está ligado, e o toque pede a permissão de postar (Android 13 em diante) e abre a tela do sistema já no Cajui.
9. **O widget da tela inicial** mostra "Pode gastar esta semana" com o que resta na semana (RN-642) — o mesmo número do painel —, uma frase, e os botões de câmera e galeria, que abrem o app direto no caminho de sempre (ADR-017). O Dart publica um retrato pronto, em texto, pelo canal `app.cajui/home` sempre que o livro muda; o lado nativo só desenha. **Um provider só** (`homeSnapshotProvider`) diz de onde sai o número: o `homeViewProvider` do Início, no modelo da planilha (ADR-023); sem plano, o widget mostra o que já saiu. Passada a semana do número, o widget pede para abrir o app em vez de mostrar o limite da semana passada.
10. **O aviso de domingo (RN-870)**, perto das 10h, por alarme **inexato** — sem permissão de alarme exato, remarcado a cada publicação, ao disparar e quando o celular reinicia. Conta, no retrato publicado, os dias dos gastos dos últimos sete dias em Outros ou lançados pela notificação e ainda não revistos; sem nenhum, nenhum aviso. O toque abre a **revisão da semana** (RN-849): cada gasto com as categorias a um toque, e "Está tudo certo" para o resto (RN-871). O revisto fica só no aparelho, num fato `review.done` que o livro não lê e a sincronização não sobe.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Ler a notificação no Kotlin e lançar de lá | Duas cópias das regras do domínio, e um segundo escritor no registro cifrado |
| Motor do Flutter sempre vivo em segundo plano | Bateria e memória o tempo todo para um aviso que chega algumas vezes por dia |
| Pedir um toque em toda notificação | É o fluxo de hoje com um passo a menos; o dono pediu "sem abrir o app" |
| Lançar também o dinheiro que entrou | Salário que entra como avulso dobra a renda do mês; a tela de recebimento já pergunta isso |
| Ler todos os apps e filtrar pelo texto | O leitor veria conversas e códigos; lista fechada é a única forma de não ver |
| Alarme exato no domingo | Exige permissão especial e acorda o celular só para isso; minutos a mais não importam |

## Consequências

- **Bom:** o gasto do cartão e do Pix entra sozinho, na hora, com a categoria aprendida; o widget responde "quanto ainda dá" sem abrir o app; o domingo fecha a semana em um minuto.
- **Custo:** uma exceção às RN-795 e RN-796, aceita pelo dono: o lançamento automático não passou pela conferência, e o que não tem palpite cai em Outros. O Desfazer e a revisão de domingo são a rede.
- **Custo:** cada banco escreve de um jeito, e muda sem avisar. O leitor cobre os formatos conhecidos; o que ele não reconhece não vira nada — a pessoa lança como antes.
- **Custo:** transferência entre contas da própria pessoa entra como gasto (a notificação não diz que a conta é dela). O Desfazer resolve na hora; a revisão de domingo a traz de volta.
- **Custo:** o widget mostra o limite da semana na tela inicial, à vista de quem pegar o celular desbloqueado. Sem o valor do que passou do limite, e o dono pediu o número ali.
- **Custo:** a abertura do app pode esperar uma rodada em segundo plano terminar — segundos, no pior caso.

## Como se confere

- Testes do domínio: compra no crédito e no débito, Pix e transferência enviados e recebidos e boleto, nos formatos de cada um dos 13 apps; o que não é movimentação não vira nada; o limite que vem antes do valor não é o valor; o nome do cartão diz o banco.
- Testes do app: a compra no cartão do banco que avisou entra sozinha, com origem `notification`, e o aviso traz Desfazer; a mesma notificação duas vezes lança uma vez; Desfazer cancela e a repetição não volta; Pix enviado cai em Outros; débito e boleto vão para as formas certas; o que já está no livro não lança; fatura não lança e sai da fila; pedido de parar deixa o resto na fila; Pix recebido pede um toque e o texto abre a tela de recebimento; compra sem cartão e parcelada pedem um toque; carteira e banco avisando a mesma compra lançam uma vez; a carteira com os dígitos no nome do cartão lança no cartão certo; o item ilegível sai da fila; a lista de bancos é a mesma dos dois lados; o retrato do widget dá o mesmo limite do painel (410,00 × 7 ÷ 17 = 168,82) e não atravessa o canal repetido; a revisão traz os sete dias certos, corrige em um toque, confirma sem gravar e fecha com "Está tudo certo"; a linha de Ajustes diz se está ligado.
- Kotlin: compila (`gradlew compileDebugKotlin`). **Não foi rodado em aparelho**: leitor de notificações, motor sem janela, widget e alarme só se conferem no celular, com notificações de verdade dos bancos.

**Revisão de 11/10/2026:** com a saída do limite semanal (ADR-023, revisão), o widget passou a mostrar o número do mês: a sobra; sem plano, o que já saiu; e, no mês que não fecha, o que sai do bolso, nunca o valor da falta (RN-872 revista).
