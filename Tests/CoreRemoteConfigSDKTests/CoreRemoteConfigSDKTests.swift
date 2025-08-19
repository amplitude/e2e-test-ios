//
//  CoreRemoteConfigSDKTests.swift
//  CoreRemoteConfigSDKTests
//
//  Created by Jin Xu on 8/7/25.
//

import AmplitudeCore
import XCTest

enum Validation {
    case wholeConfig(RemoteConfigClient.RemoteConfig)
    case iosSDKConfig([String: Sendable])
    case iosSDKPartialConfigs([String: Sendable])

    func validate(config: RemoteConfigClient.RemoteConfig?) {
        guard let config = config else {
            XCTFail("Remote config is nil")
            return
        }

        switch self {
        case .wholeConfig(let expectedConfig):
            XCTAssertEqual(config as NSDictionary, expectedConfig as NSDictionary, "Remote config does not match expected")
        case .iosSDKConfig(let expectedConfig):
            guard let analyticsSDK = config["analyticsSDK"] as? [String: Any] else {
                XCTFail("analyticsSDK is not set")
                return
            }

            guard let iosSDK = analyticsSDK["iosSDK"] as? [String: Any] else {
                XCTFail("iosSDK is not set")
                return
            }

            XCTAssertEqual(iosSDK as? NSDictionary, expectedConfig as NSDictionary, "Remote config of iosSDK does not match expected")
        case .iosSDKPartialConfigs(let expectedConfigs):
            guard let analyticsSDK = config["analyticsSDK"] as? [String: Any] else {
                XCTFail("analyticsSDK is not set")
                return
            }

            guard let iosSDK = analyticsSDK["iosSDK"] as? [String: Any] else {
                XCTFail("iosSDK is not set")
                return
            }

            for (key, expectedValue) in expectedConfigs {
                let subconfig = iosSDK[key]
                let expectedSubconfig = expectedValue
                XCTAssertEqual(subconfig as? NSDictionary, expectedSubconfig as? NSDictionary, "Remote config of \(key) does not match expected")
            }
        }
    }
}

final class CoreRemoteConfigSDKTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removePersistentDomain(forName: "com.amplitude.remoteconfig.cache.$default_instance")
        UserDefaults.standard.synchronize()
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

        try await validateConfig(apiKey: apiKey, expectedValidation: .wholeConfig(expectedConfig))
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

        try await validateConfig(apiKey: apiKey, expectedValidation: .wholeConfig(expectedConfig))
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testEmptyConfig() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY_EMPTY"] else {
            XCTFail("AMPLITUDE_API_KEY_EMPTY environment variable not set")
            return
        }

        try await validateConfig(apiKey: apiKey, expectedValidation: .iosSDKConfig([:]))
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testNestedConfig() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY_NESTED"] else {
            XCTFail("AMPLITUDE_API_KEY_NESTED environment variable not set")
            return
        }
        
        let nested: [String: Any] = [
            "user": [
                "id": 123,
                "name": "Alice",
                "profile": [
                    "age": 30,
                    "languages": ["Swift", "Objective-C", "Klingon"],
                ]
            ],
            "active": true,
        ]
        try await validateConfig(apiKey: apiKey, expectedValidation: .iosSDKConfig(nested))
    }

    func testValidConfig() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY_VALID"] else {
            XCTFail("AMPLITUDE_API_KEY_VALID environment variable not set")
            return
        }

        // Mixed numeric types
        let mixedNumbers: [String: Any] = [
            "int": 42,
            "double": 3.14159,
            "big": 9_223_372_036_854_775_807 // Int64.max
        ]

        // Weird keys
        let weirdKeys: [String: Any] = [
            " spaces ": "value",
            "emoji😊": "smile",
            "quotes\"inside": "escaped",
            "backslash\\": "slash",
            // "null\0char": "nullbyte",  \0 in key is not allowed for remote config upsert api
        ]

        // Deep nesting
        let deepNest: [String: Any] = [
            "level1": [
                "level2": [
                    "level3": [
                        "level4": [
                            "value": "bottom",
                        ]
                    ]
                ]
            ]
        ]

        // Mixed arrays
        let mixedArray: [String: Any] = [
            "array": [1, "two", ["three": 3], true]
        ]

        // Unicode stress
        let unicode: [String: Any] = [
            "japanese": "こんにちは",
            "arabic": "مرحبا",
            "combining": "e\u{0301}", // é as e + accent
            "rightToLeft": "\u{202E}txet", // RTL override
        ]

        // Special number formats
        let numbersAsStrings: [String: Any] = [
            "hexString": "0x1A",
            "expNotation": 1.2e+10,
            "negativeZero": -0.0,
        ]
        
        let expectedConfigs = [
            "mixed_numbers": mixedNumbers,
            "weird_keys": weirdKeys,
            "deep_nesting": deepNest,
            "mixed_array": mixedArray,
            "unicode_stress": unicode,
            "special_number_formats": numbersAsStrings
        ]

        try await validateConfig(apiKey: apiKey, expectedValidation: .iosSDKPartialConfigs(expectedConfigs))
    }

    func validateConfig(apiKey: String, expectedValidation: Validation) async throws {
        let context = AmplitudeContext(apiKey: apiKey)

        let didUpdateConfigExpectation = XCTestExpectation(description: "it did request config")
        didUpdateConfigExpectation.assertForOverFulfill = true
        didUpdateConfigExpectation.expectedFulfillmentCount = 1

        context.remoteConfigClient.subscribe(deliveryMode: .waitForRemote(timeout: 10)) { config, source, lastFetch in
            XCTAssertEqual(source, .remote)
            expectedValidation.validate(config: config)

            didUpdateConfigExpectation.fulfill()
        }
        await fulfillment(of: [didUpdateConfigExpectation], timeout: 10)

        let cachedContext = AmplitudeContext(apiKey: apiKey)

        let didCachedConfigExpectation = XCTestExpectation(description: "it did request config")
        didCachedConfigExpectation.assertForOverFulfill = true
        didCachedConfigExpectation.expectedFulfillmentCount = 1

        cachedContext.remoteConfigClient.subscribe() { config, source, lastFetch in
            if source == .cache {
                expectedValidation.validate(config: config)

                didCachedConfigExpectation.fulfill()
            }
        }

        await fulfillment(of: [didCachedConfigExpectation], timeout: 10)
    }
}
