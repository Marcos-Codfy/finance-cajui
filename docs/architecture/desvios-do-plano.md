# O que mudou em relação ao plano original

O plano mestre foi aprovado em 19/09/2026, antes de uma linha de código. Este documento registra, **um a um, onde a execução se afastou dele** — e por quê. Um plano que não muda ao encontrar a realidade não foi testado por ela; o que importa é que cada desvio esteja escrito, com a medição ou o motivo que o causou.

A regra de leitura: "o plano dizia" é o texto de 19/09; "o que existe" é o estado do repositório em 27/09/2026.

## Infraestrutura

| # | O plano dizia | O que existe | Por quê |
|---|---|---|---|
| 1 | VM **ARM** (Ampere A1, 4 GB) do nível gratuito da Oracle, com o servidor compilado para `linux/arm64` (ADR-003, ADR-011, spike B) | VM **x86** `VM.Standard.E2.1.Micro` (AMD, 1 GB), servidor compilado para `linux-x64` pela esteira | A A1 deu "out of host capacity" na criação, exatamente o risco 7 do plano. O servidor usa ~20 MB de memória; a micro sobra. O spike B continua válido se um dia houver vaga Arm — o binário é o mesmo código, só outro alvo |
| 2 | A web na **mesma origem** do backend, por reescrita de `/api/*` na Vercel (ADR-011); sessão web em cookie `HttpOnly` (ADR-008) | A web em `cajui-teal.vercel.app` fala **direto** com `api.cajui.example`, em outra origem; o `vercel.json` só tem cabeçalhos, sem reescrita. A sessão web é um **token em memória**, não cookie | O `vercel.json` publicado nunca teve a reescrita, e o motivo não ficou registrado. **E até 27/09 nenhuma chamada da web chegava ao servidor**: ele não respondia o cabeçalho de origem cruzada, e o navegador bloqueava tudo. Ninguém notou porque a web nunca tinha sido pareada — o teste com a digital é pendência do dono. Corrigido no mesmo dia (`Cors.allow`, só para a origem da Vercel), com teste |
| 3 | Subdomínio `cajui-app.vercel.app` | `cajui-teal.vercel.app` | A Vercel atribuiu o nome; não vale o trabalho de trocar num app de uso pessoal |
| 4 | **Backup cifrado com `age`** saindo da máquina para o armazenamento de objetos (ADR-005, ADR-011) | O backup é o registro já cifrado, sem a chave, e sai da VM por dois caminhos: o computador do dono **vem buscar** por SSH, e a VM envia ao balde por um **endereço de escrita** quando o dono o cria. Sem `age`, sem CLI da Oracle, sem chave de API | A chave de API dava à VM poder demais para o que ela precisa fazer, e pedia ao dono operar o console de identidade. O endereço de escrita só grava; e buscar pelo computador não cria nada na Oracle. Descoberto no caminho: a chave dos dados estava **presa à VM** e o dono nunca tinha recebido cópia — o backup não restauraria |
| 5 | **APK assinado** na Fase 7 | APK **de uso** (`scripts/apk.ps1 -Release`), só 64 bits, assinado pela chave de depuração do computador do dono; o número da versão é o tempo, para o Android sempre aceitar instalar por cima | A chave de publicação ainda não foi criada. Para uso pessoal, instalando pelo arquivo, não faz diferença; faria para publicar. Até 29/09 só existia o APK de depuração, de 200 MB — e o de uso **sairia sem permissão de internet**, que só os manifestos de depuração declaravam |
| 6 | Alerta do dono via orçamento da Oracle, custo R$ 0 | Igual: orçamento de R$ 5 com alertas, custo R$ 0,00 até agora; DeepSeek com US$ 2,00 de crédito pré-pago | — |

## Sincronização e dados

| # | O plano dizia | O que existe | Por quê |
|---|---|---|---|
| 7 | Android **online-first com fila de comandos** (*outbox*) idempotentes; `E-SYNC-01` para rejeição, `E-SYNC-02` para conflito com escolha manual (ADR-012) | O aparelho grava no **próprio registro de eventos cifrado** (o mesmo `packages/persistence` do servidor) e o `LedgerSync` **compara com o servidor** a cada subida, mandando a diferença — sem fila e sem marcador de "já enviei": *o servidor é o marcador* | A fila duplicava o que o registro de eventos já é. Comparar com o servidor faz um servidor restaurado de backup se completar sozinho e um aparelho reinstalado não duplicar nada. `E-SYNC-02` ficou no catálogo sem produtor |
| 8 | **Um aparelho de uso**; "há um usuário e, na prática, um aparelho" (ADR-012) | **Dois celulares, um livro** (ADR-019): cada sincronização sobe e depois **desce**; conflito de correção e de plano é decidido pelo **carimbo de edição** — a mais nova vence, chegue quando chegar; cancelamento nunca é desfeito | O dono tem dois celulares e esperava isso desde o começo (BL-062). A escolha manual da ADR-012 nunca foi construída e não se paga para dois aparelhos da mesma pessoa |
| 9 | Contador de versão por agregado; comando sobre versão velha recebe `E-SYNC-02` (ADR-004, item 5) | Carimbo de edição em UTC (`revisedAt`, `definedAt`), comparado nos dois lados por uma régua só (`EditStamp`) | O contador exige que o aparelho saiba de que versão partiu, e o app não guarda marcador de propósito |
| 10 | Persistência "atrás de portas, para trocar JSON por SQLite" | Igual; nenhum gatilho da ADR-004 foi atingido (41 registros no servidor em 23/09) | — |

## App e captura

| # | O plano dizia | O que existe | Por quê |
|---|---|---|---|
| 11 | Captura por **compartilhamento** de qualquer app, com OCR local | Compartilhamento **e mais dois caminhos que o plano não tinha**: **fotografar** o cupom pela câmera do sistema (ADR-017) e **ditar** a pergunta ao assistente pelo reconhecedor do aparelho (ADR-018) | Pedidos do dono no meio da Fase 6. Os dois seguem o mesmo padrão: o Cajui pede ao Android, não embute o recurso — zero permissão nova, zero áudio ou imagem saindo do aparelho |
| 12 | Spike C: compartilhamento + ML Kit **medidos em aparelho real** antes da Fase 6 | Medido **durante** a Fase 6, no Galaxy S22, pelo caminho de texto; achou um defeito que derrubava o app. O OCR de **imagem** foi conferido em 29/09, no APK de uso, com um comprovante fictício compartilhado da galeria; foto de verdade, PDF de banco e tempo por página continuam sem medição (BL-036) | O aparelho só chegou em 21/09; a implementação seguiu sem esperar, por decisão do dono |
| 13 | A IA classifica **todo** comprovante depois do OCR | A IA só é chamada **com sessão já aberta**; sem sessão, sem rede ou com a IA fora, valem as regras locais (RN-752) | Abrir sessão pede a digital, e pedir a digital no meio de uma conferência é pior do que classificar pelas regras. Depois do primeiro envio do dia a sessão está aberta, então na prática a IA entra |
| 14 | O assistente **responde** sobre o mês | Responde **e aconselha** (prompt v3): diz o que a pessoa pode fazer para o mês fechar e a vida financeira melhorar, sempre citando o número do contexto que sustenta cada conselho; continua sem recomendar produto financeiro (RN-902) | Pedido do dono: "aconselhar com estratégias de engenharia econômica, pessoal e financeira". O limite da RN-902 não mudou |
| 15 | Certificate pinning no Android, nas raízes ISRG (ADR-009) | **Não existe** (BL-047) | Ficou atrás de tudo o que mudava o que a pessoa vê. Sem ele, a proteção é a do TLS comum, que é a mesma de qualquer app |
| 16 | Som **medido**: `flutter_soloud` contra `audioplayers`, decidido na ADR de áudio | `audioplayers` atrás de uma porta, **sem a medição** (BL-009) | A ADR-016 escolheu começar pelo `audioplayers` e trocar se passar de 80 ms no aparelho; a medição nunca foi feita. O som funciona; a latência não foi provada |
| 17 | Toque, som e vibração sempre juntos | Igual — e um defeito de ordem fazia o toggle só soar ao desligar; corrigido em 27/09 | — |

## Qualidade, web e processo

| # | O plano dizia | O que existe | Por quê |
|---|---|---|---|
| 18 | Lighthouse ≥ 90 no preset desktop, ou decidir com o número na mão | Acessibilidade **100**, boas práticas 81, **desempenho 60**, SEO 60 na build de produção; decisão registrada em `docs/ops/lighthouse.md` e na ADR-013 | O TBT de 2,6 s é o motor do Flutter inicializando — o risco número 1 do plano, confirmado. O SEO 60 é escolha (`noindex`). A web é consulta pessoal; trocar a tecnologia da web por nota de auditoria não se justificou |
| 19 | DCM para limites de tamanho | **Verificador próprio** em `tool/code_metrics`, com `package:analyzer`: linhas, aninhamento, um tipo público por arquivo, camadas, `TODO`, cor crua em tela | O DCM virou pago; o plano já previa isso (risco 9). Virou peça de portfólio |
| 20 | Repositório privado com proteção de branch pela esteira | Privado, com esteira — **sem proteção de branch** (BL-022): merge com esteira vermelha passa | O plano gratuito do GitHub não protege branch em repositório privado. Controle compensatório: só se faz merge com a esteira verde, por disciplina |
| 21 | Fase 9: README de portfólio com GIF do app | O `FLAG_SECURE` (T-07) **bloqueia gravar a tela** do app, inclusive para o dono (BL-056) | A saída preferida é gravar a **gallery**, que mostra as mesmas telas sem a trava — e é a peça publicável de qualquer jeito (BL-027). Fica para fazer junto com o dono |
| 22 | Três checkpoints de aprovação (Fases 2, 3, 4) | Cumpridos; depois deles, o dono fixou "siga sozinho e reporte" e um teto de **três agentes**, só quando estratégico | Modo de trabalho combinado no meio do projeto |
| 23 | Fase 7: **APK assinado**, conferido pela esteira | APK de uso assinado pela chave de depuração deste computador, gerado por `scripts/apk.ps1 -Release` e conferido **à mão no aparelho**; a esteira compila só o de desenvolvimento e não abre nenhum (BL-067) | O primeiro APK de uso fechava ao abrir: o R8 removeu os construtores que o ML Kit cria por reflexão, e só a versão encolhida tem o defeito. Nenhum teste do projeto roda o binário encolhido — quem mostrou foi o celular |

## O que o app não faz hoje — restrições declaradas

Para quem vai usar de verdade. Nenhuma delas é escondida na interface.

1. **Só um usuário.** Não há conta, convite nem partilha. Dois celulares, sim; duas pessoas, não.
2. **A web é só consulta.** Lançar, corrigir, cancelar, capturar comprovante e exportar são coisas do celular. A web mostra o mesmo livro e conversa com o assistente.
3. **O que o outro celular fez chega quando este sincroniza** — ao abrir o app, ao voltar do segundo plano, depois de cada lançamento e antes de uma pergunta ao assistente, sempre **com a digital do dia já dada**; ou em Ajustes → Enviar ao servidor. O servidor não empurra nada para o aparelho.
4. **O envio automático depende de o Android ter confirmado quem você é nas últimas 24 horas.** Desbloquear a tela com digital ou senha já conta, então quase sempre tudo sobe e desce sozinho. Quando não conta — desbloqueio só por rosto, por exemplo —, os lançamentos ficam no aparelho e o painel avisa: "O envio automático está parado"; o envio pedido ali confirma a digital e libera o resto do dia. **Aparelho que o servidor não conhece** ouve outra coisa: "Este celular ainda não está cadastrado no servidor", com o caminho para o cadastro.
5. **Correções concorrentes: a mais nova pelo relógio vence.** Celular com hora errada pode ganhar ou perder uma disputa que não devia (ADR-019).
6. **Editar a dívida num celular e pagar parcela dela no outro**, sem sincronizar no meio, deixa a contagem de parcelas diferente nos dois; e dois celulares que fecham o mesmo mês antes de sincronizar ficam cada um com o seu fechamento (BL-066).
7. **Cancelar é definitivo entre aparelhos.** O que um cancelou, o outro cancela na próxima sincronização, e nada o recria.
8. **A IA de comprovante só entra com sessão aberta**; sem ela, valem as regras locais — exatas no que sabem, e sem chute de categoria.
9. **Sem rede, o celular funciona inteiro**; o assistente, não — ele mora no servidor.
10. **O backup sai da VM quando o computador vai buscar** (`scripts/backup-baixar.ps1`), e para o balde da Oracle só depois que o dono criar o endereço de escrita. **Sem a chave dos dados guardada fora da VM, backup nenhum restaura** — guardá-la é um comando que só o dono roda.
11. **APK de uso, por cabo ou cópia manual**, assinado pela chave de depuração deste computador. Não está em loja. Os APKs só se atualizam entre si: o que sair de outra máquina não instala por cima — e aí o caminho é desinstalar, cadastrar de novo e deixar o primeiro envio trazer tudo de volta.
12. **Sem pinning de certificado** (BL-047): a proteção da conexão é o TLS comum.
13. **Preferências são de cada aparelho**: som, vibração e tema não atravessam — de propósito. Comprovante guardado para conferir depois também fica só no aparelho que o recebeu.
14. **Sessão web curta e em memória**: fechar a aba — ou recarregar a página — é sair. Entrar de novo é um código de dois minutos que o celular mostra em Ajustes, Aparelhos com acesso, Abrir no computador.
15. **Um mês por vez nas telas**; os meses fechados existem no livro e ainda não têm lista (BL-044).
16. **Edição de cartão e plano zerado não atravessam** entre os celulares (BL-065). Nenhuma tela edita cartão hoje, então na prática é só o plano zerado.
17. **Os dois celulares precisam do mesmo APK.** Um APK de antes de 27/09 não carimba a correção: o servidor a mantém (`kept`) em silêncio e aquele celular fica divergente até ser atualizado.

## O que não mudou

Custo fixo R$ 0. Android é o app de uso; a web é consulta. **Cartão de crédito é forma de pagamento, nunca despesa; vale alimentação é outra moeda e nunca se soma ao dinheiro** — garantido por tipo, não por disciplina. Domínio em Dart puro, único, testado regra a regra. Registro só de acréscimo, cifrado e encadeado. Nenhum segredo e nenhum dado financeiro real no repositório. Nenhuma assinatura de IA em lugar nenhum. Som desligado por padrão, com controle visível.
