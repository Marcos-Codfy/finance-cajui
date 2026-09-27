# Arquitetura do Cajui

Como o Cajui é construído, e **por quê**. A especificação ([`docs/spec/`](../spec/)) diz o que o sistema faz; o design ([`docs/design/`](../design/)) diz como ele aparece; aqui está como as partes se encaixam. Nenhuma linha do app é escrita antes de a decisão correspondente estar aprovada neste diretório.

## Por onde começar

| Documento | Responde |
|---|---|
| [c4.md](c4.md) | Que partes existem, quem fala com quem, e onde ficam as fronteiras de confiança |
| [spikes/](spikes/) | O que foi **medido** antes de decidir |
| [adr/](adr/) | As 19 decisões, cada uma com contexto, alternativas e consequências |
| [desvios-do-plano.md](desvios-do-plano.md) | Onde a execução se afastou do plano de 19/09, uma a uma, e o que o app **não** faz hoje |

## A arquitetura em um parágrafo

Arquitetura limpa, organizada por feature, em quatro camadas — `domain`, `application`, `infrastructure`, `presentation`. **O domínio é Dart puro e único**: o mesmo pacote roda no aparelho e no servidor, de modo que cada uma das 345 regras tem uma implementação e um teste. No Android, a interface segue MVVM com Riverpod, com um estado selado por tela; o app lê do aparelho e escreve numa fila, então funciona sem rede. O servidor é um executável Dart único, atrás do Caddy, que grava um registro de eventos só de acréscimo, cifrado por registro e encadeado por hash. A IA é acessório: só o backend fala com ela, só sai texto mascarado, e o app funciona inteiro sem ela. A web é o mesmo Flutter, em WebAssembly, só para consulta.

## Padrões em uso — e onde

| Padrão | Onde | Para quê |
|---|---|---|
| Arquitetura limpa, feature-first | Todo o código de produto | A regra de negócio não depende de tela, de rede nem de disco |
| Portas e adaptadores | `EventStore`, `SnapshotStore`, `Outbox`, `ReceiptClassifier`, `Assistant`, `SoundPlayer`, `Clock` | Trocar arquivo por SQLite, DeepSeek por outro fornecedor ou um motor de áudio por outro, sem tocar no domínio |
| MVVM | Só na camada `presentation` | O `Notifier` é o ViewModel; o widget só desenha o estado |
| Event sourcing | Persistência do servidor | História auditável; correção é evento novo |
| Outbox com idempotência | Escrita no Android | Lançar sem rede, e tentar de novo sem duplicar |
| Objetos de valor | `Money` (centavos inteiros), `Tender`, `Cycle` | Dinheiro nunca é `double`; dinheiro e vale nunca se somam, por tipo |
| Estratégia | Classificação de comprovante: regras locais ou IA | O mesmo contrato, com a IA como opção |
| Tipos selados no lugar de exceção | `Result`, `Failure`, estado de tela | O compilador cobra cada erro e cada estado |

## As decisões

| ADR | Decisão | Estado |
|---|---|---|
| [001](adr/ADR-001-monorepo-e-dominio-compartilhado.md) | Monorepo; o domínio é um pacote compartilhado por app e servidor | aceita |
| [002](adr/ADR-002-estado-com-riverpod.md) | Riverpod sem gerador; MVVM só na apresentação; estado selado por tela | aceita |
| [003](adr/ADR-003-backend-dart-shelf.md) | Backend em Dart + Shelf, compilado fora do servidor como executável único | aceita · **medida** |
| [004](adr/ADR-004-registro-de-eventos-em-json.md) | Registro de eventos em JSON Lines, com limites escritos e gatilhos para SQLite | aceita |
| [005](adr/ADR-005-criptografia-em-repouso-e-dbtool.md) | Cifra por registro, `dbtool` para ler por SSH, backup cifrado com chave que não fica no servidor | aceita |
| [006](adr/ADR-006-receber-compartilhamento.md) | Canal nativo próprio para o compartilhamento; copiar o arquivo antes de tudo | aceita · **spike C pode ajustar** |
| [007](adr/ADR-007-ocr-e-pdf.md) | ML Kit embutido; todo PDF é rasterizado e passa pelo mesmo OCR | aceita · **spike C pode ajustar** |
| [008](adr/ADR-008-autenticacao.md) | Sem senha: chave do aparelho liberada por biometria; web pareada por código | aceita |
| [009](adr/ADR-009-fixacao-de-certificado.md) | Fixar as raízes, em Dart; nunca o certificado folha | aceita |
| [010](adr/ADR-010-integracao-com-a-deepseek.md) | IA só pelo backend, texto mascarado, OCR como dado, saída validada, categoria em lista fechada | aceita |
| [011](adr/ADR-011-hospedagem-a-custo-zero.md) | Oracle ARM + Caddy + DNS dinâmico + Vercel com reescrita de `/api/*` | aceita |
| [012](adr/ADR-012-modo-offline.md) | Leitura local e fila de comandos idempotentes no Android; web só com rede | aceita |
| [013](adr/ADR-013-web-de-consulta-e-lighthouse.md) | Web em Flutter Web/WebAssembly; **uma exceção nomeada** na meta de boas práticas | aceita · **medida** |
| [014](adr/ADR-014-lints-e-metricas.md) | Análise estrita, verificador próprio, ganchos e CI em dois ritmos | aceita · em parte já em vigor |
| [015](adr/ADR-015-erros-tipados-e-catalogo.md) | `Result` e `Failure` selados; `ErrorCode` compartilhado; texto de erro num arquivo só | aceita |
| [016](adr/ADR-016-motor-de-audio.md) | `audioplayers` atrás de uma porta, com critério medido para trocar | aceita · **spike C pode ajustar** |
| [017](adr/ADR-017-fotografar-comprovante.md) | Fotografar o cupom pela câmera do sistema, por intenção | aceita |
| [018](adr/ADR-018-ditar-a-pergunta.md) | Ditar a pergunta pelo reconhecedor do aparelho, por intenção | aceita |
| [019](adr/ADR-019-dois-aparelhos-um-livro.md) | Dois aparelhos, um livro: cada sincronização sobe e desce; a edição mais nova vence pelo carimbo; cancelamento nunca é desfeito | aceita · substitui em parte a 012 |

As 16 foram aceitas em 2026-09-20, no checkpoint da Fase 4. Toda ADR nasce como *proposta* e vira *aceita* num checkpoint. Decisão que mudar depois ganha ADR nova, que substitui a antiga — a antiga não é apagada.

## O que os spikes mudaram no plano

| Spike | O plano temia | A medição mostrou | O que mudou |
|---|---|---|---|
| [A · web](spikes/web-lighthouse.md) | Flutter Web não bater 90 no Lighthouse, a ponto de trocar a tecnologia da web | Performance 100, acessibilidade 100, primeiro quadro em 0,28 s — com a semântica ligada. Boas práticas em 81, por uma auditoria do motor | A web fica em Flutter. Entrou uma exceção nomeada (ADR-013). Os sons passaram a carregar sob demanda; o runtime passou a sair da própria origem |
| [B · servidor](spikes/server-arm64.md) | A compilação cruzada para ARM não funcionar a partir do Windows | 6,4 s, 6,9 MiB, rodando em contêiner arm64 com 20 MiB de memória | Nada de SDK no servidor. A VM x86 vira contingência de graça. Novo requisito: imagem com glibc |
| C · Android | Compartilhamento e OCR só se validam em aparelho | **Ainda não medido** | Espera a instalação do Android SDK e um aparelho. Três ADRs ficam como proposta até lá |

Também saíram daqui dois ajustes em requisitos: a **RNF-PERF-06** deixa de prometer 0,5 s por página de PDF com camada de texto (ADR-007: toda página passa pelo OCR, ≤ 2 s); e o orçamento de **fontes da web** continua estourado, em 341 KB contra 200 KB (BL-025).

## Riscos aceitos

| Risco | Por que se aceita | Onde está |
|---|---|---|
| Quem é root na VM lê a chave de dados | Limite de uma VM só, sem cofre de segredos a custo zero. Os backups, esses, não abrem com o que está no servidor | ADR-005 |
| Serviços gratuitos caem ou mudam de regra | O app funciona offline; cada peça é substituível | ADR-011, ADR-012 |
| A Oracle pode recolher VM ociosa | Deploy idempotente e restauração ensaiada; a saída definitiva depende de uma decisão do dono | ADR-011 |
| Mascaramento de dado pessoal tem falso negativo | Sai o mínimo; a tela de privacidade diz isso; a suíte cresce a cada formato novo | ADR-010 |
| Trocar de celular exige SSH na VM | É proteção: quem não administra o servidor não cadastra aparelho | ADR-008 |
| Boas práticas do Lighthouse em 81 | Vem do motor do Flutter; o CI afirma cada auditoria pelo nome | ADR-013 |
| A amostra do spike A é a gallery, não o app | Motor e fontes são 70% do peso e são os mesmos; a medição se repete nas Fases 6 e 7 | Spike A |

## O que falta decidir

| Pergunta | Quem decide | Quando |
|---|---|---|
| Converter a conta da Oracle para pagamento por uso (sem custo, mas com cartão) para escapar do recolhimento por ociosidade | Dono do produto | Antes da Fase 7 |
| Latência do áudio, tempo do OCR e o que cada app de banco compartilha | A medição | Spike C |
