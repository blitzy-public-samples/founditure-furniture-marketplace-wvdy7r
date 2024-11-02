// HUMAN TASKS:
// 1. Install required ESLint plugins and dependencies with exact versions specified below
// 2. Configure IDE/editor to use project's ESLint configuration
// 3. Set up pre-commit hooks to run ESLint automatically
// 4. Ensure CI pipeline includes ESLint checks

// @typescript-eslint/parser: ^5.0.0
// @typescript-eslint/eslint-plugin: ^5.0.0
// eslint-config-prettier: ^8.5.0
// eslint-plugin-security: ^1.7.0
// eslint-plugin-node: ^11.1.0

module.exports = {
  // Requirement: Code Quality Standards (3.3.2 Backend Technologies)
  // Defines environment for Node.js/Express.js backend
  env: {
    node: true,
    es2022: true,
    jest: true
  },

  // Requirement: TypeScript Development (5.1 Programming Languages)
  // Configures TypeScript parser and project reference
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
    project: './tsconfig.json'
  },

  // Requirement: Code Quality Standards (3.3.2 Backend Technologies)
  // Enables TypeScript, security, and Node.js specific plugins
  plugins: [
    '@typescript-eslint',
    'security',
    'node'
  ],

  // Requirement: Code Quality Standards (3.3.2 Backend Technologies)
  // Extends recommended configurations and integrates with Prettier
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
    'plugin:security/recommended',
    'plugin:node/recommended',
    'prettier'
  ],

  // Requirement: Security Best Practices (7.3.3 Security Controls)
  // Enforces security-related coding practices and TypeScript best practices
  rules: {
    // TypeScript-specific rules
    '@typescript-eslint/explicit-function-return-type': 'error',
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/strict-boolean-expressions': 'error',

    // Security rules
    'security/detect-object-injection': 'error',
    'security/detect-non-literal-fs-filename': 'error',
    'security/detect-eval-with-expression': 'error',

    // Node.js rules - disabled conflicting rules for TypeScript
    'node/no-unsupported-features/es-syntax': 'off',
    'node/no-missing-import': 'off',

    // General code quality rules
    'no-console': ['error', { 
      allow: ['warn', 'error']
    }],
    'no-debugger': 'error',
    'no-var': 'error',
    'prefer-const': 'error'
  }
};