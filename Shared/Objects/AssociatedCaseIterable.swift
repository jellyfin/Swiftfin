//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// A type that provides a collection of a subset of all of its values based on an external associated type.
///
/// Example:
/// - `ItemSortBy` supported cases will vary based on the `BaseItemKind`s contained in the `LibraryParent`
///
/// Using types that conform to `SupportedCaseIterable` may contain values that
/// aren't supported or valid based on an external filter or value.
protocol AssociatedCaseIterable: SupportedCaseIterable, Equatable
    where AllCases.Element == Self, SupportedCases.Element == Self
{
    associatedtype AssociatedType: Hashable

    /// Array of supported `AssociatedType` based on the value of `Self`
    var applicableTypes: [AssociatedType] { get }
}

extension AssociatedCaseIterable {

    /// The `supportedCases` filtered against `filter` `AssociatedType`.
    /// - `requiringAll` removes cases that only apply to some `AssociatedType`s but not all of them
    static func associatedCases(for filter: [AssociatedType], requiringAll: Bool = false) -> [Self] {

        let filterTypes = Set(filter)

        return Self.supportedCases.filter { element in

            let applicableTypes = Set(element.applicableTypes)

            guard applicableTypes.isNotEmpty else {
                return true
            }

            return requiringAll ? filterTypes.isSubset(of: applicableTypes) : !applicableTypes.isDisjoint(with: filterTypes)
        }
    }

    func isAssociated(with filter: [AssociatedType], requiringAll: Bool = false) -> Bool {

        let applicableTypes = Set(applicableTypes)

        guard applicableTypes.isNotEmpty else {
            return true
        }

        let filterTypes = Set(filter)

        return requiringAll
            ? filterTypes.isSubset(of: applicableTypes)
            : !applicableTypes.isDisjoint(with: filterTypes)
    }
}
