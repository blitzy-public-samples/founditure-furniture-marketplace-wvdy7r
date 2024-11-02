# Founditure Backend Service

## Overview

The Founditure backend service is a distributed cloud-based infrastructure that powers the urban furniture recovery platform. Built with Node.js and TypeScript, it provides a scalable, secure, and real-time backend system for managing furniture listings, user interactions, and AI-powered image processing.

## 🔧 Technology Stack

- **Runtime:** Node.js 18 LTS
- **Language:** TypeScript 5.0+
- **Framework:** Express.js 4.18.2
- **Databases:**
  - PostgreSQL 14 (Primary data store)
  - Redis 6 (Caching & sessions)
  - Elasticsearch 7.17 (Search engine)
  - MongoDB 5 (Document storage)
- **Message Brokers:**
  - MQTT 4.3.7 (Real-time events)
  - Socket.IO 4.6.2 (WebSocket)
- **Cloud Services:**
  - AWS S3 & CloudFront (Media storage & CDN)
- **AI/ML:**
  - TensorFlow Serving (Model inference)

## 🚀 Getting Started

### Prerequisites

- Node.js >= 18.0.0
- npm >= 9.0.0
- Docker & Docker Compose
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/founditure/backend.git
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Start development environment:
```bash
docker-compose up -d
```

5. Run database migrations:
```bash
npm run migrate
```

6. Start the development server:
```bash
npm run dev
```

## 🏗️ Architecture

### Service Components

- **API Gateway:** Entry point for client requests
- **Authentication Service:** User authentication and authorization
- **Furniture Service:** Listing management and metadata
- **Messaging Service:** Real-time communication
- **Points Service:** Gamification and rewards
- **Location Service:** Geospatial operations
- **AI Service:** Image processing and classification
- **Search Service:** Full-text and geospatial search
- **Storage Service:** Media file management

### Data Models

- Users
- Furniture Listings
- Messages
- Points & Achievements
- Locations
- Media Assets

### API Endpoints

Base URL: `/api/v1`

#### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `POST /auth/refresh` - Token refresh
- `POST /auth/logout` - User logout

#### Furniture
- `GET /furniture` - List furniture
- `POST /furniture` - Create listing
- `GET /furniture/:id` - Get details
- `PUT /furniture/:id` - Update listing
- `DELETE /furniture/:id` - Remove listing

#### Messages
- `GET /messages` - List conversations
- `POST /messages` - Send message
- `GET /messages/:id` - Get conversation
- `DELETE /messages/:id` - Delete conversation

#### Points
- `GET /points` - Get user points
- `GET /points/leaderboard` - Get leaderboard
- `POST /points/redeem` - Redeem points

## 💻 Development

### Local Setup

1. Install development tools:
```bash
npm install -g typescript ts-node nodemon
```

2. Start development services:
```bash
docker-compose up -d postgres redis elasticsearch mosquitto
```

3. Run in development mode:
```bash
npm run dev
```

### Code Structure

```
src/
├── app.ts              # Application setup
├── server.ts           # Server entry point
├── config/            # Configuration files
├── controllers/       # Request handlers
├── middleware/        # Custom middleware
├── models/           # Data models
├── routes/           # API routes
├── services/         # Business logic
├── utils/            # Utility functions
├── validators/       # Input validation
└── websocket/        # WebSocket handlers
```

### Testing

```bash
# Run unit tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific tests
npm test -- path/to/test
```

### Code Quality

```bash
# Type checking
npm run typecheck

# Linting
npm run lint

# Format code
npm run format
```

## 🚢 Deployment

### Build Process

1. Build the application:
```bash
npm run build
```

2. Build Docker image:
```bash
docker build -t founditure/backend .
```

### Container Deployment

1. Configure environment variables:
```bash
# Production environment variables
NODE_ENV=production
PORT=3000
DB_HOST=postgres
REDIS_HOST=redis
```

2. Deploy using Docker Compose:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Monitoring Setup

- Prometheus metrics: `:9090/metrics`
- Grafana dashboards: `:3001`
- Health check endpoint: `/health`

## 🔍 API Documentation

### Authentication

All API requests must include:
```
Authorization: Bearer <token>
```

### Request/Response Format

```json
{
  "status": "success",
  "data": {
    "id": "uuid",
    "type": "furniture",
    "attributes": {},
    "relationships": {}
  }
}
```

### Error Handling

```json
{
  "status": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input"
  }
}
```

## 🛠️ Troubleshooting

### Database Connection

1. Check PostgreSQL container:
```bash
docker-compose ps postgres
docker-compose logs postgres
```

2. Verify credentials:
```bash
psql -h localhost -U founditure -d founditure
```

### Redis Cache

1. Check Redis connection:
```bash
docker-compose exec redis redis-cli ping
```

2. Monitor Redis:
```bash
docker-compose exec redis redis-cli monitor
```

### API Errors

1. Check logs:
```bash
docker-compose logs -f api
```

2. Verify environment:
```bash
docker-compose exec api printenv
```

## 📚 References

- [Technical Specification](../docs/technical-spec.md)
- [API Documentation](../docs/api-spec.md)
- [Deployment Guide](../docs/deployment.md)

## 📄 License

MIT License - see [LICENSE](LICENSE) for details