//
//  SynchronousDataTransaction.swift
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


// MARK: - SynchronousDataTransaction

/**
 The `SynchronousDataTransaction` provides an interface for `DynamicObject` creates, updates, and deletes. A transaction object should typically be only used from within a transaction block initiated from `DataStack.beginSynchronous(_:)`.
 */
public final class SynchronousDataTransaction: BaseDataTransaction {
    
    /**
     Cancels a transaction by throwing `CoreStoreError.userCancelled`.
     ```
     try transaction.cancel()
     ```
     - Important: Always use plain `try` on a `cancel()` call. Never use `try?` or `try!`. Using `try?` will swallow the cancellation and the transaction will proceed to commit as normal. Using `try!` will crash the app as `cancel()` will *always* throw an error.
     */
    public func cancel() throws(CoreStoreError) -> Never {

        throw CoreStoreError.userCancelled
    }
    
    
    // MARK: BaseDataTransaction
    
    /**
     Creates a new `NSManagedObject` or `CoreStoreObject` with the specified entity type.
     
     - parameter into: the `Into` clause indicating the destination `NSManagedObject` or `CoreStoreObject` entity type and the destination configuration
     - returns: a new `NSManagedObject` or `CoreStoreObject` instance of the specified entity type.
     */
    public override func create<O>(
        _ into: Into<O>
    ) -> O {

        Internals.assert(
            !self.isCommitted,
            "Attempted to create an entity of type \(Internals.typeName(into.entityClass)) from an already committed \(Internals.typeName(self))."
        )
        
        return super.create(into)
    }
    
    /**
     Returns an editable proxy of a specified `NSManagedObject` or `CoreStoreObject`.
     
     - parameter object: the `NSManagedObject` or `CoreStoreObject` to be edited
     - returns: an editable proxy for the specified `NSManagedObject` or `CoreStoreObject`.
     */
    public override func edit<O: DynamicObject>(
        _ object: O?
    ) -> O? {

        Internals.assert(
            !self.isCommitted,
            "Attempted to update an entity of type \(Internals.typeName(object)) from an already committed \(Internals.typeName(self))."
        )
        
        return super.edit(object)
    }
    
    /**
     Returns an editable proxy of the object with the specified `NSManagedObjectID`.
     
     - parameter into: an `Into` clause specifying the entity type
     - parameter objectID: the `NSManagedObjectID` for the object to be edited
     - returns: an editable proxy for the specified `NSManagedObject` or `CoreStoreObject`.
     */
    public override func edit<O>(
        _ into: Into<O>,
        _ objectID: NSManagedObjectID
    ) -> O? {

        Internals.assert(
            !self.isCommitted,
            "Attempted to update an entity of type \(Internals.typeName(into.entityClass)) from an already committed \(Internals.typeName(self))."
        )
        
        return super.edit(into, objectID)
    }

    /**
     Deletes the objects with the specified `NSManagedObjectID`s.

     - parameter objectIDs: the `NSManagedObjectID`s of the objects to delete
     */
    public override func delete<S: Sequence>(
        objectIDs: S
    ) where S.Iterator.Element: NSManagedObjectID {

        Internals.assert(
            !self.isCommitted,
            "Attempted to delete an entities from an already committed \(Internals.typeName(self))."
        )

        super.delete(objectIDs: objectIDs)
    }

    /**
     Deletes the specified `NSManagedObject`s or `CoreStoreObject`s represented by series of `ObjectRepresentation`s.

     - parameter object: the `ObjectRepresentation` representing an `NSManagedObject` or `CoreStoreObject` to be deleted
     - parameter objects: other `ObjectRepresentation`s representing `NSManagedObject`s or `CoreStoreObject`s to be deleted
     */
    public override func delete<O: ObjectRepresentation>(
        _ object: O?,
        _ objects: O?...
    ) {

        Internals.assert(
            !self.isCommitted,
            "Attempted to delete an entities from an already committed \(Internals.typeName(self))."
        )

        super.delete(([object] + objects).compactMap { $0 })
    }

    /**
    Deletes the specified `NSManagedObject`s or `CoreStoreObject`s represented by an `ObjectRepresenation`.

    - parameter objects: the `ObjectRepresenation`s representing `NSManagedObject`s or `CoreStoreObject`s to be deleted
     */
    public override func delete<S: Sequence>(
        _ objects: S
    ) where S.Iterator.Element: ObjectRepresentation {

        Internals.assert(
            !self.isCommitted,
            "Attempted to delete an entities from an already committed \(Internals.typeName(self))."
        )

        super.delete(objects)
    }
    
    
    // MARK: Internal
    
    internal init(
        mainContext: NSManagedObjectContext,
        queue: DispatchQueue,
        sourceIdentifier: Any?
    ) {
        
        super.init(
            mainContext: mainContext,
            queue: queue,
            supportsUndo: false,
            bypassesQueueing: false,
            sourceIdentifier: sourceIdentifier
        )
    }
    
    internal func autoCommit(
        waitForMerge: Bool
    ) -> (
        hasChanges: Bool,
        error: CoreStoreError?
    ) {

        self.isCommitted = true
        let result = self.context.saveSynchronously(
            waitForMerge: waitForMerge,
            sourceIdentifier: self.sourceIdentifier
        )
        self.result = result
        defer {
            
            self.context.reset()
        }
        return result
    }
}
