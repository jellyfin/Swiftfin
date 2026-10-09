//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// Generates an option set from a nested `Options: Int` enum.
/// Cases use sequential bit positions unless given explicit values.
@attached(member, names: named(RawValue), named(rawValue), named(init), arbitrary)
@attached(extension, conformances: Swift.OptionSet)
public macro OptionSet<RawValue: FixedWidthInteger>() = #externalMacro(module: "SwiftfinMacrosPlugin", type: "OptionSetMacro")
