# Firebase Cloud Functions

Bu klasör, Firebase Realtime Database için lobi temizleme mekanizmasını içerir.

## Fonksiyonlar

### 1. cleanupEmptyLobbies
- **Tetikleyici**: `/activeLobbies/{gameId}/playerCount` yolundaki yazma işlemleri
- **Amaç**: `playerCount` 0 veya daha az olduğunda lobiyi ve ilgili oyunu siler
- **Çalışma**: Anlık (real-time trigger)

### 2. scheduledLobbyCleanup
- **Tetikleyici**: Her saat başı (cron: `0 * * * *`)
- **Amaç**: 
  - `playerCount: 0` olan lobileri temizler
  - `createdAt` zaman damgası 2 saatten eski olan lobileri temizler
- **Çalışma**: Zamanlanmış (scheduled)

## Kurulum

```bash
cd functions
npm install
```

## Geliştirme

```bash
# Build
npm run build

# Local test (emulator)
npm run serve

# Deploy
npm run deploy
```

## Notlar

- Her iki fonksiyon da sadece `status: 'waiting'` durumundaki oyunları temizler
- Oyun başlamışsa (`status: 'playing'`) temizlik yapılmaz
- `createdAt` zaman damgası `createGame` fonksiyonunda otomatik olarak eklenir

