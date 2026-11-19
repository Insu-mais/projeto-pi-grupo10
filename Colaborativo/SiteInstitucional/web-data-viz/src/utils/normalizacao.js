// Utilitário server-side para normalizar nomes de espécies
function normalizeName(nome) {
  if (nome == null) return '';
  // Normaliza Unicode, remove diacríticos
  let s = String(nome).normalize('NFD').replace(/\p{Diacritic}/gu, '');
  s = s.toLowerCase();
  // Substitui caracteres não alfanuméricos por hífen
  s = s.replace(/[^a-z0-9]+/g, '-');
  // Remove hífens no início/fim e colapsa múltiplos
  s = s.replace(/^-+|-+$/g, '').replace(/-+/g, '-');
  return s;
}

module.exports = { normalizeName };
