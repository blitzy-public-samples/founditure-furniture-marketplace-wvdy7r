#!/bin/bash

# HUMAN TASKS:
# 1. Configure SonarQube server URL and authentication token in Jenkins
# 2. Set up test report collection paths in Jenkins job configuration
# 3. Configure code coverage thresholds in quality gates
# 4. Ensure iOS simulator and Android emulator are available on build agents
# 5. Set up test environment variables in Jenkins credentials store
# 6. Configure test database access credentials
# 7. Set up test artifact archival paths

# Exit on any error
set -e

# Import build functions
source "$(dirname "$0")/build.sh"

# Global variables from specification
readonly TEST_REPORTS_DIR="./test-reports"
readonly COVERAGE_THRESHOLD=80
readonly MAX_RETRIES=3

# Requirement: CI/CD Pipeline Testing (8. Infrastructure/8.5 CI/CD Pipeline/Pipeline Stages)
run_backend_tests() {
    local environment="$1"
    echo "Running backend tests for environment: $environment"
    
    cd src/backend
    
    # Create test reports directory
    mkdir -p "${TEST_REPORTS_DIR}"
    
    # Install dependencies
    npm ci
    
    # Run Jest unit tests with coverage
    jest \
        --config jest.config.js \
        --coverage \
        --coverageDirectory="${TEST_REPORTS_DIR}/coverage" \
        --ci \
        --reporters=default \
        --reporters=jest-junit \
        --testResultsProcessor=jest-sonar-reporter
    
    # Run integration tests
    npm run test:integration
    
    # Validate coverage thresholds
    if [[ $(jq '.total.lines.pct' "${TEST_REPORTS_DIR}/coverage/coverage-summary.json") -lt ${COVERAGE_THRESHOLD} ]]; then
        echo "Coverage threshold not met"
        return 1
    fi
    
    # Archive test results
    tar -czf "${TEST_REPORTS_DIR}/backend-test-results.tar.gz" "${TEST_REPORTS_DIR}"
    
    cd ../..
    return $?
}

# Requirement: Test Automation (8. Infrastructure/8.5 CI/CD Pipeline/Automation Matrix)
run_ios_tests() {
    local scheme="$1"
    local configuration="$2"
    echo "Running iOS tests for scheme: $scheme, configuration: $configuration"
    
    cd src/ios
    
    # Install dependencies
    pod install
    
    # Clean build directory
    xcodebuild clean \
        -workspace Founditure.xcworkspace \
        -scheme "$scheme" \
        -configuration "$configuration"
    
    # Run XCTest suite
    xcodebuild test \
        -workspace Founditure.xcworkspace \
        -scheme "$scheme" \
        -configuration "$configuration" \
        -destination 'platform=iOS Simulator,name=iPhone 14' \
        -enableCodeCoverage YES \
        -resultBundlePath "${TEST_REPORTS_DIR}/ios-test-results"
    
    # Run UI tests
    xcodebuild test \
        -workspace Founditure.xcworkspace \
        -scheme "${scheme}UITests" \
        -configuration "$configuration" \
        -destination 'platform=iOS Simulator,name=iPhone 14' \
        -resultBundlePath "${TEST_REPORTS_DIR}/ios-uitest-results"
    
    # Generate test reports
    xcrun xccov view --report --json "${TEST_REPORTS_DIR}/ios-test-results.xcresult" > "${TEST_REPORTS_DIR}/ios-coverage.json"
    
    # Export test artifacts
    mv "${TEST_REPORTS_DIR}" ../..
    
    cd ../..
    return $?
}

# Requirement: Test Automation (8. Infrastructure/8.5 CI/CD Pipeline/Automation Matrix)
run_android_tests() {
    local buildVariant="$1"
    echo "Running Android tests for build variant: $buildVariant"
    
    cd src/android
    
    # Set up Android SDK environment
    export ANDROID_HOME="${ANDROID_SDK_ROOT}"
    export PATH="${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${PATH}"
    
    # Clean build directory
    ./gradlew clean
    
    # Run unit tests with JUnit
    ./gradlew test${buildVariant^}UnitTest \
        -Pandroid.testInstrumentationRunnerArguments.class=com.founditure.android.UnitTestSuite
    
    # Execute UI tests with Espresso
    ./gradlew connected${buildVariant^}AndroidTest \
        -Pandroid.testInstrumentationRunnerArguments.class=com.founditure.android.UITestSuite
    
    # Generate test reports
    ./gradlew jacocoTestReport
    
    # Export test artifacts
    mkdir -p "${TEST_REPORTS_DIR}/android"
    cp -r app/build/reports/* "${TEST_REPORTS_DIR}/android/"
    mv "${TEST_REPORTS_DIR}" ../..
    
    cd ../..
    return $?
}

# Requirement: Security Testing (7. Security Considerations/7.3.3 Security Controls)
run_security_scan() {
    local source_dir="$1"
    echo "Running security scan for directory: $source_dir"
    
    # Initialize SonarQube scanner
    sonar-scanner \
        -Dsonar.projectKey=founditure \
        -Dsonar.sources="$source_dir" \
        -Dsonar.host.url="${SONAR_HOST_URL}" \
        -Dsonar.login="${SONAR_TOKEN}" \
        -Dsonar.javascript.lcov.reportPaths="${TEST_REPORTS_DIR}/coverage/lcov.info" \
        -Dsonar.coverage.exclusions="**/*.test.ts,**/*.spec.ts,**/test/**" \
        -Dsonar.tests="src/test" \
        -Dsonar.test.inclusions="**/*.test.ts,**/*.spec.ts"
    
    # Run code quality analysis
    sonar-scanner-run
    
    # Execute vulnerability scan
    npm audit --json > "${TEST_REPORTS_DIR}/npm-audit.json"
    
    # Generate security reports
    sonar-scanner-report
    
    # Check quality gates
    if ! sonar-quality-gate-check; then
        echo "Quality gate failed"
        return 1
    fi
    
    # Export scan results
    cp .scannerwork/report-task.txt "${TEST_REPORTS_DIR}/"
    return $?
}

# Requirement: Test Automation (8. Infrastructure/8.5 CI/CD Pipeline/Automation Matrix)
check_test_results() {
    local reports_dir="$1"
    echo "Validating test results in directory: $reports_dir"
    
    # Parse test result files
    local backend_tests_passed=false
    local ios_tests_passed=false
    local android_tests_passed=false
    local security_scan_passed=false
    
    # Check backend test results
    if [ -f "${reports_dir}/junit.xml" ]; then
        if grep -q "failures=\"0\"" "${reports_dir}/junit.xml"; then
            backend_tests_passed=true
        fi
    fi
    
    # Check iOS test results
    if [ -f "${reports_dir}/ios-test-results.xcresult/Info.plist" ]; then
        if ! grep -q "failureCount" "${reports_dir}/ios-test-results.xcresult/Info.plist"; then
            ios_tests_passed=true
        fi
    fi
    
    # Check Android test results
    if [ -f "${reports_dir}/android/tests/testDebugUnitTest/index.html" ]; then
        if ! grep -q "failure" "${reports_dir}/android/tests/testDebugUnitTest/index.html"; then
            android_tests_passed=true
        fi
    fi
    
    # Check security scan results
    if [ -f "${reports_dir}/report-task.txt" ]; then
        if grep -q "status=OK" "${reports_dir}/report-task.txt"; then
            security_scan_passed=true
        fi
    fi
    
    # Generate summary report
    cat << EOF > "${reports_dir}/test-summary.txt"
Test Summary Report
------------------
Backend Tests: $([ "$backend_tests_passed" = true ] && echo "PASSED" || echo "FAILED")
iOS Tests: $([ "$ios_tests_passed" = true ] && echo "PASSED" || echo "FAILED")
Android Tests: $([ "$android_tests_passed" = true ] && echo "PASSED" || echo "FAILED")
Security Scan: $([ "$security_scan_passed" = true ] && echo "PASSED" || echo "FAILED")
EOF
    
    # Archive results
    tar -czf "${reports_dir}/all-test-results.tar.gz" "${reports_dir}"
    
    # Return overall status
    if [ "$backend_tests_passed" = true ] && \
       [ "$ios_tests_passed" = true ] && \
       [ "$android_tests_passed" = true ] && \
       [ "$security_scan_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# Main test execution function
main() {
    echo "Starting test execution"
    
    # Create test reports directory
    mkdir -p "${TEST_REPORTS_DIR}"
    
    # Run backend tests
    if ! run_backend_tests "$BUILD_ENV"; then
        echo "Backend tests failed"
        exit 1
    fi
    
    # Run mobile tests in parallel
    run_ios_tests "Founditure" "Debug" &
    run_android_tests "debug" &
    wait
    
    # Run security scan
    if ! run_security_scan "src"; then
        echo "Security scan failed"
        exit 1
    fi
    
    # Check all test results
    if ! check_test_results "${TEST_REPORTS_DIR}"; then
        echo "Test validation failed"
        exit 1
    fi
    
    echo "All tests completed successfully"
    exit 0
}

# Execute main function
main