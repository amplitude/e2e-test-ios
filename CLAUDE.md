# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS E2E (End-to-End) test suite for the Amplitude Remote Config SDK functionality. The project tests remote configuration fetching and caching capabilities across multiple Apple platforms (iOS, macOS, tvOS, watchOS, visionOS).

## Architecture

The codebase follows a simple test-focused structure:
- **Package.swift**: Defines the Swift package with dependency on AmplitudeCore-Swift (located in a sibling directory)
- **Tests/CoreRemoteConfigSDKTests**: Contains XCTest-based integration tests that validate remote config behavior
- **GitHub Actions**: CI/CD workflow for running tests across different platforms and Xcode versions

## Key Commands

### Running Tests

```bash
# Run tests for iOS Simulator
xcodebuild test \
  -scheme CoreRemoteConfigSDKTests \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  -enableCodeCoverage NO \
  -parallel-testing-enabled NO

# Run tests for macOS
xcodebuild test \
  -scheme CoreRemoteConfigSDKTests \
  -sdk macosx \
  -destination 'platform=macOS' \
  -enableCodeCoverage NO \
  -parallel-testing-enabled NO

# Run tests for specific test case
xcodebuild test \
  -scheme CoreRemoteConfigSDKTests \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  -only-testing:CoreRemoteConfigSDKTests/CoreRemoteConfigSDKTests/testDefaultConfig
```

### Building

```bash
# Build the test target
swift build --target CoreRemoteConfigSDKTests

# Clean build artifacts
swift package clean
```

## Test Structure

The tests validate two key scenarios:
1. **Default Config Test** (`testDefaultConfig`): Uses API key from `AMPLITUDE_API_KEY_DEFAULT` environment variable to fetch default remote configuration
2. **Modified Config Test** (`testModifiedConfig`): Uses API key from `AMPLITUDE_API_KEY_MODIFIED` environment variable to fetch customized remote configuration

### Local Testing with API Keys

To run tests locally, export the required environment variables:
```bash
export AMPLITUDE_API_KEY_DEFAULT="your-default-api-key"
export AMPLITUDE_API_KEY_MODIFIED="your-modified-api-key"
```

Each test validates:
- Remote config fetching with timeout
- Config structure matching expected values
- Cache functionality for subsequent fetches
- Last fetch timestamp updates

## Dependencies

- **AmplitudeCore-Swift**: Located at `../AmplitudeCore-Swift` relative to this project
- Minimum Swift version: 5.7
- Platform requirements: iOS 14+, macOS 10.13+, tvOS 12+, watchOS 4+

## CI/CD

GitHub Actions workflow (`remote-config-e2e-test-sdk.yml`) runs tests on:
- macOS 15 runner
- Xcode 16.1
- Multiple platform simulators (currently only iOS enabled, others commented out for development)

The workflow can be triggered via:
- Pull requests
- Manual workflow dispatch with optional `amplitude_core_ref` parameter to test specific AmplitudeCore-Swift branches

### Required GitHub Secrets

The following secrets must be configured in the GitHub repository settings:
- `AMPLITUDE_API_KEY_DEFAULT`: API key for the default configuration test
- `AMPLITUDE_API_KEY_MODIFIED`: API key for the modified configuration test