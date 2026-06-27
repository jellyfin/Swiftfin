//
//  Internals.DiffableDataUIDispatcher.StagedChangeset.swift
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
    
    // MARK: - StagedChangeset
    
    // Implementation based on https://github.com/ra1028/DifferenceKit
    internal struct StagedChangeset<C: Collection>: ExpressibleByArrayLiteral, Equatable, RandomAccessCollection, RangeReplaceableCollection where C: Equatable {
        
        @usableFromInline
        var changesets: ContiguousArray<Changeset<C>>

        @usableFromInline
        init<S: Sequence>(_ changesets: S) where S.Element == Changeset<C> {
            
            self.changesets = ContiguousArray(changesets)
        }
        
        
        // MARK: ExpressibleByArrayLiteral
        
        @inlinable
        init(arrayLiteral elements: Changeset<C>...) {
            
            self.init(elements)
        }
        
        
        // MARK: Equatable

        @inlinable
        static func == (lhs: StagedChangeset, rhs: StagedChangeset) -> Bool {
            
            return lhs.changesets == rhs.changesets
        }
        
        
        // MARK: Sequence

        typealias Element = Changeset<C>
        
        
        // MARK: RandomAccessCollection

        @inlinable
        var startIndex: Int {
            
            return self.changesets.startIndex
        }

        @inlinable
        var endIndex: Int {
            
            return self.changesets.endIndex
        }

        @inlinable
        func index(after i: Int) -> Int {
            
            return self.changesets.index(after: i)
        }

        @inlinable
        subscript(position: Int) -> Changeset<C> {
            
            get { return self.changesets[position] }
            set { self.changesets[position] = newValue }
        }
        
        
        // MARK: RangeReplaceableCollection

        @inlinable
        init() {
            
            self.init([])
        }

        @inlinable
        mutating func replaceSubrange<C2: Collection, R: RangeExpression>(_ subrange: R, with newElements: C2) where C2.Element == Changeset<C>, R.Bound == Int {
            
            self.changesets.replaceSubrange(subrange, with: newElements)
        }
    }
}


// MARK: - Internals.DiffableDataUIDispatcher.StagedChangeset where C: RangeReplaceableCollection, C.Element: Differentiable

extension Internals.DiffableDataUIDispatcher.StagedChangeset where C: RangeReplaceableCollection, C.Element: Differentiable {
    
    @inlinable
    internal init(source: C, target: C) {
        
        self.init(source: source, target: target, section: 0)
    }
    
    @inlinable
    internal init(source: C, target: C, section: Int) {
        
        typealias Changeset = Internals.DiffableDataUIDispatcher<O>.Changeset
        typealias ElementPath = Internals.DiffableDataUIDispatcher<O>.ElementPath
        typealias DiffResult = Internals.DiffableDataUIDispatcher<O>.DiffResult
        
        let sourceElements = ContiguousArray(source)
        let targetElements = ContiguousArray(target)
        if sourceElements.isEmpty && targetElements.isEmpty {
            
            self.init()
            return
        }
        if !sourceElements.isEmpty && targetElements.isEmpty {
            
            self.init(
                [
                    Changeset(
                        data: target,
                        elementDeleted: sourceElements.indices.map {
                            ElementPath(
                                element: $0,
                                section: section
                            )
                        }
                    )
                ]
            )
            return
        }
        if sourceElements.isEmpty && !targetElements.isEmpty {
            
            self.init(
                [
                    Changeset(
                        data: target,
                        elementInserted: targetElements.indices.map {
                            ElementPath(
                                element: $0,
                                section: section
                            )
                        }
                    )
                ]
            )
            return
        }
        var firstStageElements = ContiguousArray<C.Element>()
        var secondStageElements = ContiguousArray<C.Element>()
        let result = DiffResult.diff(
            source: sourceElements,
            target: targetElements,
            useTargetIndexForUpdated: false,
            mapIndex: { ElementPath(element: $0, section: section) },
            updatedElementsPointer: &firstStageElements,
            notDeletedElementsPointer: &secondStageElements
        )

        var changesets = ContiguousArray<Changeset<C>>()
        if !result.updated.isEmpty {
            
            changesets.append(
                Changeset(
                    data: C(firstStageElements),
                    elementUpdated: result.updated
                )
            )
        }
        if !result.deleted.isEmpty {
            
            changesets.append(
                Changeset(
                    data: C(secondStageElements),
                    elementDeleted: result.deleted
                )
            )
        }
        if !result.inserted.isEmpty || !result.moved.isEmpty {
            
            changesets.append(
                Changeset(
                    data: target,
                    elementInserted: result.inserted,
                    elementMoved: result.moved
                )
            )
        }
        if !changesets.isEmpty {
            
            let index = changesets.index(before: changesets.endIndex)
            changesets[index].data = target
        }
        self.init(changesets)
    }
}


// MARK: - Internals.DiffableDataUIDispatcher.StagedChangeset where C: RangeReplaceableCollection, C.Element: DifferentiableSection

extension Internals.DiffableDataUIDispatcher.StagedChangeset where C: RangeReplaceableCollection, C.Element: DifferentiableSection {
    
    @inlinable
    internal init(source: C, target: C) {
        
        typealias Section = C.Element
        typealias SectionIdentifier = C.Element.DifferenceIdentifier
        typealias Element = C.Element.Collection.Element
        typealias ElementIdentifier = C.Element.Collection.Element.DifferenceIdentifier
        
        typealias Changeset = Internals.DiffableDataUIDispatcher<O>.Changeset
        typealias ElementPath = Internals.DiffableDataUIDispatcher<O>.ElementPath
        typealias DiffResult = Internals.DiffableDataUIDispatcher<O>.DiffResult
        
        typealias Trace = Internals.DiffableDataUIDispatcher<O>.DiffResult<Section>.Trace
        typealias TableKey = Internals.DiffableDataUIDispatcher<O>.DiffResult<Section>.TableKey
        typealias Occurrence = Internals.DiffableDataUIDispatcher<O>.DiffResult<Section>.Occurrence
        typealias IndicesReference = Internals.DiffableDataUIDispatcher<O>.DiffResult<Section>.IndicesReference

        let sourceSections = ContiguousArray(source)
        let targetSections = ContiguousArray(target)

        let contiguousSourceSections = ContiguousArray(sourceSections.map { ContiguousArray($0.elements) })
        let contiguousTargetSections = ContiguousArray(targetSections.map { ContiguousArray($0.elements) })

        var firstStageSections = sourceSections
        var secondStageSections = ContiguousArray<Section>()
        var thirdStageSections = ContiguousArray<Section>()
        var fourthStageSections = ContiguousArray<Section>()

        var sourceElementTraces = contiguousSourceSections.map { section in
            
            ContiguousArray(repeating: Trace<ElementPath>(), count: section.count)
        }
        var targetElementReferences = contiguousTargetSections.map { section in
            
            ContiguousArray<ElementPath?>(repeating: nil, count: section.count)
        }

        let flattenSourceCount = contiguousSourceSections.reduce(into: 0) { $0 += $1.count }
        var flattenSourceIdentifiers = ContiguousArray<ElementIdentifier>()
        var flattenSourceElementPaths = ContiguousArray<ElementPath>()

        thirdStageSections.reserveCapacity(contiguousTargetSections.count)
        fourthStageSections.reserveCapacity(contiguousTargetSections.count)

        flattenSourceIdentifiers.reserveCapacity(flattenSourceCount)
        flattenSourceElementPaths.reserveCapacity(flattenSourceCount)

        let sectionResult = DiffResult.diff(
            source: sourceSections,
            target: targetSections,
            useTargetIndexForUpdated: true,
            mapIndex: { $0 }
        )

        var elementDeleted = [ElementPath]()
        var elementInserted = [ElementPath]()
        var elementUpdated = [ElementPath]()
        var elementMoved = [(source: ElementPath, target: ElementPath)]()

        for sourceSectionIndex in contiguousSourceSections.indices {
            
            for sourceElementIndex in contiguousSourceSections[sourceSectionIndex].indices {
                
                let sourceElementPath = ElementPath(element: sourceElementIndex, section: sourceSectionIndex)
                let sourceElement = contiguousSourceSections[sourceElementPath]
                flattenSourceIdentifiers.append(sourceElement.differenceIdentifier)
                flattenSourceElementPaths.append(sourceElementPath)
            }
        }
        flattenSourceIdentifiers.withUnsafeBufferPointer { bufferPointer in
            
            var sourceOccurrencesTable = [TableKey<ElementIdentifier>: Occurrence](minimumCapacity: flattenSourceCount)

            for flattenSourceIndex in flattenSourceIdentifiers.indices {
                let pointer = bufferPointer.baseAddress!.advanced(by: flattenSourceIndex)
                let key = TableKey(pointer: pointer)

                switch sourceOccurrencesTable[key] {
                    
                case .none:
                    sourceOccurrencesTable[key] = .unique(index: flattenSourceIndex)

                case .unique(let otherIndex)?:
                    let reference = IndicesReference([otherIndex, flattenSourceIndex])
                    sourceOccurrencesTable[key] = .duplicate(reference: reference)

                case .duplicate(let reference)?:
                    reference.push(flattenSourceIndex)
                }
            }

            for targetSectionIndex in contiguousTargetSections.indices {
                
                let targetElements = contiguousTargetSections[targetSectionIndex]
                for targetElementIndex in targetElements.indices {
                    
                    var targetIdentifier = targetElements[targetElementIndex].differenceIdentifier
                    let key = TableKey(pointer: &targetIdentifier)

                    switch sourceOccurrencesTable[key] {
                        
                    case .none:
                        break

                    case .unique(let flattenSourceIndex)?:
                        let sourceElementPath = flattenSourceElementPaths[flattenSourceIndex]
                        let targetElementPath = ElementPath(element: targetElementIndex, section: targetSectionIndex)
                        if case .none = sourceElementTraces[sourceElementPath].reference {
                            
                            targetElementReferences[targetElementPath] = sourceElementPath
                            sourceElementTraces[sourceElementPath].reference = targetElementPath
                        }

                    case .duplicate(let reference)?:
                        if let flattenSourceIndex = reference.next() {
                            
                            let sourceElementPath = flattenSourceElementPaths[flattenSourceIndex]
                            let targetElementPath = ElementPath(element: targetElementIndex, section: targetSectionIndex)
                            targetElementReferences[targetElementPath] = sourceElementPath
                            sourceElementTraces[sourceElementPath].reference = targetElementPath
                        }
                    }
                }
            }
        }
        for sourceSectionIndex in contiguousSourceSections.indices {
            
            let sourceSection = sourceSections[sourceSectionIndex]
            let sourceElements = contiguousSourceSections[sourceSectionIndex]
            var firstStageElements = sourceElements

            if case .some = sectionResult.sourceTraces[sourceSectionIndex].reference {
                
                var offsetByDelete = 0
                var secondStageElements = ContiguousArray<Element>()
                for sourceElementIndex in sourceElements.indices {
                    
                    let sourceElementPath = ElementPath(element: sourceElementIndex, section: sourceSectionIndex)
                    sourceElementTraces[sourceElementPath].deleteOffset = offsetByDelete

                    if let targetElementPath = sourceElementTraces[sourceElementPath].reference,
                        case .some = sectionResult.targetReferences[targetElementPath.section] {
                        
                        let targetElement = contiguousTargetSections[targetElementPath]
                        firstStageElements[sourceElementIndex] = targetElement
                        secondStageElements.append(targetElement)
                        continue
                    }
                    elementDeleted.append(sourceElementPath)
                    sourceElementTraces[sourceElementPath].isTracked = true
                    offsetByDelete += 1
                }

                let secondStageSection = Section(source: sourceSection, elements: secondStageElements)
                secondStageSections.append(secondStageSection)
            }

            let firstStageSection = Section(source: sourceSection, elements: firstStageElements)
            firstStageSections[sourceSectionIndex] = firstStageSection
        }
        for targetSectionIndex in contiguousTargetSections.indices {
            
            guard let sourceSectionIndex = sectionResult.targetReferences[targetSectionIndex] else {
                
                thirdStageSections.append(targetSections[targetSectionIndex])
                fourthStageSections.append(targetSections[targetSectionIndex])
                continue
            }

            var untrackedSourceIndex: Int? = 0
            let targetElements = contiguousTargetSections[targetSectionIndex]
            let sectionDeleteOffset = sectionResult.sourceTraces[sourceSectionIndex].deleteOffset
            let thirdStageSection = secondStageSections[sourceSectionIndex - sectionDeleteOffset]
            thirdStageSections.append(thirdStageSection)

            var fourthStageElements = ContiguousArray<Element>()
            fourthStageElements.reserveCapacity(targetElements.count)

            for targetElementIndex in targetElements.indices {
                
                untrackedSourceIndex = untrackedSourceIndex.flatMap { index in
                    
                    sourceElementTraces[sourceSectionIndex].suffix(from: index).firstIndex { !$0.isTracked }
                }
                let targetElementPath = ElementPath(element: targetElementIndex, section: targetSectionIndex)
                let targetElement = contiguousTargetSections[targetElementPath]

                guard
                    let sourceElementPath = targetElementReferences[targetElementPath],
                    let movedSourceSectionIndex = sectionResult.sourceTraces[sourceElementPath.section].reference
                    else {
                        
                        fourthStageElements.append(targetElement)
                        elementInserted.append(targetElementPath)
                        continue
                }
                sourceElementTraces[sourceElementPath].isTracked = true

                let sourceElement = contiguousSourceSections[sourceElementPath]
                fourthStageElements.append(targetElement)

                if !targetElement.isContentEqual(to: sourceElement) {
                    
                    elementUpdated.append(sourceElementPath)
                }
                if sourceElementPath.section != sourceSectionIndex || sourceElementPath.element != untrackedSourceIndex {
                    
                    let deleteOffset = sourceElementTraces[sourceElementPath].deleteOffset
                    let moveSourceElementPath = ElementPath(element: sourceElementPath.element - deleteOffset, section: movedSourceSectionIndex)
                    elementMoved.append((source: moveSourceElementPath, target: targetElementPath))
                }
            }
            let fourthStageSection = Section(source: thirdStageSection, elements: fourthStageElements)
            fourthStageSections.append(fourthStageSection)
        }

        var changesets = ContiguousArray<Changeset<C>>()
        if !elementUpdated.isEmpty {
            
            changesets.append(
                Changeset(
                    data: C(firstStageSections),
                    elementUpdated: elementUpdated
                )
            )
        }
        if !sectionResult.deleted.isEmpty || !elementDeleted.isEmpty {
            
            changesets.append(
                Changeset(
                    data: C(secondStageSections),
                    sectionDeleted: sectionResult.deleted,
                    elementDeleted: elementDeleted
                )
            )
        }
        if !sectionResult.inserted.isEmpty || !sectionResult.moved.isEmpty {
            
            changesets.append(
                Changeset(
                    data: C(thirdStageSections),
                    sectionInserted: sectionResult.inserted,
                    sectionMoved: sectionResult.moved
                )
            )
        }
        if !elementInserted.isEmpty || !elementMoved.isEmpty {
            
            changesets.append(
                Changeset(
                    data: C(fourthStageSections),
                    elementInserted: elementInserted,
                    elementMoved: elementMoved
                )
            )
        }
        if !sectionResult.updated.isEmpty {
            
            changesets.append(
                Changeset(
                    data: target,
                    sectionUpdated: sectionResult.updated
                )
            )
        }
        if !changesets.isEmpty {
            
            let index = changesets.index(before: changesets.endIndex)
            changesets[index].data = target
        }
        self.init(changesets)
    }
}


// MARK: - MutableCollection

extension MutableCollection where Element: MutableCollection, Index == Int, Element.Index == Int {
    
    @inlinable
    internal subscript<O>(path: Internals.DiffableDataUIDispatcher<O>.ElementPath) -> Element.Element {
        
        get { return self[path.section][path.element] }
        set { self[path.section][path.element] = newValue }
    }
}

#endif
