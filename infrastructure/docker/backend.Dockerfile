# HUMAN TASKS:
# 1. Configure CI/CD pipeline to build with --platform=linux/amd64 for production deployments
# 2. Set up Docker BuildKit in build environment for improved build performance
# 3. Configure Docker layer caching in CI/CD pipeline
# 4. Ensure required environment variables are configured in Kubernetes secrets
# 5. Verify Docker registry credentials are configured for production deployments

# Stage 1: Build
# Requirement: Backend Runtime Environment (5.1 Programming Languages)
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Install build dependencies
# Requirement: Security Controls (7.3.3 Security Controls)
RUN apk add --no-cache python3 make g++ git

# Copy package files
COPY src/backend/package*.json ./

# Install dependencies with exact versions for reproducibility
# Dev dependencies needed for TypeScript compilation
RUN npm ci

# Copy source code and configs
COPY src/backend/tsconfig.json ./
COPY src/backend/src ./src

# Build TypeScript to JavaScript
# Requirement: Backend Runtime Environment (5.1 Programming Languages)
RUN npm run build

# Prune dev dependencies
RUN npm prune --production

# Stage 2: Production
# Requirement: Containerization (8.3 Containerization)
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Set production environment
ENV NODE_ENV=production \
    PORT=3000

# Install production-only dependencies
RUN apk add --no-cache tini

# Copy production files from builder
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY src/backend/package*.json ./

# Set non-root user for security
# Requirement: Security Controls (7.3.3 Security Controls)
USER node

# Expose application port
EXPOSE 3000

# Configure health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Start application
# Requirement: Backend Runtime Environment (5.1 Programming Languages)
CMD ["node", "dist/server.js"]

# Apply security labels
LABEL org.opencontainers.image.title="founditure-backend" \
      org.opencontainers.image.description="Founditure backend service" \
      org.opencontainers.image.vendor="Founditure" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.url="https://github.com/founditure/backend" \
      org.opencontainers.image.licenses="MIT"