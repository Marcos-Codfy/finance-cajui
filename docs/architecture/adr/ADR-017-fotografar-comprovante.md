# ADR-017 — Fotografar o comprovante dentro do app

- **Estado:** aceita em 2026-09-21 · decidida com o app rodando em aparelho real
- **Data:** 2026-09-21
- **Responde:** pedido do dono do produto depois do primeiro teste no Galaxy S22 · relaciona-se com ADR-006 e ADR-007

## Contexto

O fluxo de captura nasceu inteiro em cima do **compartilhamento** (ADR-006): um comprovante que já é arquivo — o PDF do Pix, o print da maquininha — chega ao Cajui pelo menu "Compartilhar" de outro app.

O primeiro teste com o app instalado mostrou o furo: **cupom fiscal de supermercado é papel**. Não existe arquivo para compartilhar. A compra do mês, que é justamente o gasto que o Cajui mais precisa enxergar, ficava fora do caminho automático.

Sem câmera no app, o caminho é: sair do Cajui → abrir a câmera → fotografar → voltar → compartilhar → escolher o Cajui. Cinco passos, e um efeito colateral que importa: **a foto fica na galeria**, com valores, itens e CNPJ à vista de qualquer app que tenha permissão de ler fotos.

## Decisão

1. **O Cajui tem um botão "Fotografar comprovante"** na tela de lançamentos, ao lado de "Lançar".
2. **Quem fotografa é o app de câmera do aparelho**, chamado por intenção (`ACTION_IMAGE_CAPTURE`). O Cajui **não embute câmera própria** e **não pede permissão de câmera**: a permissão é de quem tira a foto.
3. **A foto nasce na área privada do app**, na mesma caixa de entrada do compartilhamento (`files/capture-inbox`), por um `FileProvider` não exportado que só dá acesso a esse diretório. Ela **não passa pela galeria**.
4. **Daí em diante o caminho é o já testado**: a foto entra na mesma fila, passa pelo mesmo OCR local (ADR-007), pela mesma classificação por regras e pela mesma tela de conferência. Para o Dart, fotografar e compartilhar são a mesma coisa — a única diferença é a marca `fromCamera`, que existe para o futuro (enquadramento, recorte) e não muda regra nenhuma.
5. **Aparelho sem câmera**: a intenção não resolve, o nativo devolve `false` e a tela responde com aviso, em vez de abrir nada. Na web o botão não existe (ADR-013: modo consulta).
6. **Descartar apaga o arquivo** como qualquer captura (RN-723). Foto de comprovante não é lembrança: ela existe para virar lançamento.

## Alternativas consideradas

| Alternativa | Situação |
|---|---|
| **CameraX dentro do app**, com visor e moldura de guia | É o que dá a melhor foto de cupom comprido: guia de enquadramento, foco contínuo, aviso de tremido. Custa uma dependência nativa, a permissão `CAMERA` (que o app hoje não pede) e uma tela de visor a manter. Fica como próximo passo **se** a foto do app de câmera se mostrar ruim para o OCR — e a decisão será tomada com leitura medida, não por gosto |
| **Detecção de borda e recorte automático** | Melhora muito cupom longo fotografado torto. Depende de escolher entre uma biblioteca nativa a mais e escrever o recorte à mão. Fica no backlog, junto do CameraX |
| **`image_picker`** (pacote) | Faria o mesmo que esta decisão, com uma dependência a mais e menos controle de onde o arquivo nasce — o pacote escreve no cache, e o Cajui quer a foto na caixa de entrada cifrada |
| **Continuar só com compartilhamento** | Deixaria a compra de supermercado, que é o maior gasto variável do mês, fora do fluxo automático. Foi o que o teste no aparelho reprovou |
| **Digitalizador do sistema** (Google Drive, Notas do Samsung) | Dá PDF com recorte bom, mas depende de app de terceiro instalado, muda de aparelho para aparelho e devolve o arquivo pela galeria ou pela nuvem — o oposto de "a foto nasce na área privada" |

## Consequências

- O app ganha a segunda porta de entrada de despesa, e a mais usada no dia a dia passa a ser a câmera.
- **Nenhuma permissão nova** no manifesto: só um `FileProvider` não exportado.
- O OCR passa a receber foto de papel amassado e com sombra, e não só print nítido. A leitura de cupom fiscal foi refinada junto (nome da loja pelo cabeçalho, valor pago em vez do total antes do desconto, ramo do estabelecimento pelo nome) — e o que ela não consegue ler continua ficando **em branco**, para a pessoa preencher, em vez de virar chute.
- Quando a IA entrar (ADR-010), a foto não muda nada no envio: continua saindo **só o texto**, mascarado. A imagem nunca sai do aparelho.
