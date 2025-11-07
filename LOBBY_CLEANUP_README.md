# Firebase Lobi Temizleme Mekanizması

Bu dokümantasyon, Firebase Realtime Database kullanan çok oyunculu lobi sistemindeki "hayalet lobi" sorununu çözmek için uygulanan üç aşamalı temizleme mekanizmasını açıklar.

## Problem

Mevcut sistemde lobiler `/activeLobbies` listesinde oluşturuluyordu. Bu lobiler, sadece ev sahibi oyunu manuel olarak "başlattığında" listeden kaldırılıyordu. Eğer ev sahibi veya oyuncular oyunu başlatmadan uygulamayı kapatırsa, bağlantıları koparsa veya "ayrıl" butonuna basarsa lobi veritabanında kalıcı olarak kirli veri (zombie lobby) oluşturuyordu.

## Çözüm: Üç Aşamalı Temizleme Mekanizması

### 1. Anlık Bağlantı Kopmalarını Yönet (onDisconnect)

**Dosya**: `lib/features/game/data/game_repository.dart`

**Fonksiyonlar**:
- `createGame()`: Ev sahibi lobi oluşturduğunda onDisconnect hook'ları kurar
- `joinGame()`: Oyuncu lobiye katıldığında onDisconnect hook'ları kurar
- `_setupOnDisconnectHooks()`: onDisconnect hook'larını kurar
- `_cancelOnDisconnectHooks()`: onDisconnect hook'larını iptal eder

**Mantık**:
Bir kullanıcı (ev sahibi veya oyuncu) bir lobiye başarıyla katıldığında, o kullanıcı için iki adet onDisconnect kancası kurulur:

1. **Oyuncu Silme**: Bağlantı koptuğunda, kullanıcının kaydını `/games/{gameId}/players/{userId}` yolundan siler
2. **PlayerCount Azaltma**: Bağlantı koptuğunda, `/activeLobbies/{gameId}/playerCount` değerini `ServerValue.increment(-1)` kullanarak bir azaltır

### 2. Manuel Lobiden Ayrılma İşlemini Yönet (leaveGame)

**Dosya**: `lib/features/game/data/game_repository.dart`

**Fonksiyon**: `leaveGame(gameId, userId)`

**Mantık**:
Bu fonksiyon şunları yapar:

1. Kullanıcının kaydını `/games/{gameId}/players/{userId}` yolundan manuel olarak siler
2. `/activeLobbies/{gameId}/playerCount` değerini manuel olarak `ServerValue.increment(-1)` kullanarak bir azaltır
3. **Kritik Adım**: 1. adımda ayarlanan onDisconnect kancalarını, sunucuya fazladan bir azaltma komutu göndermemeleri için `onDisconnect().cancel()` kullanarak iptal eder

**Kullanım**:
`LobbyWaitingScreen` içerisindeki "Ayrıl" butonu (geri butonu), `context.go` yapmadan hemen önce bu `leaveGame` fonksiyonunu çağırır.

**Dosya**: `lib/features/lobby/presentation/lobby_waiting_screen.dart`

### 3. Sunucu Taraflı (Cloud Functions) Kesin Temizlik

**Klasör**: `functions/`

**Fonksiyonlar**:

#### 3.1. cleanupEmptyLobbies (onWrite Trigger)

**Dosya**: `functions/src/index.ts`

**Tetikleyici**: `/activeLobbies/{gameId}/playerCount` yolundaki yazma işlemleri

**Mantık**:
- `playerCount` değeri 0 (sıfır) veya daha az bir değere güncellenirse tetiklenir
- Hem `/activeLobbies/{gameId}` hem de ilgili `/games/{gameId}` referanslarını veritabanından tamamen siler
- **Önemli**: Sadece `status: 'waiting'` durumundaki oyunları temizler (oyun başlamışsa silmez)

#### 3.2. scheduledLobbyCleanup (Scheduled Cron)

**Dosya**: `functions/src/index.ts`

**Tetikleyici**: Her saat başı (cron: `0 * * * *`)

**Mantık**:
- `/activeLobbies` listesini tarar
- Şu durumlardaki lobileri temizler:
  - `playerCount: 0` olan lobiler
  - `createdAt` zaman damgası 2 saatten eski olan lobiler
- `/games` kayıtlarıyla birlikte siler
- **Önemli**: Sadece `status: 'waiting'` durumundaki oyunları temizler

## Kurulum ve Deploy

### Cloud Functions Kurulumu

```bash
cd functions
npm install
npm run build
```

### Cloud Functions Deploy

```bash
npm run deploy
```

Veya Firebase CLI ile:

```bash
firebase deploy --only functions
```

## Veri Yapısı

### activeLobbies/{gameId}

```json
{
  "lobbyName": "Lobi Adı",
  "hostUsername": "Ev Sahibi",
  "playerCount": 2,
  "maxPlayers": 6,
  "hasPassword": false,
  "createdAt": 1234567890  // ServerValue.timestamp
}
```

### games/{gameId}

```json
{
  "hostId": "userId",
  "status": "waiting",  // "waiting" | "playing" | "finished"
  "players": {
    "userId1": { ... },
    "userId2": { ... }
  },
  ...
}
```

## Akış Diagramı

```
1. Kullanıcı Lobiye Katılır
   ├─> createGame() veya joinGame() çağrılır
   └─> onDisconnect hook'ları kurulur

2. Bağlantı Kopması Durumu
   ├─> onDisconnect hook'ları tetiklenir
   ├─> Oyuncu /games/{gameId}/players/{userId} yolundan silinir
   └─> playerCount ServerValue.increment(-1) ile azaltılır

3. Manuel Ayrılma Durumu
   ├─> LobbyWaitingScreen'de "Ayrıl" butonuna basılır
   ├─> leaveGame() çağrılır
   ├─> onDisconnect hook'ları iptal edilir
   ├─> Oyuncu manuel olarak silinir
   └─> playerCount manuel olarak azaltılır

4. playerCount = 0 Durumu
   ├─> cleanupEmptyLobbies trigger'ı tetiklenir
   └─> /activeLobbies/{gameId} ve /games/{gameId} silinir

5. Zamanlanmış Temizlik
   ├─> Her saat başı scheduledLobbyCleanup çalışır
   ├─> playerCount: 0 veya 2 saatten eski lobiler bulunur
   └─> Bu lobiler temizlenir
```

## Önemli Notlar

1. **onDisconnect Hook'ları**: Her kullanıcı için ayrı hook'lar kurulur ve manuel ayrılma durumunda iptal edilir
2. **Race Condition Önleme**: leaveGame() fonksiyonu, onDisconnect hook'larını iptal ederek çift azaltma problemini önler
3. **Oyun Durumu Kontrolü**: Cloud Functions sadece `status: 'waiting'` durumundaki oyunları temizler
4. **createdAt Zaman Damgası**: createGame() fonksiyonunda otomatik olarak eklenir
5. **Oyun Başladığında**: setGameStatus() fonksiyonu, oyun başladığında tüm onDisconnect hook'larını iptal eder

## Test Senaryoları

1. ✅ Kullanıcı uygulamayı kapatır → onDisconnect tetiklenir
2. ✅ Kullanıcı "Ayrıl" butonuna basar → leaveGame() çağrılır, hook'lar iptal edilir
3. ✅ Tüm oyuncular ayrılır → playerCount = 0 → Cloud Function temizler
4. ✅ Lobi 2 saatten eski → Scheduled function temizler
5. ✅ Oyun başlar → onDisconnect hook'ları iptal edilir, activeLobbies'den silinir

## Sorun Giderme

### Lobi temizlenmiyor

1. Cloud Functions'ın deploy edildiğinden emin olun
2. Firebase Console'da Functions loglarını kontrol edin
3. `playerCount` değerinin doğru güncellendiğinden emin olun
4. `createdAt` zaman damgasının eklendiğinden emin olun

### Çift azaltma problemi

1. `leaveGame()` fonksiyonunun `_cancelOnDisconnectHooks()` çağırdığından emin olun
2. Manuel ayrılma durumunda hook'ların iptal edildiğini doğrulayın

## İlgili Dosyalar

- `lib/features/game/data/game_repository.dart` - Ana temizleme mantığı
- `lib/features/lobby/presentation/lobby_waiting_screen.dart` - UI entegrasyonu
- `functions/src/index.ts` - Cloud Functions
- `functions/package.json` - Functions bağımlılıkları
- `firebase.json` - Firebase konfigürasyonu

