# ADR-007 — Leitura de texto no aparelho: OCR e PDF

- **Estado:** aceita em 2026-09-20 · a medição em aparelho real (spike C) ainda pode ajustá-la
- **Data:** 2026-09-20
- **Responde:** BL-005 · **ajusta:** RNF-PERF-06

## Contexto

A regra é dura: **a imagem nunca sai do aparelho**; só o texto lido vai para a IA. Logo, o OCR roda no Android. O ML Kit lê imagem, não lê PDF — e boa parte dos comprovantes de banco é PDF. O plano pedia só bibliotecas com licença realmente livre, o que tira do jogo os leitores de PDF comerciais.

## Decisão

1. **ML Kit Text Recognition v2, alfabeto latino, com o modelo embutido no APK.** Funciona sem rede desde a primeira leitura e não depende de download pelo Google Play Services.
2. **PDF vira imagem, sempre.** Cada página é rasterizada pelo `PdfRenderer` — que é do próprio Android, sem biblioteca extra — e segue para o mesmo OCR. **Um caminho só** para foto, captura de tela e PDF.
3. O ML Kit é chamado **direto do módulo nativo** de captura ([ADR-006](ADR-006-receber-compartilhamento.md)). O Dart manda o caminho do arquivo e recebe texto, blocos com posição e o progresso página a página. Nenhum bitmap atravessa o canal.
4. O progresso é real (RNF-PERF-06): "página 2 de 4" vem do trabalho feito, não de animação.
5. PDF com senha faz o `PdfRenderer` recusar a abertura: vira `E-CAPT-04`. Página acima de 10 s é interrompida: `E-CAPT-07`.
6. O texto lido é **dado não confiável** daqui em diante: tamanho limitado, caracteres de controle removidos, e nunca interpretado como instrução ([ADR-010](ADR-010-integracao-com-a-deepseek.md)).

### Ajuste na RNF-PERF-06

O requisito propunha ≤ 0,5 s por página de PDF **com camada de texto**. Esta decisão não lê a camada de texto: toda página passa pelo OCR, com o mesmo teto da imagem, **≤ 2 s por página**. A troca é deliberada — um caminho único, sem biblioteca de PDF de terceiros — e a extração direta de texto fica como otimização futura, se o spike mostrar que PDF longo (extrato) dói.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Modelo do ML Kit baixado sob demanda | APK menor, mas a primeira leitura dependeria de rede e do Play Services — justo no primeiro uso, quando a impressão se forma |
| Tesseract no aparelho | Licença livre, mas precisão e velocidade piores em foto de celular, e dezenas de MB de dados de idioma |
| OCR no servidor ou na IA | Violaria a regra de a imagem não sair do aparelho |
| Biblioteca de PDF para ler a camada de texto | As boas são comerciais ou de licença restritiva; as livres em Dart não cobrem os PDFs de banco com fonte embutida. Acrescentaria um segundo caminho, com seus próprios defeitos |
| Plugin `google_mlkit_text_recognition` | Funciona, mas exigiria rasterizar o PDF de um lado e levar a imagem ao plugin pelo Dart. Com o módulo nativo já existindo, chamar o ML Kit de dentro dele é menos código e menos cópia de memória |

## Consequências

- **Bom:** um único caminho de leitura para testar, medir e consertar.
- **Bom:** nenhuma dependência de PDF; o `PdfRenderer` acompanha o sistema.
- **Custo:** o modelo embutido acrescenta alguns MB ao APK (teto: 40 MB, RNF-PERF-11 — conferir no spike).
- **Custo:** rasterizar gasta memória: página A4 a 200 dpi é um bitmap de cerca de 15 MB. As páginas são processadas uma de cada vez e liberadas, para respeitar o pico de 300 MB.
- **Em aberto, para o spike C:** tempo por página em aparelho intermediário; qualidade da leitura em comprovante escuro, amassado e em captura de tela; tamanho real do APK.

## Como se confere

- Conjunto fixo de comprovantes de teste (sintéticos, sem dado real), com o texto esperado: a taxa de acerto de valor, data e estabelecimento vira número acompanhado.
- Teste de memória: PDF de 12 páginas sem estourar o pico.
