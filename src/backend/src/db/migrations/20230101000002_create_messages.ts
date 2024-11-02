// @package knex ^2.5.1

import { Knex } from 'knex';
import { MessageType } from '../../interfaces/message.interface';

/**
 * Human tasks:
 * 1. Ensure PostgreSQL version 12 or higher is installed for enum support
 * 2. Verify that the users and furniture tables are created before running this migration
 * 3. Configure appropriate database backup before running in production
 * 4. Review and adjust index strategies based on query patterns if needed
 */

/**
 * Creates the messages table with all required fields and constraints
 * Addresses requirements:
 * - Real-time messaging system (Core messaging system data structure)
 * - Privacy controls (Message privacy and data protection)
 */
export async function up(knex: Knex): Promise<void> {
  // Create message_type enum if it doesn't exist
  await knex.raw(`
    DO $$ 
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'message_type') THEN
        CREATE TYPE message_type AS ENUM (
          '${MessageType.TEXT}',
          '${MessageType.IMAGE}',
          '${MessageType.SYSTEM}',
          '${MessageType.LOCATION}',
          '${MessageType.ARRANGEMENT}'
        );
      END IF;
    END$$;
  `);

  // Create messages table
  await knex.schema.createTable('messages', (table) => {
    // Primary key
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));

    // Foreign key references
    table.uuid('sender_id')
      .notNullable()
      .references('id')
      .inTable('users')
      .onDelete('CASCADE')
      .onUpdate('CASCADE');

    table.uuid('receiver_id')
      .notNullable()
      .references('id')
      .inTable('users')
      .onDelete('CASCADE')
      .onUpdate('CASCADE');

    table.uuid('furniture_id')
      .nullable()
      .references('id')
      .inTable('furniture')
      .onDelete('SET NULL')
      .onUpdate('CASCADE');

    // Message content and metadata
    table.text('content').notNullable();
    table.specificType('message_type', 'message_type').notNullable();
    table.jsonb('metadata').nullable().defaultTo('{}');
    table.boolean('is_read').notNullable().defaultTo(false);
    table.timestamp('read_at').nullable();

    // Timestamps
    table.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    table.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());

    // Indexes for frequent queries
    table.index('sender_id');
    table.index('receiver_id');
    table.index('furniture_id');
    table.index('created_at');

    // Composite index for chat history queries
    table.index(['sender_id', 'receiver_id', 'created_at']);
  });

  // Create trigger to automatically update updated_at timestamp
  await knex.raw(`
    CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);
}

/**
 * Drops the messages table and related constraints
 */
export async function down(knex: Knex): Promise<void> {
  // Drop the messages table
  await knex.schema.dropTableIfExists('messages');

  // Drop the message_type enum
  await knex.raw(`
    DROP TYPE IF EXISTS message_type;
  `);
}