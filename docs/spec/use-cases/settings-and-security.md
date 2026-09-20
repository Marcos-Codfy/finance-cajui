# Casos de uso — preferências e segurança

Formato e convenções em [use-cases.md](../use-cases.md). Requisitos em [non-functional-security.md](../non-functional-security.md) e [non-functional-accessibility.md](../non-functional-accessibility.md).

Os erros `E-AUTH-03` e `E-AUTH-04` são da classe `segurança`: vagos de propósito, sem revelar o motivo exato (RNF-SEC-18). Mesmo assim dizem o que o usuário pode fazer.

## UC-SET-01 — Escolher o tema

**Plataforma:** ambas · **Regras:** [color.md](../../brand/color.md)

**Aceite:**
- Dado "seguir o sistema" (padrão), quando o aparelho muda para escuro, então o app acompanha.
- Dado o tema escuro, quando aberto, então o fundo é o azul-petróleo "noite" e os acentos são os do tema escuro — não o claro invertido.
- Dado qualquer tema, quando os pares de cor são testados, então todos passam no contraste (RNF-A11Y-02).

## UC-SET-02 — Ajustar som, toque e movimento

**Plataforma:** ambas (toque só no Android) · **Regras:** [motion-and-sound.md](../../brand/motion-and-sound.md), RNF-A11Y-07, RNF-A11Y-17

**Aceite:**
- Dado uma instalação nova, quando aberta, então o som está desligado e o controle é visível.
- Dado o som ligado, quando o usuário ajusta, então há volume próprio e três categorias independentes: toques, confirmações, ambiente.
- Dado o aparelho no silencioso, quando um som tocaria, então não toca.
- Dado "reduzir movimento" no sistema, quando o app abre, então entra no nível `reduced`: sem paralaxe, cascata, contagem de número nem herói animado.
- Dado o nível `lite` escolhido por medição, quando o usuário abre as configurações, então vê qual nível está em uso e pode trocá-lo.
- Dado a web, quando a página carrega, então nenhum som toca antes de um gesto do usuário.

## UC-SET-03 — Desbloquear o app

**Plataforma:** Android · **Regras:** RNF-SEC-03, RNF-SEC-04, RNF-SEC-19, RNF-A11Y-14

**Fluxo:** 1. Ao abrir, ou ao voltar depois de 2 minutos em segundo plano, o app pede a biometria. 2. A biometria destrava a chave em hardware, que assina o desafio do servidor. 3. O servidor entrega um token curto.

**Erros:** `E-AUTH-01` biometria indisponível: "Este aparelho está sem biometria configurada. Dá para configurar nos ajustes do Android, ou usar o bloqueio de tela do aparelho." · `E-AUTH-02` não reconhecida: "Não reconheci a digital. Tente de novo ou use o bloqueio de tela do aparelho." · `E-AUTH-03` recusa do servidor: "Não foi possível entrar com este aparelho. Se isso continuar, pareie o aparelho de novo."

**Aceite:**
- Dado o app fechado, quando aberto, então nenhum valor aparece antes do desbloqueio.
- Dado sem rede, quando a biometria passa, então o app abre com os dados locais e a fila funciona; o token é obtido quando a rede voltar.
- Dado o token copiado para outro aparelho, quando usado, então o servidor recusa.
- Dado a biometria recusada, quando o usuário escolhe a alternativa, então vale o bloqueio de tela do próprio Android — o Cajui não tem senha própria.

## UC-SET-04 — Parear um aparelho

**Plataforma:** Android · **Regras:** RNF-SEC-05

**Fluxo:** 1. O dono gera um código no servidor, por SSH. 2. Digita o código no app. 3. O app cria a chave em hardware e envia a parte pública. 4. O servidor registra o aparelho.

**Erros:** `E-AUTH-04`: "Não foi possível parear com este código. Gere um novo no servidor e tente de novo."

**Aceite:**
- Dado um código com mais de 10 minutos, já usado ou errado, quando informado, então é recusado com `E-AUTH-04`, sem dizer qual dos três aconteceu.
- Dado cinco tentativas erradas, quando a sexta é feita, então o código está invalidado.
- Dado um aparelho pareado, quando o pareamento termina, então um aviso de segurança aparece na tela de estado do sistema (RNF-SEC-13).

## UC-SET-05 — Revogar um aparelho

**Plataforma:** servidor, por SSH · **Regras:** RNF-SEC-05

**Aceite:**
- Dado o celular perdido, quando o dono revoga o aparelho por comando, então o token e a chave dele deixam de valer na hora, e o procedimento está ensaiado no runbook.

## UC-SET-06 — Entrar no modo consulta pela web

**Plataforma:** web · **Regras:** RNF-SEC-06, RNF-A11Y-11, RNF-A11Y-14 · **Em aberto:** o mecanismo de autenticação é decidido na Fase 4 (BL-011). Os critérios abaixo são de resultado.

**Aceite:**
- Dado a URL pública, quando aberta sem autenticação, então nenhum dado financeiro aparece, nem no HTML, nem em resposta de rede.
- Dado a autenticação, quando feita, então tem força equivalente à do Android e não usa senha própria do Cajui.
- Dado a aba recarregada ou fechada, quando reaberta, então pede autenticação de novo; nada de sessão fica em armazenamento do navegador.
- Dado a web autenticada, quando usada, então mostra painel, relatórios, faturas, dívidas e assistente — e nenhum controle que grave dado (Q7).
- Dado qualquer página, quando inspecionada, então leva `noindex` (decisão de 2026-09-19).
- Dado só o teclado, quando o usuário percorre a web, então alcança tudo, em ordem lógica, sem armadilha.

## UC-SET-07 — Configurar os avisos

**Plataforma:** Android · **Regras:** RN-813, RN-825, RN-838, RN-844, RN-847

**Aceite:**
- Dado os quatro tipos — vencimentos, diário, semanal, mensal —, quando a tela abre, então cada um tem chave, dia e horário próprios; o diário nasce desligado.
- Dado o semanal desligado, quando a semana vira, então os vencimentos continuam chegando.
- Dado "ocultar valores nas notificações", quando ligado, então nenhum aviso mostra valor.

## UC-SET-08 — Exportar os dados

**Plataforma:** Android · **Regras:** RN-990 a RN-996, RNF-PRIV-06

**Aceite:**
- Dado "Exportar meus dados", quando pedido, então o usuário recebe os eventos em JSON legível e os comprovantes, em até 60 s para a carga de referência.
- Dado o arquivo exportado, quando aberto num editor de texto, então é compreensível sem o app.

## UC-SET-09 — Ver o estado do sistema

**Plataforma:** ambas · **Regras:** RNF-OPS-07, RNF-SEC-13, RNF-REL

**Erros:** `E-DATA-01` cadeia do log quebrada · `E-DATA-02` snapshot e log divergem.

**Aceite:**
- Dado tudo certo, quando a tela abre, então mostra última sincronização, último backup, situação da IA e consumo de tokens.
- Dado o último backup com mais de 48 horas, quando a tela abre, então há um aviso com o que fazer.
- Dado a cadeia do log quebrada, quando detectada, então o erro diz **em que ponto**, que os dados anteriores estão íntegros, e aponta a restauração do backup — nunca "banco corrompido" e só.
- Dado lançamentos na fila, quando a tela abre, então mostra quantos aguardam envio.

## UC-SET-10 — Apagar tudo

**Plataforma:** Android · **Regras:** RNF-PRIV-07

**Aceite:**
- Dado "Apagar todos os meus dados", quando pedido, então o app exige confirmação explícita, digitando uma palavra, e oferece exportar antes.
- Dado a confirmação, quando feita, então os dados somem do servidor e do aparelho, e os backups expiram pela rotação, no prazo informado na tela.
