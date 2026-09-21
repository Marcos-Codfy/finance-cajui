# Spike B — backend Dart compilado para linux/arm64

**Pergunta.** O servidor de produção é uma VM ARM gratuita da Oracle Cloud; o desenvolvimento é num notebook Windows x64. Dá para gerar, do Windows, o executável que roda lá — sem instalar o SDK do Dart no servidor e sem uma máquina ARM para compilar?

**Resposta curta.** Dá. `dart compile exe` gera o binário de linux/arm64 a partir do Windows em **6 segundos**, e ele **rodou num contêiner arm64**, respondendo às requisições, com **20 MiB de memória**. O deploy vira copiar um arquivo.

## O que foi medido

Um servidor mínimo (`spikes/server-arm64/`): Shelf com roteador, middleware de registro, JSON de entrada e de saída e uma resposta de erro no formato do [catálogo](../../spec/error-catalog.md). Nada do produto — o que se mede é a cadeia de compilação.

```bash
dart compile exe bin/server.dart --target-os linux --target-arch arm64 -o build/server-linux-arm64
```

| Medida | linux/arm64 | linux/x64 |
|---|---|---|
| Tempo de compilação, no notebook Windows | 6,4 s | 5,1 s |
| Tamanho do executável | 6,9 MiB | 7,1 MiB |
| Comprimido (gzip) | 2,8 MiB | — |
| Cabeçalho ELF | 64 bits · AArch64 · PIE | 64 bits · x86-64 · PIE |
| Carregador dinâmico | `/lib/ld-linux-aarch64.so.1` (glibc) | `/lib64/ld-linux-x86-64.so.2` (glibc) |
| Dart | 3.13.4 | 3.13.4 |

### Rodando de verdade

O binário arm64 foi executado num contêiner `debian:stable-slim` com `--platform linux/arm64` (emulação de CPU pelo Docker Desktop), só com o arquivo montado — sem SDK do Dart dentro:

| Conferência | Resultado |
|---|---|
| `uname -m` dentro do contêiner | `aarch64` |
| `GET /v1/health` | `{"status":"ok","os":"linux","dart":"3.13.4"}` |
| `POST /v1/echo` com JSON válido | `200` e o corpo devolvido |
| `POST /v1/echo` com JSON quebrado | `400` com `{"error":{"code":"E-REQ-01",…}}` |
| Memória em repouso | 20 MiB |

## O que isto decide

1. **O backend é um executável único, compilado fora do servidor** (ADR-003). Na VM não entra SDK, gerenciador de pacotes da linguagem nem etapa de build: só o binário, o arquivo de serviço do systemd e o Caddy. Menos coisa instalada é menos coisa para atualizar e para atacar.
2. **O deploy é cópia + troca atômica + reinício** (`scp`, `mv`, `systemctl restart`), o que mantém o `scripts/deploy.sh` idempotente e curto (Fase 7).
3. **A contingência x64 é de graça.** Se a Oracle não tiver capacidade ARM (o erro "out of capacity" é conhecido), o mesmo comando com `--target-arch x64` gera o binário para a VM x86 gratuita. Nenhuma linha de código muda (ADR-011).
4. **20 MiB em repouso** deixam folga enorme mesmo na menor VM gratuita, de 1 GB.

## Limites e cuidados

- **Depende da glibc.** O executável é ligado dinamicamente: roda em Ubuntu, Debian e Oracle Linux; **não roda em Alpine** (musl). A imagem da VM precisa ser uma dessas três — vira requisito do runbook.
- **A execução foi emulada.** Prova que o binário é válido e funciona em userland arm64, mas não mede desempenho: emulação de CPU é várias vezes mais lenta que o hardware. Latência e vazão reais ficam para a Fase 7, na VM de verdade.
- **Compilação cruzada só existe para Linux.** É exatamente o alvo; registrado para ninguém contar com ela para outro sistema.
- **Bibliotecas nativas não foram testadas.** O servidor do spike é Dart puro. Se a persistência migrar para SQLite (a porta prevista na ADR-004), a biblioteca nativa do SQLite precisa existir para arm64 no servidor — conferir naquela hora, não agora.
- O servidor escuta em `127.0.0.1` por padrão e só abre para fora com `HOST` explícito: em produção quem recebe a internet é o proxy reverso.
