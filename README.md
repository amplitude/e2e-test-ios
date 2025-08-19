# Amplitude iOS E2E Tests

End-to-end tests for Amplitude Remote Config SDK functionality on iOS platforms.

## Overview

This repository contains integration tests that validate the Amplitude Remote Config SDK's ability to fetch and cache configurations across Apple platforms. The test suite covers various configuration scenarios including default, modified, empty, nested, and complex valid configurations.

## GitHub Actions Workflow

The E2E tests run automatically via GitHub Actions in the following scenarios:

### Automatic Triggers
- **Push to main**: Tests run on every push to the main branch
- **Pull Requests**: Tests run for all pull requests

### Manual Trigger (from other workflows)
The workflow can be called from other repositories using `workflow_call`:

```yaml
jobs:
  test:
    uses: amplitude/e2e-test-ios/.github/workflows/remote-config-e2e-test-sdk.yml@main
    with:
      amplitude_core_ref: 'feature-branch'  # Optional: specify branch/tag/commit
    secrets:
      AMPLITUDE_API_KEY_DEFAULT: ${{ secrets.AMPLITUDE_API_KEY_DEFAULT }}
      AMPLITUDE_API_KEY_MODIFIED: ${{ secrets.AMPLITUDE_API_KEY_MODIFIED }}
```

### Required Secrets

Configure these in GitHub repository settings (Settings → Secrets and variables → Actions):
- `AMPLITUDE_API_KEY_DEFAULT`: API key for default configuration tests
- `AMPLITUDE_API_KEY_MODIFIED`: API key for modified configuration tests
- `AMPLITUDE_API_KEY_EMPTY`: API key for empty configuration tests
- `AMPLITUDE_API_KEY_NESTED`: API key for nested configuration tests
- `AMPLITUDE_API_KEY_VALID`: API key for valid configuration format tests

## Local Testing

Run tests locally with API keys:

```bash
# Run all tests
xcodebuild test \
  -scheme Amplitude-E2E-Test-Package \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  AMPLITUDE_API_KEY_DEFAULT="your-api-key" \
  AMPLITUDE_API_KEY_MODIFIED="your-modified-api-key" \
  AMPLITUDE_API_KEY_EMPTY="your-empty-api-key" \
  AMPLITUDE_API_KEY_NESTED="your-nested-api-key" \
  AMPLITUDE_API_KEY_VALID="your-valid-api-key"

# Run a specific test
xcodebuild test \
  -scheme Amplitude-E2E-Test-Package \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  -only-testing:CoreRemoteConfigSDKTests/CoreRemoteConfigSDKTests/testDefaultConfig \
  AMPLITUDE_API_KEY_DEFAULT="your-api-key"
```

## Test Coverage

The suite includes the following test scenarios:

1. **Default Config Test** (`testDefaultConfig`): Validates default remote configuration fetching
2. **Modified Config Test** (`testModifiedConfig`): Tests customized remote configuration with privacy and sampling settings
3. **Empty Config Test** (`testEmptyConfig`): Ensures proper handling of empty configurations
4. **Nested Config Test** (`testNestedConfig`): Validates deeply nested configuration structures
5. **Valid Config Test** (`testValidConfig`): Tests various valid configuration formats including:
   - Mixed numeric types (integers, doubles, large numbers)
   - Special characters and unicode in keys and values
   - Deep nesting structures
   - Mixed arrays with different data types
   - Special number formats

Each test validates:
- Remote configuration fetching with timeout handling
- Configuration structure matching expected values
- Cache functionality for offline access
- Timestamp tracking for fetched configurations

## Dependencies

- **AmplitudeCore-Swift**: Main SDK dependency (expects sibling directory `../AmplitudeCore-Swift`)
- **Platform Requirements**: iOS 14+, macOS 10.13+, tvOS 12+, watchOS 4+
- **Xcode**: 16.1 or later