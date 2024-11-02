// Human Tasks:
// 1. Create a Firebase project in Firebase Console and obtain project credentials
// 2. Generate a new private key for service account in Firebase Console
// 3. Set up Firebase environment variables in deployment environment
// 4. Configure Firebase Authentication providers in Firebase Console
// 5. Set up FCM credentials and server key in Firebase Console
// 6. Enable necessary Firebase services (Auth, FCM) in Firebase Console

// Third-party imports with versions
import * as admin from 'firebase-admin'; // ^11.x

// Internal imports
import { logger } from '../utils/logger.utils';

// Requirement: 3.2.2 Backend Services/Authentication
// Initialize Firebase Admin instance
let firebaseApp: admin.app.App;

// Requirement: 3.2.2 Backend Services/Authentication
// Validates required Firebase configuration settings
export const validateFirebaseConfig = (): boolean => {
  try {
    const requiredEnvVars = [
      'FIREBASE_PROJECT_ID',
      'FIREBASE_CLIENT_EMAIL',
      'FIREBASE_PRIVATE_KEY',
      'FCM_SERVER_KEY'
    ];

    for (const envVar of requiredEnvVars) {
      if (!process.env[envVar]) {
        logger.error(`Missing required Firebase configuration: ${envVar}`);
        return false;
      }
    }

    // Validate service account credentials format
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
    if (!privateKey?.includes('BEGIN PRIVATE KEY')) {
      logger.error('Invalid Firebase private key format');
      return false;
    }

    logger.info('Firebase configuration validation successful');
    return true;
  } catch (error) {
    logger.error('Firebase configuration validation failed', { error });
    return false;
  }
};

// Requirement: 3.2.2 Backend Services/Authentication
// Initializes Firebase Admin SDK with service account credentials
const initializeFirebaseAdmin = (): admin.app.App => {
  try {
    if (firebaseApp) {
      return firebaseApp;
    }

    if (!validateFirebaseConfig()) {
      throw new Error('Firebase configuration validation failed');
    }

    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey
      })
    });

    logger.info('Firebase Admin SDK initialized successfully');
    return firebaseApp;
  } catch (error) {
    logger.error('Failed to initialize Firebase Admin SDK', { error });
    throw error;
  }
};

// Requirement: 3.2.2 Backend Services/Authentication
// Configures Firebase Authentication settings
const configureFirebaseAuth = (): void => {
  try {
    const auth = admin.auth();
    
    // Configure session settings
    auth.createSessionCookie('', { expiresIn: 24 * 60 * 60 * 1000 }); // 24 hours

    // Configure token settings
    auth.createCustomToken('', { 
      expiresIn: 3600 // 1 hour
    });

    logger.info('Firebase Authentication configured successfully');
  } catch (error) {
    logger.error('Failed to configure Firebase Authentication', { error });
    throw error;
  }
};

// Requirement: 5.4.2 External APIs/Push Notifications
// Configures Firebase Cloud Messaging settings
const configureFCM = (): void => {
  try {
    const messaging = admin.messaging();

    // Configure FCM settings
    messaging.setMessagingConfig({
      fcmOptions: {
        analyticsLabel: 'founditure_notification'
      }
    });

    // Configure default messaging options
    const defaultMessagingOptions = {
      priority: 'high',
      timeToLive: 60 * 60 * 24 // 24 hours
    };

    logger.info('Firebase Cloud Messaging configured successfully');
  } catch (error) {
    logger.error('Failed to configure Firebase Cloud Messaging', { error });
    throw error;
  }
};

// Initialize Firebase services
const app = initializeFirebaseAdmin();
configureFirebaseAuth();
configureFCM();

// Export Firebase instances for application-wide use
export const firebaseAdmin = {
  app
};

export const auth = admin.auth();
export const messaging = admin.messaging();