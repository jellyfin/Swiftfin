//
//  DiffableDataSourceSnapshotProtocol.swift
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

import Foundation
import CoreData


// MARK: - DiffableDataSourceSnapshotProtocol

internal protocol DiffableDataSourceSnapshotProtocol {

    init()

    var numberOfItems: Int { get }
    var numberOfSections: Int { get }
    var sectionIdentifiers: [String] { get }
    var itemIdentifiers: [NSManagedObjectID] { get }

    func numberOfItems(inSection identifier: String) -> Int
    func itemIdentifiers(inSection identifier: String) -> [NSManagedObjectID]
    func sectionIdentifier(containingItem identifier: NSManagedObjectID) -> String?
    func indexOfItem(_ identifier: NSManagedObjectID) -> Int?
    func indexOfSection(_ identifier: String) -> Int?

    mutating func appendItems<C: Collection>(_ identifiers: C, toSection sectionIdentifier: String?) where C.Element == NSManagedObjectID
    mutating func insertItems<C: Collection>(_ identifiers: C, beforeItem beforeIdentifier: NSManagedObjectID) where C.Element == NSManagedObjectID
    mutating func insertItems<C: Collection>(_ identifiers: C, afterItem afterIdentifier: NSManagedObjectID) where C.Element == NSManagedObjectID
    mutating func deleteItems<C: Collection>(_ identifiers: C) where C.Element == NSManagedObjectID
    mutating func deleteAllItems()
    mutating func moveItem(_ identifier: NSManagedObjectID, beforeItem toIdentifier: NSManagedObjectID)
    mutating func moveItem(_ identifier: NSManagedObjectID, afterItem toIdentifier: NSManagedObjectID)
    mutating func reloadItems<C: Collection>(_ identifiers: C) where C.Element == NSManagedObjectID
    mutating func appendSections<C: Collection>(_ identifiers: C) where C.Element == String
    mutating func insertSections<C: Collection>(_ identifiers: C, beforeSection toIdentifier: String) where C.Element == String
    mutating func insertSections<C: Collection>(_ identifiers: C, afterSection toIdentifier: String) where C.Element == String
    mutating func deleteSections<C: Collection>(_ identifiers: C) where C.Element == String
    mutating func moveSection(_ identifier: String, beforeSection toIdentifier: String)
    mutating func moveSection(_ identifier: String, afterSection toIdentifier: String)
    mutating func reloadSections<C: Collection>(_ identifiers: C) where C.Element == String
    
    mutating func unsafeAppendItems<C: Collection>(_ identifiers: C, toSectionAt sectionIndex: Int) where C.Element == NSManagedObjectID
    mutating func unsafeInsertItems<C: Collection>(_ identifiers: C, at indexPath: IndexPath) where C.Element == NSManagedObjectID
    mutating func unsafeDeleteItems<C: Collection>(at indexPaths: C) where C.Element == IndexPath
    mutating func unsafeMoveItem(at indexPath: IndexPath, to newIndexPath: IndexPath)
    mutating func unsafeReloadItems<C: Collection>(at indexPaths: C) where C.Element == IndexPath
    mutating func unsafeInsertSections<C: Collection>(_ identifiers: C, at sectionIndex: Int) where C.Element == String
    mutating func unsafeDeleteSections<C: Collection>(at sectionIndices: C) where C.Element == Int
    mutating func unsafeMoveSection(at sectionIndex: Int, to newSectionIndex: Int)
    mutating func unsafeReloadSections<C: Collection>(at sectionIndices: C) where C.Element == Int
    
}
