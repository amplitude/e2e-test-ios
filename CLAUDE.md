# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS E2E (End-to-End) test suite for the Amplitude Remote Config SDK functionality. The project tests remote configuration fetching and caching capabilities across multiple Apple platforms (iOS, macOS, tvOS, watchOS, visionOS).

## Architecture

The codebase follows a simple test-focused structure:
- **Package.swift**: Defines the Swift package with dependency on AmplitudeCore-Swift (located in a sibling directory)
- **Tests/CoreRemoteConfigSDKTests**: Contains XCTest-based integration tests that validate remote config behavior
- **.swiftpm/Amplitude-E2E-Test-Package.xctestplan**: Test plan configuration that maps environment variables for API keys
- **GitHub Actions**: CI/CD workflow for running tests across different platforms and Xcode versions

### Key Implementation Details

- API keys are passed as environment variables (not hardcoded) for security
- The workflow passes secrets directly to xcodebuild commands rather than using `env:` block
- The test scheme is `Amplitude-E2E-Test-Package` (not CoreRemoteConfigSDKTests)

## Key Commands

### Running Tests

```bash
# Run tests for iOS Simulator (Note: Use Amplitude-E2E-Test-Package scheme)
xcodebuild test \
  -scheme Amplitude-E2E-Test-Package \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  -enableCodeCoverage NO \
  -parallel-testing-enabled NO \
  AMPLITUDE_API_KEY_DEFAULT="your-api-key" \
  AMPLITUDE_API_KEY_MODIFIED="your-modified-api-key"

# Run tests for macOS
xcodebuild test \
  -scheme Amplitude-E2E-Test-Package \
  -sdk macosx \
  -destination 'platform=macOS' \
  -enableCodeCoverage NO \
  -parallel-testing-enabled NO \
  AMPLITUDE_API_KEY_DEFAULT="your-api-key" \
  AMPLITUDE_API_KEY_MODIFIED="your-modified-api-key"

# Run tests for specific test case
xcodebuild test \
  -scheme Amplitude-E2E-Test-Package \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  -only-testing:CoreRemoteConfigSDKTests/CoreRemoteConfigSDKTests/testDefaultConfig \
  AMPLITUDE_API_KEY_DEFAULT="your-api-key" \
  AMPLITUDE_API_KEY_MODIFIED="your-modified-api-key"
```

### Building

```bash
# Build the test target
swift build --target CoreRemoteConfigSDKTests

# Clean build artifacts
swift package clean
```

## Test Structure

The tests validate multiple scenarios:
1. **Default Config Test** (`testDefaultConfig`): Uses API key from `AMPLITUDE_API_KEY_DEFAULT` environment variable to fetch default remote configuration
2. **Modified Config Test** (`testModifiedConfig`): Uses API key from `AMPLITUDE_API_KEY_MODIFIED` environment variable to fetch customized remote configuration  
3. **Empty Config Test** (`testEmptyConfig`): Tests handling of empty configurations using `AMPLITUDE_API_KEY_EMPTY`
4. **Nested Config Test** (`testNestedConfig`): Tests deeply nested configuration structures using `AMPLITUDE_API_KEY_NESTED`
5. **Valid Config Test** (`testValidConfig`): Tests various valid configuration formats including unicode, mixed types, and special characters using `AMPLITUDE_API_KEY_VALID`

### Environment Variables

The tests require API keys to be provided as environment variables:
- `AMPLITUDE_API_KEY_DEFAULT`: API key for testing default remote configuration
- `AMPLITUDE_API_KEY_MODIFIED`: API key for testing modified remote configuration
- `AMPLITUDE_API_KEY_EMPTY`: API key for testing empty configurations
- `AMPLITUDE_API_KEY_NESTED`: API key for testing nested configurations
- `AMPLITUDE_API_KEY_VALID`: API key for testing various valid configuration formats

These can be provided either:
1. As environment variables (using `export`)
2. Directly in the xcodebuild command (as shown in the examples above)
3. Through the test plan configuration (`.swiftpm/Amplitude-E2E-Test-Package.xctestplan`)

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
- Push to `main` branch
- Pull requests
- Manual workflow dispatch (workflow_call) with optional parameters:
  - `is_workflow_call`: Indicates if invoked from another workflow (default: true)
  - `amplitude_core_ref`: AmplitudeCore-Swift branch, tag, or commit to test (default: 'main')

### Required GitHub Secrets

The following secrets must be configured in the GitHub repository settings:
- `AMPLITUDE_API_KEY_DEFAULT`: API key for the default configuration test
- `AMPLITUDE_API_KEY_MODIFIED`: API key for the modified configuration test
- `AMPLITUDE_API_KEY_EMPTY`: API key for the empty configuration test
- `AMPLITUDE_API_KEY_NESTED`: API key for the nested configuration test
- `AMPLITUDE_API_KEY_VALID`: API key for the valid configuration test