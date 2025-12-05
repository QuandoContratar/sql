-- ========================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS
-- Sistema: Quando Contratar
-- ========================================

DROP DATABASE IF EXISTS quando_contratar;
CREATE DATABASE quando_contratar;
USE quando_contratar;

-- ========================================
-- TABELA: user (Usuários do sistema)
-- ========================================

CREATE TABLE user (
    id_user INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    area VARCHAR(50),
    level_access ENUM('ADMIN','HR','MANAGER') DEFAULT 'MANAGER' COMMENT 'Níveis de acesso do usuário'
);


-- ========================================
-- TABELA: candidate (Candidatos)
-- ========================================
CREATE TABLE candidate (
    id_candidate INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    birth DATE,
    phone_number CHAR(14),
    email VARCHAR(100) NOT NULL UNIQUE,
    state CHAR(2),
    profile_picture BLOB,
    education VARCHAR(500),
    skills VARCHAR(500),
    experience TEXT,
    resume MEDIUMBLOB,
	current_stage VARCHAR(50) DEFAULT 'aguardando_triagem',
    status VARCHAR(20) DEFAULT 'ativo',
    rejection_reason VARCHAR(500),
    vacancy_id BIGINT
);

-- ========================================
-- TABELA: vacancies (Vagas)
-- ========================================
CREATE TABLE vacancies (
    id_vacancy INT AUTO_INCREMENT PRIMARY KEY,
    position_job VARCHAR(100) NOT NULL,
    period VARCHAR(20),
    work_model ENUM('presencial', 'remoto', 'híbrido') DEFAULT 'presencial',
    requirements TEXT,
    contract_type ENUM('CLT', 'PJ', 'Temporário', 'Estágio', 'Autônomo') DEFAULT 'CLT',
    salary DECIMAL(10, 2),
    location VARCHAR(100),
    opening_justification VARCHAR(255),
    area VARCHAR(100),
    status_vacancy VARCHAR(50) DEFAULT 'pendente aprovação',
    fk_manager INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fk_manager) REFERENCES user(id_user) ON DELETE SET NULL
);

-- ========================================
-- TABELA: opening_requests (Solicitações de Abertura de Vaga)
-- IMPORTANTE: Esta tabela é usada pelo frontend para criar solicitações
-- ========================================
CREATE TABLE opening_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cargo VARCHAR(100) NOT NULL,
    periodo VARCHAR(50) NOT NULL,
    modelo_trabalho VARCHAR(50) NOT NULL,
    regime_contratacao VARCHAR(50) NOT NULL,
    salario DECIMAL(10, 2) NOT NULL,
    localidade VARCHAR(100) NOT NULL,
    requisitos TEXT,
    justificativa_path VARCHAR(255),
    gestor_id INT NOT NULL,
    status ENUM('ENTRADA', 'ABERTA', 'APROVADA', 'REJEITADA', 'CANCELADA') DEFAULT 'ENTRADA',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (gestor_id) REFERENCES user(id_user) ON DELETE CASCADE,
    INDEX idx_gestor_id (gestor_id),
    INDEX idx_status (status)
);

-- ========================================
-- KANBAN – ESTÁGIOS
-- ========================================

CREATE TABLE kanban_stage (
    id_stage INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    position_order INT NOT NULL
);

INSERT INTO kanban_stage (name, position_order) VALUES
('aguardando_triagem',1),
('triagem_inicial', 2),
('avaliacao_fit_cultural', 3),
('teste_tecnico', 4),
('entrevista_tecnica', 5),
('entrevista_final', 6),
('proposta_fechamento', 7),
('contratacao', 8);

-- ========================================
-- KANBAN – CARDS
-- ========================================

CREATE TABLE kanban_card (
    id_card INT AUTO_INCREMENT PRIMARY KEY,
    fk_candidate INT NOT NULL,
    fk_vacancy INT NOT NULL,
    fk_stage INT NOT NULL,
    match_level ENUM('BAIXO','MEDIO','ALTO','DESTAQUE') DEFAULT 'MEDIO',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (fk_candidate) REFERENCES candidate(id_candidate) ON DELETE CASCADE,
    FOREIGN KEY (fk_vacancy) REFERENCES vacancies(id_vacancy) ON DELETE CASCADE,
    FOREIGN KEY (fk_stage) REFERENCES kanban_stage(id_stage) ON DELETE CASCADE
);

-- ========================================
-- TABELA: selection_process (Processo Seletivo)
-- ========================================
CREATE TABLE selection_process (
    `id_selection` INT AUTO_INCREMENT PRIMARY KEY,
    `progress` DECIMAL(5, 2) DEFAULT 0.00,
    `current_stage` ENUM (
        'aguardando_triagem', 
        'triagem_inicial', 
        'avaliacao_fit_cultural',
        'teste_tecnico', 
        'entrevista_tecnica', 
        'entrevista_final', 
        'proposta_fechamento',
        'contratacao'
    ) DEFAULT 'aguardando_triagem',
    `outcome` ENUM('aprovado', 'reprovado', 'pendente') DEFAULT 'pendente',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `fk_candidate` INT NOT NULL,
    `fk_recruiter` INT,
    `fk_vacancy` INT NOT NULL,
    FOREIGN KEY (`fk_candidate`) REFERENCES candidate(`id_candidate`) ON DELETE CASCADE,
    FOREIGN KEY (`fk_recruiter`) REFERENCES user(`id_user`) ON DELETE SET NULL,
    FOREIGN KEY (`fk_vacancy`) REFERENCES vacancies(`id_vacancy`) ON DELETE CASCADE,
    INDEX idx_candidate (`fk_candidate`),
    INDEX idx_vacancy (`fk_vacancy`)
);

-- ========================================
-- TABELA: candidate_match (Match de Candidatos com Vagas)
-- ========================================
CREATE TABLE candidate_match (
    id_match INT AUTO_INCREMENT PRIMARY KEY,
    fk_candidate INT NOT NULL,
    fk_vacancy INT NOT NULL,
    score DECIMAL(5, 2) NOT NULL COMMENT 'Compatibilidade em %',
    match_level ENUM('BAIXO', 'MEDIO', 'ALTO', 'DESTAQUE') NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fk_candidate) REFERENCES candidate(id_candidate) ON DELETE CASCADE,
    FOREIGN KEY (fk_vacancy) REFERENCES vacancies(id_vacancy) ON DELETE CASCADE,
    UNIQUE KEY unique_match (fk_candidate, fk_vacancy),
    INDEX idx_score (score),
    INDEX idx_match_level (match_level)
);

-- ========================================
-- DADOS INICIAIS
-- ========================================

-- Usuários do sistema
INSERT INTO user (name, email, password, area, level_access) VALUES
('Carlos Manager', 'cmanager@example.com', 'pass123', 'TI', 'ADMIN'),
('Ana Recruiter', 'arecruiter@example.com', 'pass456', 'RH', 'ADMIN'),
('Paulo Admin', 'admin@example.com', 'adminpass', 'TI', 'ADMIN'),
('Lucio Limeira', 'lucio@example.com', 'pass789', 'TI', 'ADMIN');

-- Candidatos
INSERT INTO candidate (name, birth, phone_number, email, state, education, skills) VALUES
('João da Silva', '1998-06-15', '(11)91234-5678', 'joao.silva@example.com', 'SP', 'Bacharel em Ciência da Computação', 'Java, Spring, MySQL'),
('Maria Oliveira', '1995-04-22', '(21)92345-6789', 'maria.oliveira@example.com', 'RJ', 'Engenharia de Software', 'Python, Django, PostgreSQL'),
('Carlos Souza', '2000-10-10', '(31)93456-7890', 'carlos.souza@example.com', 'MG', 'Sistemas de Informação', 'JavaScript, React, Node.js'),
('Ana Lima', '1992-12-05', '(47)94567-8901', 'ana.lima@example.com', 'SC', 'Análise e Desenvolvimento de Sistemas', 'C#, .NET, SQL Server'),
('Lucas Pereira', '1999-08-30', '(41)95678-9012', 'lucas.pereira@example.com', 'PR', 'Ciência da Computação', 'Kotlin, Android, Firebase');

-- Vagas (criadas a partir de opening_requests aprovadas)
INSERT INTO vacancies (position_job, period, work_model, requirements, contract_type, salary, location, opening_justification, area, fk_manager, status_vacancy) VALUES
('Desenvolvedor Java', 'Full-time', 'remoto', 'Experiência com Java e Spring Boot', 'CLT', 8000.00, 'São Paulo', 'Nova vaga para projeto X', 'Tecnologia', 1, 'aberta'),
('Analista de Dados', 'Part-time', 'presencial', 'Conhecimento em Python e SQL', 'PJ', 5000.00, 'Rio de Janeiro', 'Crescimento da área', 'Tecnologia', 1, 'aberta'),
('Desenvolvedor Full Stack', 'Full-time', 'híbrido', 'React, Node.js, MongoDB', 'CLT', 9000.00, 'São Paulo', 'Expansão do time', 'Tecnologia', 4, 'aberta');

-- Solicitações de abertura de vaga (exemplos)
-- IMPORTANTE: gestor_id deve referenciar um id_user válido
INSERT INTO opening_requests 
(cargo, periodo, modelo_trabalho, regime_contratacao, salario, localidade, requisitos, justificativa_path, gestor_id, status) 
VALUES
('Engenheiro de Software', 'Full-time', 'remoto', 'CLT', 12000.00, 'São Paulo', 'Experiência com Java, Spring Boot e Docker', '/docs/justificativas/justificativa1.pdf', 1, 'ENTRADA'),
('Analista de Suporte', 'Part-time', 'presencial', 'PJ', 4000.00, 'Rio de Janeiro', 'Conhecimento em Linux e Redes', '/docs/justificativas/justificativa2.pdf', 1, 'ENTRADA'),
('Designer UX/UI', 'Full-time', 'híbrido', 'CLT', 7000.00, 'Belo Horizonte', 'Experiência com Figma e Design Systems', NULL, 1, 'APROVADA'),
('Cientista de Dados', 'Full-time', 'remoto', 'CLT', 15000.00, 'São Paulo', 'Python, Machine Learning, SQL', '/docs/justificativas/justificativa3.pdf', 4, 'ENTRADA');

INSERT INTO kanban_card (fk_candidate, fk_vacancy, fk_stage, match_level)
VALUES
(1, 1, 1, 'ALTO'),
(2, 2, 1, 'MEDIO'),
(4, 3, 2, 'ALTO'),
(5, 1, 2, 'MEDIO'),
(3, 1, 1, 'BAIXO');


-- Matches de candidatos
INSERT INTO candidate_match (fk_candidate, fk_vacancy, score, match_level) VALUES
(1, 1, 85.50, 'ALTO'),
(2, 2, 92.30, 'DESTAQUE'),
(3, 1, 78.90, 'ALTO'),
(4, 2, 65.20, 'MEDIO'),
(5, 1, 88.70, 'ALTO');

-- ========================================
-- CONSULTAS DE VERIFICAÇÃO
-- ========================================

SELECT '=== USUÁRIOS ===' AS info;
SELECT * FROM user;

SELECT '=== CANDIDATOS ===' AS info;
SELECT * FROM candidate;

SELECT '=== VAGAS ===' AS info;
SELECT * FROM vacancies;

SELECT '=== SOLICITAÇÕES DE ABERTURA ===' AS info;
SELECT 
    o.id,
    o.cargo,
    o.periodo,
    o.modelo_trabalho,
    o.regime_contratacao,
    o.salario,
    o.localidade,
    o.status,
    u.name AS gestor_nome,
    o.created_at
FROM opening_requests o
LEFT JOIN user u ON o.gestor_id = u.id_user
ORDER BY o.created_at DESC;


SELECT 
    kc.id_card,
    c.name AS candidate_name,
    v.position_job,
    u.name AS manager_name,
    ks.name AS stage,
    kc.match_level
FROM kanban_card kc
JOIN candidate c       ON kc.fk_candidate = c.id_candidate
JOIN vacancies v       ON kc.fk_vacancy = v.id_vacancy
JOIN user u            ON v.fk_manager = u.id_user
JOIN kanban_stage ks   ON kc.fk_stage = ks.id_stage;


SELECT '=== MATCHES ===' AS info;
SELECT * FROM candidate_match;

-- ========================================
-- FIM DO SCRIPT
-- ========================================

select * from user;

desc user;

select * from user;

INSERT INTO user (name, email, password, area, level_access) VALUES
('Tilia', 'tilia@example.com', 'pass123', 'TI', 'HR'),
('Amanda', 'amanda@example.com', 'pass456', 'RH', 'HR'),
('Clara', 'clara@example.com', 'adminpass', 'TI', 'MANAGER');

select * from user;
select * from vacancies;
ALTER TABLE vacancies MODIFY COLUMN opening_justification LONGBLOB;

update vacancies set fk_manager = 1 where id_vacancy = 6;

update vacancies set status_vacancy = 'aberta' where id_vacancy = 6;

INSERT INTO opening_requests 
(cargo, periodo, modelo_trabalho, regime_contratacao, salario, localidade, requisitos, gestor_id, status)
VALUES
('Dev Backend Junior', 'Full-time', 'remoto', 'CLT', 6500, 'São Paulo', 'Java, Spring Boot', 1, 'ENTRADA'),
('Analista de Infraestrutura', 'Full-time', 'presencial', 'CLT', 8000, 'Rio de Janeiro', 'Linux, Redes, Docker', 1, 'ENTRADA'),
('Assistente de RH', 'Part-time', 'híbrido', 'CLT', 3000, 'Curitiba', 'Atendimento, Organização', 1, 'ENTRADA');


INSERT INTO opening_requests 
(cargo, periodo, modelo_trabalho, regime_contratacao, salario, localidade, requisitos, gestor_id, status)
VALUES
('Product Manager', 'Full-time', 'remoto', 'CLT', 12000, 'São Paulo', 'Scrum, Jira, UX', 1, 'ABERTA'),
('QA Analyst Pleno', 'Full-time', 'presencial', 'CLT', 7000, 'Belo Horizonte', 'Testes manuais e automação', 1, 'ABERTA'),
('Estagiário de Suporte', 'Part-time', 'presencial', 'Estágio', 1800, 'São Paulo', 'Redes básicas, Windows', 1, 'ABERTA'),
('Dev Front-end', 'Full-time', 'híbrido', 'PJ', 9000, 'Campinas', 'React, JS, HTML/CSS', 4, 'ABERTA');


INSERT INTO opening_requests 
(cargo, periodo, modelo_trabalho, regime_contratacao, salario, localidade, requisitos, gestor_id, status)
VALUES
('Designer UI/UX', 'Full-time', 'remoto', 'CLT', 7500, 'São Paulo', 'Figma, Design System', 1, 'APROVADA'),
('DevOps Engineer', 'Full-time', 'remoto', 'CLT', 14000, 'São Paulo', 'AWS, CI/CD, Kubernetes', 1, 'APROVADA');


INSERT INTO opening_requests 
(cargo, periodo, modelo_trabalho, regime_contratacao, salario, localidade, requisitos, gestor_id, status)
VALUES
('Assistente Administrativo', 'Full-time', 'presencial', 'CLT', 2500, 'São Paulo', 'Organização, Excel básico', 1, 'REJEITADA'),
('Scrum Master', 'Full-time', 'remoto', 'PJ', 11000, 'Rio de Janeiro', 'Scrum, Agile Coaching', 1, 'REJEITADA');


INSERT INTO opening_requests 
(cargo, periodo, modelo_trabalho, regime_contratacao, salario, localidade, requisitos, gestor_id, status)
VALUES
('Auxiliar de Logística', 'Full-time', 'presencial', 'CLT', 2400, 'Curitiba', 'Expedição, Organização', 1, 'CANCELADA'),
('Cientista de Dados', 'Full-time', 'remoto', 'CLT', 16000, 'São Paulo', 'Python, ML, SQL', 4, 'CANCELADA');

select * from opening_requests;

INSERT INTO vacancies 
(position_job, area, period, work_model, contract_type, salary, location, requirements, fk_manager, status_vacancy)
VALUES
('Analista de Sistemas', 'TI', 'Integral', 'Remoto', 'CLT', 5500, 'São Paulo', 'SQL, API, SCRUM', 1, 'pendente_aprovacao'),
('Assistente Financeiro', 'Financeiro', 'Integral', 'Presencial', 'CLT', 3100, 'Santo André', 'Excel, Contas a pagar/receber', 2, 'pendente_aprovacao'),
('UX Designer Jr', 'Produto', 'Meio período', 'Híbrido', 'PJ', 4200, 'São Caetano', 'Figma, Design System', 1, 'pendente_aprovacao'),
('Desenvolvedor Back-End Jr', 'TI', 'Integral', 'Remoto', 'CLT', 6500, 'Campinas', 'Java, Spring, SQL', 4, 'pendente_aprovacao');

DESCRIBE vacancies;



