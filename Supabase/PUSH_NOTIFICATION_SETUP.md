# Push Notification Setup Guide

Bu rehber, Snooker uygulaması için push notification sisteminin nasıl kurulacağını açıklar.

## 📱 iOS Tarafı (Tamamlandı)

iOS tarafında gerekli kodlar zaten eklendi:

1. **PushNotificationManager.swift** - Push notification yönetimi
2. **AppDelegate.swift** - Notification registration ve handling

### Yapılması Gerekenler:

1. **Apple Developer Console'da:**
   - Certificates, Identifiers & Profiles > Keys > Create Key
   - "Apple Push Notifications service (APNs)" seçeneğini işaretle
   - Key'i indir (.p8 dosyası)
   - **Key ID**'yi not al
   - **Team ID**'yi not al (Account > Membership)

2. **Xcode'da:**
   - Target > Signing & Capabilities > + Capability
   - "Push Notifications" ekle
   - "Background Modes" ekle ve "Remote notifications" seç

---

## 🗄️ Supabase Tarafı

### 1. SQL Setup

`01_push_notification_setup.sql` dosyasını Supabase SQL Editor'da çalıştır:

```bash
# Supabase Dashboard > SQL Editor > New Query
# Dosya içeriğini yapıştır ve çalıştır
```

Bu script şunları oluşturur:
- `device_tokens` tablosu - Cihaz token'larını saklar
- `notification_logs` tablosu - Gönderilen bildirimleri loglar
- `main_tournaments` tablosu - Ana turnuvaları tanımlar
- Trigger fonksiyonları - Maç durumu değişikliklerini yakalar

### 2. pg_net Extension

Supabase Dashboard > Database > Extensions > `pg_net` aktifleştir.

### 3. Edge Function Deploy

```bash
# Supabase CLI kurulu değilse:
npm install -g supabase

# Login:
supabase login

# Edge Function deploy:
cd Supabase/functions
supabase functions deploy send-match-notification --project-ref vlvrwvqgzdxfvotjueml
```

### 4. Edge Function Secrets

Supabase Dashboard > Edge Functions > send-match-notification > Secrets:

| Secret Name | Value |
|-------------|-------|
| `APNS_KEY_ID` | Apple'dan aldığın Key ID |
| `APNS_TEAM_ID` | Apple Developer Team ID |
| `APNS_PRIVATE_KEY` | .p8 dosyasının içeriği (base64 encoded) |
| `APNS_BUNDLE_ID` | `com.35coders.snooker` |
| `APNS_ENVIRONMENT` | `sandbox` (test) veya `production` (release) |

**.p8 dosyasını base64'e çevirmek:**

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n'
```

### 5. Service Role Key

SQL Editor'da service role key'i ayarla:

```sql
ALTER DATABASE postgres SET app.settings.service_role_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

Service role key'i Supabase Dashboard > Settings > API > service_role key'den al.

---

## 🔔 Notification Ayarları

| Setting | Açıklama |
|---------|----------|
| `all_results` | Tüm maç sonuçları için bildirim |
| `main_events` | Sadece ana turnuvalar için bildirim |
| `finals_only` | Sadece ana turnuva finalleri için bildirim |
| `none` | Bildirim yok |

### Ana Turnuvalar:
- World Championship
- UK Championship
- Masters
- Tour Championship
- Champion of Champions
- Ve diğerleri (SQL'de tanımlı)

---

## 🧪 Test Etme

### 1. Token Kaydını Test Et:

```sql
SELECT * FROM device_tokens;
```

### 2. Notification Target'larını Test Et:

```sql
SELECT * FROM get_notification_targets('World Championship 2025', 'Final');
```

### 3. Manuel Notification Gönder:

```bash
curl -X POST 'https://vlvrwvqgzdxfvotjueml.supabase.co/functions/v1/send-match-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "match_id": "test-id",
    "tournament_id": "test-tournament",
    "tournament_name": "World Championship 2025",
    "round": "Final",
    "old_status": "Live",
    "new_status": "Completed",
    "home_player": "Ronnie O'\''Sullivan",
    "away_player": "Judd Trump",
    "home_score": 18,
    "away_score": 15
  }'
```

### 4. Notification Log'larını Kontrol Et:

```sql
SELECT * FROM notification_logs ORDER BY created_at DESC LIMIT 10;
```

---

## 📊 Akış Diyagramı

```
┌─────────────────┐
│  Match Status   │
│    Changes      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   DB Trigger    │
│ notify_match_   │
│ status_change() │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Edge Function  │
│ send-match-     │
│ notification    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Get Target     │
│  Tokens (RPC)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Send to APNs   │
│  (HTTP/2)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  iOS Device     │
│  📱 🔔          │
└─────────────────┘
```

---

## ⚠️ Önemli Notlar

1. **Sandbox vs Production:**
   - Development build'lerde `sandbox` APNs server kullanılır
   - App Store/TestFlight build'lerde `production` APNs server kullanılır

2. **Token Temizliği:**
   - Invalid token'lar APNs'ten 410 döner
   - Periyodik olarak eski/invalid token'ları temizle

3. **Rate Limiting:**
   - APNs'in rate limit'i yok ama makul seviyede tut
   - Edge Function'da batch işlem yapılıyor (100'er token)

4. **Error Handling:**
   - Notification gönderilmezse log'a kaydediliyor
   - Kritik hatalar için monitoring ekle
