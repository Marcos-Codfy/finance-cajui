# ADR-020 — A chave da casa: um segredo só, em todos os aparelhos

**Estado:** aceita · 07/10/2026 — por pedido do dono ("não quero esse lance de cadastrar dispositivo com código"; "sempre que eu atualizar algo no app que seja sincronizado")
**Substitui:** [ADR-008](ADR-008-autenticacao.md) (cadastro de aparelho por código, desafio assinado pelo Keystore, pareamento da web por código de dois minutos) e [ADR-013](ADR-013-consulta-na-web.md) no que diz sobre a sessão da web morrer com a aba
**Relacionada:** [ADR-019](ADR-019-dois-aparelhos-um-livro.md) (a sincronização que agora acontece sozinha) · [ADR-005](ADR-005-cifra-do-registro.md) (a credencial cifrada do systemd, reaproveitada)

## Contexto

A ADR-008 desenhou autenticação para um risco que o dono não tem: cada celular cadastrado por SSH com código de dez minutos, cada chamada provada por assinatura do Keystore com biometria do dia, a web pareada por código de dois minutos gerado no celular e perdida ao fechar a aba. Em 06/10 o dono, depois de um mês de uso, disse que o app estava "chato de usar", que exagerei, e pediu: mexeu no app, sincronizou — sem cadastrar aparelho, sem código.

Os fatos: é **uma pessoa**, com dois celulares e um navegador. Os aparelhos são dela. O risco real é alguém com a URL do servidor ler o dinheiro dela — e esse risco um segredo compartilhado cobre.

## Decisão

1. **Uma chave da casa**: 32 bytes aleatórios em base64url, gerados uma vez no PC do dono (`scripts/chave-da-casa.ps1`), guardados em `Documentos\Cajui\chave\cajui-chave-da-casa.txt`, fora do repositório. Nunca passa pelo chat.
2. **No Android ela vai compilada no APK** (`--dart-define=CAJUI_ACCESS_KEY`, posto por `scripts/apk.ps1`). O APK só existe nas mãos do dono: instalar é entrar. Build sem a chave — a esteira, um teste — nasce sem servidor e funciona sozinho.
3. **Na web ela é digitada uma vez** e fica no `localStorage` do navegador até a pessoa sair. É o único rastro que a consulta deixa, por escolha de quem entrou.
4. **O servidor guarda só o hash**, lido de uma credencial cifrada do systemd (`cajui-access-key`), como a chave dos dados. Toda chamada leva `Authorization: Bearer <chave>`; a comparação percorre o hash inteiro sempre. Sem a credencial, o servidor sobe e só aceita a autenticação antiga.
5. **A autenticação antiga continua aceita** por um tempo: o celular com o APK anterior segue sincronizando até ser atualizado. Tirar o código velho é um passo próprio (BL-069).
6. **O aparelho continua tendo nome**: o identificador derivado da chave pública do Keystore viaja no cabeçalho `X-Cajui-Device`. Não prova nada; separa a conversa de cada celular com o assistente, e é o mesmo que já estava nos registros.
7. **A sincronização acontece sempre que dá**: depois de cada gravação e ao voltar ao app, sem gate de digital. A tela de "Enviar ao servidor", a lista de aparelhos e o convite para o computador deixaram de existir.
8. **A web continua só leitura na interface e por construção** (`RemoteLedgerJournal.append` estoura). No servidor a chave abre escopo completo: quem a tem é o dono, em qualquer aparelho.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Manter o cadastro por código e só automatizar o envio | O código por SSH era a cerimônia que o dono pediu para tirar, e o pareamento da web por aba também |
| Senha digitada uma vez por celular | Equivale à chave compilada com um passo a mais; o APK já é privado |
| Chave compilada também na web | O build da web é público na Vercel: a chave estaria no JavaScript de qualquer visitante |
| Trocar a chave a cada mês | Nada aqui vence: trocar é decisão, com três passos (arquivo, APK, VM), e fica no runbook |

## Consequências

- **Bom:** zero cerimônia. Instalar o APK é entrar; a web pede uma colagem, uma vez.
- **Bom:** cada lançamento sobe na hora, e o outro celular o recebe na próxima abertura.
- **Custo:** o APK carrega a chave; quem obtiver o arquivo do APK obtém a chave. O APK sai só deste PC para os celulares do dono, pelo canal dele. Está no modelo de ameaças como risco aceito.
- **Custo:** a chave no navegador fica ao alcance de uma extensão maliciosa naquele navegador. O dono usa o próprio computador.
- **Custo:** trocar a chave exige recompilar o APK e reenviar à VM — ver o runbook.
- O Keystore e a biometria do Android ficam sem uso no Dart; o código Kotlin que assina continua no app, sem ninguém pedir (BL-070).

## Como se confere

- Testes do servidor: a chave entra em rota de leitura e de escrita; chave errada, parecida ou ausente recebem a mesma recusa; servidor sem credencial não aceita a chave e aceita a sessão antiga; a credencial é lida do diretório do systemd e chave curta não vale.
- Testes do app: a consulta sem chave mostra só a tela de entrada; a chave vai no cabeçalho com o nome do aparelho; sem chave o classificador fica nas regras.
- Em produção, 07/10: servidor com a credencial, S22 com o APK novo sincronizando, web entrando com a chave.
