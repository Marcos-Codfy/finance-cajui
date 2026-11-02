# Pesquisa

Fase 1 do projeto. Cada arquivo é um resumo **acionável** de uma fonte: o que dela se aplica ao Cajui, as decisões que saem dali e o que não se aplica. Resumo genérico da fonte não entra.

Acesso a todas as fontes: 2026-09-19. Toda decisão tem um identificador (`D-<FONTE>-NN`) para poder ser citada na especificação, nas ADRs e nos checklists das fases seguintes.

## Arquivos

| Arquivo | Fonte e versão lida | Decisões |
|---|---|---|
| [owasp-top-10.md](owasp-top-10.md) | OWASP Top 10:**2025** (final) + listas complementares para LLM e mobile | 13 · `D-TOP10-` |
| [owasp-asvs.md](owasp-asvs.md) | OWASP ASVS **5.0.0** (2025-05-30); MASVS 2.1.0 para o cliente Android | 17 · `D-ASVS-` |
| [wcag-2-2.md](wcag-2-2.md) | WCAG 2.2 (W3C), nível AA, com WCAG2ICT para o app nativo | 27 · `D-WCAG-` |
| [wai-aria-apg.md](wai-aria-apg.md) | WAI-ARIA Authoring Practices Guide (documento vivo) | 21 · `D-APG-` |
| [lighthouse.md](lighthouse.md) | Lighthouse **13.5.0** e Lighthouse CI 0.15 | 19 · `D-LH-` |
| [vercel.md](vercel.md) | Documentação da Vercel, plano Hobby | 20 · `D-VERCEL-` |
| [mdn-web-docs.md](mdn-web-docs.md) | MDN Web Docs (documentação viva) | 21 · `D-MDN-` |
| [html-living-standard.md](html-living-standard.md) | HTML Living Standard (WHATWG), atualizado em 2026-09-17 | 18 · `D-HTML-` |
| [github-skills.md](github-skills.md) | GitHub Skills + documentação do plano Free | 20 · `D-GHS-` |
| [pro-git.md](pro-git.md) | Pro Git, 2ª edição (versão online) | 22 · `D-GIT-` |
| [ux-financial-literature.md](ux-financial-literature.md) | 26 referências em seis temas, DOIs conferidos na Crossref | 23 · `D-UX-` |

Total: **221 decisões** rastreáveis.

## O que a pesquisa mudou no plano

Pontos em que as fontes contradizem ou apertam o que estava planejado. Cada um virou item no BACKLOG do projeto com a fase em que se resolve.

### Segurança

1. **A web não tem caminho de autenticação definido.** Biometria + token de dispositivo descreve só o Android; o painel fica em URL pública. É o maior buraco encontrado (Top 10 A01/A07; ASVS 6.1.3 e 6.3.4; WCAG 3.3.8 elimina senha sem suporte a gerenciador).
2. **Biometria como booleano não conta como segundo fator.** Para fechar o ASVS 6.3.3, a biometria precisa destravar uma chave em hardware que assina um desafio do servidor — exige código de plataforma além do `local_auth`.
3. **"ASVS nível 2" só é honesto com exceções escritas.** Gestão de segredos em cofre (13.3.1), log em sistema separado (16.4.3) e TLS entre serviços internos (12.3.3) não cabem em uma VM a custo zero. A redação correta é "autoavaliado contra o ASVS 5.0.0 L2, com exceções listadas". A OWASP não certifica.
4. **Backup na mesma VM não é backup.** O plano não dizia para onde o backup vai; precisa de destino externo gratuito, cifrado antes de sair.
5. **Log append-only e criptografia em repouso não combinam de graça.** Não se anexa a um arquivo cifrado como um todo: ou cada registro é um envelope próprio, ou o log é reescrito a cada evento.
6. **Escrita atômica de um arquivo não é atomicidade de três.** Log, índice e snapshot precisam de uma ordem de gravação e de um procedimento de recuperação.
7. **O repositório privado em conta gratuita não tem proteção de branch, regras nem varredura de segredos.** "Merge por PR com CI obrigatório" é disciplina mais hook local, não imposição do servidor. O dia de abrir o repositório expõe o histórico inteiro: varredura completa é pré-requisito.

### Web e desempenho

8. **A semântica do Flutter Web nasce desligada**, "por desempenho". Acessibilidade obriga a ligar, e isso disputa com a nota de performance. Medir com ela ligada, ou a nota mente.
9. **Lighthouse e axe não enxergam dentro do canvas.** A nota cobre o shell e a árvore de semântica; contraste e alvo de toque do que é desenhado precisam de teste próprio.
10. **SEO ≥ 90 briga com privacidade.** Painel financeiro pessoal pede `noindex`, que derruba a categoria. Saída proposta: shell sem dado nenhum, não indexado por controle de acesso.
11. **Os arquivos do build do Flutter não têm hash no nome.** Cache `immutable` prenderia o usuário em versão velha.
12. **O build em wasm não roda em Firefox e Safari**, que caem no caminho mais pesado. O orçamento de performance vale para Chrome e Edge no desktop.
13. **Front e API são sites diferentes.** Cookie da API seria de terceiros; a sessão web fica em memória e cai ao recarregar a aba — a Fase 3 precisa desenhar esse retorno.

### Design e acessibilidade

14. **A paleta aprovada tem furos medidos**, conferidos de novo aqui: castanha tênue sobre areia funda 4,44:1 (é o par "placeholder dentro de campo"); areia funda sobre areia 1,11:1 (campo precisa de contorno); anel de foco "céu" contra botão "cajuí forte" 1,01:1; vereda contra barro 1,12:1 — sobra e falta ficam indistinguíveis sem o segundo sinal. Corrigir na Fase 3.
15. **"Nenhum erro genérico" tem uma exceção legítima.** Erro de login, sessão e pinning precisa ser vago de propósito (WCAG 3.3.3 abre a exceção; o ASVS exige). O catálogo de erros ganha uma classe `segurança`.
16. **Erro não pode ser aviso que some sozinho.** Snackbar temporizado é barreira; erro precisa de outro veículo.
17. **Componente refeito do zero perde foco, teclado e semântica.** Recomendação: estilizar a fundo os widgets existentes dentro do pacote de design system; componente 100% próprio só onde não há equivalente (medidor, gráficos).
18. **Movimento que roda sozinho** (contagem de número, cascata, herói em laço) precisa ser de disparo único e curto, ou ter pausa (WCAG 2.2.2).

### Produto

19. **Não existe teste direto da hipótese do "número vermelho".** Ela é coerente com a literatura, mas é extrapolação — por isso as duas versões lado a lado na Fase 3.
20. **Lembrete de fatura tem efeito colateral medido no Brasil**: reduz multa e aumenta cheque especial. Todo lembrete de vencimento carrega contexto de caixa (D-UX-20).
21. **Não há evidência de que semanal seja melhor que diário ou mensal.** O ritmo fica configurável.

## Como estes documentos são usados

- A **Fase 2** cita os identificadores ao escrever requisitos não-funcionais e regras de negócio.
- A **Fase 3** usa `wcag-2-2.md`, `wai-aria-apg.md` e `ux-financial-literature.md` como critério de aceite dos componentes e das telas de estado.
- A **Fase 4** transforma os pontos acima em ADRs; vários deles só se fecham com medição nos spikes.
- A **Fase 5** gera o `asvs-checklist.md` a partir do CSV oficial do ASVS 5.0.0, por script.

Documentação viva envelhece: MDN, Vercel, HTML e a APG mudam sem número de versão. Ao depender de um ponto específico, reler a página e atualizar a data de acesso.
