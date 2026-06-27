//
//  FetchableSource.swift
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


// MARK: - FetchableSource

/**
 Encapsulates containers which manages an internal `NSManagedObjectContext`, such as `DataStack`s and transactions, that can be used for fetching objects. CoreStore provides implementations for this protocol and should be used as a read-only abstraction.
 */
public protocol FetchableSource: AnyObject {
    
    /**
     Fetches the `DynamicObject` instance in the `FetchableSource`'s context from a reference created from another managed object context.
     
     - parameter object: a reference to the object created/fetched outside the `FetchableSource`'s context
     - returns: the `DynamicObject` instance if the object exists in the `FetchableSource`'s context, or `nil` if not found.
     */
    func fetchExisting<O: DynamicObject>(
        _ object: O
    ) -> O?

    /**
     Fetches the `DynamicObject` instance in the `FetchableSource`'s context from an `NSManagedObjectID`.
     
     - parameter objectID: the `NSManagedObjectID` for the object
     - returns: the `DynamicObject` instance if the object exists in the `FetchableSource`, or `nil` if not found.
     */
    func fetchExisting<O: DynamicObject>(
        _ objectID: NSManagedObjectID
    ) -> O?

    /**
     Fetches the `DynamicObject` instances in the `FetchableSource`'s context from references created from another managed object context.

     - parameter objects: an array of `DynamicObject`s created/fetched outside the `FetchableSource`'s context
     - returns: the `DynamicObject` array for objects that exists in the `FetchableSource`
     */
    func fetchExisting<O: DynamicObject, S: Sequence>(
        _ objects: S
    ) -> [O] where S.Iterator.Element == O

    /**
     Fetches the `DynamicObject` instances in the `FetchableSource`'s context from a list of `NSManagedObjectID`.

     - parameter objectIDs: the `NSManagedObjectID` array for the objects
     - returns: the `DynamicObject` array for objects that exists in the `FetchableSource`'s context
     */
    func fetchExisting<O: DynamicObject, S: Sequence>(
        _ objectIDs: S
    ) -> [O] where S.Iterator.Element == NSManagedObjectID

    /**
     Fetches the first `DynamicObject` instance that satisfies the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.

     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the first `DynamicObject` instance that satisfies the specified `FetchClause`s, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchOne<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> O?

    /**
     Fetches the first `DynamicObject` instance that satisfies the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.

     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the first `DynamicObject` instance that satisfies the specified `FetchClause`s, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchOne<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> O?

    /**
     Fetches the first `DynamicObject` instance that satisfies the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let youngestTeen = source.fetchOne(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: the first `DynamicObject` instance that satisfies the specified `FetchChainableBuilderType`, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchOne<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> B.ObjectType?

    /**
     Fetches all `DynamicObject` instances that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.

     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: all `DynamicObject` instances that satisfy the specified `FetchClause`s, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchAll<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> [O]

    /**
     Fetches all `DynamicObject` instances that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.

     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: all `DynamicObject` instances that satisfy the specified `FetchClause`s, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchAll<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> [O]

    /**
     Fetches all `DynamicObject` instances that satisfy the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let people = source.fetchAll(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: all `DynamicObject` instances that satisfy the specified `FetchChainableBuilderType`, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchAll<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> [B.ObjectType]

    /**
     Fetches the number of `DynamicObject`s that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.

     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the number of `DynamicObject`s that satisfy the specified `FetchClause`s
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchCount<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> Int

    /**
     Fetches the number of `DynamicObject`s that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.

     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the number of `DynamicObject`s that satisfy the specified `FetchClause`s
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchCount<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> Int

    /**
     Fetches the number of `DynamicObject`s that satisfy the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let numberOfAdults = source.fetchCount(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: the number of `DynamicObject`s that satisfy the specified `FetchChainableBuilderType`
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchCount<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> Int

    /**
     Fetches the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.

     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchClause`s, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchObjectID<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> NSManagedObjectID?

    /**
     Fetches the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.

     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchClause`s, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchObjectID<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> NSManagedObjectID?

    /**
     Fetches the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let youngestTeenID = source.fetchObjectID(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchChainableBuilderType`, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchObjectID<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> NSManagedObjectID?

    /**
     Fetches the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.

     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchClause`s, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchObjectIDs<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> [NSManagedObjectID]

    /**
     Fetches the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.

     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchClause`s, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchObjectIDs<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> [NSManagedObjectID]

    /**
     Fetches the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let idsOfAdults = source.fetchObjectIDs(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchChainableBuilderType`, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func fetchObjectIDs<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> [NSManagedObjectID]

    /**
     The internal `NSManagedObjectContext` managed by this `FetchableSource`. Using this context directly should typically be avoided, and is provided by CoreStore only for extremely specialized cases.
     */
    func unsafeContext() -> NSManagedObjectContext
}
