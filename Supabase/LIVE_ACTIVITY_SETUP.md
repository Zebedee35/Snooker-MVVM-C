# Live Activity (ActivityKit) Setup Guide

Snooker uygulaması için canlı maç **Live Activity** (Lock Screen + Dynamic Island) kurulumu.
Mevcut push notification altyapısının (`.p8` key, JWT, `pg_net` trigger) üzerine inşa edilir.

> **Özet:** Live Activity = normal push ile *aynı APNs key*, **farklı token tipi**, **ayrı bir
> Widget Extension target**, ve **`liveactivity` push-type** gönderen ikinci bir Edge Function.

---

## 0. Mimari (Architecture)

```
┌────────────────────┐   user taps "Follow"   ┌───────────────────────┐
│  LiveScore (UIKit) │ ─────────────────────► │  LiveActivityManager   │
└────────────────────┘                        │  Activity.request()    │
                                              └───────────┬───────────┘
                                                          │ pushTokenUpdates
                                                          ▼
                                              ┌───────────────────────┐
                                              │ live_activities table  │  (match_id, token)
                                              └───────────┬───────────┘
        matches row UPDATE (score/status)                 │
        ┌───────────────────────┐                         │
        │  DB trigger            │ net.http_post           │
        │ notify_live_activity_  │ ──────────────────────► │
        │ update()               │                         ▼
        └───────────────────────┘            ┌───────────────────────┐
                                              │ Edge Fn:               │
                                              │ update-live-activity   │  apns-push-type:
                                              │  → APNs /3/device/{tok}│  liveactivity
                                              └───────────┬───────────┘
                                                          ▼
                                              📱 Lock Screen + Dynamic Island
```

**Token tipleri (önemli):**
| Token | Nereden | Ne işe yarar |
|-------|---------|--------------|
| Device token (mevcut) | `didRegisterForRemoteNotifications` | Normal bildirimler |
| **Per-activity token** | `activity.pushTokenUpdates` | Belirli bir Live Activity'yi güncelle/bitir |
| **Push-to-start token** (iOS 17.2+, opsiyonel) | `Activity.pushToStartTokenUpdates` | App kapalıyken sunucudan Live Activity *başlat* |

---

## 1. iOS — Xcode Target Setup (manuel)

ActivityKit UI'ı ayrı bir **Widget Extension** target'ında çalışmak zorunda.

1. **File > New > Target… > Widget Extension**
   - Name: `SnookerWidget`
   - ✅ **Include Live Activity** kutusunu işaretle
   - "Include Configuration App Intent" gerekmez.
2. Xcode'un oluşturduğu boilerplate `SnookerWidget*.swift` dosyalarını sil; bu repodaki
   `SnookerWidget/` klasöründeki dosyaları target'a ekle:
   - `SnookerWidgetBundle.swift` → **sadece** SnookerWidgetExtension target
   - `SnookerWidgetLiveActivity.swift` → **sadece** SnookerWidgetExtension target
   - `MatchLiveActivityAttributes.swift` → ⚠️ **HER İKİ** target (Snooker **ve** SnookerWidgetExtension)
     - Dosyayı seç → File Inspector → *Target Membership* → ikisini de işaretle.
3. **App target (Snooker) > Info.plist** içine ekle:
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   ```
   (Frequent push güncellemesi istersen ayrıca `NSSupportsLiveActivitiesFrequentUpdates = true`.)
4. **Signing & Capabilities:** Push Notifications capability zaten var (notification kurulumundan).
   Live Activity ek bir capability gerektirmez — aynı APNs key kullanılır.
5. `LiveActivityManager.swift` zaten `Snooker/Managers/` içinde — app target'ta olduğundan emin ol.

### Lifecycle bağlama (App tarafı)

`AppDelegate.didFinishLaunchingWithOptions` içine ekle:
```swift
if #available(iOS 16.2, *) {
    LiveActivityManager.shared.bootstrap()   // relaunch sonrası re-attach + PTS token
}
```

"Follow" aksiyonu (örn. LiveScore hücresinde bir butondan):
```swift
if #available(iOS 16.2, *) {
    LiveActivityManager.shared.start(for: presentation, framesToWin: 18) // best-of'a göre
}
```

> `tournamentName` şu an `presentation.round` ile dolduruluyor — gerçek turnuva adın
> `LiveScoreCellPresentation`'da yoksa, oraya bir `tournamentName` alanı ekleyip geçir.

---

## 2. Backend — SQL

`03_live_activity_setup.sql` dosyasını **SQL Editor**'da çalıştır. Oluşturur:
- `live_activities` tablosu (match_id, push_token, status)
- `device_tokens.pts_token` kolonu (push-to-start, opsiyonel)
- `notify_live_activity_update()` trigger'ı → skor/durum değişince Edge Function'ı çağırır
- `cleanup_ended_live_activities()` → maç bitince token'ları `ended` yapar

**Service role key'i ayarla** (henüz yapmadıysan):
```sql
ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR_SERVICE_ROLE_KEY';
```

`pg_net` zaten aktif (push notification kurulumundan). Değilse:
```sql
CREATE EXTENSION IF NOT EXISTS pg_net;
```

---

## 3. Backend — Edge Function

```bash
cd Supabase/functions
supabase functions deploy update-live-activity --project-ref vlvrwvqgzdxfvotjueml
```

**Secrets** — `send-match-notification` ile **aynı** değerler (yeniden girmen gerekebilir):

| Secret | Değer |
|--------|-------|
| `APNS_KEY_ID` | Apple Key ID |
| `APNS_TEAM_ID` | Team ID |
| `APNS_PRIVATE_KEY` | `.p8` base64 (`base64 -i AuthKey_XXXX.p8 \| tr -d '\n'`) |
| `APNS_BUNDLE_ID` | `coders35.Snooker` |
| `APNS_ENVIRONMENT` | `sandbox` (Xcode debug) / `production` (TestFlight, App Store) |

> ⚠️ **Topic farkı:** Edge Function `apns-topic`'i otomatik olarak
> `coders35.Snooker.push-type.liveactivity` yapar — sen sadece bundle id'yi ver.

---

## 4. Realtime vs Push — Strateji

| Durum | Mekanizma | Neden |
|-------|-----------|-------|
| App **foreground** (LiveScore ekranı açık) | Mevcut polling / (opsiyonel) Supabase Realtime | UI anında güncellensin; Live Activity için `updateLocally(...)` ile anlık his |
| App **background / kapalı** | **APNs Live Activity push** (bu kurulum) | Tek güvenilir yol — sistem yönetir, pil dostu |
| Live Activity'yi **başlatma** | App-initiated (`start(for:)`) **önerilir** | En basit & güvenilir |
| Live Activity'yi **uzaktan başlatma** | Push-to-start (iOS 17.2+, opsiyonel) | App hiç açılmadan başlatmak istiyorsan |

**Kaynak doğruluğu (source of truth) sunucudur.** Live Activity güncellemeleri her zaman
APNs üzerinden gelsin; foreground'da `updateLocally` sadece *kozmetik hız* için.

---

## 5. Pil / Performans En İyi Pratikleri

1. **Trigger `matches` tablosunda**, frame tablosunda değil → push sıklığı = "frame kazanıldı /
   durum değişti" seviyesinde kalır. (Apple Live Activity update budget'ı var; spam throttle yer.)
2. **Priority ayrımı:** rutin skor `apns-priority: 5`, maç bitişi `10` (Edge Function bunu yapıyor).
3. **`stale-date`** her push'ta 30 dk → push akışı kesilirse sistem activity'yi soluklaştırır.
4. **`dismissal-date`** end push'ta 1 saat → final skor bir süre Lock Screen'de kalır, sonra kaybolur.
5. **content-state'i küçük tut** (Int/String). `Date` koyma — encoding uyumsuzluğu yaratır.
6. Maç bitince **token'ları `ended` yap** (trigger + Edge Function 410 temizliği bunu hallediyor).
7. Çok sık güncelliyorsan `NSSupportsLiveActivitiesFrequentUpdates` ekle ama yine de debounce et.

---

## 6. content-state Anahtar Eşleşmesi (KRİTİK)

ActivityKit, remote push'taki `content-state` JSON anahtarlarını Swift property adlarıyla
**birebir** eşler. `MatchLiveActivityAttributes.ContentState` ↔ Edge Function:

| Swift property | JSON key (Edge Fn gönderir) |
|----------------|------------------------------|
| `homeScore`    | `homeScore` |
| `awayScore`    | `awayScore` |
| `status`       | `status` |
| `round`        | `round` |
| `currentBreak` | `currentBreak` |
| `atTable`      | `atTable` |

Swift'te property eklersen/çıkarırsan Edge Function'daki `contentState` objesini de güncelle.

---

## 7. Test

```bash
# 1) Cihazda bir maçı "Follow" yap, sonra token oluştu mu bak:
#    SELECT * FROM live_activities WHERE status = 'active';

# 2) Manuel update push (match_id'yi live_activities'ten al):
curl -X POST 'https://vlvrwvqgzdxfvotjueml.supabase.co/functions/v1/update-live-activity' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "match_id": "MATCH_UUID",
    "event": "update",
    "status": "Live",
    "round": "Final",
    "tournament_name": "World Championship 2025",
    "home_name": "Ronnie O'\''Sullivan",
    "away_name": "Judd Trump",
    "home_score": 12,
    "away_score": 9
  }'

# 3) DB üzerinden gerçek trigger testi:
#    UPDATE matches SET home_player_score = home_player_score + 1 WHERE id = 'MATCH_UUID';
```

**Sık karşılaşılan hatalar:**
- `BadDeviceToken` → APNS_ENVIRONMENT yanlış (debug build = `sandbox`).
- Activity güncellenmiyor ama push 200 dönüyor → content-state key adları Swift ile uyuşmuyor.
- `TopicDisallowed` → `apns-topic` `.push-type.liveactivity` ile bitmiyor (Edge Function bunu otomatik ekler; bundle id'yi kontrol et).
- Token hiç gelmiyor → Info.plist'te `NSSupportsLiveActivities` yok, ya da cihaz Ayarlar'da Live Activities kapalı.
