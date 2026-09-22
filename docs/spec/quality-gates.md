# Portões de qualidade

O que precisa passar para um PR entrar na `main`, e **por que cada portão existe**. Todos rodam na [conferência do GitHub](../../.github/workflows/ci.yml); os três primeiros rodam também no `pre-commit`, para a resposta chegar em segundos em vez de minutos.

Princípio: **o básico bem feito**. Portão que ninguém consegue passar vira portão que todo mundo aprende a contornar.

## 1. Nenhum segredo — `tool/security/scan_secrets.py`

| | |
|---|---|
| **O que barra** | Chave de API (DeepSeek/OpenAI, GitHub, AWS, Google), chave privada em PEM, senha ou token atribuídos em código, e arquivo que nunca deve ser versionado (`.env`, `.pem`, `.jks`, `secrets/`) |
| **Onde olha** | No índice (pre-commit), na árvore e em **todo o histórico** |
| **Por que o histórico** | O repositório abre na Fase 9 com o histórico junto. Segredo commitado não se apaga com um commit novo: a saída é reescrever tudo e trocar a chave |
| **Como não dar falso alarme** | Comprimento mínimo separa chave de exemplo — `sk-123` não é chave de ninguém. Exemplo legítimo se marca na própria linha com `scan-secrets: exemplo`, onde quem revisa o PR vê |

## 2. Nenhuma assinatura de IA — `tool/quality/check_authorship.py`

Regra do dono desde o primeiro commit. A ferramenta que gera commits oferece essas linhas por padrão, e basta um descuido. O portão procura em mensagens de commit, em nomes de autor e no conteúdo dos arquivos.

## 3. Analisador, formatação, tamanho e arquitetura

| Portão | Régua |
|---|---|
| `flutter analyze` | **Zero avisos**, com `very_good_analysis` estrito (ADR-014) |
| `dart format --set-exit-if-changed` | Formatação é decisão da ferramenta, não de revisão |
| `tool/code_metrics` | ≤ 300 linhas por arquivo, ≤ 30 por função, ≤ 3 níveis de bloco, 1 tipo público por arquivo, camadas respeitadas, nenhuma cor ou estilo cru no app, nenhum `TODO` órfão |

## 4. Testes e cobertura

Cada pacote roda a própria suíte e tem um **piso de cobertura**. Os pisos ficam **abaixo do que há hoje**, de propósito: o portão existe para avisar quando um passo derruba a cobertura, não para obrigar quem escreve um `if` a caçar mais um teste. Cobertura como meta vira teste que existe só para a barra subir.

| Pacote | Hoje | Piso | Por que este piso |
|---|---|---|---|
| `packages/domain` | 94,4% | **90%** | É onde moram as regras de negócio. A especificação já pede > 80%; o que existe é bem mais, e o piso protege isso |
| `packages/persistence` | 94,1% | **90%** | Cifragem e cadeia de integridade: erro aqui perde dado |
| `server` | 92,4% | **85%** | Autenticação, IA e rotas — a parte exposta à rede |
| `packages/design_system` | 80,3% | **75%** | Componente tem estado visual que teste de widget alcança bem |
| `app` | 80,5% | **75%** | Tela tem caminho que só o aparelho exercita (câmera, OCR, biometria) |
| `packages/api_contract` | 76,7% | **70%** | Muito código é serialização com caso de erro raro |

`packages/design_system/gallery` e `tool/code_metrics` rodam a suíte sem piso: a gallery é vitrine, e o verificador é ferramenta.

## 5. O que compila

Na `main`, a conferência ainda **compila o APK de depuração** e o **binário do servidor para Linux x86_64**, e guarda os dois como artefato por 14 dias. O binário é o mesmo que a VM da Oracle roda: a máquina da conferência e a VM são ambas Ubuntu x86_64, então não existe cross-compile nem Dart instalado na VM.

## O que ficou de fora, e por quê

| Portão | Por que não |
|---|---|
| Cobertura de 100%, ou piso igual ao valor de hoje | Transforma cada PR numa caça a linha não coberta, e o primeiro reflexo vira escrever teste sem valor |
| Teste de mutação | Excelente medida de qualidade de teste, mas custa minutos e atenção que este projeto ainda precisa gastar em funcionalidade |
| Análise de dependências vulneráveis | O app não tem dependência de terceiros além do Flutter, do Riverpod e do `audioplayers`; entra quando houver o que auditar |
| Lighthouse na conferência | Entra no F6-14, quando a web tiver casca própria. Antes disso mediria a página de exemplo |
