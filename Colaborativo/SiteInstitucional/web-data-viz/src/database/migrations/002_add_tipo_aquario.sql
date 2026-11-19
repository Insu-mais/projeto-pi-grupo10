-- Migration 002: adicionar coluna tipo_agua na tabela aquario
-- Se a coluna já existir, esta migration é segura (IF NOT EXISTS não existe para ADD COLUMN em versões antigas do MySQL,
-- então a migration tenta adicionar e ignora se falhar manualmente ao aplicar).

ALTER TABLE aquario
  ADD COLUMN tipo_agua ENUM('doce','salgada','ambos') NULL DEFAULT NULL;

-- Nota: em dados legados, a coluna poderá ficar NULL. Regra de negócio define que na primeira associação
-- do aquario com uma especie, o sistema pode pedir ao usuário para preencher este campo.
