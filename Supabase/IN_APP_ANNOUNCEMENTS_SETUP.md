# In-App Announcements Setup

Bu dokuman, uygulama icindeki kapanabilir duyuru sistemini Supabase tarafinda nasil kuracagini adim adim anlatir.

## 1) SQL scripti calistir

Supabase SQL Editor'da su dosyanin icerigini calistir:

- `Supabase/02_in_app_announcements_setup.sql`

Bu script asagilari olusturur:

- `app_announcements` tablosu
- Tip/icerik/konum/goruntu sekli icin validation kurallari
- Performans indexleri
- `updated_at` trigger'i
- RLS policy'leri
- `get_active_announcements()` RPC fonksiyonu
- Ornek veriler

Not:
- Script, announcements nesnelerini `drop + recreate` yaptigi icin mevcut duyuru datasi silinir.

## 2) Duyuru ekleme mantigi

Tabloda kullanilan alanlar:

- `announcement_kind`: `error | info | warning | success`
- `content`: max 500 karakter
- `expires_at`: nullable (null ise suresiz)
- `display_mode`: `one_time | persistent`
- `placement_zone`: `top | bottom`
- `display_rank`: buyuk olan once gosterilir
- `is_active`: aktif/pasif

## 3) Ornek insert

```sql
insert into app_announcements (announcement_kind, content, expires_at, display_mode, placement_zone, display_rank)
values
  ('error', 'LiveScore servisinde gecici bir sorun yasiyoruz.', null, 'persistent', 'top', 100),
  ('info', 'AYARLAR kismina giderek uygulamamiza destek olabilirsiniz.', null, 'one_time', 'bottom', 50),
  ('warning', '2027 sezonu Haziran ayinda yuklenecektir.', '2026-06-11T08:25:19+00:00', 'one_time', 'top', 80);
```

## 4) Tek seferlik mesaj davranisi

Uygulama tarafinda `one_time` duyurular kullanici kapatinca cihaza kaydedilir ve tekrar gosterilmez.

Not:
- Bu davranis kullaniciya/device'a ozeldir.
- Uygulama silinirse veya cache temizlenirse tekrar gorunebilir.

## 5) Surekli mesaj davranisi

`persistent` duyurular, app her foreground oldugunda yeniden cekilir ve tekrar gosterilebilir.

## 6) Kontrol sorgulari

```sql
select * from get_active_announcements();
select * from app_announcements order by display_rank desc, created_at desc;
```
