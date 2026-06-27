//
//  DataStack+Transaction.swift
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


// MARK: - DataStack

extension DataStack {
    
    /**
     Performs a transaction asynchronously where `NSManagedObject` or `CoreStoreObject` creates, updates, and deletes can be made. The changes are commited automatically after the `task` closure returns. On success, the value returned from closure will be the wrapped as `.success(T)` in the `completion`'s `Result<T>`. Any errors thrown from inside the `task` will be reported as `.failure(CoreStoreError)`. To cancel/rollback changes, call `try transaction.cancel()`, which throws a `CoreStoreError.userCancelled`.
     
     - parameter task: the asynchronous closure where creates, updates, and deletes can be made to the transaction. Transaction blocks are executed serially in a background queue, and all changes are made from a concurrent `NSManagedObjectContext`.
     - parameter sourceIdentifier: an optional value that identifies the source of this transaction. This identifier will be passed to the change notifications and callers can use it for custom handling that depends on the source.
     - parameter completion: the closure executed after the save completes. The `Result` argument of the closure will either wrap the return value of `task`, or any uncaught errors thrown from within `task`. Cancelled `task`s will be indicated by `.failure(error: CoreStoreError.userCancelled)`. Custom errors thrown by the user will be wrapped in `CoreStoreError.userError(error: Error)`.
     */
    public func perform<T>(
        asynchronous task: @escaping (
            _ transaction: AsynchronousDataTransaction
        ) throws(any Swift.Error) -> T,
        sourceIdentifier: Any? = nil,
        completion: @escaping (AsynchronousDataTransaction.Result<T>) -> Void
    ) {
        
        self.perform(
            asynchronous: task,
            sourceIdentifier: sourceIdentifier,
            success: { completion(.success($0)) },
            failure: { completion(.failure($0)) }
        )
    }
    
    /**
     Performs a transaction asynchronously where `NSManagedObject` or `CoreStoreObject` creates, updates, and deletes can be made. The changes are commited automatically after the `task` closure returns. On success, the value returned from closure will be the argument of the `success` closure. Any errors thrown from inside the `task` will be wrapped in a `CoreStoreError` and reported in the `failure` closure. To cancel/rollback changes, call `try transaction.cancel()`, which throws a `CoreStoreError.userCancelled`.
     
     - parameter task: the asynchronous closure where creates, updates, and deletes can be made to the transaction. Transaction blocks are executed serially in a background queue, and all changes are made from a concurrent `NSManagedObjectContext`.
     - parameter sourceIdentifier: an optional value that identifies the source of this transaction. This identifier will be passed to the change notifications and callers can use it for custom handling that depends on the source.
     - parameter success: the closure executed after the save succeeds. The `T` argument of the closure will be the value returned from `task`.
     - parameter failure: the closure executed if the save fails or if any errors are thrown within `task`. Cancelled `task`s will be indicated by `CoreStoreError.userCancelled`. Custom errors thrown by the user will be wrapped in `CoreStoreError.userError(error: Error)`.
     */
    public func perform<T>(
        asynchronous task: @escaping (
            _ transaction: AsynchronousDataTransaction
        ) throws(any Swift.Error) -> T,
        sourceIdentifier: Any? = nil,
        success: @escaping (T) -> Void,
        failure: @escaping (CoreStoreError) -> Void
    ) {
        
        let transaction = AsynchronousDataTransaction(
            mainContext: self.rootSavingContext,
            queue: self.childTransactionQueue,
            sourceIdentifier: sourceIdentifier
        )
        transaction.transactionQueue.cs_async {
            
            let userInfo: T
            do {
                
                userInfo = try task(transaction)
            }
            catch let error as CoreStoreError {
                
                DispatchQueue.main.async { failure(error) }
                return
            }
            catch let error {
                
                DispatchQueue.main.async { failure(.userError(error: error)) }
                return
            }
            transaction.autoCommit { (_, error) in
                
                defer {
                    
                    withExtendedLifetime((self, transaction), {})
                }
                if let error = error {
                    
                    failure(error)
                }
                else {
                    
                    success(userInfo)
                }
            }
        }
    }
    
    /**
     Performs a transaction synchronously where `NSManagedObject` or `CoreStoreObject` creates, updates, and deletes can be made. The changes are commited automatically after the `task` closure returns. On success, the value returned from closure will be the return value of `perform(synchronous:)`. Any errors thrown from inside the `task` will be thrown from `perform(synchronous:)`. To cancel/rollback changes, call `try transaction.cancel()`, which throws a `CoreStoreError.userCancelled`.
     
     - parameter task: the synchronous non-escaping closure where creates, updates, and deletes can be made to the transaction. Transaction blocks are executed serially in a background queue, and all changes are made from a concurrent `NSManagedObjectContext`.
     - parameter waitForAllObservers: When `true`, this method waits for all observers to be notified of the changes before returning. This results in more predictable data update order, but may risk triggering deadlocks. When `false`, this method does not wait for observers to be notified of the changes before returning. This results in lower risk for deadlocks, but the updated data may not have been propagated to the `DataStack` after returning. Defaults to `true`.
     - parameter sourceIdentifier: an optional value that identifies the source of this transaction. This identifier will be passed to the change notifications and callers can use it for custom handling that depends on the source.
     - throws: a `CoreStoreError` value indicating the failure. Cancelled `task`s will be indicated by `CoreStoreError.userCancelled`. Custom errors thrown by the user will be wrapped in `CoreStoreError.userError(error: Error)`.
     - returns: the value returned from `task`
     */
    public func perform<T>(
        synchronous task: (
            _ transaction: SynchronousDataTransaction
        ) throws(any Swift.Error) -> T,
        waitForAllObservers: Bool = true,
        sourceIdentifier: Any? = nil
    ) throws(CoreStoreError) -> T {

        let transaction = SynchronousDataTransaction(
            mainContext: self.rootSavingContext,
            queue: self.childTransactionQueue,
            sourceIdentifier: sourceIdentifier
        )
        return try transaction.transactionQueue.cs_sync { () throws(CoreStoreError) -> T in

            defer {

                withExtendedLifetime((self, transaction), {})
            }
            let userInfo: T
            do {

                userInfo = try withoutActuallyEscaping(task, do: { try $0(transaction) })
            }
            catch let error as CoreStoreError {

                throw error as CoreStoreError
            }
            catch let error {

                throw CoreStoreError.userError(error: error)
            }
            if case (_, let error?) = transaction.autoCommit(waitForMerge: waitForAllObservers) {

                throw error
            }
            else {

                return userInfo
            }
        }
    }
    
    /**
     Begins a non-contiguous transaction where `NSManagedObject` or `CoreStoreObject` creates, updates, and deletes can be made. This is useful for making temporary changes, such as partially filled forms.
     
     - parameter supportsUndo: `undo()`, `redo()`, and `rollback()` methods are only available when this parameter is `true`, otherwise those method will raise an exception. Defaults to `false`. Note that turning on Undo support may heavily impact performance especially on iOS or watchOS where memory is limited.
     - parameter sourceIdentifier: an optional value that identifies the source of this transaction. This identifier will be passed to the change notifications and callers can use it for custom handling that depends on the source.
     - returns: a `UnsafeDataTransaction` instance where creates, updates, and deletes can be made.
     */
    public func beginUnsafe(
        supportsUndo: Bool = false,
        sourceIdentifier: Any? = nil
    ) -> UnsafeDataTransaction {
        
        return UnsafeDataTransaction(
            mainContext: self.rootSavingContext,
            queue: DispatchQueue.serial("com.coreStore.dataStack.unsafeTransactionQueue", qos: .userInitiated),
            supportsUndo: supportsUndo,
            sourceIdentifier: sourceIdentifier
        )
    }
    
    /**
     Refreshes all registered objects `NSManagedObject`s or `CoreStoreObject`s in the `DataStack`.
     */
    public func refreshAndMergeAllObjects() {
        
        Internals.assert(
            Thread.isMainThread,
            "Attempted to refresh entities outside their designated queue."
        )
        self.mainContext.refreshAndMergeAllObjects()
    }
}
