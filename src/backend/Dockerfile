# HUMAN TASKS:
# 1. Configure container registry credentials in CI/CD pipeline
# 2. Set up environment-specific secrets in Kubernetes
# 3. Verify health check endpoint is implemented at /health
# 4. Configure resource limits in Kubernetes deployment
# 5. Set up log aggregation for container logs

# Stage 1: Builder
# Requirement: Backend Runtime Environment (3.3.2 Backend Technologies)
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies including development ones
# Requirement: Container Orchestration (3.3.4 Infrastructure)
RUN npm ci

# Copy source code and configuration
COPY tsconfig.json ./
COPY src/ ./src/

# Build TypeScript application
RUN npm run build

# Prune development dependencies
RUN npm prune --production

# Stage 2: Production
# Requirement: Security (7.3.3 Security Controls)
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Create non-root user for security
RUN addgroup -g 1001 node && \
    adduser -u 1001 -G node -s /bin/sh -D node

# Copy built application and dependencies from builder
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package*.json ./

# Set appropriate file permissions
RUN chown -R node:node /usr/src/app

# Configure security settings
# Requirement: Security (7.3.3 Security Controls)
RUN apk add --no-cache curl && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /usr/src/app/node_modules/.cache && \
    chown -R node:node /usr/src/app/node_modules/.cache

# Switch to non-root user
USER node

# Set production environment
ENV NODE_ENV=production
ENV PORT=3000

# Expose application port
EXPOSE 3000

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Set startup command
CMD ["node", "dist/server.js"]

# Labels for container metadata
LABEL org.opencontainers.image.source="https://github.com/founditure/backend" \
      org.opencontainers.image.description="Founditure backend service" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="Founditure" \
      org.opencontainers.image.title="founditure-backend"