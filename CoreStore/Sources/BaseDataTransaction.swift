//
//  BaseDataTransaction.swift
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

/**
 The `BaseDataTransaction` is an abstract interface for `NSManagedObject` creates, updates, and deletes. All `BaseDataTransaction` subclasses manage a private `NSManagedObjectContext` which are direct children of the `NSPersistentStoreCoordinator`'s root `NSManagedObjectContext`. This means that all updates are saved first to the persistent store, and then propagated up to the read-only `NSManagedObjectContext`.
 */
public /*abstract*/ class BaseDataTransaction {
    
    // MARK: Object management
    
    /**
     Indicates if the transaction has pending changes
     */
    public var hasChanges: Bool {
        
        return self.context.hasChanges
    }
    
    /**
     Creates a new `NSManagedObject` or `CoreStoreObject` with the specified entity type.
     
     - parameter into: the `Into` clause indicating the destination `NSManagedObject` or `CoreStoreObject` entity type and the destination configuration
     - returns: a new `NSManagedObject` or `CoreStoreObject` instance of the specified entity type.
     */
    public func create<O>(_ into: Into<O>) -> O {
        
        let entityClass = into.entityClass
        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to create an entity of type \(Internals.typeName(entityClass)) outside its designated queue."
        )
        
        let context = self.context
        let dataStack = context.parentStack!
        let entityIdentifier = Internals.EntityIdentifier(entityClass)
        if into.inferStoreIfPossible {
            
            switch dataStack.persistentStore(
                for: entityIdentifier,
                configuration: nil,
                inferStoreIfPossible: true
            ) {
                
            case (let persistentStore?, _):
                return entityClass.cs_forceCreate(
                    entityDescription: dataStack.entityDescription(for: entityIdentifier)!,
                    into: context,
                    assignTo: persistentStore
                )
                
            case (nil, true):
                Internals.abort("Attempted to create an entity of type \(Internals.typeName(entityClass)) with ambiguous destination persistent store, but the configuration name was not specified.")
                
            default:
                Internals.abort("Attempted to create an entity of type \(Internals.typeName(entityClass)), but a destination persistent store containing the entity type could not be found.")
            }
        }
        else {
            
            switch dataStack.persistentStore(
                for: entityIdentifier,
                configuration: into.configuration
                    ?? DataStack.defaultConfigurationName,
                inferStoreIfPossible: false
            ) {
                
            case (let persistentStore?, _):
                return entityClass.cs_forceCreate(
                    entityDescription: dataStack.entityDescription(for: entityIdentifier)!,
                    into: context,
                    assignTo: persistentStore
                )
                
            case (nil, true):
                Internals.abort("Attempted to create an entity of type \(Internals.typeName(entityClass)) with ambiguous destination persistent store, but the configuration name was not specified.")
                
            default:
                if let configuration = into.configuration {
                    
                    Internals.abort("Attempted to create an entity of type \(Internals.typeName(entityClass)) into the configuration \"\(configuration)\", which it doesn't belong to.")
                }
                else {
                    
                    Internals.abort("Attempted to create an entity of type \(Internals.typeName(entityClass)) into the default configuration, which it doesn't belong to.")
                }
            }
        }
    }
    
    /**
     Returns an editable proxy of a specified `NSManagedObject` or `CoreStoreObject`.
     
     - parameter object: the `NSManagedObject` or `CoreStoreObject` type to be edited
     - returns: an editable proxy for the specified `NSManagedObject` or `CoreStoreObject`.
     */
    public func edit<O: DynamicObject>(
        _ object: O?
    ) -> O? {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to update an entity of type \(Internals.typeName(object)) outside its designated queue."
        )
        guard let object = object else {
            
            return nil
        }
        return self.context.fetchExisting(object)
    }
    
    /**
     Returns an editable proxy of the object with the specified `NSManagedObjectID`.
     
     - parameter into: an `Into` clause specifying the entity type
     - parameter objectID: the `NSManagedObjectID` for the object to be edited
     - returns: an editable proxy for the specified `NSManagedObject` or `CoreStoreObject`.
     */
    public func edit<O>(
        _ into: Into<O>,
        _ objectID: NSManagedObjectID
    ) -> O? {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to update an entity of type \(Internals.typeName(into.entityClass)) outside its designated queue."
        )
        Internals.assert(
            into.inferStoreIfPossible
                || (into.configuration ?? DataStack.defaultConfigurationName) == objectID.persistentStore?.configurationName,
            "Attempted to update an entity of type \(Internals.typeName(into.entityClass)) but the specified persistent store do not match the `NSManagedObjectID`."
        )
        return self.fetchExisting(objectID)
    }

    /**
     Deletes the objects with the specified `NSManagedObjectID`s.

     - parameter objectIDs: the `NSManagedObjectID`s of the objects to delete
     */
    public func delete<S: Sequence>(
        objectIDs: S
    ) where S.Iterator.Element: NSManagedObjectID {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to delete an entity outside its designated queue."
        )
        let context = self.context
        objectIDs.forEach {

            context.fetchExisting($0).map(context.delete(_:))
        }
    }
    
    /**
     Deletes the specified `NSManagedObject`s or `CoreStoreObject`s represented by series of `ObjectRepresentation`s.
     
     - parameter object: the `ObjectRepresentation` representing an `NSManagedObject` or `CoreStoreObject` to be deleted
     - parameter objects: other `ObjectRepresentation`s representing `NSManagedObject`s or `CoreStoreObject`s to be deleted
     */
    public func delete<O: ObjectRepresentation>(
        _ object: O?,
        _ objects: O?...
    ) {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to delete an entity outside its designated queue."
        )
        self.delete(([object] + objects).compactMap { $0 })
    }
    
    /**
     Deletes the specified `NSManagedObject`s or `CoreStoreObject`s represented by an `ObjectRepresenation`.
     
     - parameter objects: the `ObjectRepresenation`s representing `NSManagedObject`s or `CoreStoreObject`s to be deleted
     */
    public func delete<S: Sequence>(
        _ objects: S
    ) where S.Iterator.Element: ObjectRepresentation {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to delete entities outside their designated queue."
        )
        let context = self.context
        objects.forEach {

            $0.asEditable(in: self).map({ context.delete($0.cs_toRaw()) })
        }
    }
    
    /**
     Refreshes all registered objects `NSManagedObject`s in the transaction.
     */
    public func refreshAndMergeAllObjects() {
        
        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to refresh entities outside their designated queue."
        )
        self.context.refreshAndMergeAllObjects()
    }
    
    
    // MARK: Inspecting Pending Objects

    /**
     Returns `true` if the object has any property values changed. This method should not be called after the `commit()` method was called.

     - parameter object: the `DynamicObject` instance
     - returns: `true` if the object has any property values changed.
     */
    public func objectHasPersistentChangedValues<O: DynamicObject>(
        _ object: O
    ) -> Bool {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to access inserted objects from a \(Internals.typeName(self)) outside its designated queue."
        )
        Internals.assert(
            !self.isCommitted,
            "Attempted to access inserted objects from an already committed \(Internals.typeName(self))."
        )
        return object.cs_toRaw().hasPersistentChangedValues
    }
    
    /**
     Returns all pending `DynamicObject`s of the specified type that were inserted to the transaction. This method should not be called after the `commit()` method was called.
     
     - parameter entity: the `DynamicObject` subclass to filter
     - returns: a `Set` of pending `DynamicObject`s of the specified type that were inserted to the transaction.
     */
    public func insertedObjects<O: DynamicObject>(
        _ entity: O.Type
    ) -> Set<O> {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to access inserted objects from a \(Internals.typeName(self)) outside its designated queue."
        )
        Internals.assert(
            !self.isCommitted,
            "Attempted to access inserted objects from an already committed \(Internals.typeName(self))."
        )
        return Set(self.context.insertedObjects.compactMap({ entity.cs_matches(object: $0) ? entity.cs_fromRaw(object: $0) : nil }))
    }
    
    /**
     Returns all pending `NSManagedObjectID`s that were inserted to the transaction. This method should not be called after the `commit()` method was called.
     
     - returns: a `Set` of pending `NSManagedObjectID`s that were inserted to the transaction.
     */
    public func insertedObjectIDs() -> Set<NSManagedObjectID> {
        
        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to access inserted object IDs from a \(Internals.typeName(self)) outside its designated queue."
        )
        Internals.assert(
            !self.isCommitted,
            "Attempted to access inserted objects IDs from an already committed \(Internals.typeName(self))."
        )
        return Set(self.context.insertedObjects.map { $0.objectID })
    }
    
    /**
     Returns all pending `NSManagedObjectID`s of the specified type that were inserted to the transaction. This method should not be called after the `commit()` method was called.
     
     - parameter entity: the `DynamicObject` subclass to filter
     - returns: a `Set` of pending `NSManagedObjectID`s of the specified type that were inserted to the transaction.
     */
    public func insertedObjectIDs<O: DynamicObject>(
        _ entity: O.Type
    ) -> Set<NSManagedObjectID> {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to access inserted object IDs from a \(Internals.typeName(self)) outside its designated queue."
        )
        Internals.assert(
            !self.isCommitted,
            "Attempted to access inserted objects IDs from an already committed \(Internals.typeName(self))."
        )
        return Set(self.context.insertedObjects.compactMap({ entity.cs_matches(object: $0) ? $0.objectID : nil }))
    }
    
    /**
     Returns all pending `DynamicObject`s of the specified type that were updated in the transaction. This method should not be called after the `commit()` method was called.
     
     - parameter entity: the `DynamicObject` subclass to filter
     - returns: a `Set` of pending `DynamicObject`s of the specified type that were updated in the transaction.
     */
    public func updatedObjects<O: DynamicObject>(
        _ entity: O.Type
    ) -> Set<O> {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to access updated objects from a \(Internals.typeName(self)) outside its designated queue."
        )
        Internals.assert(
            !self.isCommitted,
            "Attempted to access updated objects from an already committed \(Internals.typeName(self))."
        )
        return Set(self.context.updatedObjects.compactMap({ entity.cs_matches(object: $0) ? entity.cs_fromRaw(object: $0) : nil }))
    }
    
    /**
     Returns all pending `NSManagedObjectID`s that were updated in the transaction. This method should not be called after the `commit()` method was called.
     
     - returns: a `Set` of pending `NSManagedObjectID`s that were updated in the transaction.
     */
    public func updatedObjectIDs() -> Set<NSManagedObjectID> {
        
        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to access updated object IDs from a \(Internals.typeName(self)) outside its designated queue."
        )
        Internals.assert(
            !self.isCommitted,
            "Attempted to access updated object IDs from an already committed \(Internals.typeName(self))."
        )
        return Set(self.context.updatedObjects.map { $0.objectID })
    }
    
    /**
     Returns all pending `NSManagedObjectID`s of the specified type that were updated in the transaction. This method should not be called after the `commit()` method was called.
     
     - parameter entity: the `DynamicObject` subclass to filter
     - returns: a `Set` of pending `NSManagedObjectID`s of the specified type that were updated in the transaction.
     */
    public func updatedObjectIDs<O: DynamicObject>(
        _ entity: O.Type
    ) -> Set<NSManagedObjectID> {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to access updated object IDs from a \(Internals.typeName(self)) outside its designated queue."
        )
        Internals.assert(
            !self.isCommitted,
            "Attempted to access updated object IDs from an already committed \(Internals.typeName(self))."
        )
        return Set(self.context.updatedObjects.compactMap({ entity.cs_matches(object: $0) ? $0.objectID : nil }))
    }
    
    /**
     Returns all pending `DynamicObject`s of the specified type that were deleted from the transaction. This method should not be called after the `commit()` method was called.
     
     - parameter entity: the `DynamicObject` subclass to filter
     - returns: a `Set` of pending `DynamicObject`s of the specified type that were deleted from the transaction.
     */
    public func deletedObjects<O: DynamicObject>(
        _ entity: O.Type
    ) -> Set<O> {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to access deleted objects from a \(Internals.typeName(self)) outside its designated queue."
        )
        Internals.assert(
            !self.isCommitted,
            "Attempted to access deleted objects from an already committed \(Internals.typeName(self))."
        )
        return Set(self.context.deletedObjects.compactMap({ entity.cs_matches(object: $0) ? entity.cs_fromRaw(object: $0) : nil }))
    }
    
    /**
     Returns all pending `NSManagedObjectID`s of the specified type that were deleted from the transaction. This method should not be called after the `commit()` method was called.
     
     - parameter entity: the `DynamicObject` subclass to filter
     - returns: a `Set` of pending `NSManagedObjectID`s of the specified type that were deleted from the transaction.
     */
    public func deletedObjectIDs() -> Set<NSManagedObjectID> {
        
        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to access deleted object IDs from a \(Internals.typeName(self)) outside its designated queue."
        )
        Internals.assert(
            !self.isCommitted,
            "Attempted to access deleted object IDs from an already committed \(Internals.typeName(self))."
        )
        return Set(self.context.deletedObjects.map { $0.objectID })
    }
    
    /**
     Returns all pending `NSManagedObjectID`s of the specified type that were deleted from the transaction. This method should not be called after the `commit()` method was called.
     
     - parameter entity: the `DynamicObject` subclass to filter
     - returns: a `Set` of pending `NSManagedObjectID`s of the specified type that were deleted from the transaction.
     */
    public func deletedObjectIDs<O: DynamicObject>(
        _ entity: O.Type
    ) -> Set<NSManagedObjectID> {

        Internals.assert(
            self.isRunningInAllowedQueue(),
            "Attempted to access deleted object IDs from a \(Internals.typeName(self)) outside its designated queue."
        )
        Internals.assert(
            !self.isCommitted,
            "Attempted to access deleted object IDs from an already committed \(Internals.typeName(self))."
        )
        return Set(self.context.deletedObjects.compactMap({ entity.cs_matches(object: $0) ? $0.objectID : nil }))
    }
    
    
    // MARK: 3rd Party Utilities
    
    /**
     An arbitrary value that identifies the source of this transaction. Callers of the transaction can provide this value through the `DataStack.perform(...)` methods.
     */
    public let sourceIdentifier: Any?
    
    /**
     Allow external libraries to store custom data in the transaction. App code should rarely have a need for this.
     ```
     enum Static {
        static var myDataKey: Void?
     }
     transaction.userInfo[&Static.myDataKey] = myObject
     ```
     - Important: Do not use this method to store thread-sensitive data.
     */
    public let userInfo = UserInfo()
    
    
    // MARK: Internal
    
    internal let context: NSManagedObjectContext
    internal let transactionQueue: DispatchQueue
    internal let childTransactionQueue = DispatchQueue.serial("com.corestore.datastack.childTransactionQueue", qos: .utility)
    internal let supportsUndo: Bool
    internal let bypassesQueueing: Bool
    internal var isCommitted = false
    internal var result: (hasChanges: Bool, error: CoreStoreError?)?
    
    internal init(
        mainContext: NSManagedObjectContext,
        queue: DispatchQueue,
        supportsUndo: Bool,
        bypassesQueueing: Bool,
        sourceIdentifier: Any?
    ) {
        
        let context = mainContext.temporaryContextInTransactionWithConcurrencyType(
            queue == .main
                ? .mainQueueConcurrencyType
                : .privateQueueConcurrencyType
        )
        self.transactionQueue = queue
        self.context = context
        self.supportsUndo = supportsUndo
        self.bypassesQueueing = bypassesQueueing
        self.sourceIdentifier = sourceIdentifier
        
        context.parentTransaction = self
        context.isTransactionContext = true
        if !supportsUndo {
            
            context.undoManager = nil
        }
        else if context.undoManager == nil {
            
            context.undoManager = UndoManager()
        }
    }
    
    internal func isRunningInAllowedQueue() -> Bool {
        
        return self.bypassesQueueing || self.transactionQueue.cs_isCurrentExecutionContext()
    }
    
    deinit {
        
        self.context.reset()
    }
}
