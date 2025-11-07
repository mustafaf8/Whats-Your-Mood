import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.database();

/**
 * 1. onWrite Trigger: playerCount 0 veya daha az olduğunda lobiyi temizle
 * 
 * /activeLobbies/{gameId}/playerCount yolundaki değişiklikleri dinler.
 * Eğer playerCount <= 0 ise, hem /activeLobbies/{gameId} hem de /games/{gameId} referanslarını siler.
 */
export const cleanupEmptyLobbies = functions.database
  .ref('/activeLobbies/{gameId}/playerCount')
  .onWrite(async (change, context) => {
    const gameId = context.params.gameId;
    const playerCount = change.after.val() as number | null;

    // playerCount 0 veya daha az ise (veya null ise) temizle
    if (playerCount === null || playerCount <= 0) {
      const batch: Promise<void>[] = [];

      // activeLobbies/{gameId} sil
      batch.push(db.ref(`activeLobbies/${gameId}`).remove().then(() => {}));

      // games/{gameId} sil (sadece status 'waiting' ise - oyun başlamışsa silme)
      const gameSnapshot = await db.ref(`games/${gameId}/status`).once('value');
      const gameStatus = gameSnapshot.val() as string | null;
      
      if (gameStatus === 'waiting' || gameStatus === null) {
        batch.push(db.ref(`games/${gameId}`).remove().then(() => {}));
        functions.logger.info(`Cleaned up empty lobby: ${gameId}`);
      } else {
        functions.logger.info(
          `Skipped cleanup for ${gameId} - game status is '${gameStatus}', not 'waiting'`
        );
      }

      await Promise.all(batch);
    }

    return null;
  });

/**
 * 2. Scheduled Function (Cron): Zamanlanmış temizlik
 * 
 * Her saat başı çalışır ve şu lobileri temizler:
 * - playerCount: 0 olan lobiler
 * - createdAt zaman damgası 2 saatten eski olan lobiler
 */
export const scheduledLobbyCleanup = functions.pubsub
  .schedule('0 * * * *') // Her saat başı (cron format: dakika saat gün ay haftanın günü)
  .timeZone('UTC')
  .onRun(async (context) => {
    functions.logger.info('Starting scheduled lobby cleanup...');

    const activeLobbiesRef = db.ref('activeLobbies');
    const snapshot = await activeLobbiesRef.once('value');

    if (!snapshot.exists()) {
      functions.logger.info('No active lobbies found.');
      return null;
    }

    const now = Date.now();
    const twoHoursInMs = 2 * 60 * 60 * 1000; // 2 saat
    const cleanupThreshold = now - twoHoursInMs;

    const lobbies = snapshot.val() as Record<string, any>;
    const cleanupPromises: Promise<void>[] = [];

    for (const [gameId, lobbyData] of Object.entries(lobbies)) {
      const playerCount = lobbyData.playerCount as number | undefined;
      const createdAt = lobbyData.createdAt as number | undefined;

      let shouldCleanup = false;
      let reason = '';

      // playerCount kontrolü
      if (playerCount === undefined || playerCount === null || playerCount <= 0) {
        shouldCleanup = true;
        reason = `playerCount is ${playerCount}`;
      }
      // Zaman damgası kontrolü (2 saatten eski)
      else if (createdAt !== undefined && createdAt !== null && createdAt < cleanupThreshold) {
        shouldCleanup = true;
        const ageHours = (now - createdAt) / (60 * 60 * 1000);
        reason = `createdAt is ${ageHours.toFixed(2)} hours old (threshold: 2 hours)`;
      }

      if (shouldCleanup) {
        functions.logger.info(
          `Scheduled cleanup: Removing lobby ${gameId} - Reason: ${reason}`
        );

        // Oyun durumunu kontrol et
        const gameStatusSnapshot = await db.ref(`games/${gameId}/status`).once('value');
        const gameStatus = gameStatusSnapshot.val() as string | null;

        // Sadece 'waiting' durumundaki veya durumu olmayan oyunları temizle
        if (gameStatus === 'waiting' || gameStatus === null) {
          cleanupPromises.push(
            db.ref(`activeLobbies/${gameId}`).remove().then(() => {
              return db.ref(`games/${gameId}`).remove().then(() => {});
            })
          );
        } else {
          functions.logger.info(
            `Skipped cleanup for ${gameId} - game status is '${gameStatus}', not 'waiting'`
          );
        }
      }
    }

    if (cleanupPromises.length > 0) {
      await Promise.all(cleanupPromises);
      functions.logger.info(`Scheduled cleanup completed: ${cleanupPromises.length} lobbies cleaned.`);
    } else {
      functions.logger.info('Scheduled cleanup completed: No lobbies needed cleanup.');
    }

    return null;
  });

