// @ts-check

// HUMAN TASKS:
// 1. Ensure Jest and ts-jest are installed: npm install --save-dev jest ts-jest @types/jest
// 2. Configure IDE test runner integration for Jest
// 3. Set up test coverage reporting in CI/CD pipeline
// 4. Create src/test/setup.ts file for test environment configuration

/** @type {import('@jest/types').Config.InitialOptions} */

// jest v29.0.0
// ts-jest v29.0.0

// Requirement: Backend Testing Infrastructure (8. Infrastructure/8.5 CI/CD Pipeline/Pipeline Stages)
// Configures Jest for unit tests and integration tests in the backend service
module.exports = {
  // Use ts-jest preset for TypeScript support
  preset: 'ts-jest',
  
  // Set Node.js as the test environment
  testEnvironment: 'node',
  
  // Define test file locations
  roots: ['<rootDir>/src'],
  
  // Pattern matching for test files
  testMatch: [
    '**/__tests__/**/*.ts',
    '**/?(*.)+(spec|test).ts'
  ],
  
  // TypeScript file transformation
  transform: {
    '^.+\\.ts$': 'ts-jest'
  },
  
  // Path alias mapping (aligned with tsconfig.json)
  moduleNameMapper: {
    '@/(.*)': '<rootDir>/src/$1'
  },
  
  // Requirement: Test Coverage Reporting (8. Infrastructure/8.5 CI/CD Pipeline/Automation Matrix)
  // Configure test coverage collection and reporting
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/*.interface.ts',
    '!src/types/**/*',
    '!src/**/__mocks__/**/*'
  ],
  
  // Coverage output directory
  coverageDirectory: 'coverage',
  
  // Coverage report formats
  coverageReporters: [
    'text',
    'lcov',
    'json-summary'
  ],
  
  // Coverage thresholds enforcement
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  
  // File extensions to consider
  moduleFileExtensions: [
    'ts',
    'js',
    'json',
    'node'
  ],
  
  // Test setup file
  setupFilesAfterEnv: [
    '<rootDir>/src/test/setup.ts'
  ],
  
  // Paths to ignore
  testPathIgnorePatterns: [
    '/node_modules/',
    '/dist/'
  ],
  
  // Detailed test output
  verbose: true,
  
  // Limit parallel test execution to 50% of available CPU cores
  maxWorkers: '50%'
};