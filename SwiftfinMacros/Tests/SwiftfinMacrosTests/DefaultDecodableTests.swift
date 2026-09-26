//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftfinMacros
import Testing

private protocol ConfigurationStorage: Codable {}

@DefaultDecodable
private struct EmptyConfiguration: Codable {}

@DefaultDecodable
private struct DecodingOnlyConfiguration: Decodable {
    var count: Int = 4
}

@DefaultDecodable
private struct Configuration: ConfigurationStorage, Equatable {
    var isTitlePresented: Bool = true
    var count: Int = 3
    var names: [String] = ["default"]
    var subtitle: String? = "Year"
    var note: String?
    var explicitOptional: Int?
    var qualifiedOptional: Int?

    static let shared = Configuration()
    var computed: String {
        "ignored"
    }
}

@DefaultDecodable
private struct RequiredConfiguration: Codable {
    let name: String
    var count: Int = 2
}

@DefaultDecodable
public struct GenericConfiguration<Value: Codable>: Codable {
    var value: Value
    var history: [Value] = []
}

@DefaultDecodable
private struct ObservedConfiguration: Codable {
    var count: Int = 1 {
        didSet { precondition(count >= 0) }
    }
}

@DefaultDecodable
private struct ExpressionConfiguration: Codable {
    var identifier: UUID = .init()
    var limits: [Int] = [1, 2].map { $0 * 2 }
    var `default`: Bool = true
}

struct DefaultDecodableTests {

    private func decode<Value: Decodable>(_ type: Value.Type, from json: String) throws -> Value {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test(arguments: [
        "{}",
        #"{"isTitlePresented":null,"count":null,"names":null,"subtitle":null,"note":null}"#,
    ])
    func `missing and null fields retain defaults`(json: String) throws {
        #expect(try decode(Configuration.self, from: json) == Configuration())
    }

    @Test
    func `saved values replace defaults`() throws {
        let value = try decode(Configuration.self, from: """
        {"isTitlePresented":false,"count":0,"names":[],"subtitle":"Runtime","note":"Saved",
         "explicitOptional":4,"qualifiedOptional":5,"futureOption":true}
        """)
        #expect(value == Configuration(
            isTitlePresented: false,
            count: 0,
            names: [],
            subtitle: "Runtime",
            note: "Saved",
            explicitOptional: 4,
            qualifiedOptional: 5
        ))
    }

    @Test(arguments: [
        #"{"isTitlePresented":"false"}"#,
        #"{"count":true}"#,
        #"{"names":[1]}"#,
        #"{"subtitle":4}"#,
        #"{"note":false}"#,
        "[]",
        "null",
    ])
    func `malformed values are not silently replaced`(json: String) {
        #expect(throws: DecodingError.self) {
            try decode(Configuration.self, from: json)
        }
    }

    @Test
    func `properties without defaults remain required`() throws {
        #expect(throws: DecodingError.self) {
            try decode(RequiredConfiguration.self, from: "{}")
        }
        #expect(throws: DecodingError.self) {
            try decode(RequiredConfiguration.self, from: #"{"name":null}"#)
        }
        let value = try decode(RequiredConfiguration.self, from: #"{"name":"Saved"}"#)
        #expect(value.name == "Saved")
        #expect(value.count == 2)
        #expect(RequiredConfiguration(name: "Memberwise").count == 2)
    }

    @Test
    func `synthesized encoding preserves stored keys`() throws {
        let value = Configuration(isTitlePresented: false, count: 10, names: [], subtitle: nil)
        let data = try JSONEncoder().encode(value)
        let json = try JSONSerialization.jsonObject(with: data)
        let object = try #require(json as? [String: Any])
        #expect(Set(object.keys) == ["isTitlePresented", "count", "names"])
        #expect(object["isTitlePresented"] as? Bool == false)
        #expect(object["count"] as? Int == 10)
        let decoded = try JSONDecoder().decode(Configuration.self, from: data)
        #expect(decoded.subtitle == "Year")
        #expect(!decoded.isTitlePresented)
    }

    @Test
    func `round trip and memberwise initializer`() throws {
        let original = Configuration(isTitlePresented: false, count: 7, names: ["Saved"], note: "Note")
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(Configuration.self, from: data) == original)
    }

    @Test
    func `generics observers and expressions`() throws {
        let generic = try decode(GenericConfiguration<Int>.self, from: #"{"value":42}"#)
        #expect(generic.value == 42)
        #expect(generic.history.isEmpty)
        #expect(try decode(ObservedConfiguration.self, from: #"{"count":4}"#).count == 4)
        let expression = try decode(ExpressionConfiguration.self, from: "{}")
        #expect(expression.limits == [2, 4])
        #expect(expression.default)
        let encoded = try JSONEncoder().encode(expression)
        let decoded = try JSONDecoder().decode(ExpressionConfiguration.self, from: encoded)
        #expect(decoded.identifier == expression.identifier)
    }

    @Test
    func `empty and decoding only configurations`() throws {
        _ = try decode(EmptyConfiguration.self, from: "{}")
        #expect(throws: DecodingError.self) {
            try decode(EmptyConfiguration.self, from: "[]")
        }
        #expect(try JSONEncoder().encode(EmptyConfiguration()) == Data("{}".utf8))
        #expect(try decode(DecodingOnlyConfiguration.self, from: "{}").count == 4)
    }
}
