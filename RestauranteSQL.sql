-- 1. Criação do banco de dados (opcional, se já estiver no contexto do banco)
CREATE DATABASE RestauranteDB;
\c RestauranteDB -- Conecta ao banco criado

-- 2. Criação das tabelas principais
CREATE TABLE Clientes (
    ClienteID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Telefone VARCHAR(15),
    DataCadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Pratos (
    PratoID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Categoria VARCHAR(50),
    Preco NUMERIC(10, 2) NOT NULL,
    Disponivel BOOLEAN DEFAULT TRUE
);

CREATE TABLE Pedidos (
    PedidoID SERIAL PRIMARY KEY,
    ClienteID INT NOT NULL REFERENCES Clientes(ClienteID),
    DataPedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ValorTotal NUMERIC(10, 2),
    Status VARCHAR(20) DEFAULT 'Pendente'
);

CREATE TABLE DetalhesPedido (
    DetalheID SERIAL PRIMARY KEY,
    PedidoID INT NOT NULL REFERENCES Pedidos(PedidoID),
    PratoID INT NOT NULL REFERENCES Pratos(PratoID),
    Quantidade INT NOT NULL,
    PrecoUnitario NUMERIC(10, 2)
);

-- 3. Criação de uma View para resumo dos pedidos
CREATE VIEW ResumoPedidos AS
SELECT 
    p.PedidoID,
    c.Nome AS Cliente,
    p.DataPedido,
    p.ValorTotal,
    p.Status
FROM Pedidos p
JOIN Clientes c ON p.ClienteID = c.ClienteID;

-- 4. Função para atualizar o valor total do pedido
CREATE OR REPLACE FUNCTION AtualizaValorTotal()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Pedidos
    SET ValorTotal = (
        SELECT SUM(Quantidade * PrecoUnitario)
        FROM DetalhesPedido
        WHERE PedidoID = NEW.PedidoID
    )
    WHERE PedidoID = NEW.PedidoID;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Criação do Trigger associado à função
CREATE TRIGGER TriggerAtualizaValorTotal
AFTER INSERT ON DetalhesPedido
FOR EACH ROW
EXECUTE FUNCTION AtualizaValorTotal();

-- 6. Função para listar pedidos por cliente
CREATE OR REPLACE FUNCTION PedidosPorCliente(ClienteIDParam INT)
RETURNS TABLE (
    PedidoID INT,
    DataPedido TIMESTAMP,
    Status VARCHAR,
    ValorTotal NUMERIC(10, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        PedidoID, 
        DataPedido, 
        Status, 
        ValorTotal
    FROM Pedidos
    WHERE ClienteID = ClienteIDParam;
END;
$$ LANGUAGE plpgsql;

-- 7. Inserção de dados de exemplo
INSERT INTO Clientes (Nome, Email, Telefone) VALUES
('Maria Silva', 'maria@gmail.com', '11987654321'),
('João Souza', 'joao@gmail.com', '21998765432');

INSERT INTO Pratos (Nome, Categoria, Preco) VALUES
('Pizza Margherita', 'Pizza', 30.00),
('Espaguete à Bolonhesa', 'Massa', 25.00),
('Risoto de Cogumelos', 'Massa', 35.00),
('Pudim de Leite', 'Sobremesa', 10.00);

INSERT INTO Pedidos (ClienteID, Status) VALUES
(1, 'Pendente'),
(2, 'Pendente');

INSERT INTO DetalhesPedido (PedidoID, PratoID, Quantidade, PrecoUnitario) VALUES
(1, 1, 2, 30.00), -- Pedido de 2 pizzas
(1, 4, 1, 10.00), -- 1 pudim
(2, 2, 3, 25.00); -- 3 espaguetes

-- 8. Consultas para validação
SELECT * FROM ResumoPedidos;

-- Chamando a função para listar pedidos de um cliente específico
SELECT * FROM PedidosPorCliente(1);

