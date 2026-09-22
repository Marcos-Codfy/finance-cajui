#!/usr/bin/env bash
# Compila a web de consulta. Roda na Vercel e também na sua máquina.
#
# A Vercel não tem Flutter: este script o baixa na versão fixada, compila e
# sai. Fixar a versão importa — build que muda de compilador sozinho é build
# que um dia quebra sem ninguém ter mexido em nada.
#
# Uso local, da raiz:  bash scripts/web.sh
set -euo pipefail

VERSAO=3.47.5
DESTINO="${FLUTTER_ROOT:-$HOME/flutter}"

if ! command -v flutter >/dev/null 2>&1; then
	echo "== baixando o Flutter $VERSAO"
	git clone --depth 1 --branch "$VERSAO" https://github.com/flutter/flutter.git "$DESTINO"
	export PATH="$DESTINO/bin:$PATH"
fi

echo "== compilando"
cd app
flutter --version
flutter pub get
# `--no-web-resources-cdn`: nada de buscar CanvasKit em CDN de terceiro. Tudo
# sai da mesma origem, que é o que a CSP e o modelo de ameaças pedem.
flutter build web --release --no-web-resources-cdn
echo "== pronto em app/build/web"
