# ADR-009 — Fixação de certificado no Android

- **Estado:** proposta · aguarda o checkpoint da Fase 4
- **Data:** 2026-09-20

## Contexto

O pedido é fixar o certificado do backend no app (certificate pinning). Três fatos limitam como:

- **Só existe no Android.** Navegador não deixa a página escolher em quem confiar; na web a defesa é HTTPS com HSTS.
- O certificado do servidor vem do **Let's Encrypt e dura 90 dias**. Fixar o certificado folha — ou a chave dele — é marcar data para o app parar de funcionar.
- O cliente HTTP do Dart **não lê** o `network_security_config` do Android. A fixação declarada no manifesto não vale para as chamadas do Flutter; tem de ser feita em Dart.

## Decisão

1. **Fixar as raízes, não a folha.** O cliente HTTP do app usa um `SecurityContext` **sem as raízes do sistema** (`withTrustedRoots: false`), carregado só com as raízes em que o Cajui confia: **ISRG Root X1 e ISRG Root X2** (Let's Encrypt), mais **uma raiz de reserva de outra autoridade**, para o dia em que for preciso trocar de emissor sem publicar app às pressas.
2. As raízes ficam no pacote do app, como arquivos PEM públicos, com a **data de validade conferida por teste**: o teste começa a falhar um ano antes de qualquer raiz vencer.
3. Falha de validação é tratada como erro de segurança: `E-AUTH-03`, vago de propósito, **sem** tentar de novo por outro caminho e sem opção de "continuar assim mesmo".
4. O Caddy envia **HSTS** e só aceita TLS 1.2 ou mais novo. Na web, é essa a proteção.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Fixar o certificado folha ou a chave pública dele | Renovação a cada 90 dias. Para manter a mesma chave entre renovações seria preciso reusar chave privada — o contrário do que se quer — e qualquer troca de servidor quebraria todos os apps instalados |
| `network_security_config` do Android | O motor do Dart não o consulta. Daria a impressão de proteção sem proteger nenhuma chamada |
| Não fixar nada | Deixa o app aceitar qualquer certificado emitido por qualquer autoridade do sistema — inclusive uma instalada no aparelho por um perfil corporativo ou por engano |
| Fixar só as raízes da ISRG, sem reserva | Se o Let's Encrypt trocar de raiz ou sair do ar, o app para até sair versão nova. A reserva custa um arquivo |

## Consequências

- **Bom:** uma autoridade instalada no aparelho não consegue interceptar o tráfego do Cajui.
- **Bom:** a renovação automática do certificado continua funcionando sem tocar no app.
- **Custo:** trocar de autoridade fora das três fixadas exige publicar APK novo antes. Entra no runbook, junto das datas: ISRG Root X1 vale até 2035; X2, até 2040.
- **Limite honesto:** fixar raiz não protege contra emissão indevida **pela própria autoridade fixada**. Para o modelo de ameaças de um app pessoal, é o ponto de equilíbrio entre proteção e o risco de se trancar do lado de fora.
- A depuração com proxy de inspeção deixa de funcionar no build de produção — de propósito. O build de desenvolvimento aceita a raiz do proxy por configuração que **não existe** no build de release.

## Como se confere

- Teste de integração: servidor local com certificado de autoridade **não** fixada — a conexão tem de falhar com `E-AUTH-03`.
- Teste de validade das raízes embutidas, com um ano de antecedência.
- Fase 7: teste de fumaça do APK assinado contra o servidor real.
