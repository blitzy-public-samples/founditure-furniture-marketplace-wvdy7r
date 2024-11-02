# Founditure Android Application

## Human Tasks
- [ ] Update Android Studio to Arctic Fox or newer for Gradle 8.1.0 compatibility
- [ ] Configure local.properties with Android SDK path
- [ ] Set up signing keys for release builds
- [ ] Configure Firebase project and add google-services.json
- [ ] Review and adjust JVM memory settings in gradle.properties if needed

## Prerequisites
- Android Studio Arctic Fox or newer
- JDK 17
- Android SDK with minimum API 26 (Android 8.0)
- Kotlin 1.9+
- Gradle 8.1+

## Architecture
The application follows Clean Architecture principles with MVVM pattern:

### UI Layer (Presentation)
- Jetpack Compose for declarative UI
- Material Design 3 components
- ViewModel for UI state management
- Navigation Compose for routing

### Domain Layer
- Use cases for business logic
- Repository interfaces
- Domain models
- Business rules validation

### Data Layer
- Repository implementations
- Remote data sources (Retrofit)
- Local data sources (Room)
- Data mapping and caching

### Core Components
- Dependency Injection with Hilt
- Coroutines for asynchronous operations
- Flow for reactive streams
- StateFlow for UI state management

## Project Structure
```
app/
├── src/
│   ├── main/
│   │   ├── kotlin/com/founditure/android/
│   │   │   ├── presentation/
│   │   │   │   ├── components/
│   │   │   │   ├── theme/
│   │   │   │   ├── navigation/
│   │   │   │   └── screens/
│   │   │   ├── domain/
│   │   │   │   ├── model/
│   │   │   │   ├── repository/
│   │   │   │   └── usecase/
│   │   │   ├── data/
│   │   │   │   ├── remote/
│   │   │   │   ├── local/
│   │   │   │   └── repository/
│   │   │   ├── di/
│   │   │   └── utils/
│   │   ├── res/
│   │   └── AndroidManifest.xml
│   ├── test/
│   └── androidTest/
└── build.gradle
```

## Setup Instructions

1. Clone Repository
```bash
git clone [repository-url]
cd founditure-android
```

2. Configuration
- Copy `local.properties.example` to `local.properties`
- Set `sdk.dir` to your Android SDK path
- Add required API keys in `gradle.properties`

3. Build
```bash
./gradlew clean build
```

4. Run
- Open project in Android Studio
- Select device/emulator
- Click Run button or use `./gradlew installDebug`

5. Testing Setup
```bash
# Run unit tests
./gradlew test

# Run instrumented tests
./gradlew connectedAndroidTest
```

## Key Features

### Furniture Listing and Discovery
- Image capture and gallery selection
- Real-time furniture recognition
- Location-based search
- Filtering and sorting options

### Real-time Messaging
- WebSocket-based chat
- Push notifications
- Message persistence
- Typing indicators

### Location Services
- GPS integration
- Geofencing
- Address lookup
- Distance calculation

### Camera Integration
- CameraX API implementation
- Image processing
- ML Kit integration
- QR code scanning

### Points System
- Achievement tracking
- Reward distribution
- Leaderboard integration
- Points history

### Offline Support
- Room database caching
- WorkManager for background tasks
- Conflict resolution
- Data synchronization

## Development Guidelines

### Code Style
- Follow Kotlin coding conventions
- Use meaningful variable/function names
- Document complex logic
- Keep functions small and focused

### Git Workflow
1. Create feature branch from develop
2. Follow conventional commits
3. Submit PR for review
4. Squash merge after approval

### Testing Requirements
- Unit tests for business logic
- UI tests for critical flows
- Integration tests for repositories
- 80% minimum code coverage

### Documentation Standards
- KDoc for public APIs
- README for each module
- Architecture decision records
- API documentation

### Performance Considerations
- Lazy loading for lists
- Image caching and compression
- Background task optimization
- Memory leak prevention

## Testing

### Unit Testing
- JUnit for unit tests
- Mockito for mocking
- Turbine for Flow testing
- Coroutines test utilities

### UI Testing
- Compose testing API
- Screenshot testing
- Accessibility testing
- Performance testing

### Integration Testing
- Repository tests
- API integration tests
- Database migration tests
- End-to-end flows

### Code Coverage
- JaCoCo reports
- Coverage thresholds
- Excluded classes
- CI/CD integration

## Deployment

### Build Variants
- Debug: Development builds
- Release: Production builds
- Staging: Pre-production testing

### Release Process
1. Version bump
2. Changelog update
3. Release branch creation
4. QA validation
5. Store metadata update

### Play Store Deployment
1. Build signed APK/Bundle
2. Update store listing
3. Submit for review
4. Monitor rollout
5. User feedback analysis

### CI/CD Pipeline
- Automated builds
- Test execution
- Static analysis
- Deployment automation