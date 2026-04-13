

--Ýlk trigger: trg_LineTotal
--Ne yapacak: OrderItems'a INSERT gelince LineTotal = Quantity * UnitPrice hesaplayýp dolduracak.
CREATE TRIGGER trg_LineTotal
ON OrderItems
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON
	UPDATE OI	
	SET LineTotal =I.Quantity*I.UnitPrice
	FROM OrderItems OI
	INNER JOIN inserted I
		ON OI.OrderItemId=I.OrderItemId;
END;



--Ne yapacak: OrderItems'a INSERT gelince Quantity sýfýr veya negatifse sipariþi engeller.
CREATE TRIGGER trg_MiktarKontrol
ON OrderItems
AFTER INSERT 
AS
BEGIN
	SET NOCOUNT ON

	IF EXISTS (
	SELECT 1
	FROM inserted I
	WHERE ISNULL(I.Quantity, 0) <= 0
)
BEGIN
        ROLLBACK TRANSACTION
        RAISERROR(N'Ýþlem iptal edildi: Miktar alaný boþ býrakýlamaz ve sýfýrdan büyük olmalýdýr.', 16, 1)
        RETURN
END
END


--Ne yapacak: OrderItems'a INSERT gelince Stocks tablosuna bakacak — yeterli stok yoksa sipariþi engelleyecek.
CREATE TRIGGER trg_StokKontrol
ON OrderItems
AFTER INSERT 
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @SiparisOzet TABLE (
    ProductID    INT,
    WarehouseID  INT,
    ToplamMiktar DECIMAL(18,2)
	);	

	INSERT INTO @SiparisOzet
		SELECT 
			ProductID, 
			WarehouseID, 
			SUM(Quantity)
		FROM inserted
	
	GROUP BY ProductID, WarehouseID
	IF EXISTS(
	SELECT 1
	FROM @SiparisOzet SO
	LEFT JOIN Stocks S
		ON SO.ProductID=S.ProductID
		AND SO.WarehouseID = S.WarehouseID
	WHERE SO.ToplamMiktar > ISNULL(S.Quantity, 0)
)
BEGIN
	ROLLBACK TRANSACTION 
	RAISERROR(N'Ýþlem iptal edildi: Yetersiz stok.', 16, 1)
	RETURN
END
END


--Ne yapacak: OrderItems'a INSERT gelince UnitPrice, ürünün CostPrice'ýndan düþükse engeller
CREATE TRIGGER trg_MaliyetAltiSatis
ON OrderItems
AFTER INSERT 
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
	SELECT 1
	FROM inserted I
	INNER JOIN Products P
		ON I.ProductId=P.ProductId
	WHERE I.UnitPrice<P.CostPrice
	)
	BEGIN
		ROLLBACK TRANSACTION;
		RAISERROR(N'Birim fiyat Maliyet fiyatýndan düþük olamaz', 16, 1)
		RETURN;
	END
END


--Ne yapacak: OrderItems'a INSERT gelince Stocks tablosundaki Quantity'yi düþürecek.
CREATE TRIGGER trg_StokGuncelle
ON OrderItems 
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON 

	DECLARE @SiparisOzet TABLE(
		ProductID INT,
		WarehouseID INT,
		ToplamMiktar DECIMAL(18,2)
	)
	
	INSERT INTO @SiparisOzet
	SELECT
		ProductID,
		WarehouseID,
		SUM(Quantity)
	FROM inserted I
	WHERE NOT EXISTS (
		SELECT 1 FROM deleted D
		WHERE D.OrderItemID = I.OrderItemID
	)
	GROUP BY 
		ProductID,
		WarehouseID

	UNION ALL

	SELECT
		I.ProductId,
		I.WarehouseId,
		SUM(I.Quantity - D.Quantity)
	FROM inserted I
	INNER JOIN deleted D 
		ON I.OrderItemId=D.OrderItemId
	GROUP BY I.ProductId, I.WarehouseId


	UPDATE S
	SET S.Quantity = S.Quantity - SO.ToplamMiktar
	FROM Stocks S
	INNER JOIN @SiparisOzet SO
		ON S.ProductID=SO.ProductID
		AND S.WarehouseID=SO.WarehouseID
		
END



--Ne yapacak: Payments'a INSERT gelince Customers tablosundaki Balance'ý günceller.
CREATE TRIGGER trg_BakiyeGuncelle
ON Payments
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON
	IF EXISTS(
		SELECT 1
		FROM inserted I
		WHERE Amount <= 0
	)
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR (N'Ödeme tutarý sýfýr veya negatif olamaz.', 16, 1);
		RETURN;
	END

	UPDATE C
	SET C.Balance = C.Balance + X.TOTALAMOUNT
	FROM Customers C
	INNER JOIN 
	(
		SELECT
			CustomerID,
			SUM(Amount) AS TOTALAMOUNT
		FROM inserted 
		WHERE PaymentStatusID = 2	
		GROUP BY CustomerID
	)X
		ON C.CustomerId=X.CustomerID;
END


--Ne yapacak: Customers tablosunda IsActive = 0 yapýlmaya çalýþýlýnca, müþterinin Balance'ý sýfýr deðilse engeller.
CREATE TRIGGER trg_PasifMusteriKontrol
ON Customers
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON; 

	IF EXISTS(
		SELECT 1 
		FROM inserted I
		WHERE I.Balance <> 0 
			AND I.IsActive =0
	)
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR (N'Bakiyesi olan müþteri pasife alýnamaz',16,1)
		RETURN
	END
END


--Ne yapacak: Products tablosunda IsActive = 0 yapýlmaya çalýþýlýnca, ürünün herhangi bir depoda stoðu varsa engeller.
CREATE TRIGGER trg_UrunPasifKontrol
ON Products
AFTER UPDATE 
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(
		SELECT 1
		FROM inserted I
		INNER JOIN Stocks S
			ON S.ProductID= I.ProductId
		WHERE I.IsActive=0
			AND S.Quantity <> 0
	)
	BEGIN 
		ROLLBACK TRANSACTION
		RAISERROR (N'Stoðu olan ürün pasife alýnamaz',16,1)
		RETURN
	END
END


--Ne yapacak: Customers tablosunda IsDeleted = 1 yapýlýnca DeletedAt kolonunu otomatik GETDATE() ile doldurur.
CREATE TRIGGER trg_SoftDelete
ON Customers
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(
		SELECT 1
		FROM inserted I
		INNER JOIN deleted D
			ON I.CustomerId = D.CustomerId
		WHERE I.IsDeleted = 1
			AND D.IsDeleted = 0
			AND ISNULL(I.Balance, 0) <> 0
	)
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR(N'Bakiyesi sýfýr olmayan müþteri silinemez.',16,1)
		RETURN;
	END

	UPDATE C
	SET DeletedAt = GETDATE()
	FROM Customers C
	INNER JOIN inserted I
		ON I.CustomerId=C.CustomerId
	INNER JOIN deleted D
		ON I.CustomerId = D.CustomerId
	WHERE I.IsDeleted = 1
		AND D.IsDeleted = 0
		AND C.DeletedAt IS NULL;
END



--Ne yapacak: OrderItems'a INSERT gelince ilgili Orders satýrýndaki TotalAmount'ý günceller.
CREATE TRIGGER trg_TotalAmountGuncelle
ON OrderItems
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE O
SET O.TotalAmount = (
    SELECT SUM(LineTotal)
    FROM OrderItems
    WHERE OrderID = O.OrderID
)
FROM Orders O
WHERE O.OrderID IN (SELECT DISTINCT OrderID FROM inserted)
END
GO



/*
STORED PROCEDURE


AÇIKLAMA:
sp_SiparisOlustur, sipariþ baþlýðý ve sipariþ detaylarýný tek transaction içinde oluþturarak veri bütünlüðünü korur 
ve web tarafýnýn tek çaðrýyla sipariþ oluþturmasýný saðlar.*/

CREATE TYPE OrderItemType AS TABLE
(
    ProductID INT,
    WarehouseID INT,
    Quantity INT,
    UnitPrice DECIMAL(18,2)
);
GO


CREATE PROCEDURE sp_SiparisOlustur
	@CustomerID INT,
	@Items      OrderItemType READONLY,
	@OrderDate  DATETIME = NULL,
	@Status     TINYINT  = 0

AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRY 
		BEGIN TRANSACTION 

		DECLARE @NewOrderID INT

		IF @OrderDate IS NULL
			SET @OrderDate = GETDATE()

		--Status Kontrolü
		IF @Status NOT IN (0,1,2,3)
		BEGIN
            ROLLBACK TRANSACTION
            RAISERROR(N'Geçersiz sipariþ durumu.', 16, 1)
            RETURN
        END

		--Boþ Sipariþ Kontrolü
		IF NOT EXISTS(SELECT 1 FROM @Items)
		BEGIN
            ROLLBACK TRANSACTION
            RAISERROR(N'Sipariþ satýrý olmadan sipariþ oluþturulamaz.', 16, 1)
            RETURN
        END

		--Orders tablosuna kayýt
		INSERT INTO Orders (CustomerId, OrderDate, Status)
		VALUES (@CustomerID, @OrderDate, @Status)

		SET @NewOrderID = SCOPE_IDENTITY()

		-- OrderItems tablosuna kayýt (LineTotal trigger hesaplayacak)
		INSERT INTO OrderItems(OrderId, ProductId, WarehouseId, Quantity, UnitPrice)
		SELECT
			@NewOrderID,
			ProductID,
			WarehouseID,
            Quantity,
            UnitPrice
		FROM @Items

		COMMIT TRANSACTION

		SELECT @NewOrderID AS OrderID

	END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END



--Ne yapacak: Ödeme alýnca Payments'a kayýt atar, Balance trigger tarafýndan güncellenir.
CREATE PROCEDURE sp_OdemeAl
	@CustomerID INT,
	@OrderID INT = NULL,
	@PaymentMethodID INT,
	@Amount DECIMAL(18,2),
	@TransactionNo VARCHAR(100) = NULL

AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRY
		BEGIN TRANSACTION

		DECLARE @PaymentDate DATETIME=GETDATE()
		DECLARE @PaymentStatusID TINYINT = 2 -- 2 = Completed


		-- 1. Tutar kontrolü
		IF @Amount <= 0 
		BEGIN 
			ROLLBACK TRANSACTION 
			RAISERROR (N'Ödeme tutarý 0dan büyük olmalýdýr.', 16, 1)
			RETURN
		END

		-- 2. Müþteri kontrolü
		IF NOT EXISTS (
			SELECT 1 FROM Customers
			WHERE CustomerId = @CustomerID
		)
		BEGIN 
			ROLLBACK TRANSACTION 
			RAISERROR (N'Geçersiz CustomerID.', 16,1)
			RETURN
		END

		-- 3. Sipariþ kontrolü (varsa)
		IF @OrderID IS NOT NULL
		BEGIN
			IF NOT EXISTS (
				SELECT 1 FROM Orders
				WHERE OrderId = @OrderID
				AND CustomerId = @CustomerID
			)
			BEGIN
                ROLLBACK TRANSACTION
                RAISERROR(N'Sipariþ bulunamadý veya müþteriye ait deðil.', 16, 1)
                RETURN
            END
        END

		-- 4. Ödeme yöntemi kontrolü
		IF NOT EXISTS (
            SELECT 1 FROM PaymentMethods
            WHERE PaymentMethodID = @PaymentMethodID
        )
        BEGIN
            ROLLBACK TRANSACTION
            RAISERROR(N'Geçersiz PaymentMethodID.', 16, 1)
            RETURN
        END

		-- 5. Ödeme kaydý (Balance trg_BakiyeGuncelle ile güncellenecek)
		INSERT INTO Payments (
            CustomerID,
            OrderID,
            PaymentStatusID,
            PaymentMethodID,
            Amount,
            TransactionNo,
            PaymentDate
        )
        VALUES (
            @CustomerID,
            @OrderID,
            @PaymentStatusID,
            @PaymentMethodID,
            @Amount,
            @TransactionNo,
            @PaymentDate
        )

        COMMIT TRANSACTION

        SELECT SCOPE_IDENTITY() AS NewPaymentID

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END



--Ýlk View: Stok Durumu Raporu 
-- Ne gösterecek:
--Ürün adý, kategori
--Depo adý, þehir
--Mevcut stok miktarý
--Stok durumu

CREATE VIEW vw_StokDurumuRaporu
AS
SELECT
	P.Name_ AS UrunAdi,
	P.Category AS Kategori,
	W.WarehouseName AS DepoAdi,
	W.City AS Sehir,
	S.Quantity AS MevcutStokMiktari,
	CASE
		WHEN S.Quantity = 0 THEN N'Kritik'
		WHEN S.Quantity < 10 THEN N'Düþük'
		ELSE  N'Normal'
	END AS StokDurumu
FROM Stocks S
INNER JOIN Products P
	ON S.ProductID = P.ProductId
INNER JOIN Warehouses W
	ON S.WarehouseID= W.WarehouseId
WHERE P.IsActive  = 1
	AND   P.IsDeleted = 0
GO


--Musteri Ozeti
--Ne gösterecek: Müþteri adý, email Toplam sipariþ sayýsý Toplam harcama Mevcut bakiye Müþteri durumu: Aktif, Pasif, Silindi

CREATE VIEW vw_MusteriOzeti
AS
SELECT
	C.CustomerId,
	C.Name_ AS MusteriAdi,
	C.Email,
	COUNT(O.OrderId) AS ToplamSiparisSayisi,
	ISNULL(SUM(O.TotalAmount),0) AS ToplamHarcama,
	C.Balance AS MevcutBakiye,
	CASE
		WHEN C.IsDeleted = 1 THEN N'Silindi'
        WHEN C.IsActive = 0 THEN N'Pasif'
		ELSE N'Aktif'
	END AS MusteriDurumu
FROM Customers C
LEFT JOIN Orders O 
	ON C.CustomerId=O.CustomerId
GROUP BY
    C.CustomerID,
    C.Name_,
    C.Email,
    C.Balance,
    C.IsDeleted,
    C.IsActive;
GO


--En Cok Satan Urunler
--Ne gösterecek:
--Ürün adý, kategori
--Toplam satýþ adedi
--Toplam satýþ tutarý
--Kaç farklý sipariþte yer aldý

CREATE VIEW vw_EnCokSatanUrunler
AS
SELECT
	P.Name_ AS UrunAdi,
	P.Category AS Kategori,
	SUM(OI.Quantity) AS ToplamSatisAdedi,
	SUM(OI.LineTotal) AS ToplamSatisTutari,
	COUNT(DISTINCT OI.OrderID) AS SiparisSayisi
FROM OrderItems OI
INNER JOIN Products P
	ON P.ProductId=OI.ProductId
GROUP BY
	P.Name_, P.Category


