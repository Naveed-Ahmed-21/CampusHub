import { initializeApp, getApps, cert } from 'firebase-admin/app';
import path from 'path';
import fs from 'fs';
import { logger } from '../logger/logger';

export const initFirebaseAdmin = () => {
  try {
    if (getApps().length > 0) {
      return;
    }

    const backendRoot = path.join(__dirname, '../../../');
    let serviceAccountPath: string | null = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || null;

    if (!serviceAccountPath || !fs.existsSync(serviceAccountPath)) {
      const files = fs.readdirSync(backendRoot);
      const matched = files.find((f) => f.includes('firebase-adminsdk') && f.endsWith('.json'));
      if (matched) {
        serviceAccountPath = path.join(backendRoot, matched);
      }
    }

    if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
      initializeApp({
        credential: cert(serviceAccount),
      });
      logger.info(`Firebase Admin SDK initialized successfully using ${path.basename(serviceAccountPath)}`);
    } else {
      logger.warn('Firebase service account file not found, FCM push dispatch running in mock mode');
    }
  } catch (err) {
    logger.error(`Failed to initialize Firebase Admin SDK: ${err}`);
  }
};
