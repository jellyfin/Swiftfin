//
//  Internals.DiffableDataSourceSnapshot.swift
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

import CoreData

#if canImport(UIKit)
import UIKit

#elseif canImport(AppKit)
import AppKit

#endif


// MARK: - Internals

extension Internals {

    // MARK: - DiffableDataSourceSnapshot

    // Implementation based on https://github.com/ra1028/DiffableDataSources
    internal struct DiffableDataSourceSnapshot: DiffableDataSourceSnapshotProtocol {

        // MARK: Internal

        init(
            sections: [NSFetchedResultsSectionInfo],
            sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?,
            fetchOffset: Int,
            fetchLimit: Int
        ) {

            self.structure = .init(
                sections: sections,
                sectionIndexTransformer: sectionIndexTransformer,
                fetchOffset: Swift.max(0, fetchOffset),
                fetchLimit: (fetchLimit > 0) ? fetchLimit : nil
            )
        }
        
        var sections: [Section] {
            
            get {
                
                return self.structure.sections
            }
            set {
                
                self.structure.sections = newValue
            }
        }


        // MARK: DiffableDataSourceSnapshotProtocol

        init() {

            self.structure = .init()
        }

        var numberOfItems: Int {

            return self.structure.allItemsCount
        }

        var numberOfSections: Int {

            return self.structure.allSectionIDs.count
        }

        var sectionIdentifiers: [String] {

            return self.structure.allSectionIDs
        }

        var itemIdentifiers: [NSManagedObjectID] {

            return self.structure.allItemIDs
        }

        var updatedItemIdentifiers: Set<NSManagedObjectID> {

            return self.structure.reloadedItems
        }

        func numberOfItems(inSection identifier: String) -> Int {

            return self.itemIdentifiers(inSection: identifier).count
        }

        func itemIdentifier(atAllItemsIndex index: Int) -> NSManagedObjectID? {

            guard index >= 0 else {

                return nil
            }
            var remainingIndex = index
            for section in self.structure.sections {

                let elements = section.elements
                let sectionCount = elements.count
                if remainingIndex < sectionCount {

                    return elements[remainingIndex].differenceIdentifier
                }

                remainingIndex -= sectionCount
            }
            return nil
        }

        func itemIdentifiers(atAllItemsBounds bounds: Range<Int>) -> [NSManagedObjectID] {

            var remainingIndex = bounds.lowerBound
            var itemIdentifiers: [NSManagedObjectID] = []
            for section in self.structure.sections {

                let elements = section.elements
                let sectionCount = elements.count
                if remainingIndex < sectionCount {

                    itemIdentifiers.append(
                        contentsOf: elements[remainingIndex..<min(sectionCount, bounds.count)]
                            .map({ $0.differenceIdentifier })
                    )
                }
                else if !itemIdentifiers.isEmpty {

                    itemIdentifiers.append(
                        contentsOf: elements.prefix(bounds.count - itemIdentifiers.count)
                            .map({ $0.differenceIdentifier })
                    )
                }
                if itemIdentifiers.count >= bounds.count {

                    return itemIdentifiers
                }

                remainingIndex -= sectionCount
            }
            return itemIdentifiers
        }

        func itemIdentifiers(inSection identifier: String) -> [NSManagedObjectID] {

            return self.structure.items(in: identifier)
        }

        func sectionIdentifier(containingItem identifier: NSManagedObjectID) -> String? {

            return self.structure.section(containing: identifier)
        }

        func indexOfItem(_ identifier: NSManagedObjectID) -> Int? {

            return self.structure.allItemIDs.firstIndex(of: identifier)
        }

        func indexOfSection(_ identifier: String) -> Int? {

            return self.structure.allSectionIDs.firstIndex(of: identifier)
        }

        mutating func appendItems<C: Collection>(_ identifiers: C, toSection sectionIdentifier: String?) where C.Element == NSManagedObjectID {

            self.structure.append(itemIDs: identifiers, to: sectionIdentifier)
        }

        mutating func insertItems<C: Collection>(_ identifiers: C, beforeItem beforeIdentifier: NSManagedObjectID) where C.Element == NSManagedObjectID {

            self.structure.insert(itemIDs: identifiers, before: beforeIdentifier)
        }

        mutating func insertItems<C: Collection>(_ identifiers: C, afterItem afterIdentifier: NSManagedObjectID) where C.Element == NSManagedObjectID {

            self.structure.insert(itemIDs: identifiers, after: afterIdentifier)
        }

        mutating func deleteItems<C: Collection>(_ identifiers: C) where C.Element == NSManagedObjectID {

            self.structure.remove(itemIDs: identifiers)
        }

        mutating func deleteAllItems() {

            self.structure.removeAllItems()
        }

        mutating func moveItem(_ identifier: NSManagedObjectID, beforeItem toIdentifier: NSManagedObjectID) {

            self.structure.move(itemID: identifier, before: toIdentifier)
        }

        mutating func moveItem(_ identifier: NSManagedObjectID, afterItem toIdentifier: NSManagedObjectID) {

            self.structure.move(itemID: identifier, after: toIdentifier)
        }

        mutating func reloadItems<C: Collection>(_ identifiers: C) where C.Element == NSManagedObjectID {

            self.structure.update(itemIDs: identifiers)
        }

        mutating func appendSections<C: Collection>(_ identifiers: C) where C.Element == String {

            self.structure.append(sectionIDs: identifiers)
        }

        mutating func insertSections<C: Collection>(_ identifiers: C, beforeSection toIdentifier: String) where C.Element == String {

            self.structure.insert(sectionIDs: identifiers, before: toIdentifier)
        }

        mutating func insertSections<C: Collection>(_ identifiers: C, afterSection toIdentifier: String) where C.Element == String {

            self.structure.insert(sectionIDs: identifiers, after: toIdentifier)
        }

        mutating func deleteSections<C: Collection>(_ identifiers: C) where C.Element == String {

            self.structure.remove(sectionIDs: identifiers)
        }

        mutating func moveSection(_ identifier: String, beforeSection toIdentifier: String) {

            self.structure.move(sectionID: identifier, before: toIdentifier)
        }

        mutating func moveSection(_ identifier: String, afterSection toIdentifier: String) {

            self.structure.move(sectionID: identifier, after: toIdentifier)
        }

        mutating func reloadSections<C: Collection>(_ identifiers: C) where C.Element == String {

            self.structure.update(sectionIDs: identifiers)
        }
        
        mutating func unsafeAppendItems<C: Collection>(_ identifiers: C, toSectionAt sectionIndex: Int) where C.Element == NSManagedObjectID {
            
            self.structure.unsafeAppend(identifiers, toSectionAt: sectionIndex)
        }
        
        mutating func unsafeInsertItems<C: Collection>(_ identifiers: C, at indexPath: IndexPath) where C.Element == NSManagedObjectID {
            
            self.structure.unsafeInsert(itemIDs: identifiers, at: indexPath)
        }
        
        mutating func unsafeDeleteItems<C: Collection>(at indexPaths: C) where C.Element == IndexPath {
            
            self.structure.unsafeRemove(itemsAt: indexPaths)
        }
        
        mutating func unsafeMoveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
            
            self.structure.unsafeMove(itemAt: indexPath, to: newIndexPath)
        }
        
        mutating func unsafeReloadItems<C: Collection>(at indexPaths: C) where C.Element == IndexPath {
            
            self.structure.unsafeUpdate(itemsAt: indexPaths)
        }
        
        mutating func unsafeInsertSections<C: Collection>(_ identifiers: C, at sectionIndex: Int) where C.Element == String {
            
            self.structure.unsafeInsert(identifiers, at: sectionIndex)
        }
        
        mutating func unsafeDeleteSections<C: Collection>(at sectionIndices: C) where C.Element == Int {
            
            self.structure.unsafeRemove(sectionsAt: sectionIndices)
        }
        
        mutating func unsafeMoveSection(at sectionIndex: Int, to newSectionIndex: Int) {
            
            self.structure.unsafeMove(sectionAt: sectionIndex, to: newSectionIndex)
        }
        
        mutating func unsafeReloadSections<C: Collection>(at sectionIndices: C) where C.Element == Int {
            
            self.structure.unsafeUpdate(sectionsAt: sectionIndices)
        }


        // MARK: Private

        private var structure: BackingStructure


        // MARK: - Section

        internal struct Section: DifferentiableSection, Equatable {

            let indexTitle: String?
            var isReloaded: Bool

            init(
                differenceIdentifier: String,
                indexTitle: String?,
                items: [Item] = [],
                isReloaded: Bool = false
            ) {
                
                self.differenceIdentifier = differenceIdentifier
                self.indexTitle = indexTitle
                self.elements = items
                self.isReloaded = isReloaded
            }

            // MARK: Differentiable

            let differenceIdentifier: String

            func isContentEqual(to source: Section) -> Bool {

                return !self.isReloaded
                    && self.differenceIdentifier == source.differenceIdentifier
            }
            
            
            // MARK: DifferentiableSection
            
            var elements: [Item] = []

            init<S: Sequence>(source: Section, elements: S) where S.Element == Item {

                self.init(
                    differenceIdentifier: source.differenceIdentifier,
                    indexTitle: source.indexTitle,
                    items: Array(elements),
                    isReloaded: source.isReloaded
                )
            }
        }


        // MARK: - Item

        internal struct Item: Differentiable, Equatable {

            var isReloaded: Bool

            init(differenceIdentifier: NSManagedObjectID, isReloaded: Bool = false) {

                self.differenceIdentifier = differenceIdentifier
                self.isReloaded = isReloaded
            }

            // MARK: Differentiable

            let differenceIdentifier: NSManagedObjectID

            func isContentEqual(to source: Item) -> Bool {

                return !self.isReloaded
                    && self.differenceIdentifier == source.differenceIdentifier
            }
        }


        // MARK: - BackingStructure

        fileprivate struct BackingStructure {

            // MARK: Internal

            let sectionIndexTransformer: (_ sectionName: String?) -> String?
            var sections: [Section]
            private(set) var reloadedItems: Set<NSManagedObjectID>

            init() {

                self.sectionIndexTransformer = { _ in nil }
                self.sections = []
                self.reloadedItems = []
            }

            init(
                sections: [NSFetchedResultsSectionInfo],
                sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?,
                fetchOffset: Int,
                fetchLimit: Int?
            ) {

                let sliceItems: (_ array: [Any], _ offset: Int) -> Array<Any>.SubSequence
                if let fetchLimit = fetchLimit {

                    var remainingCount = fetchLimit
                    sliceItems = {

                        let slice = $0[$1...].prefix(remainingCount)
                        remainingCount -= slice.count
                        return slice
                    }
                }
                else {

                    sliceItems = { $0[$1...] }
                }
                var newSections: [Internals.DiffableDataSourceSnapshot.Section] = []
                var ignoreCount = fetchOffset
                for section in sections {

                    let objects = section.objects ?? []
                    guard objects.indices.contains(ignoreCount) else {

                        ignoreCount -= objects.count
                        continue
                    }
                    let items = sliceItems(objects, ignoreCount)
                        .map({ Item(differenceIdentifier: ($0 as! NSManagedObject).objectID) })
                    ignoreCount = 0
                    guard !items.isEmpty else {

                        continue
                    }
                    newSections.append(
                        Section(
                            differenceIdentifier: section.name,
                            indexTitle: section.indexTitle,
                            items: items
                        )
                    )
                }
                self.sectionIndexTransformer = sectionIndexTransformer
                self.sections = newSections
                self.reloadedItems = []
            }

            var allSectionIDs: [String] {

                return self.sections.map({ $0.differenceIdentifier })
            }

            var allItemsCount: Int {

                return self.sections.reduce(into: 0) { (result, section) in

                    result += section.elements.count
                }
            }

            var allItemIDs: [NSManagedObjectID] {

                return self.sections.lazy.flatMap({ $0.elements }).map({ $0.differenceIdentifier })
            }

            func items(in sectionID: String) -> [NSManagedObjectID] {

                guard let sectionIndex = self.sectionIndex(of: sectionID) else {

                    Internals.abort("Section \"\(sectionID)\" does not exist")
                }
                return self.sections[sectionIndex].elements.map({ $0.differenceIdentifier })
            }
            
            func unsafeItem(at indexPath: IndexPath) -> NSManagedObjectID {
                
                return self.sections[indexPath.section]
                    .elements[indexPath.item]
                    .differenceIdentifier
            }

            func section(containing itemID: NSManagedObjectID) -> String? {

                return self.itemPositionMap(itemID)?.section.differenceIdentifier
            }

            mutating func append<C: Collection>(
                itemIDs: C,
                to sectionID: String?
            ) where C.Element == NSManagedObjectID {

                let index: Array<Section>.Index
                if let sectionID = sectionID {

                    guard let sectionIndex = self.sectionIndex(of: sectionID) else {

                        Internals.abort("Section \"\(sectionID)\" does not exist")
                    }
                    index = sectionIndex
                }
                else {

                    let section = self.sections
                    guard !section.isEmpty else {

                        Internals.abort("No sections exist")
                    }
                    index = section.index(before: section.endIndex)
                }
                let items = itemIDs.lazy.map({ Item(differenceIdentifier: $0) })
                self.sections[index].elements.append(contentsOf: items)
            }
            
            mutating func unsafeAppend<C: Collection>(
                _ itemIDs: C,
                toSectionAt sectionIndex: Int?
            ) where C.Element == NSManagedObjectID  {
                
                let index: Array<Section>.Index
                if let sectionIndex = sectionIndex {

                    index = sectionIndex
                }
                else {
                    
                    let section = self.sections
                    index = section.index(before: section.endIndex)
                }
                let items = itemIDs.lazy.map({ Item(differenceIdentifier: $0) })
                self.sections[index].elements.append(contentsOf: items)
            }

            mutating func insert<C: Collection>(
                itemIDs: C,
                before beforeItemID: NSManagedObjectID
            ) where C.Element == NSManagedObjectID {

                guard let itemPosition = self.itemPositionMap(beforeItemID) else {

                    Internals.abort("Item \(beforeItemID) does not exist")
                }
                let items = itemIDs.lazy.map({ Item(differenceIdentifier: $0) })
                self.sections[itemPosition.sectionIndex].elements
                    .insert(contentsOf: items, at: itemPosition.itemRelativeIndex)
            }

            mutating func insert<C: Collection>(
                itemIDs: C,
                after afterItemID: NSManagedObjectID
            ) where C.Element == NSManagedObjectID {

                guard let itemPosition = self.itemPositionMap(afterItemID) else {

                    Internals.abort("Item \(afterItemID) does not exist")
                }
                let itemIndex = self.sections[itemPosition.sectionIndex].elements
                    .index(after: itemPosition.itemRelativeIndex)
                let items = itemIDs.lazy.map({ Item(differenceIdentifier: $0) })
                self.sections[itemPosition.sectionIndex].elements
                    .insert(contentsOf: items, at: itemIndex)
            }
            
            mutating func unsafeInsert<C: Collection>(
                itemIDs: C,
                at indexPath: IndexPath
            ) where C.Element == NSManagedObjectID {
                
                let items = itemIDs.lazy.map({ Item(differenceIdentifier: $0) })
                self.sections[indexPath.section].elements
                    .insert(contentsOf: items, at: indexPath.item)
            }

            mutating func remove<S: Sequence>(itemIDs: S) where S.Element == NSManagedObjectID {

                let itemPositionMap = self.itemPositionMap()
                var removeIndexSetMap: [Int: IndexSet] = [:]

                for itemID in itemIDs {

                    guard let itemPosition = itemPositionMap[itemID] else {

                        continue
                    }
                    removeIndexSetMap[itemPosition.sectionIndex, default: []]
                        .insert(itemPosition.itemRelativeIndex)
                }
                for (sectionIndex, removeIndexSet) in removeIndexSetMap {

                    for range in removeIndexSet.rangeView.reversed() {

                        self.sections[sectionIndex].elements.removeSubrange(range)
                    }
                }
            }
            
            mutating func unsafeRemove<S: Sequence>(itemsAt indexPaths: S) where S.Element == IndexPath {
                
                var removeIndexSetMap: [Int: IndexSet] = [:]
                for indexPath in indexPaths {
                    
                    removeIndexSetMap[indexPath.section, default: []]
                        .insert(indexPath.item)
                }
                for (sectionIndex, removeIndexSet) in removeIndexSetMap {

                    for range in removeIndexSet.rangeView.reversed() {
                        
                        self.sections[sectionIndex].elements.removeSubrange(range)
                    }
                }
            }

            mutating func removeAllItems() {

                for sectionIndex in self.sections.indices {

                    self.sections[sectionIndex].elements.removeAll()
                }
            }

            mutating func removeAllEmptySections() {

                self.sections.removeAll(where: { $0.elements.isEmpty })
            }

            mutating func move(
                itemID: NSManagedObjectID,
                before beforeItemID: NSManagedObjectID
            ) {

                guard let removed = self.remove(itemID: itemID) else {

                    Internals.abort("Item \(itemID) does not exist")
                }
                guard let itemPosition = self.itemPositionMap(beforeItemID) else {

                    Internals.abort("Item \(beforeItemID) does not exist")
                }
                self.sections[itemPosition.sectionIndex].elements
                    .insert(removed, at: itemPosition.itemRelativeIndex)
            }

            mutating func move(
                itemID: NSManagedObjectID,
                after afterItemID: NSManagedObjectID
            ) {

                guard let removed = self.remove(itemID: itemID) else {

                    Internals.abort("Item \(itemID) does not exist")
                }
                guard let itemPosition = self.itemPositionMap(afterItemID) else {

                    Internals.abort("Item \(afterItemID) does not exist")
                }
                let itemIndex = self.sections[itemPosition.sectionIndex].elements
                    .index(after: itemPosition.itemRelativeIndex)
                self.sections[itemPosition.sectionIndex].elements
                    .insert(removed, at: itemIndex)
            }
            
            mutating func unsafeMove(
                itemAt indexPath: IndexPath,
                to newIndexPath: IndexPath
            ) {
                
                let itemID = self.sections[indexPath.section].elements
                    .remove(at: indexPath.item)
                self.sections[newIndexPath.section].elements
                    .insert(itemID, at: newIndexPath.item)
            }

            mutating func update<S: Sequence>(itemIDs: S) where S.Element == NSManagedObjectID {

                let itemPositionMap = self.itemPositionMap()
                var newItemIDs: Set<NSManagedObjectID> = []
                for itemID in itemIDs {

                    guard let itemPosition = itemPositionMap[itemID] else {

                        continue
                    }
                    self.sections[itemPosition.sectionIndex]
                        .elements[itemPosition.itemRelativeIndex].isReloaded = true
                    newItemIDs.insert(itemID)
                }
                self.reloadedItems.formUnion(newItemIDs)
            }
            
            mutating func unsafeUpdate<S: Sequence>(itemsAt indexPaths: S) where S.Element == IndexPath {
                
                var newItemIDs: Set<NSManagedObjectID> = []
                for indexPath in indexPaths {

                    self.sections[indexPath.section]
                        .elements[indexPath.item].isReloaded = true
                    newItemIDs.insert(self.unsafeItem(at: indexPath))
                }
                self.reloadedItems.formUnion(newItemIDs)
            }

            mutating func append<C: Collection>(sectionIDs: C) where C.Element == String {

                let sectionIndexTransformer = self.sectionIndexTransformer
                let newSections = sectionIDs.lazy.map {
                    
                    return Section(
                        differenceIdentifier: $0,
                        indexTitle: sectionIndexTransformer($0)
                    )
                }
                self.sections.append(contentsOf: newSections)
            }

            mutating func insert<C: Collection>(
                sectionIDs: C,
                before beforeSectionID: String
            ) where C.Element == String {

                guard let sectionIndex = self.sectionIndex(of: beforeSectionID) else {

                    Internals.abort("Section \"\(beforeSectionID)\" does not exist")
                }
                let sectionIndexTransformer = self.sectionIndexTransformer
                let newSections = sectionIDs.lazy.map {
                    
                    return Section(
                        differenceIdentifier: $0,
                        indexTitle: sectionIndexTransformer($0)
                    )
                }
                self.sections.insert(contentsOf: newSections, at: sectionIndex)
            }

            mutating func insert<C: Collection>(
                sectionIDs: C,
                after afterSectionID: String
            ) where C.Element == String {

                guard let beforeIndex = self.sectionIndex(of: afterSectionID) else {

                    Internals.abort("Section \"\(afterSectionID)\" does not exist")
                }
                let sectionIndexTransformer = self.sectionIndexTransformer
                let sectionIndex = self.sections.index(after: beforeIndex)
                let newSections = sectionIDs.lazy.map {
                    
                    return Section(
                        differenceIdentifier: $0,
                        indexTitle: sectionIndexTransformer($0)
                    )
                }
                self.sections.insert(contentsOf: newSections, at: sectionIndex)
            }
            
            mutating func unsafeInsert<C: Collection>(
                _ sectionIDs: C,
                at sectionIndex: Int
            ) where C.Element == String {
                
                let sectionIndexTransformer = self.sectionIndexTransformer
                let newSections = sectionIDs.lazy.map {
                    
                    return Section(
                        differenceIdentifier: $0,
                        indexTitle: sectionIndexTransformer($0)
                    )
                }
                self.sections.insert(contentsOf: newSections, at: sectionIndex)
            }

            mutating func remove<S: Sequence>(sectionIDs: S) where S.Element == String {

                for sectionID in sectionIDs {

                    self.remove(sectionID: sectionID)
                }
            }
            
            mutating func unsafeRemove<S: Sequence>(
                sectionsAt sectionIndices: S
            ) where S.Element == Int {
                
                for sectionIndex in sectionIndices.sorted(by: >) {
                    
                    self.sections.remove(at: sectionIndex)
                }
            }

            mutating func move(sectionID: String, before beforeSectionID: String) {

                guard let removed = self.remove(sectionID: sectionID) else {

                    Internals.abort("Section \"\(sectionID)\" does not exist")
                }
                guard let sectionIndex = self.sectionIndex(of: beforeSectionID) else {

                    Internals.abort("Section \"\(beforeSectionID)\" does not exist")
                }
                self.sections.insert(removed, at: sectionIndex)
            }

            mutating func move(sectionID: String, after afterSectionID: String) {

                guard let removed = self.remove(sectionID: sectionID) else {

                    Internals.abort("Section \"\(sectionID)\" does not exist")
                }
                guard let beforeIndex = self.sectionIndex(of: afterSectionID) else {

                    Internals.abort("Section \"\(afterSectionID)\" does not exist")
                }
                let sectionIndex = self.sections.index(after: beforeIndex)
                self.sections.insert(removed, at: sectionIndex)
            }
            
            mutating func unsafeMove(
                sectionAt sectionIndex: Int,
                to newSectionIndex: Int
            ) {
                
                self.sections.move(
                    fromOffsets: .init(integer: sectionIndex),
                    toOffset: newSectionIndex
                )
            }

            mutating func update<S: Sequence>(
                sectionIDs: S
            ) where S.Element == String {

                for sectionID in sectionIDs {

                    guard let sectionIndex = self.sectionIndex(of: sectionID) else {

                        continue
                    }
                    self.sections[sectionIndex].isReloaded = true
                }
            }
            
            mutating func unsafeUpdate<S: Sequence>(
                sectionsAt sectionIndices: S
            ) where S.Element == Int {
                
                for sectionIndex in sectionIndices {

                    self.sections[sectionIndex].isReloaded = true
                }
            }


            // MARK: Private

            private func sectionIndex(of sectionID: String) -> Array<Section>.Index? {

                return self.sections.firstIndex(where: { $0.differenceIdentifier == sectionID })
            }

            @discardableResult
            private mutating func remove(itemID: NSManagedObjectID) -> Item? {

                guard let itemPosition = self.itemPositionMap(itemID) else {

                    return nil
                }
                return self.sections[itemPosition.sectionIndex].elements
                    .remove(at: itemPosition.itemRelativeIndex)
            }

            @discardableResult
            private mutating func remove(sectionID: String) -> Section? {

                guard let sectionIndex = self.sectionIndex(of: sectionID) else {

                    return nil
                }
                return self.sections.remove(at: sectionIndex)
            }

            private func itemPositionMap(_ itemID: NSManagedObjectID) -> ItemPosition? {

                let sections = self.sections
                for (sectionIndex, section) in sections.enumerated() {

                    for (itemRelativeIndex, item) in section.elements.enumerated() {

                        guard item.differenceIdentifier == itemID else {

                            continue
                        }
                        return ItemPosition(
                            item: item,
                            itemRelativeIndex: itemRelativeIndex,
                            section: section,
                            sectionIndex: sectionIndex
                        )
                    }
                }
                return nil
            }

            private func itemPositionMap() -> [NSManagedObjectID: ItemPosition] {

                return self.sections.enumerated().reduce(into: [:]) { result, section in

                    for (itemRelativeIndex, item) in section.element.elements.enumerated() {

                        result[item.differenceIdentifier] = ItemPosition(
                            item: item,
                            itemRelativeIndex: itemRelativeIndex,
                            section: section.element,
                            sectionIndex: section.offset
                        )
                    }
                }
            }


            // MARK: - ItemPosition

            fileprivate struct ItemPosition {

                let item: Item
                let itemRelativeIndex: Int
                let section: Section
                let sectionIndex: Int
            }
        }
    }
}


#endif
