# ADR-016 — Motor de áudio

- **Estado:** proposta · a medição de latência no Android **confirma no spike C**
- **Data:** 2026-09-20
- **Responde:** BL-009 · relaciona-se com BL-026

## Contexto

O som do Cajui é resposta a toque. A RNF-PERF-05 fixa a régua: **≤ 80 ms do toque ao início do som**; acima de 100 ms, os sons de toque se desligam naquele aparelho — som atrasado é pior que nenhum som. Os sons são curtos (70 a 260 ms, e um de 580 ms), tocam muito, e às vezes um em cima do outro.

Dois candidatos: `audioplayers`, o pacote mais usado, sobre os tocadores de cada plataforma; e `flutter_soloud`, sobre um motor de jogo em C++, feito para baixa latência.

## Decisão

1. **O design system não conhece motor nenhum.** Ele fala com a porta `SoundPlayer` (`preload`, `play`, `dispose`). O motor é um adaptador — trocar é reescrever um arquivo, e nenhum componente muda. Isso já está em vigor desde a Fase 3.
2. **Começa com `audioplayers`**, em modo de baixa latência, com um tocador por som (o toque seguinte não espera o anterior) e **carregamento sob demanda**: enquanto o som está desligado — que é como ele nasce —, nenhum arquivo é baixado nem decodificado.
3. **A latência é medida em aparelho real, no spike C.** Critério de troca: se o `audioplayers` passar de 80 ms no aparelho de referência, o adaptador passa a ser o `flutter_soloud`.
4. **Formato**: WAV no Android — sem custo de decodificação, e o total é de 180 KB. Para a web, avaliar formato comprimido no BL-026.
5. **Falha de áudio nunca derruba interação**: som que não carrega deixa o app mudo, sem erro na tela.

### O que o spike A já ensinou

Na web, o `audioplayers` busca cada arquivo duas vezes (a requisição e uma de intervalo): pré-carregar os dez sons custava **20 requisições e 312 KB antes do primeiro quadro**, com o som desligado. O carregamento sob demanda derrubou o primeiro quadro de 0,92 s para 0,28 s. A lição vale para qualquer motor: **som é recurso de quem ligou o som.**

## Alternativas consideradas

| Alternativa | Situação |
|---|---|
| `flutter_soloud` desde já | Provavelmente mais rápido, mas traz biblioteca nativa a cada plataforma e um módulo WebAssembly próprio na web — peso no orçamento de 2,5 MB — antes de haver medição que o justifique. Fica como o adaptador de reserva |
| `just_audio` | Feito para música e fluxo contínuo; para efeito curto e repetido não tem vantagem sobre o `audioplayers` |
| `SoundPool` do Android por canal nativo próprio | É a API certa para efeito curto no Android, e seria a terceira opção se os dois pacotes falharem. Não cobre a web |
| Sem som na web | Simplificaria, mas a gallery pública é vitrine do design system, e a mesa de som faz parte dela |

## Consequências

- **Bom:** a decisão pode ser revertida por medição, não por opinião, ao custo de um arquivo.
- **Bom:** o app abre sem baixar som nenhum.
- **Custo:** o primeiro som depois de ligar pode sair atrasado, enquanto carrega. O pré-carregamento dispara no instante em que o som é ligado, para isso acontecer longe do primeiro toque que importa.
- **Em aberto:** a latência real. Até o spike C, o número de 80 ms é meta, não fato.

## Como se confere

- Spike C: gravação do toque e do som no mesmo aparelho, com a diferença medida quadro a quadro, para `audioplayers` e `flutter_soloud`.
- Teste do pacote: com o som desligado, o tocador não é chamado; com o som ligado, o mesmo som não toca duas vezes na mesma velocidade.
