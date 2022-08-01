//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

public struct BlurHash {
    public let components: [[(Float, Float, Float)]]

    public var numberOfHorizontalComponents: Int { components.first!.count }
    public var numberOfVerticalComponents: Int { components.count }

    public init(components: [[(Float, Float, Float)]]) {
        self.components = components
    }

    public func punch(_ factor: Float) -> BlurHash {
        BlurHash(components: components.enumerated().map { j, horizontalComponents -> [(Float, Float, Float)] in
            horizontalComponents.enumerated().map { i, component -> (Float, Float, Float) in
                if i == 0 && j == 0 {
                    return component
                } else {
                    return component * factor
                }
            }
        })
    }
}

public func + (lhs: BlurHash, rhs: BlurHash) throws -> BlurHash {
    BlurHash(components: paddedZip(lhs.components, rhs.components, [], []).map {
        paddedZip($0.0, $0.1, (0, 0, 0) as (Float, Float, Float), (0, 0, 0) as (Float, Float, Float))
            .map { ($0.0.0 + $0.1.0, $0.0.1 + $0.1.1, $0.0.2 + $0.1.2) }
    })
}

public func - (lhs: BlurHash, rhs: BlurHash) throws -> BlurHash {
    BlurHash(components: paddedZip(lhs.components, rhs.components, [], []).map {
        paddedZip($0.0, $0.1, (0, 0, 0) as (Float, Float, Float), (0, 0, 0) as (Float, Float, Float))
            .map { ($0.0.0 - $0.1.0, $0.0.1 - $0.1.1, $0.0.2 - $0.1.2) }
    })
}

private func paddedZip<Collection1, Collection2>(
    _ collection1: Collection1,
    _ collection2: Collection2,
    _ padding1: Collection1.Element,
    _ padding2: Collection2.Element
) -> Zip2Sequence<[Collection1.Element], [Collection2.Element]> where Collection1: Collection, Collection2: Collection {
    if collection1.count < collection2.count {
        let padded = collection1 + Array(repeating: padding1, count: collection2.count - collection1.count)
        return zip(padded, Array(collection2))
    } else if collection2.count < collection1.count {
        let padded = collection2 + Array(repeating: padding2, count: collection1.count - collection2.count)
        return zip(Array(collection1), padded)
    } else {
        return zip(Array(collection1), Array(collection2))
    }
}
