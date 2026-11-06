<div align="center">

<sub>**Português** · [English](README.en.md)</sub>

<img src="docs/brand/assets/app-icon.svg" width="88" alt="Ícone do Cajui: o cajuí, fruto do Cerrado, em terracota." />

# Cajui

**O dinheiro da casa, numa conversa.**

App Android de finanças pessoais com uma assistente de IA: você conversa para lançar gastos, e o app lê extratos e
comprovantes e responde com os números do mês. É um projeto completo, feito do zero: especificação, domínio em Dart
puro, app Flutter, servidor próprio na nuvem e um design system com gallery publicada.

<picture>
  <source media="(prefers-reduced-motion: reduce)" srcset="docs/media/extrato-pela-juju.png" />
  <img src="docs/media/demo.webp" width="320" alt="Demonstração do Cajui em 45 segundos, com dados fictícios: um extrato compartilhado abre na conversa com a Juju, que resume 12 movimentações; o bloco Mercado é conferido com as linhas abertas, os blocos seguintes são confirmados, a padaria ganha categoria, o Pix para uma pessoa vira 'Alguém da casa' e 9 lançamentos entram de uma vez. Depois a câmera vai para o Início, o carrossel 3D mostra a sobra, o que entra e o que sai do bolso, o Meu mês abre e a carteira de cartões aparece." />
</picture>

<sub>Gravado com o app rodando, com uma casa fictícia. Nenhum número é real.</sub>

![CI](https://github.com/Marcos-Codfy/finance-cajui/actions/workflows/ci.yml/badge.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-Android-7F52FF?logo=kotlin&logoColor=white)
![Testes](https://img.shields.io/badge/testes-1.850-2E7D32)
![Cobertura do domínio](https://img.shields.io/badge/domínio-92,9%25-2E7D32)
![Custo](https://img.shields.io/badge/custo%20fixo-R%24%200%2C00-B33A16)

**[Ver a gallery do design system ao vivo](https://cajui-teal.vercel.app/gallery/)**

[Sobre o projeto](#sobre-o-projeto) · [Arquitetura](#arquitetura) · [Documentação da API](docs/api.md) ·
[Decisões (32 ADRs)](docs/architecture/adr) · [Especificação](docs/spec) · [Design system](packages/design_system) ·
[Segurança](docs/security) · [Wireframes](docs/design/wireframes.html)

</div>

---

**Para quem avalia:** [Sobre o projeto](#sobre-o-projeto) · [Visual](#visual) · [Arquitetura](#arquitetura) ·
[Desafios que resolvi](#desafios-que-resolvi) · [Stack](#stack) · [Padrões aplicados](#padrões-de-projeto-aplicados) ·
[Segurança e privacidade](#segurança-e-privacidade) · [Qualidade](#qualidade) · [O que deu errado](#o-que-deu-errado)<br />
**Para quem desenvolve:** [Começando](#começando) · [Scripts](#scripts) · [Estrutura](#estrutura-do-projeto) ·
[Publicação](#publicação) · [Roadmap](#roadmap)

## Sobre o projeto

O Cajui é um app Android de finanças pessoais que comecei para controlar as contas da minha casa, no lugar de uma
planilha que dava trabalho para manter. A primeira versão era a planilha em formato de app, e quem usava achou
cansativo preencher tudo. Por isso mudei o foco: em vez de telas para preencher, você conversa com uma assistente (a
Juju), e o app aproveita o que o banco já envia, como notificações, extratos e comprovantes. Hoje dois celulares usam o
mesmo livro de lançamentos, sincronizado, e existe uma página web só para consultar.

Além de ferramenta pessoal, o projeto virou o meu laboratório para aprender e praticar engenharia de software de
verdade: MVVM, DDD (linguagem do negócio e regras dentro do domínio), princípios SOLID, arquitetura limpa, injeção de
dependência e padrões de projeto como Factory, Strategy, Adapter, Repository, Observer e Singleton (aqui, as instâncias
únicas ficam por conta dos providers do Riverpod). O quadro de [padrões aplicados](#padrões-de-projeto-aplicados) mostra
onde cada um aparece no código, e as decisões estão registradas em [ADRs](docs/architecture/adr).

**Como foi feito:** eu escrevi as especificações do que o app deveria fazer e fui construindo o projeto com o apoio do
Claude, como assistente de programação. A API do Claude também é usada dentro do app, na conversa com a Juju.

### O que ele faz

- **Lançamento por conversa.** Você escreve ou dita "gastei 35 no mercado", e o app cria o lançamento com categoria e
  forma de pagamento. Dá para desfazer logo em seguida.
- **Perguntas sobre o mês.** A assistente responde quanto sobra, o que vence e quanto falta para fechar o mês, usando
  os números do próprio app.
- **Leitura de extrato.** Você compartilha o PDF ou o print do extrato; o celular lê página por página, e a conversa
  confere por blocos antes de gravar. Ler o mesmo extrato duas vezes não duplica lançamentos.
- **Notificações do banco.** Uma compra aprovada vira lançamento automaticamente, com opção de desfazer. Quando entra
  dinheiro, o app pede para você confirmar.
- **Comprovantes.** Foto, print ou PDF viram uma proposta de lançamento para você conferir. O reconhecimento do texto
  acontece no aparelho, e só texto com os dados pessoais mascarados vai para a IA.
- **Dois celulares, um livro.** Os lançamentos sincronizam entre os aparelhos, e a consulta pela web é protegida por um
  código de autenticador.
- **Regras de dinheiro explícitas.** Cartão de crédito é forma de pagamento, não despesa. Vale-alimentação é uma moeda
  separada, que não se soma ao dinheiro. As duas regras estão nos tipos do domínio.

### Visão técnica

| Área            | O que foi feito                                                                                                | Onde ver |
| --------------- | -------------------------------------------------------------------------------------------------------------- | -------- |
| Arquitetura     | Arquitetura limpa por feature, MVVM com estado selado (Riverpod), Coordinator e uma raiz de composição; um verificador próprio confere as camadas | [ADR-001](docs/architecture/adr/ADR-001-monorepo-e-dominio-compartilhado.md), [002](docs/architecture/adr/ADR-002-estado-com-riverpod.md), [031](docs/architecture/adr/ADR-031-navegacao-com-coordinator.md) |
| Domínio         | Dart puro, compartilhado entre app e servidor; `Result` e `Failure` selados; dinheiro em centavos inteiros; regras de negócio numeradas, cada uma com teste | [`packages/domain`](packages/domain) |
| IA              | Claude (API de Mensagens, com *tool use*) atrás de uma interface trocável; dados pessoais mascarados antes de sair; todo valor que a IA escreve é conferido | [ADR-010](docs/architecture/adr/ADR-010-integracao-com-a-deepseek.md), [021](docs/architecture/adr/ADR-021-assistente-que-age.md), [030](docs/architecture/adr/ADR-030-extrato-pela-juju.md) |
| Servidor        | Dart + Shelf, executável único, na Oracle Cloud (OCI), com TLS; registro de eventos cifrado e encadeado; API documentada | [`server/`](server), [`docs/api.md`](docs/api.md) |
| Design system   | Pacote próprio com tokens, componentes, movimento 3D e sons; gallery publicada com 69 estados de tela; o app não define cor por conta própria | [`packages/design_system`](packages/design_system), [gallery](https://cajui-teal.vercel.app/gallery/) |
| Android nativo  | Compartilhamento, OCR no aparelho, notificações do banco, widget da tela inicial, lembretes e ditado | [`app/android`](app/android) |
| Qualidade       | 1.850 testes, nomeados pela regra que provam; cobertura de 86% a 93% por pacote; varredura de segredos no histórico | [`tool/`](tool), [quality-gates](docs/spec/quality-gates.md) |
| Processo        | 32 ADRs, Conventional Commits, pull requests e CI no GitHub Actions | [`docs/architecture`](docs/architecture) |

### Decisões que guiaram o projeto

Duas decisões moldaram o resto. A primeira: a IA só lê e sugere; quem faz conta e aplica as regras é o domínio, em
Dart puro, usado tanto no app quanto no servidor. A segunda: na conversa do extrato, as frases da Juju são montadas
pelo app a partir dos números do domínio, e não pelo modelo, então o que ela diz bate com o que a tela mostra.

Também aprendi que só os testes não bastam. O extrato passava em centenas de testes e, no primeiro PDF real, o OCR
devolveu a tabela por colunas e misturou duas linhas ([desafio 2](#2-a-tabela-que-o-ocr-desmonta)). Desde então eu
confiro cada tela nova no navegador e no celular.

### Como aproveitar este projeto

- **Rodar o app.** Clone o repositório, rode `flutter pub get` e `flutter run`. Sem servidor configurado, ele funciona
  sozinho no aparelho (veja [Começando](#começando)).
- **Ligar a um servidor seu.** O servidor em [`server/`](server) roda na sua máquina com `scripts/servidor-local.ps1`;
  o app aponta para ele pelas variáveis `CAJUI_API_URL` e `CAJUI_ACCESS_KEY`. A chave da IA fica fora do repositório.
- **Reaproveitar o design system.** O pacote [`packages/design_system`](packages/design_system) não depende do app nem
  do Riverpod, e a [gallery](https://cajui-teal.vercel.app/gallery/) mostra cada componente em todos os estados.
- **Reaproveitar o domínio.** O pacote [`packages/domain`](packages/domain) é Dart puro (dinheiro, parcelas, fatura de
  cartão, orçamento do mês) e serve para outro app ou servidor.
- **Estudar as decisões.** As [ADRs](docs/architecture/adr) explicam o porquê de cada escolha, e a
  [documentação da API](docs/api.md) descreve cada rota do servidor.

## Visual

<p align="center">
  <img src="docs/media/extrato-pela-juju.png" width="960" alt="Três telas da conversa com a Juju: o resumo do extrato e o bloco Mercado com Confere, Ver as linhas e Corrigir; a pergunta sobre um Pix para uma pessoa, com as opções É um gasto, Alguém da casa, Conta minha e Não lançar; e o fim, com 9 lançamentos gravados e os botões Pronto e Desfazer tudo." />
  <br /><sub>O extrato pela Juju: resumo, blocos por categoria, dúvidas uma a uma e o lote inteiro com "Desfazer tudo".</sub>
</p>

<p align="center">
  <img src="docs/media/o-mes-na-mao.png" width="960" alt="Três telas: o Início, com o carrossel 3D da sobra do mês e a lista Seu dinheiro; o Meu mês, com o que entra em dinheiro e no vale, separados, e o que sai por grupo; e a carteira de cartões de crédito." />
  <br /><sub>O Início com o carrossel 3D, o Meu mês com dinheiro e vale sempre separados, e a carteira de cartões.</sub>
</p>

<p align="center">
  <img src="docs/media/design-system.png" width="960" alt="A gallery do design system no navegador: menu de fundação, componentes, profundidade, telas e sentidos, e a página Conversa com a fala da Juju, a fala de quem usa e uma fala com lista de compras e botões." />
  <br /><sub>A gallery do design system: cada componente, estado e tela do app, navegável, com som e tema escuro ·
  <a href="https://cajui-teal.vercel.app/gallery/">ver ao vivo</a> · <a href="packages/design_system">o README dela</a></sub>
</p>

<p align="center">
  <img src="docs/media/design-system/widget-chegada.webp" width="260" alt="O widget de vidro na tela inicial, sobre uma aurora de luz, com a sobra do mês e dois atalhos; o toque no número abre o app crescendo de dentro do widget, e os números do Início chegam atravessando o vidro." />
  <br /><sub>O widget de vidro e a chegada no app, gravados na gallery com números inventados.</sub>
</p>

## Arquitetura

Arquitetura limpa, organizada por feature (`features/<x>/{application,infrastructure,presentation}`). O
`composition.dart` é o único lugar que liga uma porta a um adaptador, e nenhuma conta mora no app: ele pergunta ao
domínio.

```mermaid
flowchart LR
  subgraph PHONE["Celular Android"]
    UI["Telas Flutter<br/>ViewModels com estado selado"]
    APP["Casos de uso<br/>(application)"]
    NAT["Kotlin<br/>OCR · notificações · widget"]
    LOG[("Livro local<br/>eventos cifrados")]
  end
  DOM["Domínio<br/>Dart puro"]
  subgraph VM["Servidor (VM)"]
    API["API Shelf"]
    STORE[("Registro de eventos<br/>AES-256-GCM + SHA-256")]
    AI["Leitura com IA<br/>máscara e esquema"]
  end
  WEB["Web<br/>modo consulta"]
  DS["IA (Claude)"]

  UI --> APP --> DOM
  NAT --> APP
  APP --> LOG
  APP -- "lançamentos + chave de acesso" --> API
  WEB --> API
  API --> DOM
  API --> STORE
  API --> AI --> DS
```

**O extrato pela Juju**, do compartilhamento ao lote gravado:

```mermaid
sequenceDiagram
  participant P as Pessoa
  participant C as Celular
  participant S as Servidor
  participant I as IA
  P->>C: compartilha o PDF do app do banco
  C->>C: OCR por página, linhas pela posição, número consertado
  C->>C: reconhece o extrato e mascara nomes, CPF e conta
  loop cada página
    C->>S: linhas numeradas, já mascaradas
    S->>I: instrução fixa + dados entre marcadores
    I-->>S: movimentações em JSON
    S-->>C: só as que passam no esquema e têm o valor escrito
    C->>C: pede de novo as linhas com data e valor que faltaram
  end
  C->>P: resumo, blocos por categoria, dúvidas uma a uma
  P->>C: Pode lançar (N)
  C->>S: lote com chaves pelo conteúdo
```

Detalhes nas [ADRs](docs/architecture/adr): a [030](docs/architecture/adr/ADR-030-extrato-pela-juju.md) é a do
extrato, a [020](docs/architecture/adr/ADR-020-chave-da-casa.md) é a do acesso, a
[022](docs/architecture/adr/ADR-022-a-ia-le-a-foto.md) é a da foto lida pela IA.

### O app

O app é Flutter, em arquitetura limpa organizada por feature: cada uma tem `application` (casos de uso),
`infrastructure` (adaptadores) e `presentation` (telas e ViewModels).

- **MVVM com estado selado.** A tela só desenha; o ViewModel é um `Notifier` do Riverpod, e o estado é uma hierarquia
  selada, então um `switch` exaustivo faz estado novo sem desenho não compilar.
- **Navegação por Coordinator.** Cada feature tem um coordinator sobre a porta `SceneNavigator`: a tela diz o que a
  pessoa tocou, e o coordinator decide qual cena abrir. ViewModel nunca navega.
- **Uma raiz de composição.** `composition.dart` é o único lugar que liga uma porta ao adaptador, e um verificador
  reprova camada que importa a de fora. Nenhuma conta mora no app: ele pergunta ao domínio.
- **Offline primeiro.** O livro vive no aparelho, cifrado, como uma sequência de eventos, e sincroniza quando há rede.
- **Sem aparência solta.** O app é um `WidgetsApp`, e não um `MaterialApp`: toda cor, tipo e duração vem do design
  system, e o verificador reprova quem tentar definir uma na mão.

### O servidor

Um executável único em Dart (Shelf), rodando numa VM na **Oracle Cloud Infrastructure (OCI)**, na camada gratuita,
atrás de um proxy com TLS automático e gerenciado como serviço do sistema. O que ele faz:

- **Guarda o livro como registro de eventos.** Cada evento é cifrado com AES-256-GCM e encadeado por SHA-256, então
  qualquer mudança no passado é detectada. Há resumos por arquivo e um backup diário cifrado, copiado para fora da
  máquina.
- **Valida tudo o que chega.** A leitura do JSON é estrita (campo a mais, faltando ou de tipo errado é recusado), as
  regras do domínio são conferidas de novo no servidor, e todo erro sai com o código de um catálogo de 47 códigos.
- **Autentica.** O aparelho entra com uma chave de acesso, um segredo aleatório compartilhado pelos celulares da mesma casa (no projeto, a "chave da casa"); o servidor guarda só o hash e compara em tempo constante. A
  consulta pela web entra com o código do autenticador (TOTP, RFC 6238), que abre uma sessão de leitura de 30 dias, com
  trava depois de cinco erros.
- **Protege.** Limite de taxa por origem, CORS de uma origem só, e segredos em credenciais cifradas do serviço, nunca no
  repositório.
- **Fala com a IA** (próxima seção) e só devolve o que passa no esquema.

Cada rota está documentada, com request, response e erros, em [`docs/api.md`](docs/api.md).

### A IA

A Juju é uma assistente de conversa com ***tool use***: o servidor integra a API de Mensagens da Anthropic (Claude) e
oferece ao modelo ferramentas de verdade: lançar um gasto, cancelar, listar, registrar renda, recategorizar e abater
uma dívida. As decisões que valem contar:

- **A IA lê, o domínio decide.** O modelo devolve dado estruturado; quem faz conta e aplica regra é o domínio.
- **Uma porta, vários fornecedores.** O servidor só conhece a interface `ChatClient` (padrão Strategy). Há adaptadores
  para o Claude e para a DeepSeek, escolhidos por configuração, e um cliente de mentira nos testes.
- **Privacidade antes da IA.** Nome de pessoa, CPF e conta são mascarados no celular, antes de o texto sair dele.
- **A resposta da IA é entrada não confiável.** Todo valor em reais que ela escreve é conferido contra o resumo que o
  servidor mandou, as ferramentas e a pergunta (RN-943). Valor sem origem volta ao modelo uma vez; se ele insistir, sai
  uma resposta de formato fixo.
- **Limites.** Orçamento mensal de tokens, disjuntor (*circuit breaker*) e prazo por chamada; se a IA cai, o app avisa e
  continua lançando à mão.

### Sincronização entre aparelhos

O livro é uma sequência de fatos, cada um com uma chave de idempotência: reenviar o mesmo pedido não grava de novo. O
servidor só guarda e devolve; quem faz conta é cada celular, com o mesmo domínio. O app olha o topo do registro a cada
20 segundos e só baixa o livro quando ele andou. Cartão e categoria editados em dois aparelhos valem pela versão mais
nova, e um lançamento cancelado nunca ressuscita.

### O design system

O design system é um pacote Dart próprio, [`packages/design_system`](packages/design_system), e o app é a primeira
aplicação dele:

- **Tokens por papel**: cor, tipo, espaço, raio, sombra, duração, curva e som saem do pacote por nome de papel.
  Trocar a cor de todos os botões de ação é editar uma linha, e o teste de contraste roda em seguida.
- **Componentes** em todos os estados: botões, valores, cartões, campos, avisos, conversa, anéis e linha do tempo do
  mês, cartão de crédito em 3D, vidro, carrossel e pilha de cartões.
- **Movimento e som**: rolagem em profundidade, entrada cinematográfica e um som por família de controle, com três
  níveis de movimento e respeito a "reduzir movimento".
- **Acessibilidade**: contraste calculado, alvos de toque de 48 dp, fonte do sistema ampliada e leitor de tela.
- **A gallery** ([ao vivo](https://cajui-teal.vercel.app/gallery/)) é o app de exemplo: mostra cada componente, cada tela do app em 69 estados e cada
  decisão de design, com tema escuro, som e movimento ajustáveis.

### O lado nativo (Android)

Os módulos em Kotlin cobrem o que o Flutter não alcança: receber compartilhamento de imagem, PDF e texto; OCR no
aparelho com ML Kit (o PDF é rasterizado pelo próprio Android); leitura das notificações dos bancos; o widget de vidro da
tela inicial; lembretes de vencimento; ditado de voz; e a chave do aparelho guardada no Keystore.

## Desafios que resolvi

### 1. O extrato inteiro numa conversa, sem lançar nada em dobro

- **Problema:** um extrato mensal tem dezenas de linhas, e a leitura antiga parava em 30. Ler de novo, compartilhar
  duas vezes ou desfazer e relançar não podia duplicar nada.
- **Solução:** o celular lê página por página (`POST /v1/statements/read-part`), e a IA só lê. A conversa é montada
  pelo app ([`StatementDigest`](packages/domain/lib/src/statements/statement_digest.dart),
  [`StatementWords`](packages/domain/lib/src/statements/statement_words.dart)). Cada linha gravada leva uma chave
  feita do conteúdo, e não da posição ([`StatementLineKey`](packages/domain/lib/src/statements/statement_line_key.dart)),
  mais o carimbo do lançamento. "Já está no Cajui" é casamento um a um, por valor, dia e nome
  ([`StatementMatches`](app/lib/src/features/statements/application/statement_matches.dart)).
- **Resultado:** ler o mesmo extrato de novo mostra "já estava no Cajui"; duas compras iguais na mesma padaria
  continuam sendo duas; e "Desfazer tudo" seguido de "Pode lançar" grava de novo, com ids que nunca foram desfeitos.

### 2. A tabela que o OCR desmonta

- **Problema:** no primeiro teste no aparelho, a linha "Restaurante Sabor" saiu com o valor do mercado. O ML Kit
  devolve o texto por blocos, e numa página em forma de tabela cada coluna vira um bloco. Além disso, o OCR às vezes
  quebra o número ("+3.120,,00", "-32, 80"), e o servidor descartava a linha sem dizer nada.
- **Solução:** o lado nativo remonta cada página em linhas pela altura dos pedaços
  ([`TextRows.kt`](app/android/app/src/main/kotlin/app/cajui/capture/TextRows.kt)); o domínio conserta o número que o
  OCR quebrou ([`OcrLine`](packages/domain/lib/src/statements/ocr_line.dart)); e o celular confere a resposta da IA:
  linha com data e valor que ela não citou é pedida de novo, e o que ainda faltar é dito
  ([`MissedLines`](app/lib/src/features/statements/application/missed_lines.dart)).
- **Resultado:** nenhuma linha some calada. Os casos do aparelho viraram testes com as linhas exatas que o OCR leu.

### 3. Cartão é forma de pagamento; vale é outra moeda

- **Problema:** a planilha sabia que a compra no cartão conta no mês em que foi feita, e não no mês da fatura, e que o
  vale-alimentação não é dinheiro. Um app que soma tudo num total só erra o mês inteiro.
- **Solução:** todo valor do mês é um `TenderAmounts`, com dinheiro e vale em campos separados, e não existe operação
  que junte os dois. A fatura é uma visão calculada, nunca um lançamento; a compra parcelada vira compromisso do
  bloco de dívidas, parcela a parcela.
- **Resultado:** o compilador recusa a soma errada. O pagamento da fatura lido num extrato aparece como "não conta".

### 4. Privacidade antes da IA

- **Problema:** extrato e comprovante trazem nome de quem recebeu o Pix, CPF e número de conta.
- **Solução:** a máscara roda no celular antes de qualquer envio
  ([`PiiRedactor`](packages/domain/lib/src/receipts/pii_redactor.dart),
  [`TransferLine`](packages/domain/lib/src/statements/transfer_line.dart)). O nome de verdade fica no aparelho, e é
  ali que aparece na pergunta ("Pix para Carla M Souza"). A resposta da IA passa por esquema fechado, e todo valor
  precisa estar escrito no texto. Resposta lembrada que fala de pessoa nunca vira exemplo para a IA.
- **Resultado:** a IA vê "PIX ENVIADO [NOME] 150,00" e o celular mostra o nome. Há uma suíte de comprovantes
  maliciosos que tenta injeção de prompt.

<details>
<summary><b>Mais 5 desafios: sincronização, verificador próprio, troca de tela, som e o widget de vidro</b></summary>

### 5. Dois celulares, um livro

- **Problema:** o casal usa dois celulares, e cada um lança sem rede às vezes.
- **Solução:** registro de eventos (nada é apagado; corrigir e cancelar acrescentam), ids que nascem do conteúdo e
  "a edição mais nova vence" ([ADR-019](docs/architecture/adr/ADR-019-dois-aparelhos-um-livro.md)). Com o app na
  frente, cada aparelho pergunta ao servidor, a cada 20 segundos, um número que só anda quando o livro muda
  ([ADR-024](docs/architecture/adr/ADR-024-sincronia-ao-vivo-e-auth-simples.md)).
- **Resultado:** o que um lança aparece no outro em segundos, e descer o livro de novo nunca duplica nada.

### 6. Regras de código que a máquina reprova

- **Problema:** arquitetura limpa só por convenção se desfaz no primeiro prazo apertado.
- **Solução:** um verificador próprio, escrito com `package:analyzer` ([`tool/code_metrics`](tool/code_metrics)),
  roda no pre-commit e na esteira. Ele reprova import de fora para dentro das camadas, arquivo com mais de 300
  linhas, função com mais de 30, mais de 3 níveis de bloco, dois tipos públicos no mesmo arquivo e cor escrita à mão
  numa tela.
- **Resultado:** 1.166 arquivos conferidos a cada commit, nenhum limite estourado. Trocar a cor de todos os botões é
  mudar um token.

### 7. A troca de tela que misturava duas telas

- **Problema:** ao abrir uma tela, a anterior ainda aparecia por baixo da nova por alguns quadros.
- **Solução:** a câmera entre telas virou uma passagem num relógio linear comum
  ([`CameraMove`](packages/design_system/lib/src/motion/camera_move.dart)): a tela de trás sai inteira antes de a
  nova chegar.
- **Resultado:** conferido no aparelho por gravação de tela, quadro a quadro, e preso por um teste que falha com o
  código antigo.

### 8. Um som por família de controle

- **Problema:** os sons escolhidos vinham em MP3, com silêncio no começo e volumes diferentes. No celular, mesmo no
  volume máximo, quase sumiam: o alto-falante de um telefone quase não toca abaixo de 300–400 Hz, e o clique do botão
  tinha 99% da energia entre 150 e 300 Hz.
- **Solução:** corte do silêncio, entrada de 2 ms e saída em cosseno; depois, um masterizador próprio
  ([`level_sounds.py`](tool/sound/level_sounds.py)) gera harmônicos dos graves (o ouvido reconstrói a nota), corta o
  subgrave e satura de leve até o alvo de cada família, medido como o celular ouve (ponderação K da ITU-R BS.1770). A
  origem e a licença de cada arquivo estão em [`CREDITS.md`](packages/design_system/assets/CREDITS.md).
- **Resultado:** botão de ação, cartão, tecla, chave e chip têm cada um o seu som, como token do design system, e um
  teste reprova o som que voltar a ficar baixo demais para o alto-falante.

### 9. Um widget de vidro que o Android não deixa desfocar

- **Problema:** o widget da tela inicial devia ter cara de vidro, mas um widget Android é desenhado por outro processo
  (`RemoteViews`): não há desfoque do papel de parede, sombreador nem animação própria.
- **Solução:** a aurora é só luz difusa, em camadas de gradiente radial, e o vidro é um véu translúcido com borda de
  luz: parece fosco porque o que está atrás já não tem contorno. A raiz do widget é marcada como
  `@android:id/background`, e o Android 12+ abre o app crescendo de dentro dele. No app, a rota `widget` toca a
  chegada ([`CajuiGlassArrival`](packages/design_system/lib/src/motion/cajui_glass_arrival.dart)): os números do
  Início atravessam o vidro, com a aurora acesa atrás.
- **Resultado:** a mesma composição existe em componentes do design system (`CajuiAurora`, `CajuiGlassPanel`,
  `CajuiOrb`), e a gallery mostra o gesto inteiro, do toque no widget à chegada.

</details>

## Stack

| Camada            | Tecnologias                                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| App               | Flutter 3.47 (Android para usar, web para consultar), Riverpod 3 com estado selado, Dart 3.13          |
| Nativo (Android)  | Kotlin: compartilhamento, OCR com ML Kit no aparelho, leitura de notificações, widget, lembretes       |
| Domínio           | Dart puro, sem Flutter e sem `dart:io`: o mesmo código no celular e no servidor                        |
| Servidor          | Dart + Shelf, compilado em executável único, numa VM da Oracle Cloud (OCI), com proxy TLS e serviço do sistema               |
| Dados             | Registro de eventos cifrado com AES-256-GCM e encadeado por SHA-256, backup diário                     |
| IA                | Claude (API de Mensagens, com ferramentas) ou DeepSeek, atrás da mesma porta `ChatClient`                  |
| Design system     | Pacote próprio com tokens, componentes, vidro, movimento 3D e sons; gallery publicada na Vercel        |
| Qualidade         | `very_good_analysis`, verificador próprio, cobertura com piso por pacote, varredura de segredos        |
| Esteira           | GitHub Actions, Conventional Commits, Vercel para a web                                                |

## Padrões de projeto aplicados

O Cajui também é o meu trabalho de Dispositivos Móveis II, que pede o app e o design system seguindo os padrões
estudados no semestre. A regra que segui foi **um padrão por pergunta**, sem misturar dois para a mesma coisa.

| Pergunta      | Padrão escolhido                                                            | Onde está                                                                                                                                                                                       |
| ------------- | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Uma tela      | MVVM: a tela só desenha, o `Notifier` do Riverpod decide, o estado é selado | [`entries_view_model.dart`](app/lib/src/features/ledger/presentation/entries_view_model.dart)                                                                                                   |
| O app inteiro | Camadas (Clean), travadas por um verificador                                | [`layer_rules.dart`](tool/code_metrics/lib/src/layer_rules.dart) · [ADR-001](docs/architecture/adr/ADR-001-monorepo-e-dominio-compartilhado.md)                                                 |
| Navegação     | Coordinator: o ViewModel diz o que houve, o Coordinator decide para onde ir | [`core/navigation`](app/lib/src/core/navigation) · [ADR-031](docs/architecture/adr/ADR-031-navegacao-com-coordinator.md)                                                                        |
| Dependências  | Injeção com Riverpod, ligada num único composition root                     | [`composition.dart`](app/lib/src/app/composition.dart) · [ADR-002](docs/architecture/adr/ADR-002-estado-com-riverpod.md), [ADR-032](docs/architecture/adr/ADR-032-injecao-e-factory-de-cena.md) |
| Pastas        | Por feature: `features/<x>/{application,infrastructure,presentation}`       | uma pasta por cena                                                                                                                                                                              |
| Repositório   | Monorepo de pacotes                                                         | [`packages/`](packages) · [ADR-001](docs/architecture/adr/ADR-001-monorepo-e-dominio-compartilhado.md)                                                                                          |

<details>
<summary><b>As peças da aula e onde elas moram no Cajui</b></summary>

| Peça da aula                           | No Cajui                                                                                                                                                                                                                                                                                                                         |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Core (modelos, repositórios, `Result`) | [`packages/domain`](packages/domain) e [`packages/api_contract`](packages/api_contract)                                                                                                                                                                                                                                          |
| Design System                          | [`packages/design_system`](packages/design_system)                                                                                                                                                                                                                                                                               |
| Cena                                   | Uma pasta por feature, com `application`, `infrastructure` e `presentation`                                                                                                                                                                                                                                                      |
| Factory de cena                        | O Coordinator monta a tela e o provider do ViewModel entrega as dependências ([ADR-032](docs/architecture/adr/ADR-032-injecao-e-factory-de-cena.md))                                                                                                                                                                             |
| Coordinator                            | Um por feature, em `presentation`, sobre a porta [`SceneNavigator`](app/lib/src/core/navigation/scene_navigator.dart): [`LedgerCoordinator`](app/lib/src/features/ledger/presentation/ledger_coordinator.dart), `BudgetCoordinator`, `CardsCoordinator`… ([ADR-031](docs/architecture/adr/ADR-031-navegacao-com-coordinator.md)) |
| View                                   | `*_page.dart`, só desenha, com os componentes do design system                                                                                                                                                                                                                                                                   |
| ViewModel                              | `*_view_model.dart` (um `Notifier`), com o estado selado ao lado                                                                                                                                                                                                                                                                 |
| Server                                 | A porta da feature (`AssistantGateway`, `LedgerDownlink`…) e o adaptador HTTP em `infrastructure`                                                                                                                                                                                                                                |
| Storage                                | `PreferencesStore`, `HouseholdKeyStore` e o livro de eventos, cada um com versão real e em memória                                                                                                                                                                                                                               |

</details>

<details>
<summary><b>Padrões de projeto: onde aparece cada um</b></summary>

| Padrão     | Onde aparece                                                                                                                                                                                                                                                          |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Factory    | `factory of(...)` em [`home_view.dart`](app/lib/src/features/home/application/home_view.dart) e [`statement_view.dart`](app/lib/src/features/cards/application/statement_view.dart)                                                                                   |
| Adapter    | [`NativeReceiptReader`](app/lib/src/features/receipts/infrastructure/native_receipt_reader.dart) encaixa o OCR do Android na porta `ReceiptReader`; [`HttpAssistantGateway`](app/lib/src/features/assistant/infrastructure/http_assistant_gateway.dart) encaixa a API |
| Strategy   | [`ChatClient`](server/lib/src/ai/chat_client.dart) com [`DeepSeekChatClient`](server/lib/src/ai/deepseek_chat_client.dart) e [`ClaudeChatClient`](server/lib/src/ai/claude_chat_client.dart), escolhido na subida do servidor                                         |
| Observer   | `ref.watch` do Riverpod nas telas e `Stream` na sincronização ao vivo                                                                                                                                                                                                 |
| Repository | [`LedgerJournal`](app/lib/src/features/ledger/application/ledger_journal.dart), com versão local, remota e em memória                                                                                                                                                 |
| Result     | [`Result` e `Failure` selados](packages/domain/lib/src/shared/result.dart): regra recusada é valor, e não exceção; [`Decoded`](packages/api_contract/lib/src/decoded.dart) faz o mesmo com o pedido que vem de fora                                                   |

</details>

**Entregas da disciplina:**

| Entrega                               | Onde está                                                                                                                                |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Tema do app                           | [Problema e público](docs/spec/problem.md) e [marca](docs/brand)                                                                         |
| Protótipo das telas                   | [Wireframes de baixa fidelidade](docs/design/wireframes.html): mapa de navegação, 14 telas e os estados                                  |
| Componentes e sample do design system | [`packages/design_system`](packages/design_system) e a [gallery ao vivo](https://cajui-teal.vercel.app/gallery/), que é o app de exemplo |
| Documentação da API                   | [`docs/api.md`](docs/api.md): cada rota com request, response e erros                                                                    |

## Segurança e privacidade

- **Uma chave de acesso** de 32 bytes aleatórios, gerada no computador de quem instala e compilada no APK. O servidor guarda só
  o hash, numa credencial cifrada do systemd ([ADR-020](docs/architecture/adr/ADR-020-chave-da-casa.md)).
- **A web entra com código de autenticador** (TOTP, RFC 6238), e o segredo também fica cifrado na VM
  ([ADR-027](docs/architecture/adr/ADR-027-codigo-do-autenticador.md)).
- **A chave da IA existe só no servidor**, nunca no app, no bundle web ou no repositório. Um verificador varre a
  árvore **e o histórico inteiro** a cada commit e a cada PR.
- **Dados cifrados em repouso:** cada registro com AES-256-GCM e encadeado por SHA-256. Dá para provar que ninguém
  mexeu no passado.
- **Máscara antes da IA e resposta da IA como entrada hostil**, como no [desafio 4](#4-privacidade-antes-da-ia).
- Modelo de ameaças em STRIDE e checklist ASVS nível 2 em [`docs/security`](docs/security). Onde um controle **não**
  está implementado, está escrito que não está.

## Qualidade

| Item                | Situação                                                                                                  |
| ------------------- | --------------------------------------------------------------------------------------------------------- |
| Testes              | **1.850**: app 611 · domínio 493 · servidor 253 · design system 257 · contrato 104 · gallery 81 · persistência 25 · verificador 26 |
| Cobertura           | contrato 93,2% · domínio 92,9% · persistência 91,5% · servidor 89,9% · design system 88,0% · app 86,4%   |
| Regra ↔ teste       | Cada regra tem número (`RN-xxx`) e um teste com o mesmo número. Exemplo numérico da especificação vira teste, centavo a centavo |
| Textos              | Todo erro que a pessoa lê vem de um catálogo de 47 códigos, e o código que o exibe é **gerado** dele. Um teste por código garante que nenhum texto sai com marcador por preencher |
| Voz                 | Termos proibidos ("déficit", "estourou", exclamação) são reprovados por teste em todas as frases do app |
| Analisador          | `very_good_analysis`, zero aviso                                                                          |
| Verificador próprio | 1.166 arquivos, nenhum limite estourado                                                                     |
| Acessibilidade      | Lighthouse 100 na web; semântica ligada desde a raiz; o leitor de tela diz quem fala na conversa         |

**Em números:** 108 mil linhas de Dart em 1.168 arquivos (40 mil delas de teste), 2,9 mil de Kotlin, 134 requisitos não funcionais, 32 ADRs e 159 pull requests.

## O que deu errado

Problemas que apareceram no caminho, e como cada um foi resolvido:

- **Testes verdes não pegaram o que o aparelho pegou.** O extrato passou em centenas de testes, e o primeiro PDF de
  verdade misturou colunas ([desafio 2](#2-a-tabela-que-o-ocr-desmonta)). Antes disso, o app lia o corpo de erro da
  API no lugar errado, e o teste não pegou porque o servidor de mentira imitava a suposição do cliente, não o servidor.
- **A compra parcelada contava inteira no mês da compra.** O domínio sempre soube fazer certo; a camada de cima
  somava sozinha em vez de perguntar. Era o conceito central do produto, quebrado.
- **Três textos de erro saíam quebrados.** Um teste que passa por todo código de erro que a leitura do extrato pode
  trazer achou três marcadores sem valor.
- **A web nunca tinha rodado.** O cliente HTTP do `dart:io` quebra ao ser criado no navegador, e o app morria antes
  do primeiro quadro, sem mensagem.
- **Um compartilhamento ilegível fechava o app na abertura.** Um app hostil manda isso de propósito.

Cada um foi achado por revisão adversarial ou por uso real, e cada um tem hoje um teste que prende o caso.

## Custo

**R$ 0,00 fixo.** VM gratuita na Oracle, TLS do Let's Encrypt, DNS dinâmico gratuito, repositório e esteira no GitHub
e a web na Vercel, no plano Hobby. O único custo variável é a IA, cobrada por uso: com a DeepSeek a conta fica em **cerca de R$ 0,60 por mês** no
cenário de 120 lançamentos ([a conta está aqui](docs/ops/ai-cost-estimate.md)); o Claude custa mais por token, e a
troca é só de configuração.

---

## Para desenvolvedores

### Começando

**Pré-requisitos:** Flutter 3.47 (com Dart 3.13), Android SDK e um aparelho ou emulador Android. Python 3 só para os
verificadores da esteira.

```bash
git clone https://github.com/Marcos-Codfy/finance-cajui.git
cd finance-cajui
flutter pub get
cd app && flutter run
```

Sem a chave de acesso compilada, o app nasce sem servidor e funciona sozinho no aparelho. A chave
(`CAJUI_ACCESS_KEY`) e o endereço do servidor (`CAJUI_API_URL`) entram por `--dart-define` e nunca são versionados. A web de consulta sai com
`flutter build web --no-web-resources-cdn` dentro de `app/`.

### Scripts

| Comando (PowerShell, da raiz)          | O que faz                                                                    |
| -------------------------------------- | ---------------------------------------------------------------------------- |
| `.\scripts\apk.ps1 -Release`           | Compila o APK de uso e instala no celular ligado (chave e servidor por variável de ambiente) |
| `.\scripts\servidor-local.ps1`         | Sobe o servidor nesta máquina, lendo a chave da IA de fora do repositório    |
| `dart run tool/code_metrics/bin/check.dart` | Roda o verificador de tamanho e camadas                                  |

<details>
<summary><b>Testes de cada pacote</b></summary>

```bash
cd app && flutter test
cd packages/design_system && flutter test
cd packages/design_system/gallery && flutter test
cd packages/domain && dart test
cd packages/api_contract && dart test
cd packages/persistence && dart test
cd server && dart test
cd tool/code_metrics && dart test
```

</details>

### Estrutura do projeto

<details>
<summary><b>Árvore de pastas</b></summary>

```text
app/                      Flutter: Android para usar, web para consultar
  lib/src/features/       assistant, statements, receipts, ledger, budget, cards, home, export, reminders…
  android/                Kotlin: compartilhamento, OCR, notificações, widget, lembretes
packages/
  domain/                 regras de negócio em Dart puro
  api_contract/           DTOs, leitura estrita de JSON, catálogo de erros
  persistence/            registro de eventos cifrado, com cadeia de hash
  design_system/          tokens, componentes, movimento, sons
    gallery/              o sample navegável do design system
server/                   Dart + Shelf: API, leitura com IA, sincronização
tool/                     verificadores: tamanho, camadas, segredos, cobertura
docs/                     especificação, ADRs, marca, segurança, custo e desempenho
scripts/                  APK, servidor local e build da web
```

</details>

### Publicação

- **Servidor:** um executável único em Dart (`dart compile exe`), compilado na esteira e servido atrás de um proxy com
  TLS. A operação da máquina (provisionamento, serviço, backup) não faz parte desta cópia; as decisões estão nas
  ADRs [003](docs/architecture/adr/ADR-003-backend-dart-shelf.md),
  [005](docs/architecture/adr/ADR-005-criptografia-em-repouso-e-dbtool.md) e
  [011](docs/architecture/adr/ADR-011-hospedagem-a-custo-zero.md).
- **Web:** a Vercel publica a `main`: a web de consulta na raiz e a gallery do design system em `/gallery/`, as duas
  compiladas pelo [`scripts/web.sh`](scripts/web.sh).
- **App:** o APK de uso é gerado e instalado por cabo, com a chave de acesso e o endereço do servidor compilados.

## Roadmap

- [x] Especificação, marca e design system aprovados
- [x] Domínio com cartão como forma de pagamento e vale como outra moeda
- [x] Comprovante por foto, print e PDF, com OCR no aparelho e IA quando as regras não bastam
- [x] Notificações do banco que viram lançamento
- [x] A Juju: lançar falando, perguntar com os números da casa, ditar
- [x] Dois celulares sincronizados ao vivo e web de consulta com autenticador
- [x] Extrato pela Juju, página a página, com lote e "Desfazer tudo"
- [x] Lembretes de vencimento, widget, planilha do mês e movimento 3D
- [ ] Conferir a leitura com extratos reais de cada banco
- [ ] Vários arquivos do mesmo compartilhamento numa leitura só
- [x] Publicar a gallery do design system ([ao vivo](https://cajui-teal.vercel.app/gallery/))
- [ ] Ler a camada de texto do PDF, além do OCR

## Créditos

- **Especificação, design e desenvolvimento:** [Marcos Vinicius Muniz Arruda](https://github.com/Marcos-Codfy)
- **Fontes:** Fraunces e Geist (SIL Open Font License)
- **Sons de toque:** Pixabay, sob a Pixabay Content License, tratados no projeto; os demais são sintetizados aqui
  ([origem de cada arquivo](packages/design_system/assets/CREDITS.md))
- **Ícones e ilustrações:** desenhados no próprio projeto

## Licença

[MIT](LICENSE). As fontes e os sons têm as licenças próprias listadas nos créditos acima.

---

<div align="center">

<sub>O nome vem do **cajuí** (<i>Anacardium humile</i>), o cajuzinho rasteiro do Cerrado tocantinense.</sub>

<sub>Feito por <a href="https://github.com/Marcos-Codfy">Marcos Vinicius Muniz Arruda</a> · Palmas-TO · 2026</sub>

</div>
