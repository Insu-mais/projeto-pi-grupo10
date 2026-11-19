const assert = require('assert');
const { normalizeName } = require('../src/utils/normalizacao');

const cases = [
  ['Peixe-dourado', 'peixe-dourado'],
  ['peixe_dourado', 'peixe-dourado'],
  ['Peixe Dourado', 'peixe-dourado'],
  ['  Peixe  -- Dourado  ', 'peixe-dourado'],
  ['Péixe Áá', 'peixe-aa'],
  ['Tilápia (Gigante)', 'tilapia-gigante'],
  ['Salmão/Mar', 'salmao-mar'],
  ['Peixe--com__underscores', 'peixe-com-underscores'],
  ['Água-viva', 'agua-viva'],
  ['123 Peixe', '123-peixe'],
  ['Peixe@#%Nome', 'peixe-nome'],
  ['--Início', 'inicio'],
  ['Fim--', 'fim'],
  ['---Multi---Hífen---', 'multi-hifen'],
  ['', ''],
  [null, ''],
  ['ÁÉÍÓÚÂÊÎÔÛÃÕÇ', 'aeiouaeiouaoc'],
  ['Peixe  de    Água', 'peixe-de-agua'],
  ['Peixe—Em—Dash', 'peixe-em-dash'],
  ['Nº 1 - Especial', 'n-1-especial']
];

let passed = 0;
for (const [input, expected] of cases) {
  const out = normalizeName(input);
  try {
    assert.strictEqual(out, expected);
    passed++;
  } catch (e) {
    console.error(`FAIL: input='${input}' expected='${expected}' got='${out}'`);
    process.exitCode = 1;
  }
}

console.log(`Normalizacao: ${passed}/${cases.length} testes passaram.`);
