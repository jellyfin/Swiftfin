//
//  Internals.DiffableDataUIDispatcher.Changeset.swift
//  CoreStore
//
//  Copyright © 2018 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#if canImport(UIKit) || canImport(AppKit)

import Foundation


// MARK: - Internals.DiffableDataUIDispatcher

extension Internals.DiffableDataUIDispatcher {
    
    // MARK: - ChangeSet
    
    // Implementation based on https://github.com/ra1028/DifferenceKit
    internal struct Changeset<C: Collection>: Equatable where C: Equatable {
        
        var data: C
        var sectionDeleted: [Int]
        var sectionInserted: [Int]
        var sectionUpdated: [Int]
        var sectionMoved: [(source: Int, target: Int)]

        var elementDeleted: [ElementPath]
        var elementInserted: [ElementPath]
        var elementUpdated: [ElementPath]
        var elementMoved: [(source: ElementPath, target: ElementPath)]

        @usableFromInline
        init(
            data: C,
            sectionDeleted: [Int] = [],
            sectionInserted: [Int] = [],
            sectionUpdated: [Int] = [],
            sectionMoved: [(source: Int, target: Int)] = [],
            elementDeleted: [ElementPath] = [],
            elementInserted: [ElementPath] = [],
            elementUpdated: [ElementPath] = [],
            elementMoved: [(source: ElementPath, target: ElementPath)] = []
        ) {
            self.data = data
            self.sectionDeleted = sectionDeleted
            self.sectionInserted = sectionInserted
            self.sectionUpdated = sectionUpdated
            self.sectionMoved = sectionMoved
            self.elementDeleted = elementDeleted
            self.elementInserted = elementInserted
            self.elementUpdated = elementUpdated
            self.elementMoved = elementMoved
        }

        @inlinable
        var sectionChangeCount: Int {
            
            return self.sectionDeleted.count
                + self.sectionInserted.count
                + self.sectionUpdated.count
                + self.sectionMoved.count
        }

        @inlinable
        var elementChangeCount: Int {
            
            return self.elementDeleted.count
                + self.elementInserted.count
                + self.elementUpdated.count
                + self.elementMoved.count
        }

        @inlinable
        var changeCount: Int {
            
            return self.sectionChangeCount + self.elementChangeCount
        }

        @inlinable
        var hasSectionChanges: Bool {
            
            return self.sectionChangeCount > 0
        }

        @inlinable
        var hasElementChanges: Bool {
            
            return self.elementChangeCount > 0
        }

        @inlinable
        var hasChanges: Bool {
            
            return self.changeCount > 0
        }
        
        
        // MARK: Equatable
        
        static func == (lhs: Changeset, rhs: Changeset) -> Bool {
            return lhs.data == rhs.data
                && Set(lhs.sectionDeleted) == Set(rhs.sectionDeleted)
                && Set(lhs.sectionInserted) == Set(rhs.sectionInserted)
                && Set(lhs.sectionUpdated) == Set(rhs.sectionUpdated)
                && Set(lhs.sectionMoved.map(HashablePair.init)) == Set(rhs.sectionMoved.map(HashablePair.init))
                && Set(lhs.elementDeleted) == Set(rhs.elementDeleted)
                && Set(lhs.elementInserted) == Set(rhs.elementInserted)
                && Set(lhs.elementUpdated) == Set(rhs.elementUpdated)
                && Set(lhs.elementMoved.map(HashablePair.init)) == Set(rhs.elementMoved.map(HashablePair.init))
        }
        
        
        // MARK: - HashablePair
        
        private struct HashablePair<H: Hashable>: Hashable {
            
            let first: H
            let second: H
        }
    }
}

#endif
