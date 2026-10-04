//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// Generates Codable conformance for types that declare a default value. Useful for
/// types that are partially encoded, like if new properties are added over time.
@attached(extension, names: named(CodingKeys), named(init))
public macro DefaultDecodable() = #externalMacro(module: "SwiftfinMacrosPlugin", type: "DefaultDecodableMacro")
