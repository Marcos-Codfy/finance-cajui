# Checklist do OWASP ASVS 5.0.0 — nível 2

O Cajui é **autoavaliado contra o OWASP ASVS 5.0.0, nível 2, com exceções listadas** (RNF-SEC-01). A OWASP não certifica nada: este documento é a avaliação do próprio projeto, feita para ser conferida por quem quiser.

Gerado por `tool/security/build_asvs_checklist.py` a partir do CSV oficial, para que nenhum requisito seja esquecido nem inventado. O texto de cada requisito não é copiado aqui: o identificador leva à [fonte](https://github.com/OWASP/ASVS/tree/v5.0.0/5.0) (licença CC BY-SA 4.0).

## Situação

| Situação | Requisitos | Significa |
|---|---|---|
| atende | 13 | O controle já existe, com a evidência indicada |
| planejado | 150 | O controle está decidido numa ADR e nasce no passo indicado. Vira "atende" no PR daquele passo |
| não se aplica | 86 | A tecnologia ou o cenário não existe no Cajui |
| **exceção** | 4 | O nível 2 pede algo que não cabe numa VM a custo zero. Há controle compensatório, por escrito |
| **Total, níveis 1 e 2** | **253** | |

As quatro exceções respondem ao item BL-013. Dizer "ASVS nível 2" sem listá-las seria falso.

O ASVS não cobre backup, DNS, CI nem hospedagem, e não tem capítulo de IA generativa. Esses riscos estão no [modelo de ameaças](threat-model.md): fronteira 3, e a fronteira 2 inteira para injeção de prompt.

## V1 Encoding and Sanitization

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 1.1.1 | L2 | Encoding and Sanitization Architecture | planejado | Entrada decodificada uma vez, na borda da API | ADR-015 | F6-03 |
| 1.1.2 | L2 | Encoding and Sanitization Architecture | planejado | Entrada decodificada uma vez, na borda da API | ADR-015 | F6-03 |
| 1.2.1 | L1 | Injection Prevention | planejado | Sem SQL nem shell; regex do mascaramento com tempo limitado; texto do OCR nunca é interpretado | ADR-010 · T-20 | F6-04 |
| 1.2.2 | L1 | Injection Prevention | planejado | Sem SQL nem shell; regex do mascaramento com tempo limitado; texto do OCR nunca é interpretado | ADR-010 · T-20 | F6-04 |
| 1.2.3 | L1 | Injection Prevention | planejado | Sem SQL nem shell; regex do mascaramento com tempo limitado; texto do OCR nunca é interpretado | ADR-010 · T-20 | F6-04 |
| 1.2.4 | L1 | Injection Prevention | não se aplica | Não há SQL | — | — |
| 1.2.5 | L1 | Injection Prevention | planejado | Sem SQL nem shell; regex do mascaramento com tempo limitado; texto do OCR nunca é interpretado | ADR-010 · T-20 | F6-04 |
| 1.2.6 | L2 | Injection Prevention | não se aplica | Não há LDAP | — | — |
| 1.2.7 | L2 | Injection Prevention | não se aplica | Não há XPath | — | — |
| 1.2.8 | L2 | Injection Prevention | não se aplica | Não há LaTeX | — | — |
| 1.2.9 | L2 | Injection Prevention | planejado | Sem SQL nem shell; regex do mascaramento com tempo limitado; texto do OCR nunca é interpretado | ADR-010 · T-20 | F6-04 |
| 1.3.1 | L1 | Sanitization | planejado | Texto de OCR limpo de caracteres de controle e limitado em tamanho; servidor sem busca de URL vinda de dado | ADR-007 · ADR-010 | F6-04 |
| 1.3.2 | L1 | Sanitization | planejado | Texto de OCR limpo de caracteres de controle e limitado em tamanho; servidor sem busca de URL vinda de dado | ADR-007 · ADR-010 | F6-04 |
| 1.3.3 | L2 | Sanitization | planejado | Texto de OCR limpo de caracteres de controle e limitado em tamanho; servidor sem busca de URL vinda de dado | ADR-007 · ADR-010 | F6-04 |
| 1.3.4 | L2 | Sanitization | planejado | Texto de OCR limpo de caracteres de controle e limitado em tamanho; servidor sem busca de URL vinda de dado | ADR-007 · ADR-010 | F6-04 |
| 1.3.5 | L2 | Sanitization | planejado | Texto de OCR limpo de caracteres de controle e limitado em tamanho; servidor sem busca de URL vinda de dado | ADR-007 · ADR-010 | F6-04 |
| 1.3.6 | L2 | Sanitization | planejado | Texto de OCR limpo de caracteres de controle e limitado em tamanho; servidor sem busca de URL vinda de dado | ADR-007 · ADR-010 | F6-04 |
| 1.3.7 | L2 | Sanitization | planejado | Texto de OCR limpo de caracteres de controle e limitado em tamanho; servidor sem busca de URL vinda de dado | ADR-007 · ADR-010 | F6-04 |
| 1.3.8 | L2 | Sanitization | não se aplica | Não há JNDI | — | — |
| 1.3.9 | L2 | Sanitization | não se aplica | Não há memcache | — | — |
| 1.3.10 | L2 | Sanitization | planejado | Texto de OCR limpo de caracteres de controle e limitado em tamanho; servidor sem busca de URL vinda de dado | ADR-007 · ADR-010 | F6-04 |
| 1.3.11 | L2 | Sanitization | não se aplica | O servidor não envia e-mail | — | — |
| 1.4.1 | L2 | Memory, String, and Unmanaged Code | não se aplica | Dart tem gerência automática de memória | — | — |
| 1.4.2 | L2 | Memory, String, and Unmanaged Code | não se aplica | Dart tem gerência automática de memória | — | — |
| 1.4.3 | L2 | Memory, String, and Unmanaged Code | não se aplica | Dart tem gerência automática de memória | — | — |
| 1.5.1 | L1 | Safe Deserialization | não se aplica | Não há XML | — | — |
| 1.5.2 | L2 | Safe Deserialization | planejado | Só JSON, lido para tipos fechados e validado contra esquema | ADR-015 · RNF-SEC-09 | F6-03 |

## V2 Validation and Business Logic

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 2.1.1 | L1 | Validation and Business Logic Documentation | atende | As 345 regras RN-xxx são a documentação de validação | docs/spec/rules | feito |
| 2.1.2 | L2 | Validation and Business Logic Documentation | atende | As 345 regras RN-xxx são a documentação de validação | docs/spec/rules | feito |
| 2.1.3 | L2 | Validation and Business Logic Documentation | atende | As 345 regras RN-xxx são a documentação de validação | docs/spec/rules | feito |
| 2.2.1 | L1 | Input Validation | planejado | O servidor revalida tudo com o mesmo domínio do app | ADR-001 · T-05 | F6-03 |
| 2.2.2 | L1 | Input Validation | planejado | O servidor revalida tudo com o mesmo domínio do app | ADR-001 · T-05 | F6-03 |
| 2.2.3 | L2 | Input Validation | planejado | O servidor revalida tudo com o mesmo domínio do app | ADR-001 · T-05 | F6-03 |
| 2.3.1 | L1 | Business Logic Security | planejado | Limites de negócio no domínio; escrita tudo-ou-nada; chave de idempotência | ADR-004 · ADR-012 | F6-02 |
| 2.3.2 | L2 | Business Logic Security | planejado | Limites de negócio no domínio; escrita tudo-ou-nada; chave de idempotência | ADR-004 · ADR-012 | F6-02 |
| 2.3.3 | L2 | Business Logic Security | planejado | Limites de negócio no domínio; escrita tudo-ou-nada; chave de idempotência | ADR-004 · ADR-012 | F6-02 |
| 2.3.4 | L2 | Business Logic Security | planejado | Limites de negócio no domínio; escrita tudo-ou-nada; chave de idempotência | ADR-004 · ADR-012 | F6-02 |
| 2.4.1 | L2 | Anti-automation | planejado | Limite de taxa por origem e global | RNF-SEC-08 · T-11 | F6-03 |

## V3 Web Frontend Security

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 3.2.1 | L1 | Unintended Content Interpretation | planejado | Interface em canvas; nenhum HTML montado a partir de dado | ADR-013 | F6-12 |
| 3.2.2 | L1 | Unintended Content Interpretation | planejado | Interface em canvas; nenhum HTML montado a partir de dado | ADR-013 | F6-12 |
| 3.3.1 | L1 | Cookie Setup | planejado | Cookie de sessão `__Host-`, `Secure`, `HttpOnly`, `SameSite=Strict` | ADR-008 | F6-12 |
| 3.3.2 | L2 | Cookie Setup | planejado | Cookie de sessão `__Host-`, `Secure`, `HttpOnly`, `SameSite=Strict` | ADR-008 | F6-12 |
| 3.3.3 | L2 | Cookie Setup | planejado | Cookie de sessão `__Host-`, `Secure`, `HttpOnly`, `SameSite=Strict` | ADR-008 | F6-12 |
| 3.3.4 | L2 | Cookie Setup | planejado | Cookie de sessão `__Host-`, `Secure`, `HttpOnly`, `SameSite=Strict` | ADR-008 | F6-12 |
| 3.4.1 | L1 | Browser Security Mechanism Headers | planejado | HSTS, CSP, `nosniff`, `Referrer-Policy` e `frame-ancestors` na Vercel e no Caddy | RNF-SEC-10 · BL-021 | Fase 7 |
| 3.4.2 | L1 | Browser Security Mechanism Headers | planejado | HSTS, CSP, `nosniff`, `Referrer-Policy` e `frame-ancestors` na Vercel e no Caddy | RNF-SEC-10 · BL-021 | Fase 7 |
| 3.4.3 | L2 | Browser Security Mechanism Headers | planejado | HSTS, CSP, `nosniff`, `Referrer-Policy` e `frame-ancestors` na Vercel e no Caddy | RNF-SEC-10 · BL-021 | Fase 7 |
| 3.4.4 | L2 | Browser Security Mechanism Headers | planejado | HSTS, CSP, `nosniff`, `Referrer-Policy` e `frame-ancestors` na Vercel e no Caddy | RNF-SEC-10 · BL-021 | Fase 7 |
| 3.4.5 | L2 | Browser Security Mechanism Headers | planejado | HSTS, CSP, `nosniff`, `Referrer-Policy` e `frame-ancestors` na Vercel e no Caddy | RNF-SEC-10 · BL-021 | Fase 7 |
| 3.4.6 | L2 | Browser Security Mechanism Headers | planejado | HSTS, CSP, `nosniff`, `Referrer-Policy` e `frame-ancestors` na Vercel e no Caddy | RNF-SEC-10 · BL-021 | Fase 7 |
| 3.5.1 | L1 | Browser Origin Separation | planejado | Mesma origem pela reescrita de `/api/*`; `SameSite=Strict`; escrita recusada à sessão da web | ADR-011 · T-12 | F6-12 |
| 3.5.2 | L1 | Browser Origin Separation | planejado | Mesma origem pela reescrita de `/api/*`; `SameSite=Strict`; escrita recusada à sessão da web | ADR-011 · T-12 | F6-12 |
| 3.5.3 | L1 | Browser Origin Separation | planejado | Mesma origem pela reescrita de `/api/*`; `SameSite=Strict`; escrita recusada à sessão da web | ADR-011 · T-12 | F6-12 |
| 3.5.4 | L2 | Browser Origin Separation | planejado | Mesma origem pela reescrita de `/api/*`; `SameSite=Strict`; escrita recusada à sessão da web | ADR-011 · T-12 | F6-12 |
| 3.5.5 | L2 | Browser Origin Separation | planejado | Mesma origem pela reescrita de `/api/*`; `SameSite=Strict`; escrita recusada à sessão da web | ADR-011 · T-12 | F6-12 |
| 3.7.1 | L2 | Other Browser Security Considerations | planejado | Sem redirecionamento para destino vindo de dado | ADR-013 | F6-12 |
| 3.7.2 | L2 | Other Browser Security Considerations | planejado | Sem redirecionamento para destino vindo de dado | ADR-013 | F6-12 |

## V4 API and Web Service

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 4.1.1 | L1 | Generic Web Service Security | planejado | `Content-Type` com charset; a API não redireciona HTTP; cabeçalhos do proxy só valem vindos do Caddy | ADR-003 · ADR-011 | F6-03 · Fase 7 |
| 4.1.2 | L2 | Generic Web Service Security | planejado | `Content-Type` com charset; a API não redireciona HTTP; cabeçalhos do proxy só valem vindos do Caddy | ADR-003 · ADR-011 | F6-03 · Fase 7 |
| 4.1.3 | L2 | Generic Web Service Security | planejado | `Content-Type` com charset; a API não redireciona HTTP; cabeçalhos do proxy só valem vindos do Caddy | ADR-003 · ADR-011 | F6-03 · Fase 7 |
| 4.2.1 | L2 | HTTP Message Structure Validation | planejado | Limites de tamanho de mensagem no Caddy e na API | ADR-003 · E-REQ-04 | F6-03 |
| 4.3.1 | L2 | GraphQL | não se aplica | Não há GraphQL | — | — |
| 4.3.2 | L2 | GraphQL | não se aplica | Não há GraphQL | — | — |
| 4.4.1 | L1 | WebSocket | não se aplica | Não há WebSocket: o assistente usa HTTP comum | — | — |
| 4.4.2 | L2 | WebSocket | não se aplica | Não há WebSocket: o assistente usa HTTP comum | — | — |
| 4.4.3 | L2 | WebSocket | não se aplica | Não há WebSocket: o assistente usa HTTP comum | — | — |
| 4.4.4 | L2 | WebSocket | não se aplica | Não há WebSocket: o assistente usa HTTP comum | — | — |

## V5 File Handling

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 5.1.1 | L2 | File Handling Documentation | atende | Tipos e tamanhos aceitos documentados no fluxo de compartilhamento | docs/spec/sharing-flow.md | feito |
| 5.2.1 | L1 | File Upload and Content | não se aplica | O servidor não recebe arquivo, só texto extraído (ADR-007) | — | — |
| 5.2.2 | L1 | File Upload and Content | não se aplica | O servidor não recebe arquivo, só texto extraído (ADR-007) | — | — |
| 5.2.3 | L2 | File Upload and Content | não se aplica | O servidor não recebe arquivo, só texto extraído (ADR-007) | — | — |
| 5.3.1 | L1 | File Storage | não se aplica | O servidor não guarda arquivo enviado | — | — |
| 5.3.2 | L1 | File Storage | não se aplica | O servidor não guarda arquivo enviado | — | — |
| 5.4.1 | L2 | File Download | planejado | Exportação com nome gerado pelo servidor e tipo fixo | ADR-005 | F6-02 |
| 5.4.2 | L2 | File Download | planejado | Exportação com nome gerado pelo servidor e tipo fixo | ADR-005 | F6-02 |
| 5.4.3 | L2 | File Download | não se aplica | O servidor não serve arquivo enviado por terceiros | — | — |

## V6 Authentication

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 6.1.1 | L1 | Authentication Documentation | atende | Os dois caminhos de autenticação documentados, com a defesa contra força bruta | ADR-008 | feito |
| 6.1.2 | L2 | Authentication Documentation | atende | Os dois caminhos de autenticação documentados, com a defesa contra força bruta | ADR-008 | feito |
| 6.1.3 | L2 | Authentication Documentation | atende | Os dois caminhos de autenticação documentados, com a defesa contra força bruta | ADR-008 | feito |
| 6.2.1 | L1 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.2 | L1 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.3 | L1 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.4 | L1 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.5 | L1 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.6 | L1 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.7 | L1 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.8 | L1 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.9 | L2 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.10 | L2 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.11 | L2 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.2.12 | L2 | Password Security | não se aplica | Não existe senha em nenhum caminho de autenticação (ADR-008) | — | — |
| 6.3.1 | L1 | General Authentication Security | planejado | Chave em hardware liberada por biometria assina desafio; sem conta padrão; web com força equivalente | ADR-008 · T-02 | F6-11 |
| 6.3.2 | L1 | General Authentication Security | planejado | Chave em hardware liberada por biometria assina desafio; sem conta padrão; web com força equivalente | ADR-008 · T-02 | F6-11 |
| 6.3.3 | L2 | General Authentication Security | planejado | Chave em hardware liberada por biometria assina desafio; sem conta padrão; web com força equivalente | ADR-008 · T-02 | F6-11 |
| 6.3.4 | L2 | General Authentication Security | planejado | Chave em hardware liberada por biometria assina desafio; sem conta padrão; web com força equivalente | ADR-008 · T-02 | F6-11 |
| 6.4.1 | L1 | Authentication Factor Lifecycle and Recovery | planejado | Trocar ou recuperar aparelho exige SSH na VM: é a prova de identidade | ADR-008 · T-03 | F6-03 |
| 6.4.2 | L1 | Authentication Factor Lifecycle and Recovery | planejado | Trocar ou recuperar aparelho exige SSH na VM: é a prova de identidade | ADR-008 · T-03 | F6-03 |
| 6.4.3 | L2 | Authentication Factor Lifecycle and Recovery | planejado | Trocar ou recuperar aparelho exige SSH na VM: é a prova de identidade | ADR-008 · T-03 | F6-03 |
| 6.4.4 | L2 | Authentication Factor Lifecycle and Recovery | planejado | Trocar ou recuperar aparelho exige SSH na VM: é a prova de identidade | ADR-008 · T-03 | F6-03 |
| 6.5.1 | L2 | General Multi-factor authentication requirements | planejado | Códigos de uso único, de gerador criptográfico, com validade curta | ADR-008 | F6-03 |
| 6.5.2 | L2 | General Multi-factor authentication requirements | planejado | Códigos de uso único, de gerador criptográfico, com validade curta | ADR-008 | F6-03 |
| 6.5.3 | L2 | General Multi-factor authentication requirements | planejado | Códigos de uso único, de gerador criptográfico, com validade curta | ADR-008 | F6-03 |
| 6.5.4 | L2 | General Multi-factor authentication requirements | planejado | Códigos de uso único, de gerador criptográfico, com validade curta | ADR-008 | F6-03 |
| 6.5.5 | L2 | General Multi-factor authentication requirements | planejado | Códigos de uso único, de gerador criptográfico, com validade curta | ADR-008 | F6-03 |
| 6.6.1 | L2 | Out-of-Band authentication mechanisms | planejado | O código de pareamento nasce no aparelho autenticado e vale 2 minutos, uma vez | ADR-008 | F6-11 |
| 6.6.2 | L2 | Out-of-Band authentication mechanisms | planejado | O código de pareamento nasce no aparelho autenticado e vale 2 minutos, uma vez | ADR-008 | F6-11 |
| 6.6.3 | L2 | Out-of-Band authentication mechanisms | planejado | O código de pareamento nasce no aparelho autenticado e vale 2 minutos, uma vez | ADR-008 | F6-11 |
| 6.8.1 | L2 | Authentication with an Identity Provider | não se aplica | Não há provedor de identidade externo | — | — |
| 6.8.2 | L2 | Authentication with an Identity Provider | não se aplica | Não há provedor de identidade externo | — | — |
| 6.8.3 | L2 | Authentication with an Identity Provider | não se aplica | Não há provedor de identidade externo | — | — |
| 6.8.4 | L2 | Authentication with an Identity Provider | não se aplica | Não há provedor de identidade externo | — | — |

## V7 Session Management

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 7.1.1 | L2 | Session Management Documentation | atende | Tempos de sessão documentados: 15 min no app, 30 min de inatividade e 12 h na web | ADR-008 | feito |
| 7.1.2 | L2 | Session Management Documentation | atende | Tempos de sessão documentados: 15 min no app, 30 min de inatividade e 12 h na web | ADR-008 | feito |
| 7.1.3 | L2 | Session Management Documentation | atende | Tempos de sessão documentados: 15 min no app, 30 min de inatividade e 12 h na web | ADR-008 | feito |
| 7.2.1 | L1 | Fundamental Session Management Security | planejado | Token opaco de 128+ bits, validado no servidor, novo a cada autenticação | ADR-008 | F6-03 |
| 7.2.2 | L1 | Fundamental Session Management Security | planejado | Token opaco de 128+ bits, validado no servidor, novo a cada autenticação | ADR-008 | F6-03 |
| 7.2.3 | L1 | Fundamental Session Management Security | planejado | Token opaco de 128+ bits, validado no servidor, novo a cada autenticação | ADR-008 | F6-03 |
| 7.2.4 | L1 | Fundamental Session Management Security | planejado | Token opaco de 128+ bits, validado no servidor, novo a cada autenticação | ADR-008 | F6-03 |
| 7.3.1 | L2 | Session Timeout | planejado | Tempo de inatividade e tempo absoluto aplicados no servidor | ADR-008 | F6-03 |
| 7.3.2 | L2 | Session Timeout | planejado | Tempo de inatividade e tempo absoluto aplicados no servidor | ADR-008 | F6-03 |
| 7.4.1 | L1 | Session Termination | planejado | Encerrar sessão apaga o token no servidor; o celular encerra as sessões da web | ADR-008 · T-10 | F6-11 |
| 7.4.2 | L1 | Session Termination | planejado | Encerrar sessão apaga o token no servidor; o celular encerra as sessões da web | ADR-008 · T-10 | F6-11 |
| 7.4.3 | L2 | Session Termination | planejado | Encerrar sessão apaga o token no servidor; o celular encerra as sessões da web | ADR-008 · T-10 | F6-11 |
| 7.4.4 | L2 | Session Termination | planejado | Encerrar sessão apaga o token no servidor; o celular encerra as sessões da web | ADR-008 · T-10 | F6-11 |
| 7.4.5 | L2 | Session Termination | planejado | Encerrar sessão apaga o token no servidor; o celular encerra as sessões da web | ADR-008 · T-10 | F6-11 |
| 7.5.1 | L2 | Defenses Against Session Abuse | planejado | Biometria de novo antes de parear; lista de sessões abertas no app | ADR-008 | F6-11 |
| 7.5.2 | L2 | Defenses Against Session Abuse | planejado | Biometria de novo antes de parear; lista de sessões abertas no app | ADR-008 | F6-11 |
| 7.6.1 | L2 | Federated Re-authentication | não se aplica | Não há sessão federada | — | — |
| 7.6.2 | L2 | Federated Re-authentication | não se aplica | Não há sessão federada | — | — |

## V8 Authorization

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 8.1.1 | L1 | Authorization Documentation | atende | Uma regra: autenticado é o dono; sessão da web é só leitura | ADR-008 | feito |
| 8.1.2 | L2 | Authorization Documentation | atende | Uma regra: autenticado é o dono; sessão da web é só leitura | ADR-008 | feito |
| 8.2.1 | L1 | General Authorization Design | planejado | Aplicado no servidor, por rota | ADR-008 · T-12 | F6-03 |
| 8.2.2 | L1 | General Authorization Design | planejado | Aplicado no servidor, por rota | ADR-008 · T-12 | F6-03 |
| 8.2.3 | L2 | General Authorization Design | planejado | Aplicado no servidor, por rota | ADR-008 · T-12 | F6-03 |
| 8.3.1 | L1 | Operation Level Authorization | planejado | Autorização decidida no servidor, nunca no cliente | ADR-008 | F6-03 |
| 8.4.1 | L2 | Other Authorization Considerations | não se aplica | Usuário único: não há multilocação | — | — |

## V9 Self-contained Tokens

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 9.1.1 | L1 | Token source and integrity | não se aplica | A sessão usa token opaco, não token autocontido (ADR-008) | — | — |
| 9.1.2 | L1 | Token source and integrity | não se aplica | A sessão usa token opaco, não token autocontido (ADR-008) | — | — |
| 9.1.3 | L1 | Token source and integrity | não se aplica | A sessão usa token opaco, não token autocontido (ADR-008) | — | — |
| 9.2.1 | L1 | Token content | não se aplica | A sessão usa token opaco, não token autocontido (ADR-008) | — | — |
| 9.2.2 | L2 | Token content | não se aplica | A sessão usa token opaco, não token autocontido (ADR-008) | — | — |
| 9.2.3 | L2 | Token content | não se aplica | A sessão usa token opaco, não token autocontido (ADR-008) | — | — |
| 9.2.4 | L2 | Token content | não se aplica | A sessão usa token opaco, não token autocontido (ADR-008) | — | — |

## V10 OAuth and OIDC

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 10.1.1 | L2 | Generic OAuth and OIDC Security | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.1.2 | L2 | Generic OAuth and OIDC Security | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.2.1 | L2 | OAuth Client | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.2.2 | L2 | OAuth Client | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.3.1 | L2 | OAuth Resource Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.3.2 | L2 | OAuth Resource Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.3.3 | L2 | OAuth Resource Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.3.4 | L2 | OAuth Resource Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.1 | L1 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.2 | L1 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.3 | L1 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.4 | L1 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.5 | L1 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.6 | L2 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.7 | L2 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.8 | L2 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.9 | L2 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.10 | L2 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.4.11 | L2 | OAuth Authorization Server | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.5.1 | L2 | OIDC Client | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.5.2 | L2 | OIDC Client | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.5.3 | L2 | OIDC Client | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.5.4 | L2 | OIDC Client | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.5.5 | L2 | OIDC Client | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.6.1 | L2 | OpenID Provider | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.6.2 | L2 | OpenID Provider | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.7.1 | L2 | Consent Management | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.7.2 | L2 | Consent Management | não se aplica | Não há OAuth nem OIDC | — | — |
| 10.7.3 | L2 | Consent Management | não se aplica | Não há OAuth nem OIDC | — | — |

## V11 Cryptography

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 11.1.1 | L2 | Cryptographic Inventory and Documentation | planejado | Inventário de chaves e algoritmos na ADR-005 | ADR-005 | F6-02 |
| 11.1.2 | L2 | Cryptographic Inventory and Documentation | planejado | Inventário de chaves e algoritmos na ADR-005 | ADR-005 | F6-02 |
| 11.2.1 | L2 | Secure Cryptography Implementation | **exceção** | Não há biblioteca criptográfica validada formalmente em Dart puro. Compensação: Só algoritmos padrão (AES-256-GCM, SHA-256, ECDSA P-256), conferidos contra vetores de teste publicados; envelope versionado para trocar de implementação (ADR-005) | BL-013 | — |
| 11.2.2 | L2 | Secure Cryptography Implementation | planejado | Algoritmos padrão atrás de uma porta, com versão no envelope para poder trocar | ADR-005 | F6-02 |
| 11.2.3 | L2 | Secure Cryptography Implementation | planejado | Algoritmos padrão atrás de uma porta, com versão no envelope para poder trocar | ADR-005 | F6-02 |
| 11.3.1 | L1 | Encryption Algorithms | planejado | AES-256-GCM: cifra autenticada, nonce único por registro | ADR-005 · T-31 | F6-02 |
| 11.3.2 | L1 | Encryption Algorithms | planejado | AES-256-GCM: cifra autenticada, nonce único por registro | ADR-005 · T-31 | F6-02 |
| 11.3.3 | L2 | Encryption Algorithms | planejado | AES-256-GCM: cifra autenticada, nonce único por registro | ADR-005 · T-31 | F6-02 |
| 11.4.1 | L1 | Hashing and Hash-based Functions | planejado | SHA-256 na cadeia do registro; nenhuma chave derivada de senha | ADR-005 | F6-02 |
| 11.4.2 | L2 | Hashing and Hash-based Functions | planejado | SHA-256 na cadeia do registro; nenhuma chave derivada de senha | ADR-005 | F6-02 |
| 11.4.3 | L2 | Hashing and Hash-based Functions | planejado | SHA-256 na cadeia do registro; nenhuma chave derivada de senha | ADR-005 | F6-02 |
| 11.4.4 | L2 | Hashing and Hash-based Functions | planejado | SHA-256 na cadeia do registro; nenhuma chave derivada de senha | ADR-005 | F6-02 |
| 11.5.1 | L2 | Random Values | planejado | Gerador criptográfico do sistema para nonce, token e código | ADR-005 · ADR-008 | F6-02 |
| 11.6.1 | L2 | Public Key Cryptography | planejado | ECDSA P-256 para a chave do aparelho | ADR-008 | F6-11 |

## V12 Secure Communication

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 12.1.1 | L1 | General TLS Security Guidance | planejado | Só TLS 1.2 e 1.3, configurados no Caddy | RNF-SEC-02 | Fase 7 |
| 12.1.2 | L2 | General TLS Security Guidance | planejado | Só TLS 1.2 e 1.3, configurados no Caddy | RNF-SEC-02 | Fase 7 |
| 12.1.3 | L2 | General TLS Security Guidance | planejado | Só TLS 1.2 e 1.3, configurados no Caddy | RNF-SEC-02 | Fase 7 |
| 12.2.1 | L1 | HTTPS Communication with External Facing Services | planejado | Certificado público do Let's Encrypt, sem alternativa em claro | ADR-011 | Fase 7 |
| 12.2.2 | L1 | HTTPS Communication with External Facing Services | planejado | Certificado público do Let's Encrypt, sem alternativa em claro | ADR-011 | Fase 7 |
| 12.3.1 | L2 | General Service to Service Communication Security | planejado | Saída para a DeepSeek por HTTPS com validação; SSH só por chave | ADR-010 · T-26 | F6-04 · Fase 7 |
| 12.3.2 | L2 | General Service to Service Communication Security | planejado | Saída para a DeepSeek por HTTPS com validação; SSH só por chave | ADR-010 · T-26 | F6-04 · Fase 7 |
| 12.3.3 | L2 | General Service to Service Communication Security | **exceção** | Caddy e API estão na mesma máquina. Compensação: A API escuta só em `127.0.0.1`; nenhum tráfego interno sai da VM (ADR-003) | BL-013 | — |
| 12.3.4 | L2 | General Service to Service Communication Security | planejado | Saída para a DeepSeek por HTTPS com validação; SSH só por chave | ADR-010 · T-26 | F6-04 · Fase 7 |

## V13 Configuration

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 13.1.1 | L2 | Configuration Documentation | atende | Toda comunicação externa está no diagrama de contêineres | docs/architecture/c4.md | feito |
| 13.2.1 | L2 | Backend Communication Configuration | planejado | Serviço sem privilégio; saída só para a DeepSeek e o armazenamento de backup | ADR-003 · T-36 | Fase 7 |
| 13.2.2 | L2 | Backend Communication Configuration | planejado | Serviço sem privilégio; saída só para a DeepSeek e o armazenamento de backup | ADR-003 · T-36 | Fase 7 |
| 13.2.3 | L2 | Backend Communication Configuration | planejado | Serviço sem privilégio; saída só para a DeepSeek e o armazenamento de backup | ADR-003 · T-36 | Fase 7 |
| 13.2.4 | L2 | Backend Communication Configuration | planejado | Serviço sem privilégio; saída só para a DeepSeek e o armazenamento de backup | ADR-003 · T-36 | Fase 7 |
| 13.2.5 | L2 | Backend Communication Configuration | planejado | Serviço sem privilégio; saída só para a DeepSeek e o armazenamento de backup | ADR-003 · T-36 | Fase 7 |
| 13.3.1 | L2 | Secret Management | **exceção** | Cofre de segredos gerenciado não existe a custo zero. Compensação: Credencial cifrada do systemd, entregue só ao serviço; nada em variável de ambiente, arquivo legível ou repositório (ADR-005) | BL-013 | — |
| 13.3.2 | L2 | Secret Management | planejado | Segredos só como credencial cifrada do systemd, entregue ao serviço em memória | ADR-005 · T-27 | Fase 7 |
| 13.4.1 | L1 | Unintended Information Leakage | planejado | Só o executável vai para a VM: sem `.git`, sem modo de depuração, sem listagem | ADR-003 | Fase 7 |
| 13.4.2 | L2 | Unintended Information Leakage | planejado | Só o executável vai para a VM: sem `.git`, sem modo de depuração, sem listagem | ADR-003 | Fase 7 |
| 13.4.3 | L2 | Unintended Information Leakage | planejado | Só o executável vai para a VM: sem `.git`, sem modo de depuração, sem listagem | ADR-003 | Fase 7 |
| 13.4.4 | L2 | Unintended Information Leakage | planejado | Só o executável vai para a VM: sem `.git`, sem modo de depuração, sem listagem | ADR-003 | Fase 7 |
| 13.4.5 | L2 | Unintended Information Leakage | planejado | Só o executável vai para a VM: sem `.git`, sem modo de depuração, sem listagem | ADR-003 | Fase 7 |

## V14 Data Protection

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 14.1.1 | L2 | Data Protection Documentation | planejado | Classes de dado e o que pode sair do aparelho e do servidor, documentados | ADR-010 · RN-989 | F6-04 |
| 14.1.2 | L2 | Data Protection Documentation | planejado | Classes de dado e o que pode sair do aparelho e do servidor, documentados | ADR-010 · RN-989 | F6-04 |
| 14.2.1 | L1 | General Data Protection | planejado | Nada sensível em URL; sem cache de resposta da API; mascaramento antes da IA | ADR-010 · T-23 | F6-03 · F6-04 |
| 14.2.2 | L2 | General Data Protection | planejado | Nada sensível em URL; sem cache de resposta da API; mascaramento antes da IA | ADR-010 · T-23 | F6-03 · F6-04 |
| 14.2.3 | L2 | General Data Protection | planejado | Nada sensível em URL; sem cache de resposta da API; mascaramento antes da IA | ADR-010 · T-23 | F6-03 · F6-04 |
| 14.2.4 | L2 | General Data Protection | planejado | Nada sensível em URL; sem cache de resposta da API; mascaramento antes da IA | ADR-010 · T-23 | F6-03 · F6-04 |
| 14.3.1 | L1 | Client-side Data Protection | planejado | A web não grava nada no navegador além do cookie de sessão; `Clear-Site-Data` ao sair | ADR-008 · T-10 | F6-12 |
| 14.3.2 | L2 | Client-side Data Protection | planejado | A web não grava nada no navegador além do cookie de sessão; `Clear-Site-Data` ao sair | ADR-008 · T-10 | F6-12 |
| 14.3.3 | L2 | Client-side Data Protection | planejado | A web não grava nada no navegador além do cookie de sessão; `Clear-Site-Data` ao sair | ADR-008 · T-10 | F6-12 |

## V15 Secure Coding and Architecture

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 15.1.1 | L1 | Secure Coding and Architecture Documentation | planejado | Prazo de correção de dependência e funções caras documentados | ADR-014 | F6-03 |
| 15.1.2 | L2 | Secure Coding and Architecture Documentation | planejado | Prazo de correção de dependência e funções caras documentados | ADR-014 | F6-03 |
| 15.1.3 | L2 | Secure Coding and Architecture Documentation | planejado | Prazo de correção de dependência e funções caras documentados | ADR-014 | F6-03 |
| 15.2.1 | L1 | Security Architecture and Dependencies | planejado | Versões travadas num `pubspec.lock` único; nada de teste no build de produção | ADR-014 · T-37 | contínuo |
| 15.2.2 | L2 | Security Architecture and Dependencies | planejado | Versões travadas num `pubspec.lock` único; nada de teste no build de produção | ADR-014 · T-37 | contínuo |
| 15.2.3 | L2 | Security Architecture and Dependencies | planejado | Versões travadas num `pubspec.lock` único; nada de teste no build de produção | ADR-014 · T-37 | contínuo |
| 15.3.1 | L1 | Defensive Coding | planejado | DTOs fechados, tipagem estrita, só os campos necessários; cliente HTTP sem seguir redirecionamento | ADR-015 | F6-03 |
| 15.3.2 | L2 | Defensive Coding | planejado | DTOs fechados, tipagem estrita, só os campos necessários; cliente HTTP sem seguir redirecionamento | ADR-015 | F6-03 |
| 15.3.3 | L2 | Defensive Coding | planejado | DTOs fechados, tipagem estrita, só os campos necessários; cliente HTTP sem seguir redirecionamento | ADR-015 | F6-03 |
| 15.3.4 | L2 | Defensive Coding | planejado | DTOs fechados, tipagem estrita, só os campos necessários; cliente HTTP sem seguir redirecionamento | ADR-015 | F6-03 |
| 15.3.5 | L2 | Defensive Coding | planejado | DTOs fechados, tipagem estrita, só os campos necessários; cliente HTTP sem seguir redirecionamento | ADR-015 | F6-03 |
| 15.3.6 | L2 | Defensive Coding | não se aplica | Não há JavaScript próprio | — | — |
| 15.3.7 | L2 | Defensive Coding | planejado | DTOs fechados, tipagem estrita, só os campos necessários; cliente HTTP sem seguir redirecionamento | ADR-015 | F6-03 |

## V16 Security Logging and Error Handling

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 16.1.1 | L2 | Security Logging Documentation | planejado | Inventário do que se registra, e do que nunca se registra | RNF-SEC-12 | F6-03 |
| 16.2.1 | L2 | General Logging | planejado | Registro estruturado, em UTC, com `ref`; sem dado financeiro nem pessoal | ADR-015 · T-09 | F6-03 |
| 16.2.2 | L2 | General Logging | planejado | Registro estruturado, em UTC, com `ref`; sem dado financeiro nem pessoal | ADR-015 · T-09 | F6-03 |
| 16.2.3 | L2 | General Logging | planejado | Registro estruturado, em UTC, com `ref`; sem dado financeiro nem pessoal | ADR-015 · T-09 | F6-03 |
| 16.2.4 | L2 | General Logging | planejado | Registro estruturado, em UTC, com `ref`; sem dado financeiro nem pessoal | ADR-015 · T-09 | F6-03 |
| 16.2.5 | L2 | General Logging | planejado | Registro estruturado, em UTC, com `ref`; sem dado financeiro nem pessoal | ADR-015 · T-09 | F6-03 |
| 16.3.1 | L2 | Security Events | planejado | Toda autenticação, toda recusa de autorização e todo erro inesperado são registrados | RNF-SEC-13 | F6-03 |
| 16.3.2 | L2 | Security Events | planejado | Toda autenticação, toda recusa de autorização e todo erro inesperado são registrados | RNF-SEC-13 | F6-03 |
| 16.3.3 | L2 | Security Events | planejado | Toda autenticação, toda recusa de autorização e todo erro inesperado são registrados | RNF-SEC-13 | F6-03 |
| 16.3.4 | L2 | Security Events | planejado | Toda autenticação, toda recusa de autorização e todo erro inesperado são registrados | RNF-SEC-13 | F6-03 |
| 16.4.1 | L2 | Log Protection | planejado | Registro codificado contra injeção, legível só pelo serviço e por root | ADR-003 | Fase 7 |
| 16.4.2 | L2 | Log Protection | planejado | Registro codificado contra injeção, legível só pelo serviço e por root | ADR-003 | Fase 7 |
| 16.4.3 | L2 | Log Protection | **exceção** | Sistema de registro separado exigiria uma segunda máquina. Compensação: Registro local sem dado sensível, legível só por root; eventos de segurança viram aviso dentro do app (RNF-SEC-13) | BL-013 | — |
| 16.5.1 | L2 | Error Handling | planejado | Erro tipado e sem detalhe interno; falha da IA cai nas regras locais; nada falha aberto | ADR-015 · ADR-010 | F6-03 · F6-04 |
| 16.5.2 | L2 | Error Handling | planejado | Erro tipado e sem detalhe interno; falha da IA cai nas regras locais; nada falha aberto | ADR-015 · ADR-010 | F6-03 · F6-04 |
| 16.5.3 | L2 | Error Handling | planejado | Erro tipado e sem detalhe interno; falha da IA cai nas regras locais; nada falha aberto | ADR-015 · ADR-010 | F6-03 · F6-04 |

## V17 WebRTC

| Requisito | Nível | Seção | Situação | Controle, ou motivo | Onde está decidido | Nasce em |
|---|---|---|---|---|---|---|
| 17.1.1 | L2 | TURN Server | não se aplica | Não há WebRTC | — | — |
| 17.2.1 | L2 | Media | não se aplica | Não há WebRTC | — | — |
| 17.2.2 | L2 | Media | não se aplica | Não há WebRTC | — | — |
| 17.2.3 | L2 | Media | não se aplica | Não há WebRTC | — | — |
| 17.2.4 | L2 | Media | não se aplica | Não há WebRTC | — | — |
| 17.3.1 | L2 | Signaling | não se aplica | Não há WebRTC | — | — |
| 17.3.2 | L2 | Signaling | não se aplica | Não há WebRTC | — | — |
