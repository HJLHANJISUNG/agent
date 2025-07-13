-- 確保數據庫存在
CREATE DATABASE IF NOT EXISTS agentai_db;
USE agentai_db;

-- 創建用戶表
CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(255) PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    register_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 創建協議表
CREATE TABLE IF NOT EXISTS protocols (
    protocol_id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    rfc_number VARCHAR(255)
);

-- 創建知識表
CREATE TABLE IF NOT EXISTS knowledge (
    knowledge_id VARCHAR(255) PRIMARY KEY,
    protocol_id VARCHAR(255),
    content TEXT NOT NULL,
    source VARCHAR(2048),
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (protocol_id) REFERENCES protocols(protocol_id)
);

-- 創建問題表
CREATE TABLE IF NOT EXISTS questions (
    question_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    image_url VARCHAR(2048),
    file_url VARCHAR(2048),
    file_name VARCHAR(255),
    ask_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- 創建解決方案表
CREATE TABLE IF NOT EXISTS solutions (
    solution_id VARCHAR(255) PRIMARY KEY,
    question_id VARCHAR(255) NOT NULL,
    steps TEXT NOT NULL,
    confidence_score FLOAT NOT NULL,
    FOREIGN KEY (question_id) REFERENCES questions(question_id)
);

-- 創建反饋表
CREATE TABLE IF NOT EXISTS feedbacks (
    feedback_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    solution_id VARCHAR(255) NOT NULL,
    rating INT NOT NULL,
    comment TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (solution_id) REFERENCES solutions(solution_id)
);

-- 創建解決方案引用知識的關聯表
CREATE TABLE IF NOT EXISTS solution_references_knowledge (
    solution_id VARCHAR(255) NOT NULL,
    knowledge_id VARCHAR(255) NOT NULL,
    PRIMARY KEY (solution_id, knowledge_id),
    FOREIGN KEY (solution_id) REFERENCES solutions(solution_id),
    FOREIGN KEY (knowledge_id) REFERENCES knowledge(knowledge_id)
);

-- 插入測試數據
INSERT INTO protocols (protocol_id, name, rfc_number) VALUES
('p1', 'BGP', 'RFC 4271'),
('p2', 'OSPF', 'RFC 2328'),
('p3', 'TCP', 'RFC 793');

-- 插入管理員用戶
INSERT INTO users (user_id, username, email, hashed_password, register_date) VALUES
('admin1', 'admin', 'admin@example.com', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', NOW()); 