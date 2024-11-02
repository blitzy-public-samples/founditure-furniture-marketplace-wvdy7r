# HUMAN TASKS:
# 1. Configure environment-specific variables in Kubernetes ConfigMaps/Secrets
# 2. Set up monitoring for worker processes
# 3. Configure log aggregation for worker containers
# 4. Ensure proper network policies are in place for worker pods
# 5. Set up auto-scaling thresholds for worker deployments

# Build stage
# Requirement: Background Processing (3.1 High-Level Architecture Overview/Service Layer)
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY src/backend/package*.json ./

# Install build dependencies including ML libraries
# Requirement: AI/ML Infrastructure (1.2 Scope/Core System Components/AI/ML Infrastructure)
RUN apk add --no-cache python3 make g++ \
    && npm ci

# Copy source code and configs
COPY src/backend/tsconfig.json ./
COPY src/backend/src ./src

# Build TypeScript to JavaScript
RUN npm run build

# Prune dev dependencies
RUN npm prune --production

# Production stage
# Requirement: Points System (1.2 Scope/Core System Components/Backend Services)
FROM node:18-alpine

# Install runtime dependencies for ML libraries
RUN apk add --no-cache python3 libstdc++ libc6-compat

# Set working directory
WORKDIR /usr/src/app

# Set non-root user for security
# Requirement: Security Controls (7.3.3)
RUN addgroup -g 1001 -S nodejs \
    && adduser -S nodejs -u 1001 -G nodejs

# Copy production files from builder
COPY --from=builder --chown=nodejs:nodejs /usr/src/app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /usr/src/app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /usr/src/app/package*.json ./

# Install TensorFlow.js for Node.js
# Version: 4.10.0 (from JSON spec)
RUN npm install @tensorflow/tfjs-node@4.10.0

# Install Sharp for image processing
# Version: 0.32.4 (from JSON spec)
RUN npm install sharp@0.32.4

# Configure worker process environment
ENV NODE_ENV=production \
    TENSORFLOW_WORKER=true \
    USER=node

# Switch to non-root user
USER nodejs

# Health check for worker processes
# Requirement: System Health Metrics (Appendix D)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "try { require('http').get('http://localhost:${PORT:-3000}/health', (r) => r.statusCode === 200 ? process.exit(0) : process.exit(1)); } catch (e) { process.exit(1); }"

# Start worker processes
# Requirement: Content Moderation (1.2 Scope/Included Features)
CMD ["node", "dist/workers/index.js"]