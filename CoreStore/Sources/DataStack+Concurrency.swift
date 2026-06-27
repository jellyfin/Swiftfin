//
//  DataStack+Concurrency.swift
//  CoreStore
//
//  Copyright © 2021 John Rommel Estropia
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

    // MARK: Public

    /**
     Swift concurrency utilities for the `DataStack` are exposed through this namespace
     */
    public var async: DataStack.AsyncNamespace {

        return .init(self)
    }

    // MARK: - ReactiveNamespace

    /**
     Swift concurrency for the `DataStack` are exposed through this namespace. Extend this type if you need to add other `async` utilities for `DataStack`.
     */
    public struct AsyncNamespace {

        // MARK: Public

        /**
         The `DataStack` instance
         */
        public let base: DataStack


        // MARK: Internal

        internal init(_ base: DataStack) {

            self.base = base
        }
    }
}


// MARK: - DataStack.AsyncNamespace

extension DataStack.AsyncNamespace {

    // MARK: Public

    /**
     Swift concurrency extension for `CoreStore.DataStack`'s `addStorage(...)` API. Asynchronously adds a `StorageInterface` to the stack.
     ```
     let storage = try await dataStack.async.addStorage(
         InMemoryStore(configuration: "Config1")
     )
     ```
     - parameter storage: the storage
     - returns: The `StorageInterface` instance added to the `DataStack`. Note that the `StorageInterface` event value may not always be the same instance as the parameter argument if a previous `StorageInterface` was already added at the same URL and with the same configuration.
     - throws: A `CoreStoreError` value indicating the failure reason
     */
    public func addStorage<T: StorageInterface>(
        _ storage: T
    ) async throws(any Swift.Error) -> T {

        return try await Internals.withCheckedThrowingContinuation { continuation in

            self.base.addStorage(
                storage,
                completion: {

                    continuation.resume(with: $0)
                }
            )
        }
    }

    /**
     Swift concurrency extension for `CoreStore.DataStack`'s `addStorage(...)` API. Asynchronously adds a `LocalStorage` to the stack. Migrations are also initiated by default. The event emits `MigrationProgress` `enum` values.
     ```
     for try await migrationProgress in dataStack.async.addStorage(
         SQLiteStore(
             fileName: "core_data.sqlite",
             configuration: "Config1"
         )
     ) {

         print("\(round(migrationProgress.fractionCompleted * 100)) %") // 0.0 ~ 1.0
     }
     ```
     - parameter storage: the local storage
     - returns: An `AsyncThrowingStream` that emits a `MigrationProgress` value with metadata for migration progress. Note that the `LocalStorage` event value may not always be the same instance as the parameter argument if a previous `LocalStorage` was already added at the same URL and with the same configuration.
     - throws: A `CoreStoreError` value indicating the failure reason
     */
    public func addStorage<T>(
        _ storage: T
    ) -> AsyncThrowingStream<MigrationProgress<T>, any Swift.Error> {

        return .init(
            bufferingPolicy: .unbounded,
            { continuation in

                var progress: Progress? = nil
                progress = self.base.addStorage(
                    storage,
                    completion: { result in

                        progress?.setProgressHandler(nil)

                        switch result {

                        case .success(let storage):
                            continuation.yield(
                                .finished(
                                    storage: storage,
                                    migrationRequired: progress != nil
                                )
                            )
                            continuation.finish()

                        case .failure(let error):
                            continuation.finish(
                                throwing: error
                            )
                        }
                    }
                )
                if let progress = progress {

                    progress.setProgressHandler { progress in

                        continuation.yield(
                            .migrating(
                                storage: storage,
                                progressObject: progress
                            )
                        )
                    }
                }
            }
        )
    }

    /**
     Swift concurrency extension for `CoreStore.DataStack`'s `importObject(...)` API. Creates an `ImportableObject` by importing from the specified import source. The event value will be the object instance correctly associated for the `DataStack`.
     ```
     let object = try await dataStack.async.importObject(
         Into<Person>(),
         source: ["name": "John"]
     )
     ```
     - parameter into: an `Into` clause specifying the entity type
     - parameter source: the object to import values from
     - returns: The object instance correctly associated for the `DataStack` if the object was imported successfully, or `nil` if the `ImportableObject` ignored the `source`.
     - throws: A `CoreStoreError` value indicating the failure reason
     */
    public func importObject<O: DynamicObject & ImportableObject>(
        _ into: Into<O>,
        source: O.ImportSource
    ) async throws(any Swift.Error) -> O? {

        return try await Internals.withCheckedThrowingContinuation { continuation in

            self.base.perform(
                asynchronous: { (transaction) -> O? in

                    return try transaction.importObject(
                        into,
                        source: source
                    )
                },
                success: {

                    continuation.resume(
                        with: .success($0.flatMap(self.base.fetchExisting))
                    )
                },
                failure: continuation.resume(throwing:)
            )
        }
    }

    /**
     Swift concurrency extension for `CoreStore.DataStack`'s `importObject(...)` API. Updates an existing `ImportableObject` by importing values from the specified import source. The event value will be the object instance correctly associated for the `DataStack`.
     ```
     let importedPerson = try await dataStack.async.importObject(
         existingPerson,
         source: ["name": "John", "age": 30]
     )
     ```
     - parameter object: the object to update
     - parameter source: the object to import values from
     - returns: The object instance correctly associated for the `DataStack` if the object was imported successfully, or `nil` if the `ImportableObject` ignored the `source`.
     - throws: A `CoreStoreError` value indicating the failure reason
     */
    public func importObject<O: DynamicObject & ImportableObject>(
        _ object: O,
        source: O.ImportSource
    ) async throws(any Swift.Error) -> O? {

        return try await Internals.withCheckedThrowingContinuation { continuation in

            self.base.perform(
                asynchronous: { (transaction) -> O? in

                    guard let object = transaction.edit(object) else {

                        try transaction.cancel()
                    }
                    try transaction.importObject(
                        object,
                        source: source
                    )
                    return object
                },
                success: {

                    continuation.resume(
                        with: .success($0.flatMap(self.base.fetchExisting))
                    )
                },
                failure: continuation.resume(throwing:)
            )
        }
    }

    /**
     Swift concurrency extension for `CoreStore.DataStack`'s `importUniqueObject(...)` API. Updates an existing `ImportableUniqueObject` or creates a new instance by importing from the specified import source. The event value will be the object instance correctly associated for the `DataStack`.
     ```
     let person = try await dataStack.async.importUniqueObject(
         Into<Person>(),
         source: ["name": "John", "age": 30]
     )
     ```
     - parameter into: an `Into` clause specifying the entity type
     - parameter source: the object to import values from
     - returns: The object instance correctly associated for the `DataStack` if the object was imported successfully, or `nil` if the `ImportableUniqueObject` ignored the `source`.
     - throws: A `CoreStoreError` value indicating the failure reason
     */
    public func importUniqueObject<O: DynamicObject & ImportableUniqueObject>(
        _ into: Into<O>,
        source: O.ImportSource
    ) async throws(any Swift.Error) -> O? {

        return try await Internals.withCheckedThrowingContinuation { continuation in

            self.base.perform(
                asynchronous: { (transaction) -> O? in

                    return try transaction.importUniqueObject(
                        into,
                        source: source
                    )
                },
                success: {

                    continuation.resume(
                        with: .success($0.flatMap(self.base.fetchExisting))
                    )
                },
                failure: continuation.resume(throwing:)
            )
        }
    }

    /**
     Swift concurrency extension for `CoreStore.DataStack`'s `importUniqueObjects(...)` API. Updates existing `ImportableUniqueObject`s or creates them by importing from the specified array of import sources. `ImportableUniqueObject` methods are called on the objects in the same order as they are in the `sourceArray`, and are returned in an array with that same order. The event values will be object instances correctly associated for the `DataStack`.
     ```
     let people = try await dataStack.async.importUniqueObjects(
         Into<Person>(),
         sourceArray: [
             ["name": "John"],
             ["name": "Bob"],
             ["name": "Joe"]
         ]
     )
     ```
     - Warning: If `sourceArray` contains multiple import sources with same ID, no merging will occur and ONLY THE LAST duplicate will be imported.
     - parameter into: an `Into` clause specifying the entity type
     - parameter sourceArray: the array of objects to import values from
     - parameter preProcess: a closure that lets the caller tweak the internal `UniqueIDType`-to-`ImportSource` mapping to be used for importing. Callers can remove from/add to/update `mapping` and return the updated array from the closure.
     - returns: The imported objects correctly associated for the `DataStack`.
     - throws: A `CoreStoreError` value indicating the failure reason
     */
    public func importUniqueObjects<O: DynamicObject & ImportableUniqueObject, S: Sequence>(
        _ into: Into<O>,
        sourceArray: S,
        preProcess: @escaping @Sendable (
            _ mapping: [O.UniqueIDType: O.ImportSource]
        ) throws(any Swift.Error) -> [O.UniqueIDType: O.ImportSource] = { $0 }
    ) async throws(any Swift.Error) -> [O]
    where S.Iterator.Element == O.ImportSource {

        return try await Internals.withCheckedThrowingContinuation { continuation in

            self.base.perform(
                asynchronous: { (transaction) -> [O] in

                    return try transaction.importUniqueObjects(
                        into,
                        sourceArray: sourceArray,
                        preProcess: preProcess
                    )
                },
                success: {

                    continuation.resume(
                        with: .success(self.base.fetchExisting($0))
                    )
                },
                failure: continuation.resume(throwing:)
            )
        }
    }

    /**
     Swift concurrency extension for `CoreStore.DataStack`'s `perform(asynchronous:...)` API. Performs a transaction asynchronously where `NSManagedObject` creates, updates, and deletes can be made. The changes are commited automatically after the `task` closure returns. The event value will be the value returned from the `task` closure. Any errors thrown from inside the `task` will be wrapped in a `CoreStoreError` before being thrown from the `async` method. To cancel/rollback changes, call `transaction.cancel()`, which throws a `CoreStoreError.userCancelled`.
     ```
     let result = try await dataStack.async.perform(
         asynchronous: { (transaction) -> (inserted: Set<NSManagedObject>, deleted: Set<NSManagedObject>) in

             // ...
             return (
                 transaction.insertedObjects(),
                 transaction.deletedObjects()
             )
         }
     )
     let inserted = dataStack.fetchExisting(result.inserted)
     let deleted = dataStack.fetchExisting(result.deleted)
     ```
     - parameter task: the asynchronous closure where creates, updates, and deletes can be made to the transaction. Transaction blocks are executed serially in a background queue, and all changes are made from a concurrent `NSManagedObjectContext`.
     - returns: The value returned from the `task` closure.
     - throws: A `CoreStoreError` value indicating the failure reason
     */
    public func perform<Output>(
        _ asynchronous: @escaping @Sendable (AsynchronousDataTransaction) throws(any Swift.Error) -> Output
    ) async throws(any Swift.Error) -> Output {

        return try await Internals.withCheckedThrowingContinuation { continuation in

            self.base.perform(
                asynchronous: asynchronous,
                completion: {

                    continuation.resume(with: $0)
                }
            )
        }
    }
}
