import { Knex } from 'knex'; // ^2.4.0
import { 
  PointTransactionStatus, 
  AchievementStatus, 
  LeaderboardPeriod 
} from '../../../interfaces/point.interface';

/**
 * HUMAN TASKS:
 * 1. Ensure PostgreSQL is running and accessible
 * 2. Verify database user has sufficient privileges for table creation
 * 3. Check if any existing points-related tables need to be backed up before migration
 * 4. Update database connection configuration if needed
 */

/**
 * Creates the points system database tables
 * Addresses requirements:
 * - Points-based gamification engine (1.1 System Overview)
 * - Points system and leaderboards (1.2 Scope/Included Features)
 */
export async function up(knex: Knex): Promise<void> {
  // Create point_transactions table
  await knex.schema.createTable('point_transactions', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('action_type').notNullable();
    table.integer('points').notNullable();
    table.decimal('multiplier', 4, 2).notNullable().defaultTo(1.0);
    table.integer('total_points').notNullable();
    table.timestamp('timestamp').notNullable().defaultTo(knex.fn.now());
    table.timestamp('expiry_date').nullable();
    table.uuid('reference_id').nullable();
    table.enum('status', Object.values(PointTransactionStatus)).notNullable().defaultTo(PointTransactionStatus.PENDING);
    table.jsonb('metadata').nullable();
    table.timestamps(true, true);
    table.boolean('is_deleted').notNullable().defaultTo(false);

    // Indexes for frequent queries
    table.index(['user_id', 'timestamp']);
    table.index(['status', 'timestamp']);
    table.index('action_type');
  });

  // Create user_points table
  await knex.schema.createTable('user_points', (table) => {
    table.uuid('user_id').primary().references('id').inTable('users').onDelete('CASCADE');
    table.bigInteger('total_points').notNullable().defaultTo(0);
    table.bigInteger('available_points').notNullable().defaultTo(0);
    table.bigInteger('expired_points').notNullable().defaultTo(0);
    table.integer('level').notNullable().defaultTo(1);
    table.integer('rank').nullable();
    table.timestamp('last_updated').notNullable().defaultTo(knex.fn.now());
    table.timestamps(true, true);
    table.boolean('is_deleted').notNullable().defaultTo(false);

    // Indexes for leaderboard queries
    table.index(['total_points', 'rank']);
    table.index('level');
  });

  // Create achievements table
  await knex.schema.createTable('achievements', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('name').notNullable();
    table.text('description').notNullable();
    table.integer('points_required').notNullable();
    table.integer('current_progress').notNullable().defaultTo(0);
    table.timestamp('earned_date').nullable();
    table.timestamp('claimed_date').nullable();
    table.string('badge_url').nullable();
    table.enum('status', Object.values(AchievementStatus)).notNullable().defaultTo(AchievementStatus.LOCKED);
    table.timestamps(true, true);
    table.boolean('is_deleted').notNullable().defaultTo(false);

    // Indexes for achievement queries
    table.index(['user_id', 'status']);
    table.index('earned_date');
  });

  // Create leaderboard table
  await knex.schema.createTable('leaderboard', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('uuid_generate_v4()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('username').notNullable();
    table.bigInteger('points').notNullable();
    table.integer('rank').notNullable();
    table.integer('level').notNullable();
    table.integer('achievements_count').notNullable().defaultTo(0);
    table.enum('period', Object.values(LeaderboardPeriod)).notNullable();
    table.timestamp('period_start').notNullable();
    table.timestamp('period_end').notNullable();
    table.timestamps(true, true);
    table.boolean('is_deleted').notNullable().defaultTo(false);

    // Composite unique constraint
    table.unique(['user_id', 'period', 'period_start']);

    // Indexes for leaderboard queries
    table.index(['period', 'period_start', 'rank']);
    table.index(['points', 'period', 'period_start']);
  });
}

/**
 * Rolls back the points system database tables
 */
export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('leaderboard');
  await knex.schema.dropTableIfExists('achievements');
  await knex.schema.dropTableIfExists('user_points');
  await knex.schema.dropTableIfExists('point_transactions');
}