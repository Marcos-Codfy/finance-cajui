# ADR-008 — Autenticação: chave do aparelho no Android, pareamento na web

- **Estado:** aceita em 2026-09-20, no checkpoint da Fase 4
- **Data:** 2026-09-20
- **Responde:** BL-006, BL-011 e BL-012

## Contexto

Um usuário, dois lugares de acesso. A pesquisa apontou a autenticação da web como o maior buraco do plano (OWASP Top 10 A01 e A07; ASVS 6.1.3 e 6.3.4; WCAG 3.3.8). Três fatos moldam a decisão:

- O plugin `local_auth` devolve só um **booleano** — "a biometria passou". Isso não prova nada ao servidor: um app adulterado devolve `true`. Para contar como fator, a biometria precisa **destravar uma chave** que assina algo (BL-012).
- No navegador não existe armazenamento seguro: o `flutter_secure_storage` da web acaba no `localStorage`, ao alcance de qualquer script.
- Senha é o que se esquece, se reutiliza e se pesca. Num sistema de uma pessoa, dá para não ter senha nenhuma.

## Decisão

### Android — o aparelho é a credencial

1. No primeiro uso, o app gera um par de chaves **EC P-256 no Android Keystore**, em hardware quando houver (StrongBox ou TEE), marcado para exigir **autenticação biométrica a cada uso**. A chave privada nunca sai do chip.
2. **Cadastro do aparelho**: o dono roda `dbtool enroll` no servidor, por SSH, e recebe um código de uso único, válido por 10 minutos. O app envia o código e a chave pública. Quem não tem SSH na VM não cadastra aparelho.
3. **Entrada**: o servidor manda um desafio aleatório; o app pede a biometria, o Keystore assina; o servidor confere com a chave pública cadastrada e emite um **token de acesso opaco, de 15 minutos**, renovável enquanto o app estiver em uso.
4. Tokens são valores aleatórios guardados no servidor, não JWT: com um servidor só, a consulta é em memória, e revogar é apagar.
5. Isso pede código nativo próprio (BiometricPrompt com objeto criptográfico), no mesmo módulo Kotlin da captura.

### Web — pareada pelo aparelho, sem senha

1. Na web, a tela de entrada pede um **código de pareamento**. No celular, em *Ajustes › Computador*, o dono confirma a biometria e o app mostra um código de **8 caracteres, uso único, válido por 2 minutos**.
2. Digitado o código, o servidor abre uma sessão para aquele navegador: **cookie `HttpOnly; Secure; SameSite=Strict`**, 30 minutos de inatividade, 12 horas no máximo. O JavaScript da página não enxerga a sessão; nada vai para `localStorage`.
3. Para o cookie ser de primeira parte, web e API aparecem na **mesma origem**: a Vercel reescreve `/api/*` para o backend ([ADR-011](ADR-011-hospedagem-a-custo-zero.md)).
4. O celular lista as sessões de computador abertas e encerra qualquer uma.
5. A web é **só leitura** também no servidor: a sessão pareada não tem permissão de escrita, além de conversar com o assistente. Não é só a interface que esconde o botão.

### Para os dois

- Tentativas de código e de desafio têm limite de taxa por origem **e** global (`E-RATE-01`).
- Toda falha de autenticação responde a mesma coisa — `E-AUTH-03` ou `E-AUTH-04`, vagos de propósito (RNF-SEC-18).
- Não há prova cognitiva em lugar nenhum: nem senha, nem CAPTCHA (WCAG 3.3.8).

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| `local_auth` + token guardado no app | A biometria viraria enfeite: o servidor confiaria num booleano que o próprio cliente produz |
| Senha, com ou sem TOTP | Pescável, reutilizável e esquecível. Exigiria política de senha, recuperação de conta e proteção contra força bruta — tudo para um usuário que já tem um aparelho com chave em hardware |
| WebAuthn (chave de acesso) na web | É a melhor tecnologia, e fica como evolução. Hoje: a credencial prende-se ao domínio, e o projeto usa subdomínio gratuito que pode mudar; cada navegador precisaria de cadastro próprio; e o pareamento já entrega "sem senha, ligado a um aparelho com biometria" |
| Código QR em vez de código digitado | Exigiria a câmera do computador ou um segundo canal em tempo real. O código de 8 caracteres é o mesmo fluxo, mais simples e mais acessível |
| JWT | Revogar JWT exige lista de bloqueio, que é guardar estado do mesmo jeito. Sem vários servidores, não há o que o JWT resolva |

## Consequências

- **Bom:** não existe segredo memorizado para vazar, e o servidor nunca guarda nada que sirva para entrar — só chaves públicas.
- **Bom:** perder o celular não abre a conta: a chave exige a biometria, e o dono revoga o aparelho pelo `dbtool`.
- **Custo:** trocar de celular exige SSH na VM para cadastrar o novo. Para um sistema pessoal, é proteção, não defeito — e entra no runbook.
- **Custo:** sem celular por perto, não há web. É coerente com o produto: o Android é o app de uso.
- **Risco:** aparelho sem biometria configurada não usa o Cajui (`E-AUTH-01`). Aceito: a alternativa seria enfraquecer o fator para todos.

## Como se confere

- Testes do servidor: desafio reutilizado, vencido e assinado por chave não cadastrada; código de pareamento usado duas vezes e fora do prazo; sessão pareada tentando escrever — tudo recusado, com a mesma resposta vaga.
- Fase 5: este fluxo é o primeiro item do modelo de ameaças.
