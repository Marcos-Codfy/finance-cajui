# ADR-014 — Análise estática, métricas e travas de commit

- **Estado:** aceita em 2026-09-20, no checkpoint da Fase 4 · parte já em vigor desde a Fase 3
- **Data:** 2026-09-20

## Contexto

O projeto se impõe limites de tamanho — 300 linhas por arquivo, 30 por função, 3 níveis de bloco, um tipo público por arquivo — e regras de camada que nenhum lint pronto cobra. A ferramenta que fazia isso no ecossistema Dart (DCM) virou paga. E o repositório é privado no plano gratuito do GitHub: sem proteção de branch e sem varredura de segredos do lado do servidor (BL-022).

Regra que não é conferida por máquina vira intenção. Com uma pessoa só no projeto, não há revisor para cobrar.

## Decisão

1. **`very_good_analysis`**, no modo mais estrito (`strict-casts`, `strict-inference`, `strict-raw-types`), com `public_member_api_docs`: todo membro público tem documentação, em português, dizendo o porquê. Zero aviso é condição de commit.
2. **Verificador próprio, `tool/code_metrics`**, sobre o `package:analyzer` — só análise sintática, rápido o bastante para todo commit. Em vigor:
   - linhas por arquivo, linhas por função, profundidade de bloco de controle, tipos públicos por arquivo.
3. O mesmo verificador ganha, **na Fase 6**, as regras que protegem a arquitetura:
   - **importação por camada**: `domain` não importa Flutter, `dart:io` nem `dart:html`; `presentation` não importa `infrastructure` ([ADR-001](ADR-001-monorepo-e-dominio-compartilhado.md), [ADR-002](ADR-002-estado-com-riverpod.md));
   - **fonte única do design**: fora de `packages/design_system`, reprova `Color(`, `TextStyle(`, `Duration(` de interface e widget cru do Material;
   - **`TODO` sem dono**: todo `TODO` cita um item do `BACKLOG.md`, ou reprova.

   **Em vigor desde o passo 5 da Fase 6** (`ArchitectureChecker`, regras `layer-imports`, `raw-style` e `orphan-todo`), com três precisões que só apareceram na hora de escrever:
   - o domínio tem lista do que **pode** importar (`dart:core`, `async`, `collection`, `convert`, `math`, `typed_data`, `package:meta` e ele mesmo), e não do que não pode — dependência nova no domínio passa a ser decisão, não descuido;
   - além de `presentation` não enxergar `infrastructure`, `application` não enxerga nenhuma das duas, e `infrastructure` não enxerga `presentation`. Quem liga as pontas é a raiz de composição do app;
   - "widget cru do Material" virou proibição do **import** de `material.dart` e `cupertino.dart` em `app/lib`, mesmo com `show`. O que o app precisar do Material entra no design system (foi assim que nasceu `CajuiLocalizations`). `Duration(` só é reprovado em `presentation`: espera de rede em `infrastructure` não é duração de interface.

   Escrever as regras revelou um furo do próprio verificador: as pastas conferidas por padrão eram só `packages` e `tool`, e `server/` nunca tinha sido medido — havia dois arquivos de teste acima de 300 linhas, divididos no mesmo passo. A lista padrão agora é `app`, `packages`, `server` e `tool`.
4. **Trava local antes do commit** (gancho `pre-commit`): varredura de segredos com `gitleaks`, `flutter analyze`, o verificador e os testes do pacote alterado. Gancho `commit-msg`: Conventional Commits.
5. **O CI repete tudo** — a trava local é conveniência; quem garante é o CI. Em dois ritmos (BL-023): leve em todo PR (análise, verificador, testes, `gitleaks`); pesado só no `main` (build Android, build web, Lighthouse).

### O que o verificador deliberadamente não conta

- Função anônima e coleção literal **não** contam como nível de aninhamento. A árvore de widgets do Flutter é aninhada por natureza; o que a regra contém é lógica dentro de lógica.
- Em arquivo de teste, `main` não tem limite de linhas: é o sumário dos casos. O limite do arquivo continua valendo.
- Comentário de documentação não entra na conta da função.

Cada uma dessas escolhas está escrita e testada no próprio verificador, para não virar exceção silenciosa.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| DCM | Pago. Fere o custo zero |
| `custom_lint` com regras próprias | Integra ao editor, o que é bom, mas roda como plugin do analisador, mais lento e mais frágil a cada versão do SDK. O verificador por linha de comando tem 300 linhas e testes próprios; se a integração ao editor fizer falta, as regras migram |
| Só revisão manual | Não há segundo revisor |
| Limites mais frouxos para a interface | Tentador, porque `build()` é verboso. A Fase 3 mostrou que 30 linhas bastam extraindo partes com nome — e que o código fica melhor assim: 138 arquivos, zero violações |

## Consequências

- **Bom:** as regras de tamanho e de camada viram falha de build, não conversa.
- **Bom:** a fonte única do design system fica protegida por máquina: o dia em que alguém escrever `Color(0xFF…)` numa tela, o commit para.
- **Custo:** manter o verificador. É pequeno, mas acompanha a API do `analyzer`, que muda entre versões — a versão é fixada no workspace.
- **Custo:** o gancho local deixa o commit alguns segundos mais lento. O verificador foi feito só sintático por isso.

## Como se confere

- O verificador tem testes para cada regra e para cada exceção deliberada.
- O CI falha o PR com qualquer aviso do analisador, qualquer limite estourado ou qualquer segredo detectado.
