//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Collection {

    var asArray: [Element] {
        Array(self)
    }

    func sorted<Value: Comparable>(using keyPath: KeyPath<Element, Value>) -> [Element] {
        sorted(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })
    }
    
    func subtracting<Value: Equatable> (_ other: some Collection<Element>, using keyPath: KeyPath<Element, Value>) -> [Element] {
        filter { x in
            !other.contains(where: { $0[keyPath: keyPath] == x[keyPath: keyPath] })
        }
    }
    
    func subtracting<Value: Equatable> (_ other: some Collection<Value>, using keyPath: KeyPath<Element, Value>) -> [Element] {
        filter { x in
            !other.contains(where: { $0 == x[keyPath: keyPath] })
        }
    }

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Collection where Element: Equatable {
    
    func subtracting(_ other: some Collection<Element>) -> [Element] {
        filter { x in
            !other.contains(where: { $0 == x })
        }
    }
}
