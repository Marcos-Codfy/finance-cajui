# ADR-001 — Monorepo com domínio compartilhado

- **Estado:** proposta · aguarda o checkpoint da Fase 4
- **Data:** 2026-09-20

## Contexto

App e servidor são escritos em Dart. As regras do Cajui — o cartão como forma de pagamento, o vale que nunca se soma ao dinheiro, o limite da semana — precisam valer **nos dois lados**: no aparelho, para o painel abrir e o lançamento salvar sem rede; no servidor, porque ele é a fonte da verdade e não confia no que chega. São 345 regras especificadas. Escrevê-las duas vezes é garantir que um dia elas discordem.

O pedido original é arquitetura limpa *feature-first*, com `domain/application/infrastructure/presentation` dentro de cada feature.

## Decisão

1. **Um repositório, um workspace do pub** (`resolution: workspace`), com um único `pubspec.lock`: app, servidor e pacotes resolvem as mesmas versões.
2. **O domínio mora em `packages/domain`**, Dart puro, organizado por feature (`lib/src/ledger/`, `lib/src/budget/`…). App e servidor dependem dele. As outras três camadas continuam dentro de cada feature, em `app/` e em `server/`.
3. **`packages/api_contract`** guarda o que atravessa a rede: DTOs, validação de esquema e o enum de códigos de erro. O domínio não conhece JSON.
4. **Regra de dependência**: `presentation → application → domain ← infrastructure`. `domain` não importa Flutter, `dart:io`, `dart:html` nem pacote com efeito colateral.

Este é um **desvio consciente** do pedido: a camada `domain` sai de dentro da feature e vai para um pacote. A organização por feature se mantém dentro dele.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Domínio dentro de cada feature, em `app/` e em `server/` | Duas cópias de cada regra. A divergência é questão de tempo, e o teste de um lado não protege o outro |
| Repositórios separados, com o domínio publicado como pacote | Versionar e publicar um pacote para um projeto de uma pessoa é cerimônia sem retorno; uma mudança de regra viraria três PRs |
| Servidor "burro", que só guarda o que o app manda | O servidor deixaria de validar. Contraria a regra de tratar toda entrada como não confiável (ASVS V2) |
| Gerar o cliente a partir de OpenAPI | Resolve o contrato, não as regras. O contrato já fica resolvido por um pacote Dart compartilhado, sem gerador |

## Consequências

- **Bom:** cada regra `RN-xxx` tem uma implementação e um teste, nomeado pela regra. A meta de cobertura acima de 80% no domínio se mede num pacote só.
- **Bom:** o domínio é testável sem emulador, sem servidor e sem rede — roda em milissegundos no CI.
- **Custo:** o domínio precisa ser estrito quanto a plataforma. Nada de `DateTime.now()` direto: o relógio entra por porta (`Clock`), o que também torna os testes determinísticos.
- **Custo:** mudança incompatível no domínio quebra app e servidor juntos. É desejável — o erro aparece na compilação —, mas exige publicar os dois em ordem (RNF-COMPAT-05: a API tem prefixo de versão e reconhece app antigo).

## Como se confere

- O verificador do projeto (`tool/code_metrics`) ganha a regra de importação por camada na Fase 6: `packages/domain` importando `package:flutter`, `dart:io` ou `dart:html` reprova o commit.
- `dart test` em `packages/domain` roda sem Flutter instalado.
