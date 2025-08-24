//
//  CoreRemoteConfigSDKTests.swift
//  CoreRemoteConfigSDKTests
//
//  Created by Jin Xu on 8/7/25.
//

import AmplitudeCore
import XCTest

protocol AnyValidation {
    func validate(config: RemoteConfigClient.RemoteConfig?)
}

struct Validation<T: Equatable>: AnyValidation {
    let keyPath: String
    let expectedValue: T
    
    func validate(config: RemoteConfigClient.RemoteConfig?) {
        guard let config = config else {
            XCTFail("Remote config is nil")
            return
        }
        
        let keys = keyPath.split(separator: ".")
        var currentConfig: Any = config
        var currentKeys = [String]()
        for key in keys {
            let key = String(key)
            currentKeys.append(key)
            guard let subconfig = (currentConfig as? [String: Any])?[key] else {
                XCTFail("KeyPath \(currentKeys.joined(separator: ".")) is not set")
                return
            }
            currentConfig = subconfig
        }
        
        XCTAssertEqual(currentConfig as? T, expectedValue, "Remote config of \(keyPath) does not match expected")
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

        let validations: [AnyValidation] = [
            Validation(keyPath: "sessionReplay.sr_ios_privacy_config.defaultMaskLevel", expectedValue: "medium"),
            Validation(keyPath: "sessionReplay.sr_ios_sampling_config.capture_enabled", expectedValue: true)
        ]

        try await validateConfig(apiKey: apiKey, expectedValidations: validations)
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testModifiedConfig() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY_MODIFIED"] else {
            XCTFail("AMPLITUDE_API_KEY_MODIFIED environment variable not set")
            return
        }

        let validations: [AnyValidation] = [
            Validation(keyPath: "sessionReplay.sr_ios_privacy_config.defaultMaskLevel", expectedValue: "light"),
            Validation(keyPath: "sessionReplay.sr_ios_sampling_config.capture_enabled", expectedValue: true),
            Validation(keyPath: "sessionReplay.sr_ios_sampling_config.sample_rate", expectedValue: NSNumber(value: 1))
        ]

        try await validateConfig(apiKey: apiKey, expectedValidations: validations)
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testEmptyConfig() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY_EMPTY"] else {
            XCTFail("AMPLITUDE_API_KEY_EMPTY environment variable not set")
            return
        }

        try await validateConfig(apiKey: apiKey, expectedValidations: [Validation(keyPath: "analyticsSDK.iosSDK", expectedValue: NSDictionary())])
    }

    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func testNestedConfig() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY_NESTED"] else {
            XCTFail("AMPLITUDE_API_KEY_NESTED environment variable not set")
            return
        }
        
        let nested: NSDictionary = [
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
        try await validateConfig(apiKey: apiKey, expectedValidations: [Validation(keyPath: "analyticsSDK.iosSDK", expectedValue: nested)])
    }

    func testValidConfig() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY_VALID"] else {
            XCTFail("AMPLITUDE_API_KEY_VALID environment variable not set")
            return
        }

        // Mixed numeric types
        let mixedNumbers: NSDictionary = [
            "int": 42,
            "double": 3.14159,
            "big": 9_223_372_036_854_775_807 // Int64.max
        ]

        // Weird keys
        let weirdKeys: NSDictionary = [
            " spaces ": "value",
            "emoji😊": "smile",
            "quotes\"inside": "escaped",
            "backslash\\": "slash",
            // "null\0char": "nullbyte",  \0 in key is not allowed for remote config upsert api
        ]

        // Deep nesting
        let deepNest: NSDictionary = [
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
        let mixedArray: NSDictionary = [
            "array": [1, "two", ["three": 3], true]
        ]

        // Unicode stress
        let unicode: NSDictionary = [
            "japanese": "こんにちは",
            "arabic": "مرحبا",
            "combining": "e\u{0301}", // é as e + accent
            "rightToLeft": "\u{202E}txet", // RTL override
        ]

        // Special number formats
        let numbersAsStrings: NSDictionary = [
            "hexString": "0x1A",
            "expNotation": 1.2e+10,
            "negativeZero": -0.0,
        ]
        
        let validations: [AnyValidation] = [
            Validation(keyPath: "analyticsSDK.iosSDK.mixed_numbers", expectedValue: mixedNumbers),
            Validation(keyPath: "analyticsSDK.iosSDK.weird_keys", expectedValue: weirdKeys),
            Validation(keyPath: "analyticsSDK.iosSDK.deep_nesting", expectedValue: deepNest),
            Validation(keyPath: "analyticsSDK.iosSDK.mixed_array", expectedValue: mixedArray),
            Validation(keyPath: "analyticsSDK.iosSDK.unicode_stress", expectedValue: unicode),
            Validation(keyPath: "analyticsSDK.iosSDK.special_number_formats", expectedValue: numbersAsStrings)
        ]

        try await validateConfig(apiKey: apiKey, expectedValidations: validations)
    }

    func validateConfig(apiKey: String, expectedValidations: [AnyValidation]) async throws {
        let context = AmplitudeContext(apiKey: apiKey)

        let didUpdateConfigExpectation = XCTestExpectation(description: "it did request config")
        didUpdateConfigExpectation.assertForOverFulfill = true
        didUpdateConfigExpectation.expectedFulfillmentCount = 1

        context.remoteConfigClient.subscribe(deliveryMode: .waitForRemote(timeout: 10)) { config, source, lastFetch in
            XCTAssertEqual(source, .remote)
            expectedValidations.forEach { validation in
                validation.validate(config: config)
            }

            didUpdateConfigExpectation.fulfill()
        }
        await fulfillment(of: [didUpdateConfigExpectation], timeout: 10)

        let cachedContext = AmplitudeContext(apiKey: apiKey)

        let didCachedConfigExpectation = XCTestExpectation(description: "it did request config")
        didCachedConfigExpectation.assertForOverFulfill = true
        didCachedConfigExpectation.expectedFulfillmentCount = 1

        cachedContext.remoteConfigClient.subscribe() { config, source, lastFetch in
            if source == .cache {
                expectedValidations.forEach { validation in
                    validation.validate(config: config)
                }

                didCachedConfigExpectation.fulfill()
            }
        }

        await fulfillment(of: [didCachedConfigExpectation], timeout: 10)
    }
}
