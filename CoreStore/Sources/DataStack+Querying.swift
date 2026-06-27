//
//  DataStack+Querying.swift
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

extension DataStack: FetchableSource, QueryableSource {
    
    // MARK: FetchableSource
    
    /**
     Fetches the `DynamicObject` instance in the `DataStack`'s context from a reference created from a transaction or from a different managed object context.
     
     - parameter object: a reference to the object created/fetched outside the `DataStack`
     - returns: the `DynamicObject` instance if the object exists in the `DataStack`, or `nil` if not found.
     */
    public func fetchExisting<O: DynamicObject>(
        _ object: O
    ) -> O? {

        return self.mainContext.fetchExisting(object)
    }
    
    /**
     Fetches the `DynamicObject` instance in the `DataStack`'s context from an `NSManagedObjectID`.
     
     - parameter objectID: the `NSManagedObjectID` for the object
     - returns: the `DynamicObject` instance if the object exists in the `DataStack`, or `nil` if not found.
     */
    public func fetchExisting<O: DynamicObject>(
        _ objectID: NSManagedObjectID
    ) -> O? {

        return self.mainContext.fetchExisting(objectID)
    }
    
    /**
     Fetches the `DynamicObject` instances in the `DataStack`'s context from references created from a transaction or from a different managed object context.
     
     - parameter objects: an array of `DynamicObject`s created/fetched outside the `DataStack`
     - returns: the `DynamicObject` array for objects that exists in the `DataStack`
     */
    public func fetchExisting<O: DynamicObject, S: Sequence>(
        _ objects: S
    ) -> [O] where S.Iterator.Element == O {

        return self.mainContext.fetchExisting(objects)
    }
    
    /**
     Fetches the `DynamicObject` instances in the `DataStack`'s context from a list of `NSManagedObjectID`.
     
     - parameter objectIDs: the `NSManagedObjectID` array for the objects
     - returns: the `DynamicObject` array for objects that exists in the `DataStack`
     */
    public func fetchExisting<O: DynamicObject, S: Sequence>(
        _ objectIDs: S
    ) -> [O] where S.Iterator.Element == NSManagedObjectID {

        return self.mainContext.fetchExisting(objectIDs)
    }
    
    /**
     Fetches the first `DynamicObject` instance that satisfies the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the first `DynamicObject` instance that satisfies the specified `FetchClause`s, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchOne<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> O? {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchOne(from, fetchClauses)
    }
    
    /**
     Fetches the first `DynamicObject` instance that satisfies the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the first `DynamicObject` instance that satisfies the specified `FetchClause`s, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchOne<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> O? {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchOne(from, fetchClauses)
    }
    
    /**
     Fetches the first `DynamicObject` instance that satisfies the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let youngestTeen = dataStack.fetchOne(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: the first `DynamicObject` instance that satisfies the specified `FetchChainableBuilderType`, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchOne<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> B.ObjectType? {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchOne(clauseChain)
    }
    
    /**
     Fetches all `DynamicObject` instances that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: all `DynamicObject` instances that satisfy the specified `FetchClause`s, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchAll<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> [O] {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchAll(from, fetchClauses)
    }
    
    /**
     Fetches all `DynamicObject` instances that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: all `DynamicObject` instances that satisfy the specified `FetchClause`s, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchAll<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> [O] {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchAll(from, fetchClauses)
    }
    
    /**
     Fetches all `DynamicObject` instances that satisfy the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let people = dataStack.fetchAll(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: all `DynamicObject` instances that satisfy the specified `FetchChainableBuilderType`, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchAll<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> [B.ObjectType] {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchAll(clauseChain)
    }
    
    /**
     Fetches the number of `DynamicObject`s that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the number of `DynamicObject`s that satisfy the specified `FetchClause`s
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchCount<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> Int {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchCount(from, fetchClauses)
    }
    
    /**
     Fetches the number of `DynamicObject`s that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the number of `DynamicObject`s that satisfy the specified `FetchClause`s
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchCount<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> Int {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchCount(from, fetchClauses)
    }
    
    /**
     Fetches the number of `DynamicObject`s that satisfy the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let numberOfAdults = dataStack.fetchCount(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: the number of `DynamicObject`s that satisfy the specified `FetchChainableBuilderType`
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchCount<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> Int {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchCount(clauseChain)
    }
    
    /**
     Fetches the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchClause`s, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchObjectID<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> NSManagedObjectID? {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchObjectID(from, fetchClauses)
    }
    
    /**
     Fetches the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchClause`s, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchObjectID<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> NSManagedObjectID? {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchObjectID(from, fetchClauses)
    }
    
    /**
     Fetches the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let youngestTeenID = dataStack.fetchObjectID(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: the `NSManagedObjectID` for the first `DynamicObject` that satisfies the specified `FetchChainableBuilderType`, or `nil` if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchObjectID<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> NSManagedObjectID? {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchObjectID(clauseChain)
    }
    
    /**
     Fetches the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchClause`s, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchObjectIDs<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> [NSManagedObjectID] {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchObjectIDs(from, fetchClauses)
    }
    
    /**
     Fetches the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchClause`s. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for the fetch request. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchClause`s, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchObjectIDs<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> [NSManagedObjectID] {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchObjectIDs(from, fetchClauses)
    }
    
    /**
     Fetches the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchChainableBuilderType` built from a chain of clauses.
     ```
     let idsOfAdults = dataStack.fetchObjectIDs(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: the `NSManagedObjectID` for all `DynamicObject`s that satisfy the specified `FetchChainableBuilderType`, or an empty array if no match was found
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func fetchObjectIDs<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> [NSManagedObjectID] {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to fetch from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.fetchObjectIDs(clauseChain)
    }
    
    
    // MARK: QueryableSource
    
    /**
     Queries aggregate values as specified by the `QueryClause`s. Requires at least a `Select` clause, and optional `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     
     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter selectClause: a `Select<U>` clause indicating the properties to fetch, and with the generic type indicating the return type.
     - parameter queryClauses: a series of `QueryClause` instances for the query request. Accepts `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     - returns: the result of the the query, or `nil` if no match was found. The type of the return value is specified by the generic type of the `Select<U>` parameter.
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func queryValue<O, U: QueryableAttributeType>(
        _ from: From<O>,
        _ selectClause: Select<O, U>,
        _ queryClauses: QueryClause...
    ) throws(CoreStoreError) -> U? {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to query from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.queryValue(from, selectClause, queryClauses)
    }
    
    /**
     Queries aggregate values as specified by the `QueryClause`s. Requires at least a `Select` clause, and optional `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     
     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter selectClause: a `Select<U>` clause indicating the properties to fetch, and with the generic type indicating the return type.
     - parameter queryClauses: a series of `QueryClause` instances for the query request. Accepts `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     - returns: the result of the the query, or `nil` if no match was found. The type of the return value is specified by the generic type of the `Select<U>` parameter.
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func queryValue<O, U: QueryableAttributeType>(
        _ from: From<O>,
        _ selectClause: Select<O, U>,
        _ queryClauses: [QueryClause]
    ) throws(CoreStoreError) -> U? {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to query from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.queryValue(from, selectClause, queryClauses)
    }
    
    /**
     Queries a property value or aggregate as specified by the `QueryChainableBuilderType` built from a chain of clauses.
     
     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.
     ```
     let averageAdultAge = dataStack.queryValue(
         From<MyPersonEntity>()
             .select(Int.self, .average(\.age))
             .where(\.age > 18)
     )
     ```
     - parameter clauseChain: a `QueryChainableBuilderType` indicating the property/aggregate to fetch and the series of queries for the request.
     - returns: the result of the the query as specified by the `QueryChainableBuilderType`, or `nil` if no match was found.
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func queryValue<B: QueryChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> B.ResultType? where B.ResultType: QueryableAttributeType {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to query from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.queryValue(
            clauseChain.from,
            clauseChain.select,
            clauseChain.queryClauses
        )
    }
    
    /**
     Queries a dictionary of attribute values as specified by the `QueryClause`s. Requires at least a `Select` clause, and optional `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     
     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter selectClause: a `Select<U>` clause indicating the properties to fetch, and with the generic type indicating the return type.
     - parameter queryClauses: a series of `QueryClause` instances for the query request. Accepts `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     - returns: the result of the the query. The type of the return value is specified by the generic type of the `Select<U>` parameter.
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func queryAttributes<O>(
        _ from: From<O>,
        _ selectClause: Select<O, NSDictionary>,
        _ queryClauses: QueryClause...
    ) throws(CoreStoreError) -> [[String: Any]] {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to query from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.queryAttributes(from, selectClause, queryClauses)
    }
    
    /**
     Queries a dictionary of attribute values as specified by the `QueryClause`s. Requires at least a `Select` clause, and optional `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     
     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter selectClause: a `Select<U>` clause indicating the properties to fetch, and with the generic type indicating the return type.
     - parameter queryClauses: a series of `QueryClause` instances for the query request. Accepts `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     - returns: the result of the the query. The type of the return value is specified by the generic type of the `Select<U>` parameter.
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func queryAttributes<O>(
        _ from: From<O>,
        _ selectClause: Select<O, NSDictionary>,
        _ queryClauses: [QueryClause]
    ) throws(CoreStoreError) -> [[String: Any]] {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to query from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.queryAttributes(from, selectClause, queryClauses)
    }
    
    /**
     Queries a dictionary of attribute values or  as specified by the `QueryChainableBuilderType` built from a chain of clauses.
     
     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.
     ```
     let results = dataStack.queryAttributes(
         From<MyPersonEntity>()
             .select(
                 NSDictionary.self,
                 .attribute(\.age, as: "age"),
                 .count(\.age, as: "numberOfPeople")
             )
             .groupBy(\.age)
     )
     for dictionary in results! {
         let age = dictionary["age"] as! Int
         let count = dictionary["numberOfPeople"] as! Int
         print("There are \(count) people who are \(age) years old."
     }
     ```
     - parameter clauseChain: a `QueryChainableBuilderType` indicating the properties to fetch and the series of queries for the request.
     - returns: the result of the the query as specified by the `QueryChainableBuilderType`
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    public func queryAttributes<B: QueryChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> [[String: Any]] where B.ResultType == NSDictionary {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to query from a \(Internals.typeName(self)) outside the main thread."
        )
        return try self.mainContext.queryAttributes(
            clauseChain.from,
            clauseChain.select,
            clauseChain.queryClauses
        )
    }
    
    
    // MARK: FetchableSource, QueryableSource
    
    /**
     The internal `NSManagedObjectContext` managed by this instance. Using this context directly should typically be avoided, and is provided by CoreStore only for extremely specialized cases.
     */
    public func unsafeContext() -> NSManagedObjectContext {
        
        return self.mainContext
    }
}
