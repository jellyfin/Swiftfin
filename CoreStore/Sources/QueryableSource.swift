//
//  QueryableSource.swift
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


// MARK: - QueryableSource

/**
 Encapsulates containers which manages an internal `NSManagedObjectContext`, such as `DataStack`s and transactions, that can be used for querying values. CoreStore provides implementations for this protocol and should be used as a read-only abstraction.
 */
public protocol QueryableSource: AnyObject {
    
    /**
     Queries aggregate values as specified by the `QueryClause`s. Requires at least a `Select` clause, and optional `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.

     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.

     - parameter from: a `From` clause indicating the entity type
     - parameter selectClause: a `Select<U>` clause indicating the properties to fetch, and with the generic type indicating the return type.
     - parameter queryClauses: a series of `QueryClause` instances for the query request. Accepts `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     - returns: the result of the the query, or `nil` if no match was found. The type of the return value is specified by the generic type of the `Select<U>` parameter.
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func queryValue<O, U: QueryableAttributeType>(
        _ from: From<O>,
        _ selectClause: Select<O, U>,
        _ queryClauses: QueryClause...
    ) throws(CoreStoreError) -> U?

    /**
     Queries aggregate values as specified by the `QueryClause`s. Requires at least a `Select` clause, and optional `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.

     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.

     - parameter from: a `From` clause indicating the entity type
     - parameter selectClause: a `Select<U>` clause indicating the properties to fetch, and with the generic type indicating the return type.
     - parameter queryClauses: a series of `QueryClause` instances for the query request. Accepts `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     - returns: the result of the the query, or `nil` if no match was found. The type of the return value is specified by the generic type of the `Select<U>` parameter.
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func queryValue<O, U: QueryableAttributeType>(
        _ from: From<O>,
        _ selectClause: Select<O, U>,
        _ queryClauses: [QueryClause]
    ) throws(CoreStoreError) -> U?

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
    func queryValue<B: QueryChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> B.ResultType? where B.ResultType: QueryableAttributeType

    /**
     Queries a dictionary of attribute values as specified by the `QueryClause`s. Requires at least a `Select` clause, and optional `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.

     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.

     - parameter from: a `From` clause indicating the entity type
     - parameter selectClause: a `Select<U>` clause indicating the properties to fetch, and with the generic type indicating the return type.
     - parameter queryClauses: a series of `QueryClause` instances for the query request. Accepts `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     - returns: the result of the the query. The type of the return value is specified by the generic type of the `Select<U>` parameter.
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func queryAttributes<O>(
        _ from: From<O>,
        _ selectClause: Select<O, NSDictionary>,
        _ queryClauses: QueryClause...
    ) throws(CoreStoreError) -> [[String: Any]]

    /**
     Queries a dictionary of attribute values as specified by the `QueryClause`s. Requires at least a `Select` clause, and optional `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.

     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.

     - parameter from: a `From` clause indicating the entity type
     - parameter selectClause: a `Select<U>` clause indicating the properties to fetch, and with the generic type indicating the return type.
     - parameter queryClauses: a series of `QueryClause` instances for the query request. Accepts `Where`, `OrderBy`, `GroupBy`, and `Tweak` clauses.
     - returns: the result of the the query. The type of the return value is specified by the generic type of the `Select<U>` parameter.
     - throws: `CoreStoreError.persistentStoreNotFound` if the specified entity could not be found in any store's schema.
     */
    func queryAttributes<O>(
        _ from: From<O>,
        _ selectClause: Select<O, NSDictionary>,
        _ queryClauses: [QueryClause]
    ) throws(CoreStoreError) -> [[String: Any]]

    /**
     Queries a dictionary of attribute values or  as specified by the `QueryChainableBuilderType` built from a chain of clauses.
     
     A "query" differs from a "fetch" in that it only retrieves values already stored in the persistent store. As such, values from unsaved transactions or contexts will not be incorporated in the query result.
     ```
     let results = source.queryAttributes(
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
    func queryAttributes<B: QueryChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> [[String: Any]] where B.ResultType == NSDictionary

    /**
     The internal `NSManagedObjectContext` managed by this `QueryableSource`. Using this context directly should typically be avoided, and is provided by CoreStore only for extremely specialized cases.
     */
    func unsafeContext() -> NSManagedObjectContext
}
