//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

class Trie {

    private let root = TrieNode()

    // MARK: - Insert Word into Trie

    func insert(_ word: String) {
        guard !word.isEmpty else { return }
        var currentNode = root

        for char in word.lowercased() {
            if currentNode.children[char] == nil {
                currentNode.children[char] = TrieNode()
            }
            currentNode = currentNode.children[char]!
            currentNode.words.append(word)
        }
        currentNode.isEndOfWord = true
    }

    // MARK: - Search for Prefix Matches

    func search(prefix: String) -> [String] {
        guard !prefix.isEmpty else { return [] }
        var currentNode = root

        for char in prefix.lowercased() {
            guard let nextNode = currentNode.children[char] else {
                return []
            }
            currentNode = nextNode
        }

        return currentNode.words
    }
}

extension Trie {

    class TrieNode {

        var children: [Character: TrieNode] = [:]
        var isEndOfWord: Bool = false
        var words: [String] = []
    }
}
