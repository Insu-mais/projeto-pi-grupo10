// Script Node para análise de duplicatas de espécies.
// Não executa merges automaticamente; gera relatório JSON para revisão.

const db = require('../../database/config');
const normalizacao = require('../../utils/normalizacao');

function gerarRelatorio() {
  const instr = `SELECT id, nome_original, slug FROM especie`;
  return db.executar(instr).then(rows => {
    const bySlug = {};
    for (const r of rows) {
      const slug = r.slug || normalizacao.normalizeName(r.nome_original);
      if (!bySlug[slug]) bySlug[slug] = [];
      bySlug[slug].push(r);
    }
    const duplicados = Object.entries(bySlug).filter(([k, v]) => v.length > 1).map(([slug, items]) => ({ slug, items }));
    console.log(JSON.stringify({ total: rows.length, duplicados }, null, 2));
  });
}

gerarRelatorio().catch(err => { console.error('Erro ao gerar relatório:', err); process.exit(1); });
