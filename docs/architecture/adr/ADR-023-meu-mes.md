# ADR-023 — Meu mês: o modelo da planilha do dono

**Estado:** aceita · 11/10/2026 — por pedido do dono ("resolvi simplificar o controle", com as regras e a planilha `Controle_Financeiro_Simples.xlsx`)
**Substitui:** o orçamento por faixas mínimo/máximo, os ajustes possíveis e o fechamento manual do mês (RN-420 a RN-443, RN-620 a RN-663 no que falam de faixa, folga e fechamento). As regras novas estão em [meu-mes.md](../../spec/rules/meu-mes.md), RN-1000 a RN-1060
**Relacionada:** [ADR-019](ADR-019-dois-aparelhos-um-livro.md) (os fatos que atravessam aparelhos) · [ADR-021](ADR-021-assistente-que-age.md) (o assistente recebe os números prontos)

## Contexto

Depois de um mês de uso, o dono achou o app difícil: faixas de mínimo e máximo, folga, ajustes e um botão de fechar o mês. A planilha que ele usa é bem mais simples, e é ela que ele quer no app: uma lista do que sai todo mês, em quatro grupos; os salários da casa e o vale; o dízimo; e quatro números — sobrou ou faltou, pode gastar por semana, já está gasto, quanto ainda devo.

## Decisão

1. **Os quatro grupos são o `Block`**, que ganhou `subscription` somando. Os nomes guardados nos eventos (`fixed`, `variable`, `debt`) não mudam: "Dia a dia" continua `variable` por dentro. Uma linha de conta usa `LineGroup`, que não tem o valor de dívida: parcela vem da dívida e nunca é digitada, e o tipo impede o contrário.
2. **"Minhas contas" é uma lista de `BudgetLine`**: o que é, quanto, grupo, categoria, onde se paga, observação. Não há mínimo e máximo: a estimativa já é a maior, como a planilha manda.
3. **Em cada categoria conta o maior entre o previsto e o gasto.** É o "use o maior" da planilha, que o modelo antigo já fazia nos variáveis, agora em todos os grupos.
4. **O plano é `BudgetPlan`**: salários (um `IncomeSource` por pessoa), vale do mês, dízimo em centésimos de por cento e as linhas. Não é obrigatório. O plano antigo (`MonthSetup`) é lido como o novo, sem migração escrita no registro.
5. **As contas da planilha moram em `MonthBudget`**, e um agregado `Finances` monta o mês, a semana, o uso dos cartões, as dívidas e o histórico a partir dos fatos. O app e o servidor chamam o mesmo agregado; ninguém fora do domínio faz conta.
6. **O vale do mês** é o crédito de vale registrado no mês, ou o do plano quando não há. O saldo que passa de um mês para outro continua na tela do vale, mas não entra na conta do mês, como na planilha.
7. **Dívida pelo calendário.** O saldo cai a cada vencimento: na parcelada, pelo maior entre as parcelas informadas no cadastro e as vencidas; na de saldo informado (conta atrasada, rotativo), uma parcela a cada vencimento depois do dia informado. Entrou o tipo `overdueBill` (conta atrasada), somando aos nomes de sempre, e a ordem de quitação é uma lista de identificadores.
8. **Mês a mês é calculado**, nunca fechado: cada mês com o plano que valia nele. O evento `month.closed` continua sendo lido de quem ainda o manda, mas o app deixa de escrevê-lo.
9. **Cartão no mês** é a pergunta simples da planilha — quanto passei neste cartão este mês —, com aviso a 50% e 80% do limite. O "tomado" do banco (RN-305) continua existindo na tela da fatura.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Um enum novo de grupos ao lado do `Block` | Dois nomes para a mesma coisa; e trocar o `Block` quebraria a releitura dos eventos guardados no servidor |
| Uma linha de conta para cada categoria | Juntaria coisas que a pessoa separa (Claude e Gemini são duas linhas, a mesma categoria) |
| Somar o saldo do vale que vem do mês anterior | A planilha não soma, e a conta fica mais difícil de explicar do que o ganho |
| Gravar o histórico ao virar o mês | Um lançamento atrasado deixaria o número velho; calcular sempre é mais simples e sempre certo |

## Consequências

- **Bom:** os números da tela são os da planilha que o dono já entende; o app funciona sem plano; não há botão de fechar mês.
- **Custo:** o histórico dos meses já fechados pode mudar em relação ao número congelado antes, porque a conta agora inclui as contas previstas; o app nunca mostra os dois.
- **Custo:** a semana soma dinheiro e vale num número só, como a planilha; a tela mostra junto quanto dele é vale, para as moedas nunca se misturarem na mão da pessoa (RN-111).

## Como se confere

- Testes do domínio com uma casa inventada na estrutura da planilha: o mês inteiro (RN-1010 a RN-1017), a identidade "limite × 4 = sobra + dia a dia", o mês que falta, o dízimo zero, o vale que cobre só a comida, o maior entre previsto e gasto, juros como dia a dia, pagamento ligado à dívida que não conta duas vezes, salário recebido e entrada avulsa, vale creditado, a semana, os avisos do cartão por centavos, a dívida pelo calendário nos dois jeitos, os tipos, a ordem, quanto ainda devo, o mês a mês com o plano de cada mês, a sugestão depois de 30 dias e a leitura do plano antigo.

## Revisão de 11/10/2026: o "pode gastar por semana" saiu

No mesmo dia, depois de usar, o dono pediu: "aquele item de quanto eu posso gastar na semana retire, na prática eu não uso e nem é útil pra mim".

Saiu tudo:
- do Início, o pote, que mostrava esse número;
- do alto da Juju;
- do widget, que passou a mostrar a sobra do mês (RN-872 revista);
- do Meu mês, a linha da semana;
- do formulário de lançamento, a linha "resta na semana";
- do contexto da Juju (prompt v7);
- do domínio: `WeekAllowance`, `MonthBudget.weeklyLimit`, `weeklyVoucher` e `Finances.weekOf`.

Com ele saíram os indicadores semanais antigos, que já não tinham tela (`WeeklyLimit`, `BudgetWeek`), e os resumos do dia e da semana. A identidade "limite × 4 = sobra + dia a dia" deixa de existir. A RN-1015 e a RN-1018 ficam revogadas, e a pergunta do BL-086 (÷4 em mês de 5 semanas) perde o objeto.

O número principal passa a ser o do mês: a sobra, ou quanto falta para fechar.
