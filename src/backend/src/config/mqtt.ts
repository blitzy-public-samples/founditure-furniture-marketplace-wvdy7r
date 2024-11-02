// Human Tasks:
// 1. Set up MQTT broker credentials in environment variables (MQTT_USERNAME, MQTT_PASSWORD)
// 2. Configure MQTT broker host and port for different environments
// 3. Verify MQTT broker SSL/TLS certificates if using secure connections
// 4. Set up appropriate MQTT access control lists (ACLs) on the broker
// 5. Configure MQTT topic hierarchy and access patterns

// Third-party imports with versions
import mqtt from 'mqtt'; // ^4.3.7
import retry from 'retry'; // ^0.13.1
import { logger } from '../utils/logger.utils';

// Environment variables and constants
const MQTT_HOST = process.env.MQTT_HOST || 'localhost';
const MQTT_PORT = process.env.MQTT_PORT || 1883;
const MQTT_USERNAME = process.env.MQTT_USERNAME;
const MQTT_PASSWORD = process.env.MQTT_PASSWORD;
const MQTT_KEEP_ALIVE = 60;
const MQTT_RECONNECT_PERIOD = 1000;
const MQTT_CONNECT_TIMEOUT = 30000;

// Requirement: Event-driven messaging - MQTT broker configuration
const createMQTTClient = (): mqtt.Client => {
  const brokerUrl = `mqtt://${MQTT_HOST}:${MQTT_PORT}`;
  
  const options: mqtt.IClientOptions = {
    keepalive: MQTT_KEEP_ALIVE,
    reconnectPeriod: MQTT_RECONNECT_PERIOD,
    connectTimeout: MQTT_CONNECT_TIMEOUT,
    clean: true // Start with a clean session
  };

  // Add authentication if credentials are provided
  if (MQTT_USERNAME && MQTT_PASSWORD) {
    options.username = MQTT_USERNAME;
    options.password = MQTT_PASSWORD;
  }

  // Create MQTT client with connection options
  const client = mqtt.connect(brokerUrl, options);

  // Set up event handlers
  setupMQTTEventHandlers(client);

  return client;
};

// Requirement: Real-time Features - MQTT event handler setup
const setupMQTTEventHandlers = (client: mqtt.Client): void => {
  client.on('connect', () => {
    logger.info('MQTT client connected successfully', {
      host: MQTT_HOST,
      port: MQTT_PORT,
      component: 'mqtt'
    });
  });

  client.on('reconnect', () => {
    logger.warn('MQTT client attempting to reconnect', {
      host: MQTT_HOST,
      port: MQTT_PORT,
      component: 'mqtt'
    });
  });

  client.on('error', (error) => {
    logger.error('MQTT client error', {
      error: error.message,
      host: MQTT_HOST,
      port: MQTT_PORT,
      component: 'mqtt'
    });
  });

  client.on('offline', () => {
    logger.warn('MQTT client went offline', {
      host: MQTT_HOST,
      port: MQTT_PORT,
      component: 'mqtt'
    });
  });

  client.on('message', (topic, message) => {
    logger.debug('MQTT message received', {
      topic,
      message: message.toString(),
      component: 'mqtt'
    });
  });
};

// Requirement: Message Queue - MQTT configuration validation
const validateMQTTConfig = (): boolean => {
  try {
    // Validate host
    if (!MQTT_HOST) {
      logger.error('MQTT host not configured');
      return false;
    }

    // Validate port
    const port = Number(MQTT_PORT);
    if (isNaN(port) || port <= 0 || port > 65535) {
      logger.error('Invalid MQTT port number', { port: MQTT_PORT });
      return false;
    }

    // Check credentials if required
    if ((MQTT_USERNAME && !MQTT_PASSWORD) || (!MQTT_USERNAME && MQTT_PASSWORD)) {
      logger.error('Incomplete MQTT credentials');
      return false;
    }

    // Validate connection parameters
    if (MQTT_KEEP_ALIVE <= 0 || MQTT_RECONNECT_PERIOD <= 0 || MQTT_CONNECT_TIMEOUT <= 0) {
      logger.error('Invalid MQTT connection parameters');
      return false;
    }

    logger.info('MQTT configuration validated successfully', {
      host: MQTT_HOST,
      port: MQTT_PORT,
      component: 'mqtt'
    });

    return true;
  } catch (error) {
    logger.error('MQTT configuration validation error', {
      error: error instanceof Error ? error.message : 'Unknown error',
      component: 'mqtt'
    });
    return false;
  }
};

// Create and configure the MQTT client with retry mechanism
const operation = retry.operation({
  retries: 5,
  factor: 2,
  minTimeout: 1000,
  maxTimeout: 60000
});

let mqttClient: mqtt.Client;

operation.attempt(() => {
  try {
    if (validateMQTTConfig()) {
      mqttClient = createMQTTClient();
    } else {
      const error = new Error('Invalid MQTT configuration');
      if (operation.retry(error)) {
        return;
      }
      logger.error('Failed to create MQTT client after retries');
    }
  } catch (error) {
    if (operation.retry(error instanceof Error ? error : new Error('MQTT client creation failed'))) {
      return;
    }
    logger.error('Failed to create MQTT client after retries', {
      error: error instanceof Error ? error.message : 'Unknown error',
      component: 'mqtt'
    });
  }
});

// Export configured MQTT client and validation utility
export default mqttClient;
export { validateMQTTConfig };