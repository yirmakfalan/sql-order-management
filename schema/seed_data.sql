-- =============================================
-- E-Ticaret Sipariþ Yönetimi - Örnek Veriler
-- =============================================

-- PaymentStatuses
IF NOT EXISTS (SELECT 1 FROM PaymentStatuses)
BEGIN
INSERT INTO PaymentStatuses (PaymentStatusId, StatusName, IsFinal) VALUES
(1, 'Pending',   0),
(2, 'Completed', 1),
(3, 'Failed',    1),
(4, 'Refunded',  1);
END

-- PaymentMethods
INSERT INTO PaymentMethods (MethodName, IsActive) VALUES
(N'Kredi Kartý',    1),
(N'Havale/EFT',     1),
(N'Kapýda Ödeme',   1),
(N'Dijital Cüzdan', 1);

-- Customers
INSERT INTO Customers (Name_, Email, Phone, Balance, IsActive) VALUES
(N'Ayþe Kaya',      'ayse.kaya@email.com',      '05321234567', 0, 1),
(N'Mehmet Demir',   'mehmet.demir@email.com',    '05339876543', 0, 1),
(N'Zeynep Çelik',   'zeynep.celik@email.com',    '05351112233', 0, 1),
(N'Can Yýldýz',     'can.yildiz@email.com',      '05364445566', 0, 1),
(N'Elif Þahin',     'elif.sahin@email.com',      '05377778899', 0, 1);

-- Warehouses
INSERT INTO Warehouses (WarehouseCode, WarehouseName, WarehouseType, Capacity, Address, City, Country, IsActive) VALUES
('WH-IST', N'Ýstanbul Ana Depo',       'Main',                500, N'Dudullu OSB, Ümraniye',    N'Ýstanbul', N'Türkiye', 1),
('WH-IZM', N'Ýzmir Daðýtým Merkezi',   'Distribution Center', 300, N'Kemalpaþa OSB',            N'Ýzmir',    N'Türkiye', 1),
('WH-ANK', N'Ankara Maðaza Deposu',    'Store',               150, N'Ostim OSB, Yenimahalle',   N'Ankara',   N'Türkiye', 1);

-- Products
INSERT INTO Products (Name_, Category, CostPrice, SalePrice, IsActive) VALUES
(N'Laptop 15"',         N'Elektronik',  8000.00,  11999.99, 1),
(N'Kablosuz Mouse',     N'Elektronik',   150.00,    299.99, 1),
(N'Mekanik Klavye',     N'Elektronik',   400.00,    749.99, 1),
(N'USB-C Hub',          N'Elektronik',   200.00,    399.99, 1),
(N'Ofis Koltuðu',       N'Mobilya',      900.00,   1799.99, 1),
(N'Çalýþma Masasý',     N'Mobilya',     1200.00,   2499.99, 1),
(N'Webcam HD',          N'Elektronik',   250.00,    499.99, 1),
(N'Monitör 27"',        N'Elektronik',  3500.00,   5999.99, 1),
(N'Laptop Çantasý',     N'Aksesuar',     100.00,    219.99, 1),
(N'HDMI Kablo 2m',      N'Aksesuar',     30.00,     69.99, 1);

-- Stocks (ProductID, WarehouseID, Quantity)
INSERT INTO Stocks (ProductID, WarehouseID, Quantity) VALUES
(1, 1, 25),  -- Laptop - Ýstanbul
(1, 2, 10),  -- Laptop - Ýzmir
(2, 1, 100), -- Mouse - Ýstanbul
(2, 2, 60),  -- Mouse - Ýzmir
(2, 3, 40),  -- Mouse - Ankara
(3, 1, 50),  -- Klavye - Ýstanbul
(3, 3, 20),  -- Klavye - Ankara
(4, 1, 80),  -- USB-C Hub - Ýstanbul
(4, 2, 30),  -- USB-C Hub - Ýzmir
(5, 1, 15),  -- Koltuk - Ýstanbul
(5, 2, 8),   -- Koltuk - Ýzmir
(6, 1, 10),  -- Masa - Ýstanbul
(7, 1, 45),  -- Webcam - Ýstanbul
(7, 3, 15),  -- Webcam - Ankara
(8, 1, 20),  -- Monitör - Ýstanbul
(8, 2, 12),  -- Monitör - Ýzmir
(9, 1, 70),  -- Çanta - Ýstanbul
(9, 2, 40),  -- Çanta - Ýzmir
(9, 3, 30),  -- Çanta - Ankara
(10, 1, 200),-- HDMI - Ýstanbul
(10, 2, 100),-- HDMI - Ýzmir
(10, 3, 80); -- HDMI - Ankara

