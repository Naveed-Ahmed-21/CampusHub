import { initializeApp, getApps, cert } from 'firebase-admin/app';
import path from 'path';
import fs from 'fs';
import { logger } from '../logger/logger';

export const initFirebaseAdmin = () => {
  try {
    if (getApps().length > 0) {
      return;
    }

    const serviceAccountPath = path.join(__dirname, '../../../campushub-4f0e5-firebase-adminsdk-fbsvc-b400d3ac99.json');
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
      initializeApp({
        credential: cert(serviceAccount),
      });
      logger.info('Firebase Admin SDK initialized successfully with campushub-4f0e5 project credentials');
    } else {
      logger.warn('Firebase service account file not found, FCM push dispatch running in mock mode');
    }
  } catch (err) {
    logger.error(`Failed to initialize Firebase Admin SDK: ${err}`);
  }
};
