# ADR-029 — Lembretes de vencimento: o domínio escreve, o aparelho marca

**Estado:** aceita · 11/10/2026.

O dono aprovou a sugestão: "as contas fixas já têm dia de vencimento; um aviso na véspera evita multa". As regras de produto já existiam (RN-840 a RN-849); faltava decidir onde cada parte mora.

**Relacionada:**
- [ADR-025](ADR-025-notificacoes-do-banco.md): o aviso de domingo, o alarme inexato e o caminho do toque até a tela, que este lembrete reaproveita.
- [ADR-001](ADR-001-monorepo-e-dominio-compartilhado.md): a conta e as frases moram no domínio.

## Contexto

- O lembrete precisa chegar com o app fechado, às vezes dias depois de o app ter sido aberto pela última vez.
- O texto leva contexto de caixa (RN-841): o valor, a data e o que o mês fica sendo. Essa conta é do domínio, que roda em Dart; o alarme é do Android, que roda em Kotlin.
- O plano da planilha não liga lançamento a conta. Não há um "pago" gravado: é preciso deduzir.

## Decisão

1. **O domínio calcula a lista inteira, já em texto** (`DueReminders.upcoming`): contas com dia, parcelas de dívida e faturas em aberto nos próximos 35 dias, cada uma dois dias antes e no dia, às 9h. O app refaz a lista a cada mudança do livro, do dia ou da chave em Ajustes, e só a lista que mudou atravessa o canal `app.cajui/reminders`.
2. **O Android só guarda, marca e mostra.** A lista vai para as preferências privadas do app. Um único alarme **inexato** é marcado para o próximo lembrete ainda não mostrado, como o de domingo; um receptor próprio o marca de novo depois de reiniciar o celular ou atualizar o app. Não há permissão de alarme exato.
3. **Canal próprio, "Contas a vencer", em prioridade baixa e sem som** (RN-825). A versão pública da notificação não tem nome nem valor: "Uma conta vence sábado, 10" e "Desbloqueie para ver o valor." (RN-843, RN-1085).
4. **O que já foi mostrado fica do lado nativo**, com validade até o fim do dia do vencimento: o mesmo lembrete nunca chega duas vezes, mesmo que o app publique a lista de novo. No mês com falta, o segundo momento de um vencimento já avisado fica em silêncio (RN-846, RN-1086). A cada publicação, sai da bandeja o lembrete que deixou a lista — a conta paga, a chave desligada.
5. **"Pago" é deduzido, e erra para o lado de avisar** (RN-1082 a RN-1084). Conta: o gasto do mês na categoria cobre a linha, pagando as linhas na ordem do vencimento. Parcela: a contagem de pagas alcançou a parcela. Fatura: o calculado menos o que já foi pago dela.
6. **O toque abre a tela do assunto** (RN-1087): a intenção leva `reminder:bills`, `reminder:debts` ou `reminder:cards` e entra no mesmo caminho do aviso de domingo (`NoticeRouter`).

## Alternativas descartadas

- **Calcular no Kotlin:** duplicaria a conta do mês e as frases. Um número diferente do da tela faz desconfiar do app.
- **Alarme exato por lembrete:** pede uma permissão especial e acorda o celular a cada aviso; uns minutos depois das 9h não fazem diferença.
- **Botão "marcar como paga" na conta:** seria mais preciso que deduzir pela categoria, mas é mais uma coisa a lembrar de tocar. O dono pediu simplicidade em 06/10.

## Consequências

- A lista guardada no aparelho tem valores em texto, na área privada do app, como o retrato do widget. `allowBackup` está desligado.
- Conta paga com valor menor que a estimativa da planilha continua lembrada ("na dúvida, lembra").
- O texto vale do jeito que estava na última publicação: lançar algo com o app fechado só muda o lembrete na próxima abertura (BL-101).
- A chave nasce ligada. A permissão de notificar do Android 13 é pedida quando a pessoa liga a chave ou toca na linha que avisa que o Android está segurando as notificações.
