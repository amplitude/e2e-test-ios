//
//  CoreRemoteConfigSDKTests.swift
//  CoreRemoteConfigSDKTests
//
//  Created by Jin Xu on 8/7/25.
//

import AmplitudeCore
import XCTest

final class CoreRemoteConfigSDKTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testDefaultConfig() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY_DEFAULT"] else {
            XCTFail("AMPLITUDE_API_KEY_DEFAULT environment variable not set")
            return
        }
        let expectedConfig: RemoteConfigClient.RemoteConfig = [
            "analyticsSDK": [String:Any](),
            "sessionReplay": [
                "sr_ios_privacy_config": [
                    "defaultMaskLevel": "medium",
                    "blockSelector": [],
                    "maskSelector": [],
                    "unmaskSelector": []
                ],
                "sr_ios_sampling_config": [
                    "capture_enabled": true
                ]
            ]
        ]

        try await validateConfig(apiKey: apiKey, expectedConfig: expectedConfig)
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testModifiedConfig() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY_MODIFIED"] else {
            XCTFail("AMPLITUDE_API_KEY_MODIFIED environment variable not set")
            return
        }
        let expectedConfig: RemoteConfigClient.RemoteConfig = [
            "analyticsSDK": [String:Any](),
            "sessionReplay": [
                "sr_ios_privacy_config": [
                    "defaultMaskLevel": "light",
                    "blockSelector": ["video"],
                    "maskSelector": ["a", "[contenteditable=\"true\" i]", "[data-amp-default-track]", ".blue"],
                    "unmaskSelector": ["button"]
                ],
                "sr_ios_sampling_config": [
                    "capture_enabled": true,
                    "sample_rate": 1
                ]
            ]
        ]

        try await validateConfig(apiKey: apiKey, expectedConfig: expectedConfig)
    }

    func validateConfig(apiKey: String, expectedConfig: RemoteConfigClient.RemoteConfig) async throws {
        let expectedCachedConfigLastFetch = Date.distantPast

        let context = AmplitudeContext(apiKey: apiKey)

        let didUpdateConfigExpectation = XCTestExpectation(description: "it did request config")
        didUpdateConfigExpectation.assertForOverFulfill = true
        didUpdateConfigExpectation.expectedFulfillmentCount = 1

        print("🔵 Setting up subscription...")
        context.remoteConfigClient.subscribe(deliveryMode: .waitForRemote(timeout: 10)) { config, source, lastFetch in
            print("🟢 Subscription callback triggered:")
            print("   - Source: \(source)")
            print("   - Last fetch: \(String(describing: lastFetch))")
            print("   - Config keys: \(String(describing: config?.keys))")

            XCTAssertEqual(source, .remote)
            print("🟢 Remote config received, comparing with expected...")

            // Debug: Print both configs for comparison
            print("   - Received config: \(String(describing: config))")
            print("   - Expected config: \(expectedConfig)")
            XCTAssertEqual(config as? NSDictionary, expectedConfig as NSDictionary, "Remote config doesn't match expected")
            XCTAssertNotEqual(lastFetch, expectedCachedConfigLastFetch, "Last fetch date should be updated")

            didUpdateConfigExpectation.fulfill()
        }
        print("🔵 Subscription set up, waiting for fulfillment...")
        await fulfillment(of: [didUpdateConfigExpectation], timeout: 10)

        let cachedContext = AmplitudeContext(apiKey: apiKey)

        let didCachedConfigExpectation = XCTestExpectation(description: "it did request config")
        didCachedConfigExpectation.assertForOverFulfill = true
        didCachedConfigExpectation.expectedFulfillmentCount = 1

        cachedContext.remoteConfigClient.subscribe() { config, source, lastFetch in
            print("🟢 Subscription callback triggered:")
            print("   - Source: \(source)")
            print("   - Last fetch: \(String(describing: lastFetch))")
            print("   - Config keys: \(String(describing: config?.keys))")

            if source == .cache {
                print("🟢 Cached config fetched, comparing with expected...")

                // Debug: Print both configs for comparison
                print("   - Cached config: \(String(describing: config))")
                print("   - Expected config: \(expectedConfig)")
                XCTAssertEqual(config as? NSDictionary, expectedConfig as NSDictionary, "Remote config doesn't match expected")
                XCTAssertNotEqual(lastFetch, expectedCachedConfigLastFetch, "Last fetch date should be updated")

                didCachedConfigExpectation.fulfill()
            }
        }

        print("🔵 Subscription set up, waiting for fulfillment...")
        await fulfillment(of: [didCachedConfigExpectation], timeout: 10)
        print("✅ TEST PASSED: Expectation fulfilled")
    }
}
