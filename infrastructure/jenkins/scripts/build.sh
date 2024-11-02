#!/bin/bash

# HUMAN TASKS:
# 1. Configure AWS credentials in Jenkins credentials store
# 2. Set up iOS signing certificates and provisioning profiles in Jenkins
# 3. Configure Android signing keystore in Jenkins credentials
# 4. Set up Docker registry credentials for ECR access
# 5. Configure Gradle and CocoaPods caching for faster builds
# 6. Verify Xcode version 14.x is installed on build agents
# 7. Ensure Node.js 18.x is configured in build environment

# Exit on any error
set -e

# Required external tools versions
# Requirement: Technology Stack (5.1 Programming Languages)
readonly REQUIRED_NODE_VERSION="18.x"
readonly REQUIRED_XCODE_VERSION="14.x"
readonly REQUIRED_GRADLE_VERSION="7.x"
readonly REQUIRED_DOCKER_VERSION="20.x"
readonly REQUIRED_AWS_CLI_VERSION="2.x"

# Global variables from specification
DOCKER_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
BUILD_ENV="${BUILD_ENV:-dev}"
IMAGE_TAG="${BUILD_NUMBER:-latest}"

# Requirement: CI/CD Pipeline Build Stage (8.5 CI/CD Pipeline)
build_backend() {
    local environment="$1"
    echo "Building backend services for environment: $environment"
    
    cd src/backend
    
    # Install dependencies with exact versions
    npm ci
    
    # Run TypeScript type checking
    npm run typecheck
    
    # Run linting
    npm run lint
    
    # Run unit tests
    npm run test
    
    # Build TypeScript to JavaScript
    npm run build
    
    # Return to root directory
    cd ../..
    
    return $?
}

# Requirement: Technology Stack Builds (5.1 Programming Languages)
build_ios_app() {
    local configuration="$1"
    echo "Building iOS application with configuration: $configuration"
    
    cd src/ios
    
    # Install CocoaPods dependencies
    pod install
    
    # Build and archive iOS app
    xcodebuild \
        -workspace Founditure.xcworkspace \
        -scheme Founditure \
        -configuration "$configuration" \
        -archivePath build/Founditure.xcarchive \
        clean archive
    
    # Export IPA
    xcodebuild \
        -exportArchive \
        -archivePath build/Founditure.xcarchive \
        -exportOptionsPlist exportOptions.plist \
        -exportPath build/
    
    cd ../..
    
    return $?
}

# Requirement: Technology Stack Builds (5.1 Programming Languages)
build_android_app() {
    local buildType="$1"
    echo "Building Android application with build type: $buildType"
    
    cd src/android
    
    # Clean build directory
    ./gradlew clean
    
    # Build Android app
    ./gradlew "assemble${buildType}" \
        -Dorg.gradle.daemon=false \
        -Dorg.gradle.parallel=true \
        -Dorg.gradle.jvmargs="-Xmx4g -XX:MaxPermSize=2048m"
    
    # Sign APK/AAB if in release mode
    if [ "$buildType" = "Release" ]; then
        ./gradlew "sign${buildType}Bundle" \
            -Pandroid.injected.signing.store.file="$ANDROID_KEYSTORE_PATH" \
            -Pandroid.injected.signing.store.password="$ANDROID_KEYSTORE_PASSWORD" \
            -Pandroid.injected.signing.key.alias="$ANDROID_KEY_ALIAS" \
            -Pandroid.injected.signing.key.password="$ANDROID_KEY_PASSWORD"
    fi
    
    cd ../..
    
    return $?
}

# Requirement: Containerization (8.3 Containerization)
build_docker_images() {
    local service_name="$1"
    local image_tag="$2"
    echo "Building Docker image for service: $service_name with tag: $image_tag"
    
    # Authenticate with AWS ECR
    aws ecr get-login-password --region "${AWS_REGION}" | \
        docker login --username AWS --password-stdin "${DOCKER_REGISTRY}"
    
    # Build optimized Docker image
    DOCKER_BUILDKIT=1 docker build \
        --platform=linux/amd64 \
        --build-arg BUILD_ENV="${BUILD_ENV}" \
        --build-arg NODE_ENV=production \
        --cache-from "${DOCKER_REGISTRY}/${service_name}:latest" \
        --tag "${DOCKER_REGISTRY}/${service_name}:${image_tag}" \
        --tag "${DOCKER_REGISTRY}/${service_name}:latest" \
        --file "infrastructure/docker/${service_name}.Dockerfile" \
        .
    
    # Push images to ECR
    docker push "${DOCKER_REGISTRY}/${service_name}:${image_tag}"
    docker push "${DOCKER_REGISTRY}/${service_name}:latest"
    
    # Clean up local images
    docker rmi "${DOCKER_REGISTRY}/${service_name}:${image_tag}"
    docker rmi "${DOCKER_REGISTRY}/${service_name}:latest"
    
    return $?
}

# Requirement: CI/CD Pipeline Build Stage (8.5 CI/CD Pipeline)
main() {
    echo "Starting build process for environment: $BUILD_ENV"
    
    # Build backend services
    build_backend "$BUILD_ENV"
    local backend_status=$?
    
    # Build mobile applications in parallel
    build_ios_app "Release" &
    build_android_app "Release" &
    wait
    local mobile_status=$?
    
    # Build and push Docker images
    build_docker_images "backend" "$IMAGE_TAG"
    local docker_status=$?
    
    # Generate build reports
    echo "Build Report" > build-report.txt
    echo "Environment: $BUILD_ENV" >> build-report.txt
    echo "Backend Build Status: $backend_status" >> build-report.txt
    echo "Mobile Build Status: $mobile_status" >> build-report.txt
    echo "Docker Build Status: $docker_status" >> build-report.txt
    
    # Exit with overall status
    if [ $backend_status -eq 0 ] && [ $mobile_status -eq 0 ] && [ $docker_status -eq 0 ]; then
        echo "Build completed successfully"
        exit 0
    else
        echo "Build failed"
        exit 1
    fi
}

# Execute main function
main