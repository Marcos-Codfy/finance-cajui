// Servidor estático do spike de Lighthouse.
//
// Imita o que a hospedagem de produção faz e o `python -m http.server` não
// faz: comprime com Brotli, manda o tipo certo para `.wasm` e envia os
// cabeçalhos de isolamento de origem que o runtime em WebAssembly do Flutter
// pede. Sem isso a medição puniria o app por um defeito do servidor de teste.
//
// Uso: node serve.mjs <pasta-do-build> <porta>

import { createServer } from 'node:http';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { extname, join, relative, sep } from 'node:path';
import { brotliCompressSync, constants } from 'node:zlib';

const [root, port] = [process.argv[2], Number(process.argv[3] ?? 5190)];

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.png': 'image/png',
  '.wav': 'audio/wav',
  '.symbols': 'text/plain; charset=utf-8',
};
const compressible = new Set(['.html', '.js', '.mjs', '.json', '.wasm', '.ttf', '.otf', '.wav']);

/** Lê a pasta inteira para a memória, já comprimida: a medição não paga disco. */
function load(folder, files = new Map()) {
  for (const name of readdirSync(folder)) {
    const path = join(folder, name);
    if (statSync(path).isDirectory()) {
      load(path, files);
      continue;
    }
    const raw = readFileSync(path);
    const ext = extname(name);
    const packed = compressible.has(ext)
      ? brotliCompressSync(raw, { params: { [constants.BROTLI_PARAM_QUALITY]: 11 } })
      : null;
    files.set('/' + relative(root, path).split(sep).join('/'), { raw, packed, ext });
  }
  return files;
}

const files = load(root);
const sizes = [...files.values()].reduce(
  (sum, f) => ({ raw: sum.raw + f.raw.length, packed: sum.packed + (f.packed ?? f.raw).length }),
  { raw: 0, packed: 0 },
);
console.log(`${files.size} arquivos · ${sizes.raw} bytes crus · ${sizes.packed} comprimidos`);

createServer((request, response) => {
  const url = new URL(request.url, 'http://localhost').pathname;
  const file = files.get(url === '/' ? '/index.html' : url);
  if (!file) {
    response.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' });
    response.end('Arquivo não encontrado');
    return;
  }
  const brotli = file.packed && /\bbr\b/.test(request.headers['accept-encoding'] ?? '');
  response.writeHead(200, {
    'content-type': types[file.ext] ?? 'application/octet-stream',
    'cache-control': 'no-cache',
    'cross-origin-opener-policy': 'same-origin',
    'cross-origin-embedder-policy': 'require-corp',
    'x-robots-tag': 'noindex',
    'x-content-type-options': 'nosniff',
    ...(brotli ? { 'content-encoding': 'br', vary: 'accept-encoding' } : {}),
  });
  response.end(brotli ? file.packed : file.raw);
}).listen(port, '127.0.0.1', () => console.log(`http://127.0.0.1:${port}`));
