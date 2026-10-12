#!/usr/bin/env bash
# Compila a web de consulta e a gallery do design system. Roda na Vercel e
# também na sua máquina.
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

# A gallery do design system mora no mesmo endereço, em /gallery/: é a peça
# de portfólio (BL-027) e só mostra números inventados. Sai do mesmo build,
# sem projeto novo na Vercel e sem custo.
echo "== compilando a gallery do design system"
cd ../packages/design_system/gallery
# `MSYS_NO_PATHCONV`: no Git Bash do Windows, "/gallery/" virava caminho de
# disco. Na Vercel (Linux) a variável não faz nada.
MSYS_NO_PATHCONV=1 flutter build web --release --no-web-resources-cdn --base-href /gallery/
rm -rf ../../../app/build/web/gallery
cp -r build/web ../../../app/build/web/gallery
echo "== pronto em app/build/web (e a gallery em app/build/web/gallery)"
