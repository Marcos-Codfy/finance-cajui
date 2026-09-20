# ADR-012 — Funcionar sem rede

- **Estado:** proposta · aguarda o checkpoint da Fase 4
- **Data:** 2026-09-20

## Contexto

O Cajui é usado no caixa do mercado, no ônibus, onde o sinal é ruim. A RNF-PERF-10 é direta: **painel, listas e captura funcionam sem rede**, e abrir o app ou lançar não faz nenhuma chamada de rede no caminho. Ao mesmo tempo, o servidor é a fonte da verdade, e a web lê de lá. O servidor é gratuito — vai cair de vez em quando ([ADR-011](ADR-011-hospedagem-a-custo-zero.md)).

## Decisão

### No Android: ler do aparelho, escrever numa fila

1. **Leitura local primeiro.** O app guarda a última cópia do que mostra — o resumo do mês, os lançamentos recentes, faturas e dívidas — e abre a partir dela. A atualização vem depois, em segundo plano, e a tela diz de quando é a cópia quando está sem rede.
2. **Escrita por fila de comandos** (*outbox*). Lançar, editar e confirmar geram um comando com **chave de idempotência** (um UUID criado no aparelho), gravado na fila antes de qualquer tentativa de envio. A tela já reflete o comando, marcado como "ainda não enviado".
3. **As regras rodam no aparelho**, pelo domínio compartilhado ([ADR-001](ADR-001-monorepo-e-dominio-compartilhado.md)): o limite da semana muda na hora, sem esperar o servidor. O servidor valida de novo ao receber.
4. **Envio**: em ordem, com recuo exponencial (2 s, 4 s, 8 s… até 5 min) e ao voltar a conexão. Comando repetido com a mesma chave é reconhecido e respondido sem duplicar.
5. **Rejeição** (`E-SYNC-01`): o comando sai da fila e vai para "Para conferir", com o motivo. **Conflito** (`E-SYNC-02`): o app relê o estado e mostra as duas versões. Nada some em silêncio.
6. **Captura sem rede**: o OCR é local; a classificação usa as regras locais; o lançamento entra na fila. A IA não é pré-requisito.
7. **Armazenamento**: arquivos JSON cifrados com o mesmo envelope do servidor ([ADR-005](ADR-005-criptografia-em-repouso-e-dbtool.md)), com a chave no Android Keystore, atrás de duas portas: `LocalSnapshotStore` e `Outbox`. A fila atravessa atualização do app sem perda (RNF-COMPAT-05).

### Na web: só com rede

A web de consulta não guarda nada no navegador — nem dado, nem sessão em disco. Sem rede, mostra `E-NET-01`. É o preço de não deixar dado financeiro num computador que pode não ser do dono.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Só online | Inviabiliza o uso na rua e amarra o app à disponibilidade de um servidor gratuito |
| Sincronização por estado (mandar o resultado, não o comando) | Conflito vira sobrescrita silenciosa. Comando com intenção ("lançar R$ 38,40") casa com o registro de eventos e deixa o servidor decidir |
| CRDT ou sincronização de banco pronta | Resolve concorrência entre muitos escritores. Aqui há um usuário e, na prática, um aparelho: complexidade sem problema |
| SQLite no aparelho (drift) | Bom banco, mas seria uma segunda tecnologia de persistência para os mesmos dados pequenos, com sua própria migração. O volume local é de um mês de uma pessoa; arquivos atrás de portas bastam, e a troca continua possível |
| Guardar dados no navegador para a web funcionar offline | Dado financeiro em armazenamento que qualquer script da página lê, num computador compartilhável |

## Consequências

- **Bom:** zero chamadas de rede para abrir o app e para lançar; o servidor fora do ar atrasa a sincronização, não o uso.
- **Bom:** a chave de idempotência torna a nova tentativa segura — inclusive depois de uma queda entre enviar e receber a resposta.
- **Custo:** o app mostra, por alguns instantes, um estado que o servidor ainda não confirmou. A interface é honesta sobre isso: o item pendente é marcado, e a fila é visível (RNF-REL-03).
- **Custo:** toda regra que roda no aparelho roda de novo no servidor, e os dois têm de concordar — o que o domínio único garante por construção.
- **Limite:** dois aparelhos editando o mesmo lançamento offline caem no conflito e pedem escolha manual. Aceitável para um usuário.

## Como se confere

- Teste: 20 comandos na fila, atualização do app no meio, nenhum perdido (RNF-COMPAT-05).
- Teste: resposta perdida depois do envio → nova tentativa → um único evento no servidor.
- Teste: modo avião do começo ao fim de uma captura — abre, lê, classifica por regra, entra na fila.
