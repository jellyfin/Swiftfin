//
//  UnsafeDataTransaction.swift
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


// MARK: - UnsafeDataTransaction

/**
 The `UnsafeDataTransaction` provides an interface for non-contiguous `NSManagedObject` or `CoreStoreObject` creates, updates, and deletes. This is useful for making temporary changes, such as partially filled forms. An unsafe transaction object should typically be only used from the main queue.
 */
public final class UnsafeDataTransaction: BaseDataTransaction {
    
    // MARK: -
    
    /**
     Saves the transaction changes asynchronously. For an `UnsafeDataTransaction`, multiple commits are allowed, although it is the developer's responsibility to ensure a reasonable leeway to prevent blocking the main thread.
     
     - parameter completion: the block executed after the save completes. Success or failure is reported by the optional `error` argument of the block.
     */
    public func commit(
        _ completion: @escaping (_ error: CoreStoreError?) -> Void
    ) {

        self.context.saveAsynchronously(
            sourceIdentifier: self.sourceIdentifier,
            completion: { (_, error) in
                
                completion(error)
                withExtendedLifetime(self, {})
            }
        )
    }
    
    /**
     Saves the transaction changes and waits for completion synchronously. For an `UnsafeDataTransaction`, multiple commits are allowed, although it is the developer's responsibility to ensure a reasonable leeway to prevent blocking the main thread.
     
     - throws: a `CoreStoreError` value indicating the failure.
     */
    public func commitAndWait() throws(CoreStoreError) {

        if case (_, let error?) = self.context.saveSynchronously(
            waitForMerge: true,
            sourceIdentifier: self.sourceIdentifier
        ) {
            
            throw error
        }
    }
    
    /**
     Rolls back the transaction.
     */
    public func rollback() {
        
        Internals.assert(
            self.supportsUndo,
            "Attempted to rollback a \(Internals.typeName(self)) with Undo support disabled."
        )
        self.context.rollback()
    }
    
    /**
     Undo's the last change made to the transaction.
     */
    public func undo() {
        
        Internals.assert(
            self.supportsUndo,
            "Attempted to undo a \(Internals.typeName(self)) with Undo support disabled."
        )
        self.context.undo()
    }
    
    /**
     Immediately flushes all pending changes to the transaction's observers. This is useful in conjunction with `ListMonitor`s and `ObjectMonitor`s created from `UnsafeDataTransaction`s used to manage temporary "scratch" data.
     
     - Important: Note that unlike `commit()`, `flush()` does not propagate/save updates to the `DataStack` and the persistent store. However, the flushed changes will be seen by children transactions created further from the current transaction (i.e. through `transaction.beginUnsafe()`)
     - throws: an error thrown from `closure`, or an error thrown by Core Data (usually validation errors or conflict errors)
     */
    public func flush() {
        
        self.context.processPendingChanges()
    }
    
    /**
     Flushes all pending changes to the transaction's observers at the end of the `closure`'s execution. This is useful in conjunction with `ListMonitor`s and `ObjectMonitor`s created from `UnsafeDataTransaction`s used to manage temporary "scratch" data.
     
     - Important: Note that unlike `commit()`, `flush()` does not propagate/save updates to the `DataStack` and the persistent store. However, the flushed changes will be seen by children transactions created further from the current transaction (i.e. through `transaction.beginUnsafe()`)
     - parameter closure: the closure where changes can be made prior to the flush
     - throws: an error thrown from `closure`, or an error thrown by Core Data (usually validation errors or conflict errors)
     */
    public func flush(
        closure: () throws(any Swift.Error) -> Void
    ) rethrows {

        try closure()
        self.context.processPendingChanges()
    }
    
    /**
     Redo's the last undone change to the transaction.
     */
    public func redo() {
        
        Internals.assert(
            self.supportsUndo,
            "Attempted to redo a \(Internals.typeName(self)) with Undo support disabled."
        )
        self.context.redo()
    }
    
    /**
     Begins a child transaction where `NSManagedObject` or `CoreStoreObject` creates, updates, and deletes can be made. This is useful for making temporary changes, such as partially filled forms.
     
     - parameter supportsUndo: `undo()`, `redo()`, and `rollback()` methods are only available when this parameter is `true`, otherwise those method will raise an exception. Defaults to `false`. Note that turning on Undo support may heavily impact performance especially on iOS or watchOS where memory is limited.
     - parameter sourceIdentifier: an optional value that identifies the source of this transaction. This identifier will be passed to the change notifications and callers can use it for custom handling that depends on the source.     
     - returns: an `UnsafeDataTransaction` instance where creates, updates, and deletes can be made.
     */
    public func beginUnsafe(
        supportsUndo: Bool = false,
        sourceIdentifier: Any? = nil
    ) -> UnsafeDataTransaction {
        
        return UnsafeDataTransaction(
            mainContext: self.context,
            queue: self.transactionQueue,
            supportsUndo: supportsUndo,
            sourceIdentifier: sourceIdentifier
        )
    }
    
    
    // MARK: Internal
    
    internal init(
        mainContext: NSManagedObjectContext,
        queue: DispatchQueue,
        supportsUndo: Bool,
        sourceIdentifier: Any?
    ) {
        
        super.init(
            mainContext: mainContext,
            queue: queue,
            supportsUndo: supportsUndo,
            bypassesQueueing: true,
            sourceIdentifier: sourceIdentifier
        )
    }
}
