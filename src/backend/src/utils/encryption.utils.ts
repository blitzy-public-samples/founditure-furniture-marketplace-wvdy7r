// Human Tasks:
// 1. Configure AWS KMS key ID in environment variables (KMS_KEY_ID)
// 2. Set up proper IAM roles with KMS permissions
// 3. Configure password hashing parameters (iterations, key length) based on security requirements
// 4. Set up monitoring for KMS API usage and quotas
// 5. Implement key rotation schedule in AWS KMS
// 6. Configure CloudWatch alarms for encryption failures

// Third-party imports with versions
import { GenerateDataKeyCommand, DecryptCommand } from '@aws-sdk/client-kms'; // ^3.x
import crypto from 'crypto'; // built-in

// Internal imports
import { kmsClient } from '../config/aws';
import { logger } from './logger.utils';

// Global constants for encryption configuration
const ENCRYPTION_ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;
const AUTH_TAG_LENGTH = 16;
const KMS_KEY_ID = process.env.KMS_KEY_ID;

// PBKDF2 configuration for password hashing
const PBKDF2_ITERATIONS = 100000;
const PBKDF2_KEYLEN = 64;
const PBKDF2_DIGEST = 'sha512';

// Requirement: 7.2.1 Encryption Standards - AWS KMS for key management
export async function generateDataKey(): Promise<{ plaintext: Buffer; encrypted: Buffer }> {
  try {
    const command = new GenerateDataKeyCommand({
      KeyId: KMS_KEY_ID,
      KeySpec: 'AES_256'
    });

    const response = await kmsClient.send(command);

    if (!response.Plaintext || !response.CiphertextBlob) {
      throw new Error('Failed to generate data key');
    }

    return {
      plaintext: Buffer.from(response.Plaintext),
      encrypted: Buffer.from(response.CiphertextBlob)
    };
  } catch (error) {
    logger.error('Failed to generate data key', { error });
    throw new Error('Encryption key generation failed');
  }
}

// Requirement: 7.2.1 Encryption Standards - AES-256 encryption for data at rest
export async function encrypt(data: Buffer | string): Promise<{
  encryptedData: Buffer;
  encryptedKey: Buffer;
  iv: Buffer;
}> {
  try {
    // Generate a new data key for this encryption operation
    const { plaintext: dataKey, encrypted: encryptedKey } = await generateDataKey();

    // Generate a random IV
    const iv = crypto.randomBytes(IV_LENGTH);

    // Create cipher with AES-256-GCM
    const cipher = crypto.createCipheriv(ENCRYPTION_ALGORITHM, dataKey, iv);

    // Encrypt the data
    const encryptedContent = Buffer.concat([
      cipher.update(Buffer.isBuffer(data) ? data : Buffer.from(data)),
      cipher.final()
    ]);

    // Get the auth tag
    const authTag = cipher.getAuthTag();

    // Combine encrypted content with auth tag
    const encryptedData = Buffer.concat([encryptedContent, authTag]);

    // Zero out the plaintext key from memory
    dataKey.fill(0);

    return {
      encryptedData,
      encryptedKey,
      iv
    };
  } catch (error) {
    logger.error('Encryption failed', { error });
    throw new Error('Data encryption failed');
  }
}

// Requirement: 7.2.1 Encryption Standards - AES-256 encryption for data at rest
export async function decrypt(
  encryptedData: Buffer,
  encryptedKey: Buffer,
  iv: Buffer
): Promise<Buffer> {
  try {
    // Decrypt the data key using KMS
    const decryptCommand = new DecryptCommand({
      CiphertextBlob: encryptedKey,
      KeyId: KMS_KEY_ID
    });

    const { Plaintext: decryptedKey } = await kmsClient.send(decryptCommand);

    if (!decryptedKey) {
      throw new Error('Failed to decrypt data key');
    }

    // Separate the auth tag from the encrypted data
    const authTag = encryptedData.subarray(encryptedData.length - AUTH_TAG_LENGTH);
    const encryptedContent = encryptedData.subarray(0, encryptedData.length - AUTH_TAG_LENGTH);

    // Create decipher
    const decipher = crypto.createDecipheriv(
      ENCRYPTION_ALGORITHM,
      Buffer.from(decryptedKey),
      iv
    );

    // Set auth tag for verification
    decipher.setAuthTag(authTag);

    // Decrypt the data
    const decryptedData = Buffer.concat([
      decipher.update(encryptedContent),
      decipher.final()
    ]);

    // Zero out the decrypted key from memory
    Buffer.from(decryptedKey).fill(0);

    return decryptedData;
  } catch (error) {
    logger.error('Decryption failed', { error });
    throw new Error('Data decryption failed');
  }
}

// Requirement: 7.2.2 Data Protection Measures - Password hashing
export async function hashPassword(password: string): Promise<{
  hash: string;
  salt: string;
}> {
  try {
    // Generate a random salt
    const salt = crypto.randomBytes(32);

    // Hash the password using PBKDF2
    const hash = await new Promise<Buffer>((resolve, reject) => {
      crypto.pbkdf2(
        password,
        salt,
        PBKDF2_ITERATIONS,
        PBKDF2_KEYLEN,
        PBKDF2_DIGEST,
        (err, derivedKey) => {
          if (err) reject(err);
          else resolve(derivedKey);
        }
      );
    });

    logger.info('Password hashed successfully');

    return {
      hash: hash.toString('base64'),
      salt: salt.toString('base64')
    };
  } catch (error) {
    logger.error('Password hashing failed', { error });
    throw new Error('Password hashing failed');
  }
}

// Requirement: 7.2.2 Data Protection Measures - Password verification
export async function verifyPassword(
  password: string,
  storedHash: string,
  storedSalt: string
): Promise<boolean> {
  try {
    // Decode the stored salt
    const salt = Buffer.from(storedSalt, 'base64');

    // Hash the input password with the stored salt
    const hash = await new Promise<Buffer>((resolve, reject) => {
      crypto.pbkdf2(
        password,
        salt,
        PBKDF2_ITERATIONS,
        PBKDF2_KEYLEN,
        PBKDF2_DIGEST,
        (err, derivedKey) => {
          if (err) reject(err);
          else resolve(derivedKey);
        }
      );
    });

    // Compare the hashes in constant time
    const inputHash = hash.toString('base64');
    const result = crypto.timingSafeEqual(
      Buffer.from(inputHash),
      Buffer.from(storedHash)
    );

    logger.info('Password verification completed');

    return result;
  } catch (error) {
    logger.error('Password verification failed', { error });
    throw new Error('Password verification failed');
  }
}