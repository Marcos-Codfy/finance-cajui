// Resume um relatório do Lighthouse numa linha: notas, métricas de carga,
// peso transferido e o primeiro quadro do Flutter (a marca `cajui:first-frame`
// que o index.html registra).
//
// Uso: node summarize.mjs <relatório.json> [--failures]

import { readFileSync } from 'node:fs';

const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const audit = (id) => report.audits[id];
const score = (id) => Math.round(report.categories[id].score * 100);
const ms = (id) => Math.round(audit(id).numericValue);

const firstFrame = audit('user-timings')?.details?.items?.find(
  (item) => item.name === 'cajui:first-frame',
);

console.log(
  JSON.stringify({
    performance: score('performance'),
    accessibility: score('accessibility'),
    bestPractices: score('best-practices'),
    fcpMs: ms('first-contentful-paint'),
    lcpMs: ms('largest-contentful-paint'),
    tbtMs: ms('total-blocking-time'),
    cls: Number(audit('cumulative-layout-shift').numericValue.toFixed(3)),
    speedIndexMs: ms('speed-index'),
    firstFrameMs: firstFrame ? Math.round(firstFrame.startTime) : null,
    transferKb: Math.round(audit('total-byte-weight').numericValue / 1024),
    requests: audit('network-requests').details.items.length,
  }),
);

if (process.argv.includes('--failures')) {
  for (const category of Object.values(report.categories)) {
    for (const ref of category.auditRefs) {
      const item = report.audits[ref.id];
      if (item.score !== null && item.score < 1 && ref.weight > 0) {
        console.log(`  ${category.id} · ${ref.id} · ${item.score} · ${item.title}`);
      }
    }
  }
}
