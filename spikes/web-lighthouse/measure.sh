#!/usr/bin/env bash
# Mede um build web com o Lighthouse, no preset desktop, três vezes.
#
# Uso, da raiz do repositório:
#   spikes/web-lighthouse/measure.sh <nome> <pasta-do-build> [porta]
#
# Deixa os relatórios em spikes/web-lighthouse/reports/<nome>-N.json e imprime
# uma linha de resumo por rodada. A mediana é tirada à mão, no relatório do
# spike: três números não pedem ferramenta.
set -euo pipefail

name="$1"
build="$2"
port="${3:-5190}"
here="$(cd "$(dirname "$0")" && pwd)"

node "$here/serve.mjs" "$build" "$port" &
server=$!
trap 'kill $server 2>/dev/null || true' EXIT

# O servidor comprime o build inteiro antes de abrir a porta; espera por ele.
for _ in $(seq 1 90); do
  curl -s -o /dev/null "http://127.0.0.1:$port/" && break
  sleep 2
done

for run in 1 2 3; do
  report="$here/reports/$name-$run.json"
  npx --yes lighthouse "http://127.0.0.1:$port/" \
    --preset=desktop \
    --only-categories=performance,accessibility,best-practices \
    --chrome-flags="--headless=new" \
    --output=json --output-path="$report" --quiet 2>/dev/null || true
  # No Windows o Lighthouse termina com erro ao apagar a pasta temporária do
  # Chrome, depois de já ter gravado o relatório. Vale o relatório.
  node "$here/summarize.mjs" "$report"
done
