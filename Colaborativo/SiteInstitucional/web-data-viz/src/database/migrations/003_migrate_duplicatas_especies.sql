-- Migration 003 (análise): identificar slugs duplicados existentes
-- Este script gera um relatório das slugs que aparecem mais de uma vez.

SELECT
  slug,
  COUNT(*) AS quantidade,
  GROUP_CONCAT(id) AS ids,
  GROUP_CONCAT(nome_original SEPARATOR ' | ') AS nomes
FROM especie
GROUP BY slug
HAVING quantidade > 1;

-- Execução: rodar apenas em modo de análise. Para execução/merge real, usar script Node com revisão humana.
