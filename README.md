# 🛒 E-Ticaret Sipariş Yönetimi Sistemi

SQL Server ile geliştirilmiş, katmanlı iş kuralları ve veri bütünlüğü odaklı tam kapsamlı bir e-ticaret sipariş yönetimi sistemi.

\---

## 📋 Proje Hakkında

Bu proje; müşteri yönetimi, ürün ve stok takibi, sipariş işleme ve ödeme akışını kapsayan bir veritabanı sistemidir. İş kuralları trigger'lar ve stored procedure'ler aracılığıyla veritabanı katmanında uygulanmıştır.

\---

## 🗄️ Tablolar (9 Tablo)

|Tablo|Açıklama|
|-|-|
|`Customers`|Müşteri bilgileri, bakiye, aktif/silindi durumu|
|`Products`|Ürün bilgileri, maliyet fiyatı, aktif durumu|
|`Warehouses`|Depo bilgileri ve şehir|
|`Stocks`|Ürün-depo bazlı stok miktarları|
|`Orders`|Sipariş başlığı, müşteri ve tarih bilgisi|
|`OrderItems`|Sipariş kalemleri, miktar, fiyat, satır toplamı|
|`Payments`|Ödeme kayıtları ve tutar|
|`PaymentMethods`|Ödeme yöntemi tanımları|
|`PaymentStatuses`|Ödeme durumu tanımları|

\---

## ⚡ Trigger'lar (10 Trigger)

|Trigger|Tablo|Açıklama|
|-|-|-|
|`trg\_LineTotal`|OrderItems|INSERT'te LineTotal = Quantity × UnitPrice hesaplar|
|`trg\_MiktarKontrol`|OrderItems|Sıfır veya negatif miktarı engeller|
|`trg\_StokKontrol`|OrderItems|Yetersiz stokta siparişi engeller (bulk-safe)|
|`trg\_MaliyetAltiSatis`|OrderItems|UnitPrice < CostPrice ise engeller|
|`trg\_StokGuncelle`|OrderItems|INSERT/UPDATE'te stok miktarını düşürür|
|`trg\_TotalAmountGuncelle`|OrderItems|Sipariş toplam tutarını günceller|
|`trg\_BakiyeGuncelle`|Payments|Tamamlanan ödemelerde müşteri bakiyesini günceller|
|`trg\_PasifMusteriKontrol`|Customers|Bakiyesi olan müşteriyi pasife almayı engeller|
|`trg\_UrunPasifKontrol`|Products|Stoğu olan ürünü pasife almayı engeller|
|`trg\_SoftDelete`|Customers|Soft delete'te DeletedAt'i doldurur, bakiye kontrolü yapar|

\---

## 🔧 Stored Procedure'ler (2 SP)

### `sp\_SiparisOlustur`

Sipariş başlığı ve detaylarını tek transaction içinde oluşturur.

* User Defined Table Type (`OrderItemType`) ile toplu kalem girişi
* Boş sipariş ve geçersiz status kontrolü
* `TRY...CATCH` ile hata yönetimi

### `sp\_OdemeAl`

Ödeme kaydı oluşturur, bakiye trigger tarafından güncellenir.

* Tutar, müşteri, sipariş ve ödeme yöntemi validasyonu
* `TRY...CATCH` ile hata yönetimi

\---

## 📊 View'lar (3 View)

|View|Açıklama|
|-|-|
|`vw\_StokDurumuRaporu`|Ürün-depo bazlı stok durumu (Normal / Düşük / Kritik)|
|`vw\_MusteriOzeti`|Müşteri bazlı sipariş sayısı, harcama ve bakiye özeti|
|`vw\_EnCokSatanUrunler`|Kategori bazlı en çok satan ürünler ve satış tutarları|

\---

## 🛠️ Kullanılan Teknolojiler

* **Microsoft SQL Server**
* T-SQL (Trigger, Stored Procedure, View, CTE)
* User Defined Table Type (UDTT)
* Soft Delete pattern (`IsDeleted` / `DeletedAt`)
* Bulk-safe trigger tasarımı (table variable + `GROUP BY`)

\---

## 📁 Dosya Yapısı

```
├── E-ticaret\_Siparis\_Yonetimi.sql      # Tablo şemaları ve view'lar
├── TRIGGER.sql                          # Tüm trigger ve stored procedure'ler
└── E-ticaret\_Siparis\_Yonetimi\_Testler.sql  # Test scriptleri



\## 📊 Veritabanı Diyagramı



!\[Veritabanı Diyagramı](docs/diagram.png)
```

