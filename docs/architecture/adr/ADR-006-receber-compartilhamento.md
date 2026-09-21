# ADR-006 — Receber o compartilhamento do Android

- **Estado:** aceita em 2026-09-20 · a medição em aparelho real (spike C) ainda pode ajustá-la
- **Data:** 2026-09-20
- **Responde:** BL-004

## Contexto

O fluxo mais importante do Cajui começa fora dele: a pessoa está no app do banco, toca em "compartilhar" e escolhe o Cajui. O app precisa aparecer na folha de compartilhamento para imagem, PDF e texto, receber um ou vários arquivos, e funcionar tanto fechado (abertura a frio) quanto já aberto.

Há um detalhe que decide o desenho: o endereço recebido (`content://`) vem com **permissão de leitura temporária**, que some quando a atividade termina. Quem não copia o arquivo na hora perde o acesso — é o erro `E-CAPT-05` do [catálogo](../../spec/error-catalog.md).

## Decisão

1. **Canal de plataforma próprio, em Kotlin**, dentro de um módulo nativo de captura — o mesmo que rasteriza PDF e roda o OCR ([ADR-007](ADR-007-ocr-e-pdf.md)). Sem plugin de terceiros neste caminho.
2. O manifesto declara filtros de intenção para `ACTION_SEND` e `ACTION_SEND_MULTIPLE`, com `image/*`, `application/pdf` e `text/plain`.
3. Ao receber, o lado nativo, **antes de qualquer outra coisa**:
   - confere tipo e tamanho pelo `ContentResolver`, sem ler o conteúdo (`E-CAPT-02`, `E-CAPT-03`);
   - confere o espaço livre (`E-CAPT-06`);
   - **copia para a área privada do app** e só então avisa o Dart. A permissão temporária deixa de importar.
4. Abertura a frio e app já aberto usam o mesmo caminho: a intenção inicial é lida na criação da atividade, e as seguintes chegam por `onNewIntent`. O Dart recebe sempre a mesma mensagem: uma lista de arquivos locais, na ordem recebida (RN-705).
5. Nome de arquivo, tipo declarado e conteúdo são **entrada não confiável**: o nome é descartado e substituído por um identificador gerado; o tipo é conferido pelos primeiros bytes do arquivo.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Plugin pronto (`receive_sharing_intent` e similares) | Resolve o caso comum, mas entrega o endereço `content://` ao Dart e deixa a cópia para depois — exatamente onde mora o `E-CAPT-05`. É o fluxo crítico do produto apoiado num pacote de manutenção irregular |
| Plugin pronto, com a cópia feita por cima | Dois lugares cuidando da mesma intenção, e a ordem entre eles vira fonte de defeito |
| Abrir o seletor de arquivos dentro do Cajui | É o caminho alternativo ("Escolher outro"), mas como caminho principal inverte o gesto: a pessoa já está no comprovante |

## Consequências

- **Bom:** o tratamento de permissão, tamanho e espaço fica num lugar só, antes de o Flutter acordar. Os seis erros de captura têm uma origem clara.
- **Bom:** uma dependência de terceiros a menos no caminho que mais importa.
- **Custo:** cerca de 150 linhas de Kotlin para manter e testar. O teste de verdade é em aparelho: emulador não tem os apps de banco de onde o comprovante vem.
- **Em aberto, para o spike C:** tempo do toque em "Cajui" até a tela aberta, a frio e a morno (RNF-PERF-07: ≤ 2 s e ≤ 1 s); comportamento com 10 arquivos de uma vez; o que cada app de banco realmente compartilha — imagem, PDF ou texto.

## Como se confere

- Roteiro em aparelho real com ao menos três origens: galeria, um app de banco e um leitor de PDF.
- Teste instrumentado do módulo nativo: intenção com endereço sem permissão, arquivo de 22 MB, tipo declarado diferente do conteúdo.
