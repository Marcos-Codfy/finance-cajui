# ADR-003 — Backend em Dart com Shelf, como executável único

- **Estado:** aceita em 2026-09-20, no checkpoint da Fase 4
- **Data:** 2026-09-20
- **Medido em:** [spike B](../spikes/server-arm64.md)

## Contexto

O backend existe por três motivos: guardar a fonte da verdade fora do aparelho, esconder a chave da IA e servir a web de consulta. Atende **uma pessoa**. Roda numa VM ARM gratuita, e o custo fixo do projeto é R$ 0. A [ADR-001](ADR-001-monorepo-e-dominio-compartilhado.md) exige que ele rode o mesmo domínio do app.

## Decisão

1. **Dart + Shelf**, compilado com `dart compile exe` para `linux/arm64` **a partir da máquina de desenvolvimento**. Na VM entra só o executável.
2. O servidor é uma composição explícita: `Pipeline` de middlewares (identificador da requisição · limite de taxa · autenticação · tradução de falha em resposta · registro sem dado financeiro) e um `Router` por feature.
3. Roda como **serviço do systemd**, sem privilégio, escutando só em `127.0.0.1`. Quem recebe a internet é o Caddy ([ADR-011](ADR-011-hospedagem-a-custo-zero.md)).
4. Toda rota vive sob `/v1`. O servidor reconhece app antigo demais e responde `E-REQ-03` (RNF-COMPAT-05).

## O que o spike mediu

| Medida | Valor |
|---|---|
| Compilação para linux/arm64, do Windows | 6,4 s |
| Executável | 6,9 MiB (2,8 MiB comprimido) |
| Execução em contêiner arm64 | Rotas respondendo, inclusive o erro no formato do catálogo |
| Memória em repouso | 20 MiB |

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Dart Frog | Bom, mas acrescenta gerador de código e roteamento por arquivo sobre o mesmo Shelf. Com uma dúzia de rotas, a composição à mão é mais legível e tem uma dependência a menos |
| Serverpod | Traz ORM, gerador e exige PostgreSQL. Pesado para uma pessoa e incompatível com a persistência em arquivo ([ADR-004](ADR-004-registro-de-eventos-em-json.md)) |
| Go ou Node | Perde-se o domínio compartilhado, que é o motivo de existir um monorepo |
| Sem backend: tudo no aparelho, com sincronização por arquivo | A chave da IA teria de ir para o app (proibido), e a web de consulta não teria de onde ler |
| Funções sem servidor (Vercel, Cloudflare) | Não rodam Dart AOT, e o registro de eventos em arquivo precisa de disco e de um único escritor |

## Consequências

- **Bom:** deploy é copiar um arquivo e reiniciar o serviço. Sem SDK, sem gerenciador de pacotes e sem etapa de build no servidor: menos superfície de ataque e de manutenção.
- **Bom:** a contingência para VM x86 é o mesmo comando com outra arquitetura.
- **Custo:** o executável depende de **glibc** — a imagem da VM é Ubuntu, Debian ou Oracle Linux, nunca Alpine. Entra no runbook.
- **Custo:** Shelf não dá nada pronto além do básico. Limite de taxa, validação de esquema e tradução de erro são código nosso — pequeno, testado e sem mágica.
- **Em aberto:** desempenho real em ARM. A execução do spike foi emulada; latência e vazão são medidas na Fase 7, na VM.

## Como se confere

- Teste de integração sobe o `Pipeline` inteiro em memória e exercita cada rota, inclusive os erros do catálogo.
- `scripts/deploy.sh` confere o cabeçalho ELF do binário antes de enviar, para nunca subir a arquitetura errada.
