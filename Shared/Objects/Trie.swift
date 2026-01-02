//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

class Trie<Key: Collection & Hashable, Element> where Key.Element: Hashable {

    class TrieNode {
        var children: [Key.Element: TrieNode] = [:]
        var isLeafNode: Bool = false
        var elements: [Element] = []
    }

    private let root = TrieNode()
}

extension Trie {

    func contains(key: Key) -> Bool {
        var currentNode = root

        for key in key {
            guard let nextNode = currentNode.children[key] else {
                return false
            }
            currentNode = nextNode
        }

        return currentNode.isLeafNode
    }

    func insert(key: Key, element: Element) {
        var currentNode = root

        for key in key {
            if currentNode.children[key] == nil {
                currentNode.children[key] = TrieNode()
            }
            currentNode = currentNode.children[key]!
            currentNode.elements.append(element)
        }
        currentNode.isLeafNode = true
    }

    func insert(contentsOf contents: [Key: Element]) {
        for (key, element) in contents {
            insert(key: key, element: element)
        }
    }

    func search(prefix: Key) -> [Element] {

        guard prefix.isNotEmpty else { return [] }

        var currentNode = root

        for key in prefix {
            guard let nextNode = currentNode.children[key] else {
                return []
            }
            currentNode = nextNode
        }

        return currentNode.elements
    }
}
