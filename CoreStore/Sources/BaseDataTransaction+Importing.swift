//
//  BaseDataTransaction+Importing.swift
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


// MARK: - BaseDataTransaction

extension BaseDataTransaction {
    
    /**
     Creates an `ImportableObject` by importing from the specified import source.
     
     - parameter into: an `Into` clause specifying the entity type
     - parameter source: the object to import values from
     - throws: an `Error` thrown from any of the `ImportableObject` methods
     - returns: the created `ImportableObject` instance, or `nil` if the import was ignored
     */
    public func importObject<O: ImportableObject>(
        _ into: Into<O>,
        source: O.ImportSource
    ) throws(any Swift.Error) -> O? {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to import an object of type \(Internals.typeName(into.entityClass)) outside the transaction's designated queue."
        )

        return try Internals.autoreleasepool {

            let entityType = into.entityClass
            guard entityType.shouldInsert(from: source, in: self) else {

                return nil
            }

            let object = self.create(into)
            try object.didInsert(from: source, in: self)
            return object
        }
    }
    
    /**
     Updates an existing `ImportableObject` by importing values from the specified import source.
     
     - parameter object: the `ImportableObject` to update
     - parameter source: the object to import values from
     - throws: an `Error` thrown from any of the `ImportableObject` methods
     */
    public func importObject<O: ImportableObject>(
        _ object: O,
        source: O.ImportSource
    ) throws(any Swift.Error) {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to import an object of type \(Internals.typeName(object)) outside the transaction's designated queue."
        )

        try Internals.autoreleasepool {

            let entityType = object.runtimeType()
            guard entityType.shouldInsert(from: source, in: self) else {

                return
            }
            try object.didInsert(from: source, in: self)
        }
    }
    
    /**
     Creates multiple `ImportableObject`s by importing from the specified array of import sources.
     
     - parameter into: an `Into` clause specifying the entity type
     - parameter sourceArray: the array of objects to import values from
     - throws: an `Error` thrown from any of the `ImportableObject` methods
     - returns: the array of created `ImportableObject` instances
     */
    public func importObjects<O: ImportableObject, S: Sequence>(
        _ into: Into<O>,
        sourceArray: S
    ) throws(any Swift.Error) -> [O] where S.Iterator.Element == O.ImportSource {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to import an object of type \(Internals.typeName(into.entityClass)) outside the transaction's designated queue."
        )

        return try Internals.autoreleasepool {

            return try sourceArray.compactMap { (source) -> O? in

                let entityType = into.entityClass
                guard entityType.shouldInsert(from: source, in: self) else {

                    return nil
                }
                return try autoreleasepool {

                    let object = self.create(into)
                    try object.didInsert(from: source, in: self)
                    return object
                }
            }
        }
    }
    
    /**
     Updates an existing `ImportableUniqueObject` or creates a new instance by importing from the specified import source.
     
     - parameter into: an `Into` clause specifying the entity type
     - parameter source: the object to import values from
     - throws: an `Error` thrown from any of the `ImportableUniqueObject` methods
     - returns: the created/updated `ImportableUniqueObject` instance, or `nil` if the import was ignored
     */
    public func importUniqueObject<O: ImportableUniqueObject>(
        _ into: Into<O>,
        source: O.ImportSource
    ) throws(any Swift.Error) -> O? {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to import an object of type \(Internals.typeName(into.entityClass)) outside the transaction's designated queue."
        )

        return try Internals.autoreleasepool {

            let entityType = into.entityClass
            let uniqueIDKeyPath = entityType.uniqueIDKeyPath
            guard let uniqueIDValue = try entityType.uniqueID(from: source, in: self) else {

                return nil
            }

            if let object = try self.fetchOne(From(entityType), Where<O>(uniqueIDKeyPath, isEqualTo: uniqueIDValue)) {

                guard entityType.shouldUpdate(from: source, in: self) else {

                    return nil
                }
                try object.update(from: source, in: self)
                return object
            }
            else {

                guard entityType.shouldInsert(from: source, in: self) else {

                    return nil
                }
                let object = self.create(into)
                object.uniqueIDValue = uniqueIDValue
                try object.didInsert(from: source, in: self)
                return object
            }
        }
    }
    
    /**
     Updates existing `ImportableUniqueObject`s or creates them by importing from the specified array of import sources.
     `ImportableUniqueObject` methods are called on the objects in the same order as they are in the `sourceArray`, and are returned in an array with that same order.
     - Warning: If `sourceArray` contains multiple import sources with same ID, only the last `ImportSource` of the duplicates will be imported.
     
     - parameter into: an `Into` clause specifying the entity type
     - parameter sourceArray: the array of objects to import values from
     - parameter preProcess: a closure that lets the caller tweak the internal `UniqueIDType`-to-`ImportSource` mapping to be used for importing. Callers can remove from/add to/update `mapping` and return the updated array from the closure.
     - throws: an `Error` thrown from any of the `ImportableUniqueObject` methods
     - returns: the array of created/updated `ImportableUniqueObject` instances
     */
    public func importUniqueObjects<O: ImportableUniqueObject, S: Sequence>(
        _ into: Into<O>,
        sourceArray: S,
        preProcess: @escaping (
            _ mapping: [O.UniqueIDType: O.ImportSource]
        ) throws(any Swift.Error) -> [O.UniqueIDType: O.ImportSource] = { $0 }
    ) throws(any Swift.Error) -> [O] where S.Iterator.Element == O.ImportSource {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to import an object of type \(Internals.typeName(into.entityClass)) outside the transaction's designated queue."
        )

        return try Internals.autoreleasepool {

            let entityType = into.entityClass
            var importSourceByID = Dictionary<O.UniqueIDType, O.ImportSource>()
            let sortedIDs = try Internals.autoreleasepool {

                return try sourceArray.compactMap { (source) -> O.UniqueIDType? in

                    guard let uniqueIDValue = try entityType.uniqueID(from: source, in: self) else {

                        return nil
                    }
                    importSourceByID[uniqueIDValue] = source // effectively replaces duplicate with the latest
                    return uniqueIDValue
                }
            }

            importSourceByID = try Internals.autoreleasepool { try preProcess(importSourceByID) }

            var existingObjectsByID = Dictionary<O.UniqueIDType, O>()
            try self
                .fetchAll(From(entityType), Where<O>(entityType.uniqueIDKeyPath, isMemberOf: sortedIDs))
                .forEach { existingObjectsByID[$0.uniqueIDValue] = $0 }

            var processedObjectIDs = Set<O.UniqueIDType>()
            var result = [O]()

            for objectID in sortedIDs where !processedObjectIDs.contains(objectID) {

                guard let source = importSourceByID[objectID] else {

                    continue
                }
                try Internals.autoreleasepool {

                    if let object = existingObjectsByID[objectID]
                        ?? self.context.insertedObjects
                        .compactMap({ O.cs_matches(object: $0) ? O.cs_fromRaw(object: $0) : nil })
                        .first(where: { $0.uniqueIDValue == objectID }) {

                        guard entityType.shouldUpdate(from: source, in: self) else {

                            return
                        }
                        try object.update(from: source, in: self)
                        result.append(object)
                    }
                    else if entityType.shouldInsert(from: source, in: self) {

                        let object = self.create(into)
                        object.uniqueIDValue = objectID
                        try object.didInsert(from: source, in: self)
                        result.append(object)
                    }
                    processedObjectIDs.insert(objectID)
                }
            }
            return result
        }
    }
}
