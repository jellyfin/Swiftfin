//
//  Internals.DiffableDataUIDispatcher.DiffResult.swift
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
    
    // MARK: - DiffResult
    
    // Implementation based on https://github.com/ra1028/DifferenceKit
    @usableFromInline
    internal struct DiffResult<Index> {
        
        @usableFromInline
        internal let deleted: [Index]
        @usableFromInline
        internal let inserted: [Index]
        @usableFromInline
        internal let updated: [Index]
        @usableFromInline
        internal let moved: [(source: Index, target: Index)]
        @usableFromInline
        internal let sourceTraces: ContiguousArray<Trace<Int>>
        @usableFromInline
        internal let targetReferences: ContiguousArray<Int?>
        
        @inlinable
        @discardableResult
        static func diff<E: Differentiable>(
            source: ContiguousArray<E>,
            target: ContiguousArray<E>,
            useTargetIndexForUpdated: Bool,
            mapIndex: (Int) -> Index,
            updatedElementsPointer: UnsafeMutablePointer<ContiguousArray<E>>? = nil,
            notDeletedElementsPointer: UnsafeMutablePointer<ContiguousArray<E>>? = nil
        ) -> DiffResult<Index> {
            
            var deleted = [Index]()
            var inserted = [Index]()
            var updated = [Index]()
            var moved = [(source: Index, target: Index)]()
            
            var sourceTraces = ContiguousArray<Trace<Int>>()
            var sourceIdentifiers = ContiguousArray<E.DifferenceIdentifier>()
            var targetReferences = ContiguousArray<Int?>(repeating: nil, count: target.count)
            
            sourceTraces.reserveCapacity(source.count)
            sourceIdentifiers.reserveCapacity(source.count)
            
            for sourceElement in source {
                
                sourceTraces.append(Trace())
                sourceIdentifiers.append(sourceElement.differenceIdentifier)
            }
            sourceIdentifiers.withUnsafeBufferPointer { bufferPointer in
                
                var sourceOccurrencesTable = [TableKey<E.DifferenceIdentifier>: Occurrence](minimumCapacity: source.count)
                
                for sourceIndex in sourceIdentifiers.indices {
                    
                    let pointer = bufferPointer.baseAddress!.advanced(by: sourceIndex)
                    let key = TableKey(pointer: pointer)
                    
                    switch sourceOccurrencesTable[key] {
                    case .none:
                        sourceOccurrencesTable[key] = .unique(index: sourceIndex)
                        
                    case .unique(let otherIndex)?:
                        let reference = IndicesReference([otherIndex, sourceIndex])
                        sourceOccurrencesTable[key] = .duplicate(reference: reference)
                        
                    case .duplicate(let reference)?:
                        reference.push(sourceIndex)
                    }
                }
                for targetIndex in target.indices {
                    
                    var targetIdentifier = target[targetIndex].differenceIdentifier
                    let key = TableKey(pointer: &targetIdentifier)
                    
                    switch sourceOccurrencesTable[key] {
                        
                    case .none:
                        break
                        
                    case .unique(let sourceIndex)?:
                        if case .none = sourceTraces[sourceIndex].reference {
                            
                            targetReferences[targetIndex] = sourceIndex
                            sourceTraces[sourceIndex].reference = targetIndex
                        }
                        
                    case .duplicate(let reference)?:
                        if let sourceIndex = reference.next() {
                            
                            targetReferences[targetIndex] = sourceIndex
                            sourceTraces[sourceIndex].reference = targetIndex
                        }
                    }
                }
            }
            
            var offsetByDelete = 0
            var untrackedSourceIndex: Int? = 0
            
            for sourceIndex in source.indices {
                
                sourceTraces[sourceIndex].deleteOffset = offsetByDelete
                
                if let targetIndex = sourceTraces[sourceIndex].reference {
                    
                    let targetElement = target[targetIndex]
                    updatedElementsPointer?.pointee.append(targetElement)
                    notDeletedElementsPointer?.pointee.append(targetElement)
                }
                else {
                    
                    let sourceElement = source[sourceIndex]
                    deleted.append(mapIndex(sourceIndex))
                    sourceTraces[sourceIndex].isTracked = true
                    offsetByDelete += 1
                    updatedElementsPointer?.pointee.append(sourceElement)
                }
            }
            for targetIndex in target.indices {
                
                untrackedSourceIndex = untrackedSourceIndex.flatMap { index in
                    
                    sourceTraces.suffix(from: index).firstIndex { !$0.isTracked }
                }
                if let sourceIndex = targetReferences[targetIndex] {
                    
                    sourceTraces[sourceIndex].isTracked = true
                    
                    let sourceElement = source[sourceIndex]
                    let targetElement = target[targetIndex]
                    
                    if !targetElement.isContentEqual(to: sourceElement) {
                        
                        updated.append(mapIndex(useTargetIndexForUpdated ? targetIndex : sourceIndex))
                    }
                    if sourceIndex != untrackedSourceIndex {
                        
                        let deleteOffset = sourceTraces[sourceIndex].deleteOffset
                        moved.append((source: mapIndex(sourceIndex - deleteOffset), target: mapIndex(targetIndex)))
                    }
                }
                else {
                    
                    inserted.append(mapIndex(targetIndex))
                }
            }
            return DiffResult(
                deleted: deleted,
                inserted: inserted,
                updated: updated,
                moved: moved,
                sourceTraces: sourceTraces,
                targetReferences: targetReferences
            )
        }
        
        
        // MARK: Private
        
        @usableFromInline
        internal init(
            deleted: [Index] = [],
            inserted: [Index] = [],
            updated: [Index] = [],
            moved: [(source: Index, target: Index)] = [],
            sourceTraces: ContiguousArray<Trace<Int>>,
            targetReferences: ContiguousArray<Int?>
        ) {
            
            self.deleted = deleted
            self.inserted = inserted
            self.updated = updated
            self.moved = moved
            self.sourceTraces = sourceTraces
            self.targetReferences = targetReferences
        }
        
        
        // MARK: - Trace

        // Implementation based on https://github.com/ra1028/DifferenceKit
        @usableFromInline
        internal struct Trace<I> {

            @usableFromInline
            internal var reference: I?

            @usableFromInline
            internal var deleteOffset = 0
            
            @usableFromInline
            internal var isTracked = false
            
            @usableFromInline
            init() {}
        }
        
        
        // MARK: - Occurrence

        // Implementation based on https://github.com/ra1028/DifferenceKit
        @usableFromInline
        internal enum Occurrence {
            
            case unique(index: Int)
            case duplicate(reference: IndicesReference)
        }
        
        
        // MARK: - IndicesReference

        // Implementation based on https://github.com/ra1028/DifferenceKit
        @usableFromInline
        internal final class IndicesReference {
            
            @usableFromInline
            internal var indices: ContiguousArray<Int>
            
            @usableFromInline
            internal var position = 0
            
            @usableFromInline
            internal init(_ indices: ContiguousArray<Int>) {
                
                self.indices = indices
            }
            
            @inlinable
            internal func push(_ index: Int) {
                
                self.indices.append(index)
            }
            
            @inlinable
            internal func next() -> Int? {
                
                guard self.position < self.indices.endIndex else {
                    
                    return nil
                }
                defer {
                    
                    self.position += 1
                }
                return self.indices[self.position]
            }
        }
        
        
        // MARK: - TableKey

        // Implementation based on https://github.com/ra1028/DifferenceKit
        @usableFromInline
        internal struct TableKey<T: Hashable>: Hashable {
            
            @usableFromInline
            internal let pointeeHashValue: Int
            
            @usableFromInline
            internal let pointer: UnsafePointer<T>
            
            @usableFromInline
            internal init(pointer: UnsafePointer<T>) {
                
                self.pointeeHashValue = pointer.pointee.hashValue
                self.pointer = pointer
            }
            
            
            // MARK: Equatable
            
            @inlinable
            internal static func == (lhs: TableKey, rhs: TableKey) -> Bool {
                
                return lhs.pointeeHashValue == rhs.pointeeHashValue
                    && (lhs.pointer.distance(to: rhs.pointer) == 0
                        || lhs.pointer.pointee == rhs.pointer.pointee)
            }
            
            
            // MARK: Hashable
            
            @inlinable
            internal func hash(into hasher: inout Hasher) {
                
                hasher.combine(pointeeHashValue)
            }
        }
    }
}

#endif
