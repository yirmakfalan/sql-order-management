-- Ödeme yöntemleri
INSERT INTO PaymentMethods (MethodName, IsActive) VALUES
('Nakit', 1),
('Kredi Kartı', 1),
('Banka Transferi', 1)

-- Ödeme durumları (IDENTITY yok, manuel ver)
INSERT INTO PaymentStatuses (PaymentStatusID, StatusName, IsFinal) VALUES
(1, 'Pending', 0),
(2, 'Completed', 1),
(3, 'Failed', 0),
(4, 'Refunded', 1)


-- Müşteriler
INSERT INTO Customers (Name_, Email, Phone, Balance, IsActive, IsDeleted) VALUES
('Ayşe Kaya', 'ayse@gmail.com', '05301112233', 0, 1, 0),
('Mehmet Demir', 'mehmet@gmail.com', '05422223344', 0, 1, 0)

-- Ürünler
INSERT INTO Products (Name_, Category, CostPrice, SalePrice, IsActive, IsDeleted) VALUES
('Laptop', 'Elektronik', 15000, 18000, 1, 0),
('Mouse', 'Elektronik', 150, 250, 1, 0),
('Klavye', 'Elektronik', 300, 500, 1, 0)

-- Depolar
INSERT INTO Warehouses (WarehouseCode, WarehouseName, WarehouseType, Capacity, Address, City) VALUES
('WH01', 'Ana Depo', 'Main', 10000, 'Atatürk Cad. No:1', 'İzmir'),
('WH02', 'Mağaza Depo', 'Store', 500, 'Cumhuriyet Cad. No:5', 'İstanbul')

-- Stok
INSERT INTO Stocks (ProductID, WarehouseID, Quantity) VALUES
(1, 1, 50),   -- Laptop, Ana Depo
(2, 1, 200),  -- Mouse, Ana Depo
(3, 1, 100),  -- Klavye, Ana Depo
(2, 2, 30),   -- Mouse, Mağaza Depo
(3, 2, 20)    -- Klavye, Mağaza Depo



--TRIGGER TEST
-- Ayşe Kaya'nın siparişi
INSERT INTO Orders (CustomerID, Status, TotalAmount) VALUES
(1, 0, 0)  -- Status: 0=Pending, TotalAmount trigger'la güncellenecek

INSERT INTO OrderItems (OrderID, ProductID, WarehouseID, Quantity, UnitPrice) VALUES
(1, 2, 1, 5, 250)   -- 5 adet Mouse, Ana Depo, 250 TL


-- LineTotal doldu mu?
SELECT * FROM OrderItems

-- Stok düştü mü? (200'den 195'e inmeli)
SELECT * FROM Stocks WHERE ProductID = 2 AND WarehouseID = 1


-- Ana Depoda 195 Mouse var, 300 sipariş et → engellenmeli
INSERT INTO OrderItems (OrderID, ProductID, WarehouseID, Quantity, UnitPrice) VALUES
(1, 2, 1, 300, 250)


-- Mouse'un CostPrice'ı 150, 100'e satmaya çalış → engellenmeli
INSERT INTO OrderItems (OrderID, ProductID, WarehouseID, Quantity, UnitPrice) VALUES
(1, 2, 1, 1, 100)


-- Miktar 0 → engellenmeli
INSERT INTO OrderItems (OrderID, ProductID, WarehouseID, Quantity, UnitPrice) VALUES
(1, 2, 1, 0, 250)


-- Ödeme ekle → Balance güncellenecek
INSERT INTO Payments (CustomerID, OrderID, PaymentMethodID, PaymentStatusID, Amount, TransactionNo)
VALUES (1, 1, 1, 2, 500, 'TRX001')

-- Balance değişti mi? (0'dan 500'e çıkmalı)
SELECT CustomerID, Name_, Balance FROM Customers WHERE CustomerID = 1

-- Bakiyesi olan müşteriyi pasife almaya çalış → engellenmeli
UPDATE Customers SET IsActive = 0 WHERE CustomerID = 1



-- Test 1: Bakiyesi olan müşteriyi silmeye çalış → engellenmeli
UPDATE Customers SET IsDeleted = 1 WHERE CustomerID = 1

-- Test 2: Önce bakiyeyi sıfırla, sonra sil → DeletedAt dolmalı
UPDATE Customers SET Balance = 0 WHERE CustomerID = 1
UPDATE Customers SET IsDeleted = 1 WHERE CustomerID = 1

-- DeletedAt doldu mu?
SELECT CustomerID, Name_, IsDeleted, DeletedAt FROM Customers WHERE CustomerID = 1

-- Test 3: Stoklu ürünü pasife almaya çalış → engellenmeli
UPDATE Products SET IsActive = 0 WHERE ProductID = 2





--SP TEST
-- Test
DECLARE @Sepet OrderItemType
INSERT INTO @Sepet VALUES (2, 1, 3, 250)  -- 3 adet Mouse
INSERT INTO @Sepet VALUES (3, 1, 2, 500)  -- 2 adet Klavye

EXEC sp_SiparisOlustur
    @CustomerID = 2,
    @Items      = @Sepet


-- Sipariş oluştu mu?
SELECT * FROM Orders WHERE OrderID = 2

-- Kalemler doğru mu? LineTotal trigger hesapladı mı?
SELECT * FROM OrderItems WHERE OrderID = 2

-- Stok düştü mü?
-- Mouse: 195'ten 192'ye (3 adet düşmeli)
-- Klavye: 100'den 98'e (2 adet düşmeli)
SELECT * FROM Stocks WHERE ProductID IN (2, 3) AND WarehouseID = 1





-- Yeni test siparişi
DECLARE @Sepet OrderItemType
INSERT INTO @Sepet VALUES (2, 1, 1, 250)  -- 1 adet Mouse

EXEC sp_SiparisOlustur
    @CustomerID = 2,
    @Items      = @Sepet

-- Yeni siparişin TotalAmount'ı 250 olmalı
SELECT OrderID, TotalAmount FROM Orders WHERE OrderID = 3



--Ödeme alınca Payments'a kayıt atar, Balance trigger tarafından güncellenir.
-- Normal senaryo
EXEC sp_OdemeAl
    @CustomerID      = 2,
    @OrderID         = 2,
    @PaymentMethodID = 1,
    @Amount          = 1750

-- Balance güncellendi mi?
SELECT CustomerID, Name_, Balance FROM Customers WHERE CustomerID = 2


--View: Stok Durumu Raporu 
SELECT * FROM vw_StokDurumuRaporu
ORDER BY StokDurumu, UrunAdi

--Musteri Ozeti
SELECT * FROM vw_MusteriOzeti
ORDER BY ToplamHarcama DESC

--En Cok Satan Urunler
SELECT * FROM vw_EnCokSatanUrunler
ORDER BY ToplamSatisAdedi DESC
	