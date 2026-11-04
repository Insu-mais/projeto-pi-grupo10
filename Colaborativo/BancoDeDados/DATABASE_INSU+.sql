CREATE DATABASE insumais;
USE insumais;

-- Tabela para armazenar dados do cliente (empresa) que comprará a nossa solução
CREATE TABLE cliente(
    id INT PRIMARY KEY AUTO_INCREMENT,
    razaoSocial VARCHAR(100) NOT NULL UNIQUE,
    nmFantasia VARCHAR(100),
    cnpj CHAR(14) UNIQUE NOT NULL, -- somente números (sem pontos, barra ou traço)
    -- Padronização: CNPJ precisa ter exatamente 14 dígitos numéricos
    CONSTRAINT chkCnpj CHECK(cnpj REGEXP '^[0-9]{14}$')
);

-- Tabela de acesso ao sistema: guarda o email e a senha usados no login (separada de [cliente])
CREATE TABLE usuario(
    id INT PRIMARY KEY AUTO_INCREMENT,
    fk_cliente INT NOT NULL, -- Ligação com [cliente]: a qual empresa esse acesso pertence
    email VARCHAR(255) NOT NULL UNIQUE, -- UNIQUE: impede dois cadastros com o mesmo email (usado no login)
    senha VARCHAR(255) NOT NULL, -- hash da senha (nunca a senha pura)
    CONSTRAINT fk_usuario_cliente FOREIGN KEY (fk_cliente) REFERENCES cliente(id),
    -- Padronização: email precisa ter algo antes e depois do @ e um ponto no domínio
    CONSTRAINT chkEmail CHECK(email LIKE '%_@_%._%')
);

-- Tabela para armazenar informações relacionadas ao insumo
CREATE TABLE insumo(
    id INT PRIMARY KEY AUTO_INCREMENT,
    tipo VARCHAR(100) NOT NULL,
    fabricante VARCHAR(255) NOT NULL,
    custoPorTon DECIMAL(10,2) NOT NULL,
    CONSTRAINT chkCustoPorTon CHECK(custoPorTon > 0)
);

-- Guarda dados do canavial inteiro, como quem é o dono, qual a meta de volume e o tamanho da área
CREATE TABLE canavial(
    id INT PRIMARY KEY AUTO_INCREMENT,
    fk_dono INT NOT NULL, -- Ligação com [cliente]
    nome VARCHAR(100) NOT NULL, -- Nome para o cliente identificar o canavial (ex.: 'Talhão Norte')
    areaHa DECIMAL(10,2) NOT NULL, -- Área em hectares
    metaVol INT NOT NULL, -- Toneladas
    CONSTRAINT fk_canavial_cliente FOREIGN KEY (fk_dono) REFERENCES cliente(id),
    CONSTRAINT chkAreaHa CHECK(areaHa > 0),
    CONSTRAINT chkMetaVol CHECK(metaVol > 0),
    -- O mesmo cliente não pode ter dois canaviais com o mesmo nome
    CONSTRAINT uqCanavialNome UNIQUE (fk_dono, nome)
);

-- Guarda dados de grupos de colmos dentro de um canavial, diz qual insumo está sendo utilizado e quando o grupo foi plantado
-- (dtColeta é a colheita: NULL = em andamento)
CREATE TABLE amostra(
    id INT PRIMARY KEY AUTO_INCREMENT,
    fk_canavial INT NOT NULL, -- Ligação com [canavial]
    fk_insumo INT NOT NULL, -- Ligação com [insumo]
    dtCicloInit DATE NOT NULL,
    dtColeta DATE DEFAULT NULL,
    CONSTRAINT fk_amostra_canavial FOREIGN KEY (fk_canavial) REFERENCES canavial(id),
    CONSTRAINT fk_amostra_insumo FOREIGN KEY (fk_insumo) REFERENCES insumo(id),
    -- A coleta não pode ser antes do início do ciclo
    CONSTRAINT chkDtColeta CHECK(dtColeta IS NULL OR dtColeta >= dtCicloInit)
);

-- Tabela para o colmo (cana) individual, a altura é um dado em constante atualização conforme o crescimento do colmo
CREATE TABLE colmo(
    id INT PRIMARY KEY AUTO_INCREMENT,
    fk_amostra INT NOT NULL, -- Qual grupo ele pertence (ligação com [amostra]). O colmo NÃO muda de amostra
    altura INT NOT NULL, -- em CM (leitura ATUAL; as anteriores ficam em [historico])
    dtPlantado DATETIME DEFAULT NULL,
    dtUltimaLeitura DATETIME DEFAULT NOW(),
    CONSTRAINT fk_colmo_amostra FOREIGN KEY (fk_amostra) REFERENCES amostra(id),
    CONSTRAINT chkAltura CHECK(altura > 0)
);

-- Tabela do equipamento (sensor): guarda apenas o status do aparelho.
-- A altura medida NÃO fica aqui: ela já existe em [colmo].altura (atual) e [historico] (anteriores).
-- Manter a medição aqui duplicaria o dado (atributo derivado) e poderia ficar divergente.
CREATE TABLE sensor(
    id INT PRIMARY KEY AUTO_INCREMENT,
    dtInstalacao DATETIME DEFAULT NOW(),
    ativo TINYINT NOT NULL DEFAULT 1, -- 1 = ativo, 0 = desativado
    fk_colmo INT NOT NULL, -- Ligação com [colmo]
    CONSTRAINT fk_sensor_colmo FOREIGN KEY (fk_colmo) REFERENCES colmo(id),
    CONSTRAINT chkAtivo CHECK(ativo IN (0, 1))
);

-- Funciona como um log: cada vez que o colmo é atualizado, o valor anterior vai para cá (várias linhas por colmo)
CREATE TABLE historico(
    idHist INT PRIMARY KEY AUTO_INCREMENT,
    fk_colmo INT NOT NULL, -- Ligação com [colmo]
    alturaPast INT NOT NULL, -- em CM
    dtReg DATETIME DEFAULT NOW(), -- Data do registro
    CONSTRAINT fk_historico_colmo FOREIGN KEY (fk_colmo) REFERENCES colmo(id),
    CONSTRAINT chkAlturaPast CHECK(alturaPast > 0)
);

/*
    Inserção de dados mocados
*/

-- O hash abaixo é apenas um EXEMPLO de formato bcrypt (60 caracteres). No site real, ele é gerado pelo back-end no cadastro
INSERT INTO cliente (razaoSocial, nmFantasia, cnpj) VALUES
('Usina Raizen Teste', NULL, '12345678000199'),
('Usina Santa Clara Teste', 'Santa Clara', '98765432000110');

INSERT INTO usuario (fk_cliente, email, senha) VALUES
(1, 'contato@raizen.com', '$2b$10$EXEMPLOdeHashBcryptGeradoNoBackEnd0000000000000000000'),
(2, 'contato@santaclara.com.br', '$2b$10$EXEMPLOdeHashBcryptGeradoNoBackEnd0000000000000000000');

INSERT INTO insumo (tipo, fabricante, custoPorTon) VALUES
('Fertilizante nitrogenado', 'Yara', 335.00),
('Herbicida', 'Ihara', 300.00),
('Fertilizante fosfatado', 'Mosaic', 410.50),
('Inoculante biológico', 'Biotrop', 280.00); -- ainda não usado em nenhuma amostra

INSERT INTO canavial (fk_dono, nome, areaHa, metaVol) VALUES
(1, 'Canavial Norte', 120.50, 5000), -- canavial 1 (Raizen)
(1, 'Canavial Sul', 80.00, 3200),    -- canavial 2 (Raizen)
(2, 'Canavial Leste', 95.75, 4100);  -- canavial 3 (Santa Clara)

INSERT INTO amostra (fk_canavial, fk_insumo, dtCicloInit, dtColeta) VALUES
(1, 1, '2026-01-01', NULL),         -- amostra 1: nitrogenado, em andamento
(1, 2, '2026-01-01', NULL),         -- amostra 2: herbicida, em andamento
(3, 1, '2026-01-10', NULL),         -- amostra 3: nitrogenado (Santa Clara), em andamento
(2, 3, '2026-01-15', NULL),         -- amostra 4: fosfatado, em andamento
(1, 3, '2025-02-01', '2025-12-10'); -- amostra 5: ciclo antigo, já coletado

-- Colmos das amostras em andamento (leitura inicial)
INSERT INTO colmo (fk_amostra, altura, dtPlantado, dtUltimaLeitura) VALUES
(1, 45, '2026-01-05', '2026-01-20'),
(1, 47, '2026-01-05', '2026-01-20'),
(1, 44, '2026-01-05', '2026-01-20'),
(1, 46, '2026-01-05', '2026-01-20'),
(1, 45, '2026-01-05', '2026-01-20'),
(2, 43, '2026-01-05', '2026-01-20'),
(2, 44, '2026-01-05', '2026-01-20'),
(2, 42, '2026-01-05', '2026-01-20'),
(2, 45, '2026-01-05', '2026-01-20'),
(2, 43, '2026-01-05', '2026-01-20'),
(3, 46, '2026-01-12', '2026-01-20'),
(3, 45, '2026-01-12', '2026-01-20'),
(3, 47, '2026-01-12', '2026-01-20'),
(4, 44, '2026-01-18', '2026-01-20'),
(4, 46, '2026-01-18', '2026-01-20'),
(4, 45, '2026-01-18', '2026-01-20');

/*
    Funcionamento do historico (log):
    1) o valor ATUAL do colmo é copiado para a tabela historico
    2) a tabela colmo é atualizada com os novos valores
    Repetimos isso duas vezes para simular dois ciclos de leitura.
*/

-- Ciclo 1: guarda a leitura inicial e atualiza o crescimento (cada insumo cresce de um jeito)
INSERT INTO historico (fk_colmo, alturaPast, dtReg)
SELECT id, altura, '2026-01-20' FROM colmo;

UPDATE colmo SET altura = altura + 23, dtUltimaLeitura = '2026-02-20' WHERE fk_amostra = 1;
UPDATE colmo SET altura = altura + 15, dtUltimaLeitura = '2026-02-20' WHERE fk_amostra = 2;
UPDATE colmo SET altura = altura + 22, dtUltimaLeitura = '2026-02-20' WHERE fk_amostra = 3;
UPDATE colmo SET altura = altura + 20, dtUltimaLeitura = '2026-02-20' WHERE fk_amostra = 4;

-- Ciclo 2: guarda a leitura de fevereiro e atualiza novamente
INSERT INTO historico (fk_colmo, alturaPast, dtReg)
SELECT id, altura, '2026-02-20' FROM colmo;

UPDATE colmo SET altura = altura + 27, dtUltimaLeitura = '2026-03-20' WHERE fk_amostra = 1;
UPDATE colmo SET altura = altura + 17, dtUltimaLeitura = '2026-03-20' WHERE fk_amostra = 2;
UPDATE colmo SET altura = altura + 25, dtUltimaLeitura = '2026-03-20' WHERE fk_amostra = 3;
UPDATE colmo SET altura = altura + 22, dtUltimaLeitura = '2026-03-20' WHERE fk_amostra = 4;

-- Colmos do ciclo antigo (amostra 5, já colhida): entram depois e ficam sem histórico
INSERT INTO colmo (fk_amostra, altura, dtPlantado, dtUltimaLeitura) VALUES
(5, 310, '2025-02-05', '2025-12-10'),
(5, 305, '2025-02-05', '2025-12-10'),
(5, 298, '2025-02-05', '2025-12-10');

-- Sensores: cada colmo tem um sensor instalado na data do plantio (a altura fica em [colmo])
INSERT INTO sensor (dtInstalacao, ativo, fk_colmo)
SELECT dtPlantado, 1, id FROM colmo;

-- Sensores desativados: o do colmo 3 (defeito) e os do ciclo já colhido (amostra 5)
UPDATE sensor SET ativo = 0 WHERE fk_colmo = 3;
UPDATE sensor SET ativo = 0 WHERE fk_colmo IN (17, 18, 19);

/*
    Testes das restrições (cada INSERT abaixo DEVE FALHAR).
    Descomente um por vez para verificar se as regras estão funcionando.

    -- CNPJ com pontuação (fora do padrão)
    INSERT INTO cliente (razaoSocial, cnpj)
    VALUES ('Teste 1', '12.345.678/0001-99');

    -- CNPJ repetido
    INSERT INTO cliente (razaoSocial, cnpj)
    VALUES ('Teste 3', '12345678000199');

    -- Usuário com email inválido
    INSERT INTO usuario (fk_cliente, email, senha) VALUES (1, 'emailinvalido', 'x');

    -- Usuário com email repetido
    INSERT INTO usuario (fk_cliente, email, senha) VALUES (1, 'contato@raizen.com', 'x');

    -- Usuário ligado a um cliente que não existe
    INSERT INTO usuario (fk_cliente, email, senha) VALUES (99, 'novo@teste.com', 'x');

    -- Meta de volume negativa
    INSERT INTO canavial (fk_dono, nome, areaHa, metaVol) VALUES (1, 'Teste', 10, -5);

    -- Coleta antes do início do ciclo
    INSERT INTO amostra (fk_canavial, fk_insumo, dtCicloInit, dtColeta)
    VALUES (1, 1, '2026-05-01', '2026-01-01');

    -- Altura zero
    INSERT INTO colmo (fk_amostra, altura) VALUES (1, 0);

    -- Sensor com status inválido
    INSERT INTO sensor (ativo, fk_colmo) VALUES (5, 1);
*/

/*
    Selects de demonstração.
*/

-- Consulta 1: Como estão minhas plantas hoje?
SELECT
    id AS 'Identificador do colmo',
    altura AS 'Altura em CM',
    IFNULL(DATE_FORMAT(dtPlantado, '%d/%m/%Y'), 'Sem data de plantio') AS 'Data de Plantio'
FROM colmo
ORDER BY id;

-- Consulta 2: O que eu apliquei em cada área, já foi colhido?
SELECT
    a.id AS 'Amostra',
    i.tipo AS 'Insumo',
    a.dtCicloInit AS 'Inicio do Ciclo',
    CASE WHEN a.dtColeta IS NULL THEN 'Coleta pendente' ELSE a.dtColeta END AS 'Data da Coleta'
FROM amostra a
    JOIN insumo i
        ON a.fk_insumo = i.id
ORDER BY a.id;

-- Consulta 3: Minha cana cresceu? (compara com o registro MAIS RECENTE do histórico de cada colmo)
SELECT
    c.id AS 'Colmo',
    h.alturaPast AS 'Altura Anterior',
    c.altura AS 'Altura Atual',
    c.altura - h.alturaPast AS 'Crescimento (cm)',
    CASE
        WHEN h.idHist IS NULL THEN 'Sem histórico'
        WHEN c.altura > h.alturaPast THEN 'Cresceu'
        ELSE 'Sem crescimento'
    END AS 'Situação de crescimento'
FROM colmo c
    LEFT JOIN historico h
        ON h.idHist = (SELECT MAX(h2.idHist) FROM historico h2 WHERE h2.fk_colmo = c.id)
ORDER BY c.id;

-- Consulta 4: Visão geral do canavial
SELECT
    cli.razaoSocial AS 'Cliente',
    can.id AS 'Canavial',
    can.nome AS 'Nome do canavial',
    can.areaHa AS 'Área (ha)',
    can.metaVol AS 'Meta de Toneladas',
    CONCAT(i.tipo, ' do ', i.fabricante) AS 'Info. do Insumo',
    a.dtCicloInit AS 'Inicio do ciclo',
    CASE WHEN a.dtColeta IS NULL THEN 'Em andamento' ELSE a.dtColeta END AS 'Status de Coleta'
FROM cliente cli
    JOIN canavial can
        ON can.fk_dono = cli.id
    JOIN amostra a
        ON a.fk_canavial = can.id
    JOIN insumo i
        ON a.fk_insumo = i.id
-- Cada ON liga uma tabela à anterior pela FK; sem eles o select combinaria todos os registros com todos (produto cartesiano)
ORDER BY cli.razaoSocial;

-- Consulta 5: Como está a altura das plantas de cada insumo agora? (só amostras em andamento)
SELECT
    i.tipo AS 'Insumo',
    i.fabricante AS 'Fabricante',
    COUNT(c.id) AS 'Qtd. de colmos',
    ROUND(AVG(c.altura), 1) AS 'Altura média (cm)',
    i.custoPorTon AS 'Custo por ton'
FROM colmo c
    JOIN amostra a
        ON c.fk_amostra = a.id
    JOIN insumo i
        ON a.fk_insumo = i.id
WHERE a.dtColeta IS NULL
GROUP BY i.id, i.tipo, i.fabricante, i.custoPorTon
ORDER BY AVG(c.altura) DESC;

-- Consulta 6: Qual insumo fez a cana crescer mais desde a primeira leitura? (crescimento x custo)
SELECT
    i.tipo AS 'Insumo',
    ROUND(AVG(c.altura - h.alturaPast), 1) AS 'Crescimento médio (cm)',
    i.custoPorTon AS 'Custo por ton',
    ROUND(AVG(c.altura - h.alturaPast) / i.custoPorTon, 3) AS 'cm ganhos por unidade de custo'
FROM colmo c
    JOIN historico h
        ON h.idHist = (SELECT MIN(h2.idHist) FROM historico h2 WHERE h2.fk_colmo = c.id) -- primeira leitura do colmo
    JOIN amostra a
        ON c.fk_amostra = a.id
    JOIN insumo i
        ON a.fk_insumo = i.id
GROUP BY i.id, i.tipo, i.custoPorTon
ORDER BY AVG(c.altura - h.alturaPast) DESC;

-- Consulta 7: Quais sensores estão desativados em amostras em andamento? (precisam de manutenção)
SELECT
    cli.razaoSocial AS 'Cliente',
    can.id AS 'Canavial',
    a.id AS 'Amostra',
    c.id AS 'Colmo',
    s.id AS 'Sensor'
FROM sensor s
    JOIN colmo c
        ON s.fk_colmo = c.id
    JOIN amostra a
        ON c.fk_amostra = a.id
    JOIN canavial can
        ON a.fk_canavial = can.id
    JOIN cliente cli
        ON can.fk_dono = cli.id
WHERE s.ativo = 0
  AND a.dtColeta IS NULL; -- ignora os sensores desligados de propósito após a colheita

-- Consulta 8: Resumo por cliente (quantos canaviais, meta total, área total e colmos monitorados)
SELECT
    cli.razaoSocial AS 'Cliente',
    COUNT(can.id) AS 'Qtd. de canaviais',
    IFNULL(SUM(can.areaHa), 0) AS 'Área total (ha)',
    IFNULL(SUM(can.metaVol), 0) AS 'Soma das metas (ton)',
    -- Subselect separado para contar os colmos, assim os JOINs não repetem a meta de cada canavial
    (SELECT COUNT(*)
        FROM colmo c
            JOIN amostra a
                ON c.fk_amostra = a.id
            JOIN canavial can2
                ON a.fk_canavial = can2.id
        WHERE can2.fk_dono = cli.id) AS 'Colmos monitorados'
FROM cliente cli
    LEFT JOIN canavial can
        ON can.fk_dono = cli.id
GROUP BY cli.id, cli.razaoSocial
ORDER BY cli.razaoSocial;

-- Consulta 9: Quais insumos cadastrados nunca foram usados em nenhuma amostra?
SELECT
    i.id AS 'Insumo',
    i.tipo AS 'Tipo',
    i.fabricante AS 'Fabricante'
FROM insumo i
    LEFT JOIN amostra a
        ON a.fk_insumo = i.id
WHERE a.id IS NULL;

-- Consulta 10: Login do site. O back-end busca o usuário pelo email e compara o hash da senha digitada com o hash salvo
SELECT
    u.id AS 'Usuário',
    cli.id AS 'Cliente',
    cli.razaoSocial AS 'Razão social',
    u.senha AS 'Hash salvo (comparado no back-end)'
FROM usuario u
    JOIN cliente cli
        ON u.fk_cliente = cli.id
WHERE u.email = 'contato@raizen.com';
