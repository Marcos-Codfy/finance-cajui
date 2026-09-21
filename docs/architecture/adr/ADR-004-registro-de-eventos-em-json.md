# ADR-004 — Persistência em registro de eventos JSON, com porta para SQLite

- **Estado:** aceita em 2026-09-20, no checkpoint da Fase 4
- **Data:** 2026-09-20
- **Responde:** BL-015 (em conjunto com a [ADR-005](ADR-005-criptografia-em-repouso-e-dbtool.md))

## Contexto

O pedido é persistir em JSON, com acesso direto por SSH, sem banco de dados para administrar. O modelo de dados já é de eventos: o registro é só de acréscimo, encadeado por hash, e correção é evento novo ([modelo de dados](../../spec/data-model.md)). O volume é o de uma pessoa: cerca de 120 lançamentos por mês — da ordem de **2 mil eventos por ano**, contando edições, liquidações e ajustes.

Arquivo JSON como banco tem limites reais. Esta ADR os escreve, em vez de fingir que não existem.

## Decisão

1. **Um arquivo JSON Lines por ano** (`events-2026.jsonl`): um evento por linha, só acréscimo. Cada registro traz `seq`, `id`, `type`, `at`, `schema`, `payload` e `prev` — o hash do registro anterior.
2. **Um único escritor**: o processo da API, com uma fila interna que serializa os comandos. Gravar é `append` + `fsync` antes de responder. Não há segundo processo escrevendo; o `dbtool` só lê.
3. **O estado vive em memória**, reconstruído ao subir: carrega o último resumo (snapshot) e reaplica os eventos posteriores. Resumos são gravados por `arquivo temporário + rename`, que é atômico.
4. **O domínio não sabe de nada disso.** Ele fala com duas portas, `EventStore` e `SnapshotStore`. Trocar arquivo por SQLite é escrever dois adaptadores novos, sem tocar em regra.
5. Conflito de escrita é otimista: cada agregado tem versão; comando sobre versão velha recebe `E-SYNC-02`.

## Limites honestos

| Limite | Por que é aceitável aqui | Gatilho para migrar |
|---|---|---|
| Um processo escritor; sem concorrência entre máquinas | Há um usuário e um servidor | Precisar de um segundo processo gravando |
| Subir exige reaplicar eventos | Com resumo mensal, são centenas de eventos, não milhares | Subida acima de **2 s**, medida no CI com 50 mil eventos sintéticos |
| Sem consulta ad hoc: só as projeções que o código mantém | As consultas são conhecidas: mês, fatura, dívidas, resumos | Relatório novo que exija varrer tudo a cada pedido |
| Tudo cabe em memória | 10 anos de uso são da ordem de 20 mil eventos, poucos MB | Arquivo do ano acima de **50 MB** |
| `fsync` a cada comando limita a vazão | Uma pessoa gera poucos comandos por minuto | Não previsto |

Se algum gatilho disparar, o caminho é SQLite (um arquivo, sem servidor), atrás das mesmas portas. O [spike B](../spikes/server-arm64.md) registra o cuidado: a biblioteca nativa precisa existir para arm64.

## Medido na implementação

`packages/persistence/tool/load_benchmark.dart`, no notebook de desenvolvimento, com eventos do tamanho de um lançamento com pagamento dividido:

| Eventos | Equivale a | Conferir a cadeia, sem a chave | Abrir tudo, decifrando | Tamanho |
|---|---|---|---|---|
| 5 mil | cerca de 2,5 anos de uso | 83 ms | 271 ms | 2,6 MiB |
| 50 mil | cerca de 25 anos | 585 ms | **2,4 s** | 25,7 MiB |

O gatilho de 2 s só é tocado com 25 anos de história, e o custo está quase todo em decifrar em Dart puro. A implementação atual decifra o registro inteiro ao abrir, o que é o mais simples e basta por anos; abrir pelo resumo e decifrar só a cauda é o item BL-028, com gatilho mais conservador: **abertura acima de 1 s** — cerca de 20 mil eventos.

## Alternativas consideradas

| Alternativa | Por que não agora |
|---|---|
| SQLite desde o início | Tecnicamente melhor em quase tudo. Perde no pedido explícito (JSON legível por SSH) e acrescenta dependência nativa na compilação cruzada. Fica como destino previsto, não como ponto de partida |
| PostgreSQL | Um serviço a mais para instalar, atualizar, proteger e copiar, numa VM gratuita, para uma pessoa |
| Um JSON único, regravado a cada mudança | Regravar o arquivo inteiro a cada comando: risco de corrupção na queda e custo que cresce com o histórico |
| Banco gerenciado gratuito | Dado financeiro em terceiro, limite de plano que muda sem aviso, e mais uma conta |

## Consequências

- **Bom:** a história inteira é auditável — cada número do painel se explica por eventos. Desfazer é um evento, não uma perda.
- **Bom:** backup é copiar arquivos que só crescem; a cópia de ontem é prefixo da de hoje.
- **Custo:** toda projeção (mês, fatura, dívida) é código e teste nossos. É o mesmo código que roda no app, pelo domínio compartilhado.
- **Custo:** mudar o formato de um evento exige versão (`schema`) e um leitor para as versões antigas. Evento gravado nunca é reescrito.

## Como se confere

- Teste de queda no meio da escrita: processo morto entre `append` e `fsync`; ao subir, a última linha incompleta é detectada e descartada, e a cadeia continua íntegra.
- Teste de carga sintética de 50 mil eventos, com a subida cronometrada — é ele que vigia o gatilho de 2 s.
- `dbtool verify` percorre a cadeia de hash e aponta o registro exato em que ela quebra (`E-DATA-01`).
