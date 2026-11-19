-- Migration 001: criar tabela especie e tabela associativa especie_aquario
-- Supondo MySQL, compatível com script-tabelas.sql existente

CREATE TABLE IF NOT EXISTS especie (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nome_original VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL,
  tipo_agua ENUM('doce','salgada','ambos') DEFAULT 'ambos',
  tamanho VARCHAR(100),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY ux_especie_slug (slug)
);

CREATE TABLE IF NOT EXISTS especie_aquario (
  especie_id INT NOT NULL,
  aquario_id INT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (especie_id, aquario_id),
  INDEX idx_especie (especie_id),
  INDEX idx_aquario (aquario_id),
  CONSTRAINT fk_ea_especie FOREIGN KEY (especie_id) REFERENCES especie(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ea_aquario FOREIGN KEY (aquario_id) REFERENCES aquario(id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Observação: esta migration cria a tabela `especie` e a associativa `especie_aquario`.
-- As constraints assumem que a tabela `aquario` já existe (ver 002_add_tipo_aquario.sql e src/database/script-tabelas.sql).
