# ADR-024 — Sincronia ao vivo entre aparelhos, cadastro que atravessa e só a chave da casa

**Estado:** aceita · 11/10/2026 — por pedido do dono ("o app ficou difícil de usar"; "app pessoal, segurança demais atrapalha, faça só o básico bem feito"; a assistente passa a se chamar Juju)
**Substitui em parte:** [ADR-019](ADR-019-dois-aparelhos-um-livro.md) no que diz sobre **quando** a sincronização acontece e sobre o cartão só atravessar uma vez; [ADR-020](ADR-020-chave-da-casa.md) no que mantinha a autenticação antiga viva até os celulares serem atualizados
**Relacionada:** [ADR-008](ADR-008-autenticacao.md) (a autenticação por aparelho, agora apagada do código) · [ADR-021](ADR-021-assistente-que-age.md) (a assistente, que muda de nome)

## Contexto

Três coisas atrapalhavam o uso de verdade.

1. **O que um celular lançava, o outro não via.** O celular subia o livro a cada gravação, mas só **descia** ao abrir, ao voltar ao app e em volta de uma pergunta à assistente. A web lia o servidor uma vez, ao abrir. Lançar no Poco e olhar o S22 em cima da mesa mostrava o mês de antes.
2. **Editar um cartão não chegava ao outro celular — e sem erro nenhum.** O servidor gravava o cartão com a chave `card-<id>`; a segunda versão voltava como repetida e era descartada. A subida só mandava cartão que o servidor não conhecia, e a descida só trazia cartão que o aparelho não tinha (BL-065, letra a). O mesmo valia para a categoria reagrupada numa versão nova do app, gravada com a chave `category-<id>`.
3. **A autenticação antiga continuava no código** — cadastro por código, desafio assinado, sessão de 15 minutos, código da web, a digital no Kotlin —, sem ninguém a usar desde a chave da casa (BL-069, BL-070). Código de segurança que não é exercitado é o que apodrece primeiro.

## Decisão

### Sincronia ao vivo

1. **O servidor diz, num número, se o livro mudou.** `GET /v1/head` passa a responder `{seq, ledgerSeq}`: o `seq` continua sendo o topo do registro (T-39); o `ledgerSeq` é o `seq` do último evento que **mexe no livro** — categoria, cartão, plano, lançamento, correção, cancelamento, estorno, renda, acerto do vale e os fatos guardados da ADR-019. Uso da IA (`ai.usage_recorded`) e os eventos de aparelho de antes da ADR-020 (`device.*`) não contam: senão cada pergunta à assistente faria todos os aparelhos descerem o livro inteiro. A projeção guarda o **maior** `seq` aplicado, porque o registro devolve o evento antigo quando a chave se repete.
2. **Enquanto o app está na frente, cada aparelho pergunta esse número a cada 20 segundos** (`LiveSync`). Só quando ele anda o livro desce — no celular, pela sincronização de sempre (sobe, depois desce), na **mesma fila** da que acontece depois de cada lançamento (`QuietSync.request`); nunca duas ao mesmo tempo. A pergunta à assistente também passou por essa fila. Na web, o livro é relido **no lugar** (`LedgerReload`), sem voltar ao esqueleto de carregamento.
3. **O número é lido antes de descer**: o que mudar enquanto o livro desce faz o número andar de novo, e a conferência seguinte pega. Descida que falhou não conta como vista. Abrir e voltar ao app no celular sincroniza mesmo sem o número ter andado: é quando sobe o que foi lançado sem rede.
4. **No fundo o relógio para.** Celular no bolso não pergunta nada; ao voltar, pergunta na hora.
5. **A leitura do servidor é inteira ou nenhuma.** Se o plano, o cartão, o que entrou, os estornos ou os fatos não responderem, o retrato inteiro é "não sei": a web não mostra meio livro, e o celular não desce meio livro.

### O cadastro que atravessa

6. **Cada versão de cartão e de categoria leva um carimbo `definedAt`, e vale a mais nova.** A chave do evento no servidor passa a ser `card-<id>-<impressão do conteúdo>` (e `category-…`): uma versão nova grava; a mesma de novo não. O servidor responde `kept` à versão mais velha e à repetida, sem gravar nada, e recusa carimbo mais de 10 minutos à frente do relógio dele (T-40).
7. **Versão sem carimbo — gravada antes desta decisão — conta como a mais velha.** Entre duas sem carimbo, vale a do servidor: dois celulares com versões velhas diferentes não ficam trocando uma pela outra, porque versão sem carimbo nunca sobe por cima de nada.
8. **O carimbo de uma edição nunca é anterior ao da versão que o aparelho já tem.** Quem edita depois de ver a edição do outro está respondendo a ela; com o relógio uns minutos atrasado, a edição sumiria da tela no ato (BL-064). Edições de fato simultâneas continuam decididas pelos relógios.
9. **A projeção segue a mesma regra**, no servidor e no aparelho: reler o registro, onde a versão do outro celular pode ter sido gravada antes da daqui, chega ao mesmo cartão.
10. **As categorias nascem do código**, então o carimbo delas é o do cadastro de fábrica (`CatalogStamp`). Quem muda uma categoria de lugar sobe o carimbo junto; um teste guarda o cadastro e reprova a mudança que esquecer. Nenhum nome de enum gravado em evento mudou, e todo evento antigo continua sendo lido.

### Só a chave da casa

11. **App e web entram só com a chave da casa** (ADR-020). Saíram do servidor: as rotas de cadastro, desafio, sessão e código da web; as rotas de aparelhos; o livro de desafios, os códigos de cadastro e da web, o verificador de assinatura, o cadastro de aparelhos e o subcomando `enroll`. Saíram do Android: a assinatura, a caixa da digital (`BiometricGate`), os métodos `sign`/`signQuietly`/`forget` do canal `app.cajui/device` e a dependência `androidx.biometric`; a atividade voltou a ser `FlutterActivity`.
12. **Fica:** o livro de sessões, o escopo só de leitura e o prefixo público `v1/auth/` — o login com código de seis dígitos vai entrar por ali. Hoje nenhuma rota abre sessão, e o servidor sem a chave configurada não deixa ninguém entrar (e diz isso no registro do serviço).
13. **O nome do aparelho** continua saindo da chave pública do par que já estava no Keystore: os celulares do dono mantêm o mesmo nome no servidor. O par novo, de quem instala agora, nasce sem exigir digital — não há o que liberar.
14. **Os eventos `device.enrolled` e `device.revoked` continuam no registro**, e são ignorados ao subir.

### A assistente se chama Juju

15. O nome mora em `AssistantIdentity` e só lá; "Juju, quanto sobrou?" é a mesma pergunta que "quanto sobrou?", e "jujuba" não é o nome. Ela se apresenta como "a Juju". As instruções da IA subiram para a versão 5.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Descer o livro inteiro a cada 20 segundos | São sete leituras por vez, por aparelho, o dia inteiro — para, na maior parte do tempo, nada ter mudado |
| Empurrar do servidor (WebSocket, SSE) | Conexão aberta o tempo todo no celular e no Caddy, reconexão a cuidar, e o Android derruba conexão em segundo plano; o ganho sobre 20 segundos não paga |
| Notificação push (FCM) | Conta e dependência do Google, contra o custo zero e o "sem serviço de terceiros" do projeto |
| Carimbo pelo relógio do servidor, na chegada | Quem sincroniza tarde passaria por cima de quem editou antes: é o problema que a ADR-019 resolveu para o plano |
| Trocar a chave pública por um identificador sorteado e guardado | Daria nome novo aos dois celulares sem ganho nenhum; o par do Keystore já estava lá |
| Manter a autenticação antiga "por garantia" | O Poco e o S22 já entram pela chave; código de segurança sem uso é superfície de ataque sem dono |

## Consequências

- **Bom:** o que um lança aparece no outro e na web em até 20 segundos, sem tocar em nada. Editar o limite do cartão num celular chega ao outro.
- **Bom:** menos código de segurança para manter; nenhuma digital pedida, nenhum código digitado.
- **Custo:** cada aparelho na frente faz uma leitura minúscula a cada 20 segundos — três por minuto. Depois de um lançamento feito no próprio aparelho, a conferência seguinte vê o número andar por causa dele e sincroniza mais uma vez à toa: umas 14 leituras pequenas por gravação. Os aparelhos da casa atrás do mesmo Wi-Fi dividem o limite de 120 pedidos por minuto por origem; uma rajada de lançamentos nos três ao mesmo tempo chega perto dele, e o que passar recebe `E-RATE-01` e é tentado na conferência seguinte.
- **Custo:** a ordem de implantação importa. O servidor novo precisa subir **antes** do APK novo: o servidor antigo recusa o campo `definedAt` no cartão e na categoria com `E-REQ-01`, e a recusa do cadastro interrompe a subida inteira. E o APK de antes de 07/10, que só entra pela autenticação antiga, deixa de sincronizar com este servidor.
- **Custo:** edições de fato simultâneas do mesmo cartão continuam decididas pelos relógios dos celulares (BL-064).
- **Risco aceito:** sem a autenticação por aparelho, quem tiver a chave da casa entra de qualquer lugar. A chave mora no APK do dono, no navegador dele e, como hash, no servidor; trocá-la está no runbook.

## Como se confere

- Testes do servidor: o topo responde `seq` e `ledgerSeq`, zero e zero no registro vazio; cada fato do livro move os dois; o uso da IA move só o `seq`; o mesmo pedido de novo não move nada, nem para trás; sem a chave, 401. Os eventos `device.*` de antes ficam no registro, são ignorados ao subir e não contam como mudança do livro. A edição mais nova do cartão grava e passa a valer, com o carimbo; a mais velha chegando depois responde `kept`; a mesma versão de novo não grava evento; carimbo no futuro é `E-REQ-01`; o cartão sem carimbo conta como o mais velho; reler o registro chega à mesma versão. A categoria reagrupada passa a valer, e a de antes, sem carimbo, não a desfaz. As rotas de cadastro não existem mais; sem a chave configurada, ninguém entra. As instruções da IA se apresentam como Juju, versão 5.
- Testes do contrato: o carimbo vai e volta em UTC; a assinatura ignora id e carimbo; a mais nova toma o lugar; sem carimbo é a mais velha; só a versão estritamente mais nova sobe.
- Testes do app: a conferência pergunta a cada 20 segundos; topo parado não desce, topo que andou desce uma vez; a volta ao app desce mesmo sem o topo andar; no fundo o relógio para; uma conferência por vez; descida que falhou é tentada de novo; sem rede nada desce. No celular, o topo que andou sincroniza sozinho em até 20 segundos, e o fundo para de perguntar; na web, o lançamento do celular aparece sem voltar ao "carregando", e sem resposta o que está na tela fica. Dois celulares: trocar dia de fechamento e limite chega ao outro sem duplicar o cartão; edições simultâneas ficam com a mais nova nos dois; quem edita depois de ver a do outro vence mesmo com relógio atrasado; a segunda versão também desce. A categoria igual não sobe, a reagrupada sobe com o carimbo do cadastro, a mais nova do servidor não é desfeita; o teste do cadastro reprova mudança sem carimbo novo. O topo pela API lê `ledgerSeq`, cai no `seq` do servidor antigo e diz "não sei" sem servidor; a leitura do servidor é inteira ou nenhuma.
- Não conferido em aparelho: a conferência ao vivo com dois celulares de verdade e a web, e o APK com a `FlutterActivity` aberto num celular (a compilação passa; abrir é o teste do dono — BL-067).
