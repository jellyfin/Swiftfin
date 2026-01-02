//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// A type that provides a collection of a subset of all of its values.
///
/// Using types that conform to `CaseIterable` may contain values that
/// aren't supported or valid in certain scenarios.
protocol SupportedCaseIterable: CaseIterable {

    associatedtype SupportedCases: Collection = [Self] where Self == Self.SupportedCases.Element

    static var supportedCases: Self.SupportedCases { get }
}

extension SupportedCaseIterable where SupportedCases.Element: Equatable {

    var isSupported: Bool {
        Self.supportedCases.contains(self)
    }
}
