# Créditos e licenças

Todo arquivo de terceiros que entra no repositório é registrado aqui **antes** do commit: o que é, de onde veio, sob qual licença. Sem registro, não entra.

## Fontes

| Arquivo | Obra | Autoria | Origem | Licença |
|---|---|---|---|---|
| `packages/design_system/assets/fonts/Fraunces.ttf` | Fraunces, fonte variável (eixos `opsz`, `wght`, `SOFT`, `WONK`) | The Fraunces Project Authors | `github.com/google/fonts`, pasta `ofl/fraunces` | SIL Open Font License 1.1 — texto em `OFL-Fraunces.txt`, na mesma pasta |
| `packages/design_system/assets/fonts/Geist.ttf` | Geist, fonte variável (eixo `wght`) | The Geist Project Authors | `github.com/google/fonts`, pasta `ofl/geist` | SIL Open Font License 1.1 — texto em `OFL-Geist.txt`, na mesma pasta |

A OFL permite uso, empacotamento e redistribuição, inclusive comercial, desde que a fonte não seja vendida sozinha e que a licença acompanhe os arquivos.

## Sons

Todos os sons do Cajui são **sintetizados por script do próprio projeto** (`tool/sound/build_sounds.py`), sem amostra de terceiros. Não há licença externa a cumprir; a autoria é do projeto.

| Arquivo | Como é gerado |
|---|---|
| `packages/design_system/assets/sounds/*.wav` | `python tool/sound/build_sounds.py` |

Se um som gravado ou de terceiros vier a substituir um sintetizado, só entra material em domínio público (CC0), com autor, endereço de origem e licença registrados nesta tabela.

## Ícones e ilustrações

| Arquivo | Origem | Licença |
|---|---|---|
| `docs/brand/assets/*.svg` | Gerados por `tool/brand/build_logo.py`, de autoria do projeto | Do projeto |
