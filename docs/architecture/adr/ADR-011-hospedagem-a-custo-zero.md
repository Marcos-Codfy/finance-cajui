# ADR-011 — Hospedagem a custo fixo zero

- **Estado:** proposta · aguarda o checkpoint da Fase 4
- **Data:** 2026-09-20
- **Responde:** BL-007 e BL-014

## Contexto

Projeto pessoal, custo fixo de **R$ 0 por mês**; o único gasto aceito é o consumo da IA. É preciso: uma máquina para o backend com disco persistente, um nome com certificado TLS válido, um lugar para a web estática e um destino para o backup fora da máquina.

## Decisão

| Peça | Escolha | Por quê |
|---|---|---|
| Backend | **VM ARM (Ampere A1) do nível sempre gratuito da Oracle Cloud**, com Ubuntu LTS | Disco persistente, IP público e folga de sobra para um executável de 20 MiB. Ubuntu por causa da glibc ([spike B](../spikes/server-arm64.md)) |
| TLS e proxy | **Caddy** na própria VM | Certificado do Let's Encrypt emitido e renovado sozinho; HSTS e cabeçalhos de segurança num arquivo curto |
| Nome do backend | **DNS dinâmico gratuito** (DuckDNS ou equivalente), apontando para o IP da VM | O Let's Encrypt exige um nome. Sem domínio comprado, é a saída gratuita. O app Android fala com esse nome, com a raiz fixada ([ADR-009](ADR-009-fixacao-de-certificado.md)) |
| Web | **Vercel, plano Hobby**, só arquivos estáticos | Uso pessoal e não comercial cabe no plano; HTTPS e CDN sem configuração |
| Mesma origem | **Reescrita de `/api/*` na Vercel para o backend** | O navegador enxerga uma origem só: o cookie de sessão é de primeira parte ([ADR-008](ADR-008-autenticacao.md)) e não há CORS para configurar nem para errar |
| Backup | **Armazenamento de objetos sempre gratuito da Oracle** + cópia puxada para o computador do dono | Fora do disco da VM, a custo zero. O arquivo sai cifrado com `age` ([ADR-005](ADR-005-criptografia-em-repouso-e-dbtool.md)) |
| APK | Distribuição direta (arquivo assinado), sem loja | Conta de desenvolvedor da loja é paga; o app é de uma pessoa |

## Riscos conhecidos, e o que fazer

| Risco | Resposta |
|---|---|
| **"Out of capacity"** ao criar a VM ARM — comum em regiões cheias | Tentar outra região ou domínio de disponibilidade; persistindo, usar a **VM x86 micro gratuita**. O mesmo comando compila o binário para x64 — provado no spike B |
| **Recolhimento por ociosidade**: a Oracle pode recuperar instância gratuita ociosa | O backend de uma pessoa **é** ocioso. Saída sem custo: converter a conta para pagamento por uso mantendo-se dentro dos limites gratuitos, o que tira a instância da regra de ociosidade. **É decisão do dono**, porque exige cartão cadastrado. Sem isso, o runbook cobre a recriação: o deploy é idempotente e o dado volta do backup |
| DNS dinâmico gratuito sai do ar ou some | O app para de achar o servidor. Os lançamentos ficam na fila offline ([ADR-012](ADR-012-modo-offline.md)); trocar de nome exige APK novo. Alternativa paga, e **não recomendada agora**: domínio próprio |
| A Vercel muda o plano gratuito | A web é um punhado de arquivos estáticos; serve de qualquer lugar, inclusive do próprio Caddy. A reescrita vira uma regra de proxy |
| Oracle guarda a VM **e** o backup: a mesma conta é ponto único de falha | Por isso a segunda cópia no computador do dono, puxada por script semanal |
| A reescrita da Vercel vê o tráfego da API da web | O tráfego é HTTPS nas duas pernas, mas termina na Vercel. Aceito para o modo consulta, que só lê agregados. **O app Android não passa pela Vercel**: fala direto com o backend |

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Plataformas gratuitas de contêiner (Render, Fly.io, Railway) | Planos gratuitos sem disco persistente, que dormem ou que acabaram. O registro de eventos precisa de disco e de processo sempre no ar |
| Servir a web do próprio Caddy | Funciona, e é o plano B. A Vercel entra pelo CDN, pelo deploy a cada `push` e por manter a VM fora do caminho crítico da página |
| CORS restrito em vez de reescrita | O cookie viraria de terceiros — que os navegadores bloqueiam cada vez mais — e a configuração de CORS é fonte clássica de falha de segurança |
| Túnel (Cloudflare Tunnel e similares) | Esconde o IP e dispensa DNS dinâmico, mas põe mais um terceiro no caminho de dado financeiro e exige domínio na Cloudflare |
| Domínio `.app` próprio | Resolveria o DNS de vez, por cerca de US$ 15 a 20 por ano. Fora do R$ 0; fica como melhoria opcional |

## Consequências

- **Bom:** custo fixo zero, com cada peça substituível sem reescrever código.
- **Custo:** a disponibilidade é a de serviços gratuitos. O desenho absorve isso: o app funciona offline e a fila sobe quando o servidor volta.
- **Custo:** três contas para manter (Oracle, Vercel, DNS). O runbook da Fase 7 lista cada uma, o que ela guarda e como se recupera o acesso.

## Como se confere

- Fase 7: `scripts/deploy.sh` rodado duas vezes seguidas sem efeito colateral; restauração de backup numa VM limpa; teste de fumaça depois do deploy.
- A medição do Lighthouse é repetida contra o endereço publicado.
