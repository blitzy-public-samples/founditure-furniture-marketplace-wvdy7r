// @package knex ^2.5.1

import { Knex } from 'knex';

/**
 * Human Tasks:
 * 1. Ensure PostGIS extension is installed on the database
 * 2. Verify database user has necessary permissions for creating extensions
 * 3. Configure appropriate backup strategy for JSONB columns
 * 4. Set up monitoring for spatial index performance
 */

/**
 * Creates the furniture table with all required fields, indexes, and constraints
 * Addresses requirements:
 * - Core furniture listing management data structure
 * - Distributed database schema for furniture data
 * - Support for AI-generated metadata storage
 * - Geospatial data structure for furniture locations
 */
export async function up(knex: Knex): Promise<void> {
  // Enable PostGIS extension for geospatial functionality
  await knex.raw('CREATE EXTENSION IF NOT EXISTS postgis');

  // Create furniture table
  await knex.schema.createTable('furniture', (table) => {
    // Primary key and relationships
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');

    // Basic furniture information
    table.string('title', 255).notNullable();
    table.text('description').notNullable();
    table.string('category', 50).notNullable().checkIn([
      'SEATING', 'TABLES', 'STORAGE', 'BEDS', 'LIGHTING', 'DECOR', 'OUTDOOR', 'OTHER'
    ]);
    table.string('condition', 50).notNullable().checkIn([
      'LIKE_NEW', 'GOOD', 'FAIR', 'NEEDS_REPAIR', 'FOR_PARTS'
    ]);

    // Images array for furniture photos
    table.specificType('image_urls', 'text[]').notNullable().defaultTo('{}');

    // Dimensions as JSONB for flexible unit support
    table.jsonb('dimensions').notNullable().checkValid(
      "dimensions ? 'length' AND dimensions ? 'width' AND " +
      "dimensions ? 'height' AND dimensions ? 'weight' AND dimensions ? 'unit'"
    );

    // Materials array
    table.specificType('materials', 'text[]').notNullable().defaultTo('{}');

    // Location information
    table.decimal('latitude', 10, 8).notNullable();
    table.decimal('longitude', 11, 8).notNullable();
    table.string('address', 512).notNullable();
    table.string('privacy_level', 50).notNullable().defaultTo('PUBLIC');
    
    // Create PostGIS geography point column
    table.specificType(
      'location_point',
      'geography(Point, 4326)'
    ).notNullable();

    // Status and availability
    table.string('status', 50).notNullable().defaultTo('AVAILABLE').checkIn([
      'AVAILABLE', 'PENDING', 'CLAIMED', 'EXPIRED', 'REMOVED'
    ]);
    table.boolean('is_available').notNullable().defaultTo(true);
    table.integer('points_value').notNullable().defaultTo(0);

    // Pickup details as JSONB
    table.jsonb('pickup_details').notNullable();

    // AI/ML metadata as JSONB
    table.jsonb('ai_metadata').notNullable().checkValid(
      "ai_metadata ? 'style' AND ai_metadata ? 'confidenceScore' AND " +
      "ai_metadata ? 'detectedMaterials' AND ai_metadata ? 'suggestedCategories' AND " +
      "ai_metadata ? 'similarItems' AND ai_metadata ? 'qualityAssessment'"
    );

    // Timestamps
    table.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    table.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    table.timestamp('expires_at').notNullable();
  });

  // Create indexes for frequently queried columns
  await knex.schema.raw(`
    CREATE INDEX idx_furniture_user_id ON furniture(user_id);
    CREATE INDEX idx_furniture_category ON furniture(category);
    CREATE INDEX idx_furniture_status ON furniture(status);
    CREATE INDEX idx_furniture_is_available ON furniture(is_available);
    CREATE INDEX idx_furniture_created_at ON furniture(created_at);
    CREATE INDEX idx_furniture_expires_at ON furniture(expires_at);
    
    -- Create spatial index for location-based queries
    CREATE INDEX idx_furniture_location ON furniture USING GIST(location_point);
    
    -- Create GIN indexes for JSONB columns for efficient searching
    CREATE INDEX idx_furniture_ai_metadata ON furniture USING GIN(ai_metadata);
    CREATE INDEX idx_furniture_dimensions ON furniture USING GIN(dimensions);
    CREATE INDEX idx_furniture_pickup_details ON furniture USING GIN(pickup_details);
  `);

  // Create trigger for updating updated_at timestamp
  await knex.schema.raw(`
    CREATE OR REPLACE FUNCTION update_furniture_updated_at()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = CURRENT_TIMESTAMP;
      RETURN NEW;
    END;
    $$ language 'plpgsql';

    CREATE TRIGGER trigger_furniture_updated_at
      BEFORE UPDATE ON furniture
      FOR EACH ROW
      EXECUTE FUNCTION update_furniture_updated_at();
  `);
}

/**
 * Drops the furniture table and related constraints
 */
export async function down(knex: Knex): Promise<void> {
  // Drop triggers first
  await knex.schema.raw(`
    DROP TRIGGER IF EXISTS trigger_furniture_updated_at ON furniture;
    DROP FUNCTION IF EXISTS update_furniture_updated_at();
  `);

  // Drop the furniture table (will cascade to indexes)
  await knex.schema.dropTableIfExists('furniture');
}