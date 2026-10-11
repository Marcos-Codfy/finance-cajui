# ADR-027 — A web entra com o código do autenticador

**Estado:** aceita · 11/10/2026.

O dono pediu "uma ferramenta simples que eu consiga gerar sempre que quiser, ao invés de ser obrigatório ter o app pré-instalado em algum outro para gerar o código". Ele escolheu o código de seis dígitos do Google Authenticator, com um script no PC.

**Relacionada:**
- [ADR-020](ADR-020-chave-da-casa.md): a chave da casa, que continua valendo.
- [ADR-024](ADR-024-sincronia-ao-vivo-e-auth-simples.md): saiu o código de pareamento que dependia de um celular já cadastrado.

## Contexto

Na web, a entrada era a chave da casa: 43 caracteres, guardados num arquivo do PC e nos Ajustes do celular. Digitá-la em outro computador é penoso.

O código de pareamento antigo pedia um celular com o app para gerá-lo. O dono não queria depender disso.

## Decisão

1. **TOTP (RFC 6238).** O código é o do Google Authenticator: HMAC-SHA1, passos de 30 segundos, seis dígitos.
   - O segredo tem 160 bits.
   - Nasce no PC do dono (`scripts/autenticador.ps1`) e fica em `Documentos\Cajui\chave\cajui-autenticador.txt`, fora do repositório.
   - Chega à VM cifrado e preso à máquina (`servidor-atualizar.ps1 -Autenticador`, credencial `cajui-totp`), como a chave da casa.
   - Nunca passa pelo chat nem pelo repositório.
2. **O script do PC também calcula o código** (`-Codigo`): o dono entra na web mesmo sem o celular à mão. Ele mostra a chave para o autenticador quando pedido (`-Mostrar`), e cria o segredo sem mostrar nada (`-Calado`), para quem prepara o servidor por ele.
3. **`POST /v1/auth/code`** troca o código por uma sessão de 30 dias com escopo `webReadOnly`: lê e conversa (RN-906), não grava.
   - A sessão fica no registro como evento `auth.session-opened`, só com o hash do token, e volta quando o servidor reinicia.
4. **Defesas básicas:**
   - vale o passo de agora e os vizinhos;
   - cada passo vale uma vez só;
   - cinco códigos errados seguidos fecham a entrada por quinze minutos;
   - código errado, entrada fechada e servidor sem segredo dão a mesma resposta (`E-AUTH-03`).

   Sem a trava, seis dígitos se acertariam por tentativa em horas, mesmo com o limite de taxa. Com ela, levariam anos.
5. **A tela de entrada aceita os dois:** seis dígitos viram código, e o resto é a chave da casa. O código que não serviu mostra o `E-AUTH-04`, do catálogo.

## Consequências

- Entrar na web de um computador novo é abrir o autenticador e digitar seis dígitos.
- O celular continua entrando com a chave compilada no APK. O código serve só à consulta pela web.
- Trocar o segredo é `autenticador.ps1 -Novo`, refazer a conta no autenticador e levá-lo de novo à VM.

**Não validado:** a primeira configuração no Google Authenticator do dono, que só ele pode fazer.
