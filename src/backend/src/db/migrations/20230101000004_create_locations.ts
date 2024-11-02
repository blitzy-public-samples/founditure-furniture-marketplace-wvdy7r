// knex v2.5.0
import { Knex } from 'knex';
import { LocationType } from '../interfaces/location.interface';

/**
 * HUMAN TASKS:
 * 1. Ensure PostgreSQL PostGIS extension is installed on the database for spatial indexing
 * 2. Verify that the users table exists and has UUID primary keys
 * 3. Configure appropriate database permissions for spatial operations
 */

/**
 * Creates the locations table with geospatial support and privacy settings
 * Addresses requirements:
 * - Location Services: Database schema for storing location data with geospatial capabilities
 * - Privacy Controls: Schema support for location privacy settings and data protection
 * - Location-based Search: Geospatial indexing for efficient location-based queries
 */
export async function up(knex: Knex): Promise<void> {
  // Enable PostGIS extension if not already enabled
  await knex.raw('CREATE EXTENSION IF NOT EXISTS postgis');

  // Create locations table
  await knex.schema.createTable('locations', (table) => {
    // Primary key and relationships
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users')
      .onDelete('CASCADE').onUpdate('CASCADE');

    // Geospatial coordinates
    table.decimal('latitude', 10, 8).notNullable()
      .checkIn('latitude', [-90, 90]);
    table.decimal('longitude', 11, 8).notNullable()
      .checkIn('longitude', [-180, 180]);
    table.decimal('accuracy', 10, 2).nullable();

    // Address components
    table.string('address', 255).nullable();
    table.string('city', 100).nullable();
    table.string('state', 100).nullable();
    table.string('country', 100).nullable();
    table.string('postal_code', 20).nullable();

    // Location type enumeration
    table.enum('type', Object.values(LocationType)).notNullable();

    // Privacy settings
    table.enum('visibility_level', ['public', 'private', 'friends'])
      .notNullable().defaultTo('public');
    table.integer('radius_blur').nullable().defaultTo(0)
      .comment('Radius in meters to blur the exact location');
    table.boolean('show_exact_location').notNullable().defaultTo(true);

    // Timestamps
    table.timestamp('created_at').notNullable()
      .defaultTo(knex.raw('CURRENT_TIMESTAMP'));
    table.timestamp('updated_at').notNullable()
      .defaultTo(knex.raw('CURRENT_TIMESTAMP'));
  });

  // Create spatial index for efficient geospatial queries
  await knex.raw(`
    CREATE INDEX locations_coordinates_idx 
    ON locations USING gist (
      ST_SetSRID(
        ST_MakePoint(longitude, latitude),
        4326
      )
    );
  `);

  // Create indexes for common queries
  await knex.schema.alterTable('locations', (table) => {
    table.index(['user_id'], 'locations_user_id_idx');
    table.index(['type'], 'locations_type_idx');
  });

  // Create trigger for automatic updated_at timestamp
  await knex.raw(`
    CREATE TRIGGER update_locations_timestamp
    BEFORE UPDATE ON locations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  `);
}

/**
 * Drops the locations table and associated indexes
 */
export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('locations');
}