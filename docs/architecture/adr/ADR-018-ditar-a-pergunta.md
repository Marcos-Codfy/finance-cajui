# ADR-018 — Ditar a pergunta, com o reconhecedor do aparelho

**Estado:** aceita · 22/09/2026
**Relacionada:** [ADR-010](ADR-010-deepseek.md) (a IA) · [ADR-017](ADR-017-fotografar-comprovante.md) (a câmera, mesmo padrão)

## Contexto

Perguntar ao assistente no celular, andando, digitando com uma mão só, é desconfortável. O dono perguntou se dava para **falar** a pergunta e a IA transcrever.

A DeepSeek **não transcreve áudio**. A API dela expõe um único caminho, `/chat/completions`, com dois modelos de texto (`deepseek-flash` e `deepseek-v4-pro`); o modelo experimental de visão foi aposentado. Não há endpoint de fala, nem em formato próprio nem no formato compatível com a OpenAI.

Mesmo que houvesse, mandar áudio seria a pior escolha possível para este app:

- **Custo.** Áudio custa muito mais que texto, por segundo em vez de por palavra — e o projeto tem orçamento de tokens (RN-960).
- **Privacidade.** Áudio carrega a voz, o ruído de fundo e quem mais estiver falando por perto. A regra do projeto para comprovante é mandar **só o texto extraído, nunca a imagem** (RN-780); o mesmo princípio vale aqui, com mais força.
- **Tempo.** Subir áudio por rede móvel antes de começar a pensar estoura o prazo de 8 s.

## Decisão

**Quem ouve e transcreve é o reconhecedor do próprio aparelho**, chamado por intenção — `RecognizerIntent.ACTION_RECOGNIZE_SPEECH`, em `pt-BR`. É o mesmo padrão da câmera (ADR-017): o Cajui não embute o recurso, ele pede ao Android.

Consequências dessa escolha:

- **Nenhuma permissão nova.** Quem grava é o app de reconhecimento; o Cajui não declara `RECORD_AUDIO`.
- **O Cajui nunca vê áudio.** Não grava, não guarda, não envia. O que atravessa a porta `SpeechInput` já é texto.
- **O áudio não vai para o servidor do Cajui nem para a DeepSeek.** O que sobe, quando sobe, é a pergunta escrita — igual à digitada, e tratada com a mesma desconfiança (RN-950 a RN-955).
- **Custo zero.** O reconhecimento é do sistema, e em aparelho moderno com o pacote de idioma instalado roda **no próprio aparelho**, sem internet.
- **O texto entra no campo, e não é enviado sozinho.** Quem confere o que foi entendido é a pessoa. Reconhecimento erra; pergunta errada enviada sozinha viraria resposta sobre outra coisa.

Aparelho sem reconhecedor não mostra o botão, em vez de mostrar um botão que falha.

## Alternativas consideradas

| Caminho | Por que não |
|---|---|
| Mandar o áudio para a DeepSeek | Ela não aceita áudio. Não existe. |
| Outro provedor de transcrição (Whisper hospedado, Google Speech-to-Text) | Custo fixo ou por minuto, conta nova, chave nova para proteger, e áudio saindo do aparelho. Contra o custo R$ 0 e contra o modelo de ameaças. |
| Embutir um modelo de reconhecimento no APK | Dezenas de MB num APK que já tem o ML Kit, para resolver o que o sistema já resolve. |
| Só o microfone do teclado | Já funciona hoje, e continua funcionando — mas fica escondido atrás do teclado, e é um toque a mais. O botão no campo é o caminho curto. |

## O que fica em aberto

O reconhecedor padrão de muitos aparelhos é o do Google, que **pode** enviar o áudio aos servidores dele para transcrever, conforme a configuração do aparelho e a existência do pacote de idioma local. Isso é escolha da pessoa e do fabricante, e está fora do alcance do app — mas está escrito aqui para que ninguém suponha o contrário. Quem quiser garantir que nada saia do aparelho instala o reconhecimento de voz offline em português nas configurações do Android.

Ditar **um lançamento** inteiro — "gastei quarenta reais no mercado hoje no Pix" — é outra história: precisa interpretar valor, data, categoria e forma de pagamento a partir de fala solta. Fica no BACKLOG (BL-050), e o caminho natural é reaproveitar o que já existe para comprovante: o texto passa pelo mesmo leitor de campos e cai na mesma tela de conferência.
