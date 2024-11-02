import { Knex } from 'knex'; // ^2.5.1

/**
 * Human Tasks:
 * 1. Ensure PostgreSQL is configured to handle UUID and JSONB data types
 * 2. Configure appropriate database user permissions for migrations
 * 3. Verify that the database collation supports case-sensitive email addresses
 * 4. Set up appropriate backup procedures for the users table
 * 5. Configure monitoring for table size and index usage
 */

/**
 * Creates the users table with all required fields and constraints
 * Addresses requirements:
 * - User authentication and authorization (1.2 Scope/Core System Components/Backend Services)
 * - Privacy controls (7.2 Data Security/7.2.3 Privacy Controls)
 * - Points system (1.2 Scope/Included Features)
 */
export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('users', (table) => {
    // Primary key and identification
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    
    // Authentication fields
    // Requirement: User authentication and authorization
    table.string('email').unique().notNullable();
    table.string('password_hash').notNullable();
    table.string('full_name').notNullable();
    table.string('phone_number').nullable();
    table.string('profile_image_url').nullable();
    
    // Status and role management
    // Requirement: User authentication and authorization
    table.enum('status', ['ACTIVE', 'INACTIVE', 'SUSPENDED', 'DELETED'])
      .notNullable()
      .defaultTo('ACTIVE');
    table.enum('role', ['USER', 'VERIFIED_USER', 'MODERATOR', 'ADMIN'])
      .notNullable()
      .defaultTo('USER');
    
    // Points tracking
    // Requirement: Points system
    table.decimal('points_balance', 10, 2)
      .notNullable()
      .defaultTo(0);
    table.jsonb('points_history')
      .notNullable()
      .defaultTo('[]');
    
    // Location tracking
    table.decimal('last_latitude', 10, 8).nullable();
    table.decimal('last_longitude', 11, 8).nullable();
    table.timestamp('last_location_update').nullable();
    
    // User preferences and privacy settings
    // Requirement: Privacy controls
    table.jsonb('preferences').notNullable().defaultTo(JSON.stringify({
      language: 'en',
      notifications: {
        email: true,
        push: true,
        sms: false
      },
      searchRadius: 10,
      theme: 'light'
    }));
    
    table.jsonb('privacy_settings').notNullable().defaultTo(JSON.stringify({
      profileVisibility: 'public',
      locationSharing: true,
      activityVisibility: 'followers'
    }));
    
    // Authentication and security tracking
    table.timestamp('last_active').nullable();
    table.integer('failed_login_attempts').notNullable().defaultTo(0);
    table.timestamp('lockout_until').nullable();
    table.timestamp('last_password_change').notNullable().defaultTo(knex.fn.now());
    
    // Timestamps
    table.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    table.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    
    // Indexes for performance optimization
    table.index('email');
    table.index('status');
    table.index('role');
    table.index(['last_latitude', 'last_longitude']);
    table.index('points_balance');
    table.index('created_at');
    table.index('last_active');
  });

  // Create trigger for updating updated_at timestamp
  await knex.raw(`
    CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);
}

/**
 * Drops the users table and related objects
 */
export async function down(knex: Knex): Promise<void> {
  // Drop the trigger first
  await knex.raw(`DROP TRIGGER IF EXISTS update_users_updated_at ON users`);
  
  // Drop the table
  await knex.schema.dropTableIfExists('users');
}