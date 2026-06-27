//
//  From+Querying.swift
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


// MARK: - From

extension From {
    
    /**
     Creates a `FetchChainBuilder` that starts with the specified `Where` clause
     
     - parameter clause: the `Where` clause to create a `FetchChainBuilder` with
     - returns: a `FetchChainBuilder` that starts with the specified `Where` clause
     */
    public func `where`(
        _ clause: Where<O>
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clause)
    }
    
    /**
     Creates a `FetchChainBuilder` that `AND`s the specified `Where` clauses. Use this overload if the compiler cannot infer the types when chaining multiple `&&` operators.
     
     - parameter clauses: the `Where` clauses to create a `FetchChainBuilder` with
     - returns: a `FetchChainBuilder` that `AND`s the specified `Where` clauses
     */
    public func `where`(
        combineByAnd clauses: Where<O>...
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clauses.combinedByAnd())
    }
    
    /**
     Creates a `FetchChainBuilder` that `OR`s the specified `Where` clauses. Use this overload if the compiler cannot infer the types when chaining multiple `||` operators.
     
     - parameter clauses: the `Where` clauses to create a `FetchChainBuilder` with
     - returns: a `FetchChainBuilder` that `OR`s the specified `Where` clauses
     */
    public func `where`(
        combineByOr clauses: Where<O>...
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clauses.combinedByOr())
    }
    
    /**
     Creates a `FetchChainBuilder` with a predicate using the specified string format and arguments
     
     - parameter format: the format string for the predicate
     - parameter args: the arguments for `format`
     - returns: a `FetchChainBuilder` with a predicate using the specified string format and arguments
     */
    public func `where`(
        format: String,
        _ args: Any...
    ) -> FetchChainBuilder<O> {
        
        return self.fetchChain(appending: Where<O>(format, argumentArray: args))
    }
    
    /**
     Creates a `FetchChainBuilder` with a predicate using the specified string format and arguments
     
     - parameter format: the format string for the predicate
     - parameter argumentArray: the arguments for `format`
     - returns: a `FetchChainBuilder` with a predicate using the specified string format and arguments
     */
    public func `where`(
        format: String,
        argumentArray: [Any]?
    ) -> FetchChainBuilder<O> {
        
        return self.fetchChain(appending: Where<O>(format, argumentArray: argumentArray))
    }

    /**
     Creates a `FetchChainBuilder` that starts with the specified `OrderBy` clause.

     - parameter clause: the `OrderBy` clause to create a `FetchChainBuilder` with
     - returns: a `FetchChainBuilder` that starts with the specified `OrderBy` clause
     */
    public func orderBy(
        _ clause: OrderBy<O>
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clause)
    }
    
    /**
     Creates a `FetchChainBuilder` with a series of `SortKey`s
     
     - parameter sortKey: a single `SortKey`
     - parameter sortKeys: a series of other `SortKey`s
     - returns: a `FetchChainBuilder` with a series of `SortKey`s
     */
    public func orderBy(
        _ sortKey: OrderBy<O>.SortKey,
        _ sortKeys: OrderBy<O>.SortKey...
    ) -> FetchChainBuilder<O> {
        
        return self.fetchChain(appending: OrderBy<O>([sortKey] + sortKeys))
    }

    /**
     Creates a `FetchChainBuilder` with a series of `SortKey`s

     - parameter sortKeys: a series of `SortKey`s
     - returns: a `FetchChainBuilder` with a series of `SortKey`s
     */
    public func orderBy(
        _ sortKeys: [OrderBy<O>.SortKey]
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: OrderBy<O>(sortKeys))
    }
    
    /**
     Creates a `FetchChainBuilder` with a closure where the `NSFetchRequest` may be configured
     
     - parameter fetchRequest: the block to customize the `NSFetchRequest`
     - returns: a `FetchChainBuilder` with closure where the `NSFetchRequest` may be configured
     */
    public func tweak(
        _ fetchRequest: @escaping (NSFetchRequest<NSFetchRequestResult>) -> Void
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: Tweak(fetchRequest))
    }
    
    /**
     Creates a `FetchChainBuilder` and immediately appending a `FetchClause`
     
     - parameter clause: the `FetchClause` to add to the `FetchChainBuilder`
     - returns: a `FetchChainBuilder` containing the specified `FetchClause`
     */
    public func appending(
        _ clause: FetchClause
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clause)
    }
    
    /**
     Creates a `FetchChainBuilder` and immediately appending a series of `FetchClause`s
     
     - parameter clauses: the `FetchClause`s to add to the `FetchChainBuilder`
     - returns: a `FetchChainBuilder` containing the specified `FetchClause`s
     */
    public func appending<S: Sequence>(
        contentsOf clauses: S
    ) -> FetchChainBuilder<O> where S.Element == FetchClause {

        return self.fetchChain(appending: clauses)
    }
    
    /**
     Creates a `QueryChainBuilder` that starts with the specified `Select` clause
     
     - parameter clause: the `Select` clause to create a `QueryChainBuilder` with
     - returns: a `QueryChainBuilder` that starts with the specified `Select` clause
     */
    public func select<R>(
        _ clause: Select<O, R>
    ) -> QueryChainBuilder<O, R> {

        return .init(
            from: self,
            select: clause,
            queryClauses: []
        )
    }
    
    /**
     Creates a `QueryChainBuilder` that starts with a `Select` clause created from the specified `SelectTerm`s
     
     - parameter resultType: the generic `SelectResultType` for the `Select` clause
     - parameter selectTerm: a `SelectTerm`
     - parameter selectTerms: a series of `SelectTerm`s
     - returns: a `QueryChainBuilder` that starts with a `Select` clause created from the specified `SelectTerm`s
     */
    public func select<R>(
        _ resultType: R.Type,
        _ selectTerm: SelectTerm<O>,
        _ selectTerms: SelectTerm<O>...
    ) -> QueryChainBuilder<O, R> {
        
        return self.select(resultType, [selectTerm] + selectTerms)
    }
    
    /**
     Creates a `QueryChainBuilder` that starts with a `Select` clause created from the specified `SelectTerm`s
     
     - parameter resultType: the generic `SelectResultType` for the `Select` clause
     - parameter selectTerms: a series of `SelectTerm`s
     - returns: a `QueryChainBuilder` that starts with a `Select` clause created from the specified `SelectTerm`s
     */
    public func select<R>(
        _ resultType: R.Type,
        _ selectTerms: [SelectTerm<O>]
    ) -> QueryChainBuilder<O, R> {
        
        return .init(
            from: self,
            select: .init(selectTerms),
            queryClauses: []
        )
    }
    
    /**
     Creates a `SectionMonitorChainBuilder` that starts with the `SectionBy` to use to group `ListMonitor` objects into sections
     
     - parameter clause: the `SectionBy` to be used by the `ListMonitor`
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy(
        _ clause: SectionBy<O>
    ) -> SectionMonitorChainBuilder<O> {

        return .init(
            from: self,
            sectionBy: clause,
            fetchClauses: []
        )
    }
    
    /**
     Creates a `SectionMonitorChainBuilder` with the key path to use to group `ListMonitor` objects into sections
     
     - parameter sectionKeyPath: the key path to use to group the objects into sections
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy(
        _ sectionKeyPath: KeyPathString
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionBy(sectionKeyPath, sectionIndexTransformer: { _ in nil })
    }
    
    /**
     Creates a `SectionMonitorChainBuilder` with the key path to use to group `ListMonitor` objects into sections, and a closure to transform the value for the key path to an appropriate section index title
     
     - Important: Some utilities (such as `ListMonitor`s) may keep `SectionBy`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter sectionKeyPath: the key path to use to group the objects into sections
     - parameter sectionIndexTransformer: a closure to transform the value for the key path to an appropriate section index title
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy(
        _ sectionKeyPath: KeyPathString,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) -> SectionMonitorChainBuilder<O> {
        
        return .init(
            from: self,
            sectionBy: .init(
                sectionKeyPath,
                sectionIndexTransformer: sectionIndexTransformer
            ),
            fetchClauses: []
        )
    }
    
    
    // MARK: Private
    
    private func fetchChain(
        appending clause: FetchClause
    ) -> FetchChainBuilder<O> {

        return .init(from: self, fetchClauses: [clause])
    }
    
    private func fetchChain<S: Sequence>(
        appending clauses: S
    ) -> FetchChainBuilder<O> where S.Element == FetchClause {

        return .init(from: self, fetchClauses: Array(clauses))
    }
}


// MARK: - From where O: NSManagedObject

extension From where O: NSManagedObject {
    
    /**
     Creates a `QueryChainBuilder` that starts with a `Select` clause created from the specified key path
     
     - parameter keyPath: the keyPath to query the value for
     - returns: a `QueryChainBuilder` that starts with a `Select` clause created from the specified key path
     */
    public func select<R>(
        _ keyPath: KeyPath<O, R>
    ) -> QueryChainBuilder<O, R> {

        return self.select(R.self, [SelectTerm<O>.attribute(keyPath)])
    }
    
    /**
     Creates a `SectionMonitorChainBuilder` with the key path to use to group `ListMonitor` objects into sections
     
     - parameter sectionKeyPath: the `KeyPath` to use to group the objects into sections
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, T>
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionBy(
            sectionKeyPath._kvcKeyPathString!,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    /**
     Creates a `SectionMonitorChainBuilder` with the key path to use to group `ListMonitor` objects into sections, and a closure to transform the value for the key path to an appropriate section index title
     
     - Important: Some utilities (such as `ListMonitor`s) may keep `SectionBy`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter sectionKeyPath: the `KeyPath` to use to group the objects into sections
     - parameter sectionIndexTransformer: a closure to transform the value for the key path to an appropriate section index title
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, T>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) -> SectionMonitorChainBuilder<O> {
        
        return self.sectionBy(
            sectionKeyPath._kvcKeyPathString!,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
}


// MARK: - From where O: CoreStoreObject

extension From where O: CoreStoreObject {
    
    /**
     Creates a `FetchChainBuilder` that starts with the specified `Where` clause
     
     - parameter clause: a closure that returns a `Where` clause
     - returns: a `FetchChainBuilder` that starts with the specified `Where` clause
     */
    public func `where`<T: AnyWhereClause>(
        _ clause: (O) -> T
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clause(O.meta))
    }
    
    /**
     Creates a `SectionMonitorChainBuilder` with the key path to use to group `ListMonitor` objects into sections
     
     - parameter sectionKeyPath: the `KeyPath` to use to group the objects into sections
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, FieldContainer<O>.Stored<T>>
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    /**
     Creates a `SectionMonitorChainBuilder` with the key path to use to group `ListMonitor` objects into sections
     
     - parameter sectionKeyPath: the `KeyPath` to use to group the objects into sections
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, FieldContainer<O>.Virtual<T>>
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }

    /**
     Creates a `SectionMonitorChainBuilder` with the key path to use to group `ListMonitor` objects into sections

     - parameter sectionKeyPath: the `KeyPath` to use to group the objects into sections
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, FieldContainer<O>.Coded<T>>
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }

    /**
     Creates a `SectionMonitorChainBuilder` with the key path to use to group `ListMonitor` objects into sections, and a closure to transform the value for the key path to an appropriate section index title

     - Important: Some utilities (such as `ListMonitor`s) may keep `SectionBy`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter sectionKeyPath: the `KeyPath` to use to group the objects into sections
     - parameter sectionIndexTransformer: a closure to transform the value for the key path to an appropriate section index title
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, FieldContainer<O>.Stored<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }

    /**
     Creates a `SectionMonitorChainBuilder` with the key path to use to group `ListMonitor` objects into sections, and a closure to transform the value for the key path to an appropriate section index title

     - Important: Some utilities (such as `ListMonitor`s) may keep `SectionBy`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter sectionKeyPath: the `KeyPath` to use to group the objects into sections
     - parameter sectionIndexTransformer: a closure to transform the value for the key path to an appropriate section index title
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, FieldContainer<O>.Virtual<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }

    /**
     Creates a `SectionMonitorChainBuilder` with the key path to use to group `ListMonitor` objects into sections, and a closure to transform the value for the key path to an appropriate section index title

     - Important: Some utilities (such as `ListMonitor`s) may keep `SectionBy`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter sectionKeyPath: the `KeyPath` to use to group the objects into sections
     - parameter sectionIndexTransformer: a closure to transform the value for the key path to an appropriate section index title
     - returns: a `SectionMonitorChainBuilder` that is sectioned by the specified key path
     */
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, FieldContainer<O>.Coded<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
}


// MARK: - FetchChainBuilder

extension FetchChainBuilder {
    
    /**
     Adds a `Where` clause to the `FetchChainBuilder`
     
     - parameter clause: a `Where` clause to add to the fetch builder
     - returns: a new `FetchChainBuilder` containing the `Where` clause
     */
    public func `where`(
        _ clause: Where<O>
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clause)
    }
    
    /**
     Creates a `FetchChainBuilder` that `AND`s the specified `Where` clauses. Use this overload if the compiler cannot infer the types when chaining multiple `&&` operators.
     
     - parameter clauses: the `Where` clauses to create a `FetchChainBuilder` with
     - returns: a `FetchChainBuilder` that `AND`s the specified `Where` clauses
     */
    public func `where`(
        combineByAnd clauses: Where<O>...
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clauses.combinedByAnd())
    }
    
    /**
     Creates a `FetchChainBuilder` that `OR`s the specified `Where` clauses. Use this overload if the compiler cannot infer the types when chaining multiple `||` operators.
     
     - parameter clauses: the `Where` clauses to create a `FetchChainBuilder` with
     - returns: a `FetchChainBuilder` that `OR`s the specified `Where` clauses
     */
    public func `where`(
        combineByOr clauses: Where<O>...
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clauses.combinedByOr())
    }
    
    /**
     Adds a `Where` clause to the `FetchChainBuilder`
     
     - parameter format: the format string for the predicate
     - parameter args: the arguments for `format`
     - returns: a new `FetchChainBuilder` containing the `Where` clause
     */
    public func `where`(
        format: String,
        _ args: Any...
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: Where<O>(format, argumentArray: args))
    }
    
    /**
     Adds a `Where` clause to the `FetchChainBuilder`
     
     - parameter format: the format string for the predicate
     - parameter argumentArray: the arguments for `format`
     - returns: a new `FetchChainBuilder` containing the `Where` clause
     */
    public func `where`(
        format: String,
        argumentArray: [Any]?
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: Where<O>(format, argumentArray: argumentArray))
    }

    /**
     Adds an `OrderBy` clause to the `FetchChainBuilder`

     - parameter clause: the `OrderBy` clause to add
     - returns: a new `FetchChainBuilder` containing the `OrderBy` clause
     */
    public func orderBy(
        _ clause: OrderBy<O>
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clause)
    }
    
    /**
     Adds an `OrderBy` clause to the `FetchChainBuilder`
     
     - parameter sortKey: a single `SortKey`
     - parameter sortKeys: a series of other `SortKey`s
     - returns: a new `FetchChainBuilder` containing the `OrderBy` clause
     */
    public func orderBy(
        _ sortKey: OrderBy<O>.SortKey,
        _ sortKeys: OrderBy<O>.SortKey...
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: OrderBy<O>([sortKey] + sortKeys))
    }

    /**
     Adds an `OrderBy` clause to the `FetchChainBuilder`

     - parameter sortKeys: a series of `SortKey`s
     - returns: a new `FetchChainBuilder` containing the `OrderBy` clause
     */
    public func orderBy(
        _ sortKeys: [OrderBy<O>.SortKey]
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: OrderBy<O>(sortKeys))
    }
    
    /**
     Adds a `Tweak` clause to the `FetchChainBuilder` with a closure where the `NSFetchRequest` may be configured
     
     - parameter fetchRequest: the block to customize the `NSFetchRequest`
     - returns: a new `FetchChainBuilder` containing the `Tweak` clause
     */
    public func tweak(
        _ fetchRequest: @escaping (NSFetchRequest<NSFetchRequestResult>) -> Void
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: Tweak(fetchRequest))
    }
    
    /**
     Appends a `FetchClause` to the `FetchChainBuilder`
     
     - parameter clause: the `FetchClause` to add to the `FetchChainBuilder`
     - returns: a new `FetchChainBuilder` containing the `FetchClause`
     */
    public func appending(
        _ clause: FetchClause
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clause)
    }
    
    /**
     Appends a series of `FetchClause`s to the `FetchChainBuilder`
     
     - parameter clauses: the `FetchClause`s to add to the `FetchChainBuilder`
     - returns: a new `FetchChainBuilder` containing the `FetchClause`s
     */
    public func appending<S: Sequence>(
        contentsOf clauses: S
    ) -> FetchChainBuilder<O> where S.Element == FetchClause {

        return self.fetchChain(appending: clauses)
    }
    
    
    // MARK: Private
    
    private func fetchChain(
        appending clause: FetchClause
    ) -> FetchChainBuilder<O> {

        return .init(
            from: self.from,
            fetchClauses: self.fetchClauses + [clause]
        )
    }
    
    private func fetchChain<S: Sequence>(
        appending clauses: S
    ) -> FetchChainBuilder<O> where S.Element == FetchClause {

        return .init(
            from: self.from,
            fetchClauses: self.fetchClauses + Array(clauses)
        )
    }
}


// MARK: - FetchChainBuilder where O: CoreStoreObject

extension FetchChainBuilder where O: CoreStoreObject {
    
    public func `where`<T: AnyWhereClause>(
        _ clause: (O) -> T
    ) -> FetchChainBuilder<O> {

        return self.fetchChain(appending: clause(O.meta))
    }
}


// MARK: - QueryChainBuilder

extension QueryChainBuilder {
    
    /**
     Adds a `Where` clause to the `QueryChainBuilder`
     
     - parameter clause: a `Where` clause to add to the query builder
     - returns: a new `QueryChainBuilder` containing the `Where` clause
     */
    public func `where`(
        _ clause: Where<O>
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: clause)
    }
    
    /**
     Creates a `FetchChainBuilder` that `AND`s the specified `Where` clauses. Use this overload if the compiler cannot infer the types when chaining multiple `&&` operators.
     
     - parameter clauses: the `Where` clauses to create a `FetchChainBuilder` with
     - returns: a `FetchChainBuilder` that `AND`s the specified `Where` clauses
     */
    public func `where`(
        combineByAnd clauses: Where<O>...
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: clauses.combinedByAnd())
    }
    
    /**
     Creates a `FetchChainBuilder` that `OR`s the specified `Where` clauses. Use this overload if the compiler cannot infer the types when chaining multiple `||` operators.
     
     - parameter clauses: the `Where` clauses to create a `FetchChainBuilder` with
     - returns: a `FetchChainBuilder` that `OR`s the specified `Where` clauses
     */
    public func `where`(
        combineByOr clauses: Where<O>...
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: clauses.combinedByOr())
    }
    
    /**
     Adds a `Where` clause to the `QueryChainBuilder`
     
     - parameter format: the format string for the predicate
     - parameter args: the arguments for `format`
     - returns: a new `QueryChainBuilder` containing the `Where` clause
     */
    public func `where`(
        format: String,
        _ args: Any...
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: Where<O>(format, argumentArray: args))
    }
    
    /**
     Adds a `Where` clause to the `QueryChainBuilder`
     
     - parameter format: the format string for the predicate
     - parameter argumentArray: the arguments for `format`
     - returns: a new `QueryChainBuilder` containing the `Where` clause
     */
    public func `where`(
        format: String,
        argumentArray: [Any]?
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: Where<O>(format, argumentArray: argumentArray))
    }

    /**
     Adds an `OrderBy` clause to the `QueryChainBuilder`

     - parameter clause: the `OrderBy` clause to add
     - returns: a new `QueryChainBuilder` containing the `OrderBy` clause
     */
    public func orderBy(
        _ clause: OrderBy<O>
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: clause)
    }
    
    /**
     Adds an `OrderBy` clause to the `QueryChainBuilder`
     
     - parameter sortKey: a single `SortKey`
     - parameter sortKeys: a series of other `SortKey`s
     - returns: a new `QueryChainBuilder` containing the `OrderBy` clause
     */
    public func orderBy(
        _ sortKey: OrderBy<O>.SortKey,
        _ sortKeys: OrderBy<O>.SortKey...
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: OrderBy<O>([sortKey] + sortKeys))
    }

    /**
     Adds an `OrderBy` clause to the `QueryChainBuild`

     - parameter sortKeys: a series of `SortKey`s
     - returns: a new `QueryChainBuilder` containing the `OrderBy` clause
     */
    public func orderBy(
        _ sortKeys: [OrderBy<O>.SortKey]
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: OrderBy<O>(sortKeys))
    }
    
    /**
     Adds a `Tweak` clause to the `QueryChainBuilder` with a closure where the `NSFetchRequest` may be configured
     
     - parameter fetchRequest: the block to customize the `NSFetchRequest`
     - returns: a new `QueryChainBuilder` containing the `Tweak` clause
     */
    public func tweak(
        _ fetchRequest: @escaping (NSFetchRequest<NSFetchRequestResult>) -> Void
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: Tweak(fetchRequest))
    }
    
    /**
     Adds a `GroupBy` clause to the `QueryChainBuilder`
     
     - parameter clause: a `GroupBy` clause to add to the query builder
     - returns: a new `QueryChainBuilder` containing the `GroupBy` clause
     */
    public func groupBy(
        _ clause: GroupBy<O>
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: clause)
    }
    
    /**
     Adds a `GroupBy` clause to the `QueryChainBuilder`
     
     - parameter keyPath: a key path to group the query results with
     - parameter keyPaths: other key paths to group the query results with
     - returns: a new `QueryChainBuilder` containing the `GroupBy` clause
     */
    public func groupBy(
        _ keyPath: KeyPathString,
        _ keyPaths: KeyPathString...
    ) -> QueryChainBuilder<O, R> {

        return self.groupBy(GroupBy<O>([keyPath] + keyPaths))
    }
    
    /**
     Adds a `GroupBy` clause to the `QueryChainBuilder`
     
     - parameter keyPaths: a series of key paths to group the query results with
     - returns: a new `QueryChainBuilder` containing the `GroupBy` clause
     */
    public func groupBy(
        _ keyPaths: [KeyPathString]
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: GroupBy<O>(keyPaths))
    }
    
    /**
     Appends a `QueryClause` to the `QueryChainBuilder`
     
     - parameter clause: the `QueryClause` to add to the `QueryChainBuilder`
     - returns: a new `QueryChainBuilder` containing the `QueryClause`
     */
    public func appending(
        _ clause: QueryClause
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: clause)
    }
    
    /**
     Appends a series of `QueryClause`s to the `QueryChainBuilder`
     
     - parameter clauses: the `QueryClause`s to add to the `QueryChainBuilder`
     - returns: a new `QueryChainBuilder` containing the `QueryClause`s
     */
    public func appending<S: Sequence>(
        contentsOf clauses: S
    ) -> QueryChainBuilder<O, R> where S.Element == QueryClause {

        return self.queryChain(appending: clauses)
    }
    
    
    // MARK: Private
    
    private func queryChain(
        appending clause: QueryClause
    ) -> QueryChainBuilder<O, R> {

        return .init(
            from: self.from,
            select: self.select,
            queryClauses: self.queryClauses + [clause]
        )
    }
    
    private func queryChain<S: Sequence>(
        appending clauses: S
    ) -> QueryChainBuilder<O, R> where S.Element == QueryClause {

        return .init(
            from: self.from,
            select: self.select,
            queryClauses: self.queryClauses + Array(clauses)
        )
    }
}


// MARK: - QueryChainBuilder where O: NSManagedObject

extension QueryChainBuilder where O: NSManagedObject {
    
    /**
     Adds a `GroupBy` clause to the `QueryChainBuilder`
     
     - parameter keyPath: a key path to group the query results with
     - returns: a new `QueryChainBuilder` containing the `GroupBy` clause
     */
    public func groupBy<T>(
        _ keyPath: KeyPath<O, T>
    ) -> QueryChainBuilder<O, R> {

        return self.groupBy(GroupBy<O>(keyPath))
    }
}


// MARK: - QueryChainBuilder where O: CoreStoreObject

extension QueryChainBuilder where O: CoreStoreObject {
    
    /**
     Adds a `Where` clause to the `QueryChainBuilder`
     
     - parameter clause: a `Where` clause to add to the query builder
     - returns: a new `QueryChainBuilder` containing the `Where` clause
     */
    public func `where`<T: AnyWhereClause>(
        _ clause: (O) -> T
    ) -> QueryChainBuilder<O, R> {

        return self.queryChain(appending: clause(O.meta))
    }
    
    /**
     Adds a `GroupBy` clause to the `QueryChainBuilder`
     
     - parameter keyPath: a key path to group the query results with
     - returns: a new `QueryChainBuilder` containing the `GroupBy` clause
     */
    public func groupBy<T>(
        _ keyPath: KeyPath<O, FieldContainer<O>.Stored<T>>
    ) -> QueryChainBuilder<O, R> {

        return self.groupBy(GroupBy<O>(keyPath))
    }
    
    /**
     Adds a `GroupBy` clause to the `QueryChainBuilder`
     
     - parameter keyPath: a key path to group the query results with
     - returns: a new `QueryChainBuilder` containing the `GroupBy` clause
     */
    public func groupBy<T>(
        _ keyPath: KeyPath<O, FieldContainer<O>.Virtual<T>>
    ) -> QueryChainBuilder<O, R> {

        return self.groupBy(GroupBy<O>(keyPath))
    }
    
    /**
     Adds a `GroupBy` clause to the `QueryChainBuilder`
     
     - parameter keyPath: a key path to group the query results with
     - returns: a new `QueryChainBuilder` containing the `GroupBy` clause
     */
    public func groupBy<T>(
        _ keyPath: KeyPath<O, FieldContainer<O>.Coded<T>>
    ) -> QueryChainBuilder<O, R> {

        return self.groupBy(GroupBy<O>(keyPath))
    }
}


// MARK: - SectionMonitorChainBuilder

extension SectionMonitorChainBuilder {
    
    /**
     Adds a `Where` clause to the `SectionMonitorChainBuilder`
     
     - parameter clause: a `Where` clause to add to the fetch builder
     - returns: a new `SectionMonitorChainBuilder` containing the `Where` clause
     */
    public func `where`(
        _ clause: Where<O>
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: clause)
    }
    
    /**
     Creates a `FetchChainBuilder` that `AND`s the specified `Where` clauses. Use this overload if the compiler cannot infer the types when chaining multiple `&&` operators.
     
     - parameter clauses: the `Where` clauses to create a `FetchChainBuilder` with
     - returns: a `FetchChainBuilder` that `AND`s the specified `Where` clauses
     */
    public func `where`(
        combineByAnd clauses: Where<O>...
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: clauses.combinedByAnd())
    }
    
    /**
     Creates a `FetchChainBuilder` that `OR`s the specified `Where` clauses. Use this overload if the compiler cannot infer the types when chaining multiple `||` operators.
     
     - parameter clauses: the `Where` clauses to create a `FetchChainBuilder` with
     - returns: a `FetchChainBuilder` that `OR`s the specified `Where` clauses
     */
    public func `where`(
        combineByOr clauses: Where<O>...
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: clauses.combinedByOr())
    }
    
    /**
     Adds a `Where` clause to the `SectionMonitorChainBuilder`
     
     - parameter format: the format string for the predicate
     - parameter args: the arguments for `format`
     - returns: a new `SectionMonitorChainBuilder` containing the `Where` clause
     */
    public func `where`(
        format: String,
        _ args: Any...
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: Where<O>(format, argumentArray: args))
    }
    
    /**
     Adds a `Where` clause to the `SectionMonitorChainBuilder`
     
     - parameter format: the format string for the predicate
     - parameter argumentArray: the arguments for `format`
     - returns: a new `SectionMonitorChainBuilder` containing the `Where` clause
     */
    public func `where`(
        format: String,
        argumentArray: [Any]?
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: Where<O>(format, argumentArray: argumentArray))
    }

    /**
     Adds an `OrderBy` clause to the `SectionMonitorChainBuilder`

     - parameter clause: the `OrderBy` clause to add
     - returns: a new `SectionMonitorChainBuilder` containing the `OrderBy` clause
     */
    public func orderBy(
        _ clause: OrderBy<O>
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: clause)
    }
    
    /**
     Adds an `OrderBy` clause to the `SectionMonitorChainBuilder`
     
     - parameter sortKey: a single `SortKey`
     - parameter sortKeys: a series of other `SortKey`s
     - returns: a new `SectionMonitorChainBuilder` containing the `OrderBy` clause
     */
    public func orderBy(
        _ sortKey: OrderBy<O>.SortKey,
        _ sortKeys: OrderBy<O>.SortKey...
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: OrderBy<O>([sortKey] + sortKeys))
    }

    /**
     Adds an `OrderBy` clause to the `SectionMonitorChainBuilder`

     - parameter sortKeys: a series of `SortKey`s
     - returns: a new `SectionMonitorChainBuilder` containing the `OrderBy` clause
     */
    public func orderBy(
        _ sortKeys: [OrderBy<O>.SortKey]
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: OrderBy<O>(sortKeys))
    }
    
    /**
     Adds a `Tweak` clause to the `SectionMonitorChainBuilder` with a closure where the `NSFetchRequest` may be configured
     
     - parameter fetchRequest: the block to customize the `NSFetchRequest`
     - returns: a new `SectionMonitorChainBuilder` containing the `Tweak` clause
     */
    public func tweak(
        _ fetchRequest: @escaping (NSFetchRequest<NSFetchRequestResult>) -> Void
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: Tweak(fetchRequest))
    }
    
    /**
     Appends a `QueryClause` to the `SectionMonitorChainBuilder`
     
     - parameter clause: the `QueryClause` to add to the `SectionMonitorChainBuilder`
     - returns: a new `SectionMonitorChainBuilder` containing the `QueryClause`
     */
    public func appending(
        _ clause: FetchClause
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: clause)
    }
    
    /**
     Appends a series of `QueryClause`s to the `SectionMonitorChainBuilder`
     
     - parameter clauses: the `QueryClause`s to add to the `SectionMonitorChainBuilder`
     - returns: a new `SectionMonitorChainBuilder` containing the `QueryClause`s
     */
    public func appending<S: Sequence>(
        contentsOf clauses: S
    ) -> SectionMonitorChainBuilder<O> where S.Element == FetchClause {

        return self.sectionMonitorChain(appending: clauses)
    }
    
    
    // MARK: Private
    
    private func sectionMonitorChain(
        appending clause: FetchClause
    ) -> SectionMonitorChainBuilder<O> {

        return .init(
            from: self.from,
            sectionBy: self.sectionBy,
            fetchClauses: self.fetchClauses + [clause]
        )
    }
    
    private func sectionMonitorChain<S: Sequence>(
        appending clauses: S
    ) -> SectionMonitorChainBuilder<O> where S.Element == FetchClause {

        return .init(
            from: self.from,
            sectionBy: self.sectionBy,
            fetchClauses: self.fetchClauses + Array(clauses)
        )
    }
}


// MARK: - SectionMonitorChainBuilder where O: CoreStoreObject

extension SectionMonitorChainBuilder where O: CoreStoreObject {
    
    /**
     Adds a `Where` clause to the `SectionMonitorChainBuilder`
     
     - parameter clause: a `Where` clause to add to the fetch builder
     - returns: a new `SectionMonitorChainBuilder` containing the `Where` clause
     */
    public func `where`<T: AnyWhereClause>(
        _ clause: (O) -> T
    ) -> SectionMonitorChainBuilder<O> {

        return self.sectionMonitorChain(appending: clause(O.meta))
    }
}


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension From where O: CoreStoreObject {
    
    public func select<R>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<R>>) -> QueryChainBuilder<O, R> {
        
        return self.select(R.self, [SelectTerm<O>.attribute(keyPath)])
    }
    
    public func select<R>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<R>>) -> QueryChainBuilder<O, R> {
        
        return self.select(R.self, [SelectTerm<O>.attribute(keyPath)])
    }
    
    public func select<R>(_ keyPath: KeyPath<O, TransformableContainer<O>.Required<R>>) -> QueryChainBuilder<O, R> {
        
        return self.select(R.self, [SelectTerm<O>.attribute(keyPath)])
    }
    
    public func select<R>(_ keyPath: KeyPath<O, TransformableContainer<O>.Optional<R>>) -> QueryChainBuilder<O, R> {
        
        return self.select(R.self, [SelectTerm<O>.attribute(keyPath)])
    }
    
    public func sectionBy<T>(_ sectionKeyPath: KeyPath<O, ValueContainer<O>.Required<T>>) -> SectionMonitorChainBuilder<O> {
        
        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    public func sectionBy<T>(_ sectionKeyPath: KeyPath<O, ValueContainer<O>.Optional<T>>) -> SectionMonitorChainBuilder<O> {
        
        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    public func sectionBy<T>(_ sectionKeyPath: KeyPath<O, TransformableContainer<O>.Required<T>>) -> SectionMonitorChainBuilder<O> {
        
        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    public func sectionBy<T>(_ sectionKeyPath: KeyPath<O, TransformableContainer<O>.Optional<T>>) -> SectionMonitorChainBuilder<O> {
        
        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, ValueContainer<O>.Required<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) -> SectionMonitorChainBuilder<O> {
        
        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
    
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, ValueContainer<O>.Optional<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) -> SectionMonitorChainBuilder<O> {
        
        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
    
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, TransformableContainer<O>.Required<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) -> SectionMonitorChainBuilder<O> {
        
        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
    
    public func sectionBy<T>(
        _ sectionKeyPath: KeyPath<O, TransformableContainer<O>.Optional<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) -> SectionMonitorChainBuilder<O> {
        
        return self.sectionBy(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension QueryChainBuilder where O: CoreStoreObject {
    
    public func groupBy<T>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<T>>) -> QueryChainBuilder<O, R> {
        
        return self.groupBy(GroupBy<O>(keyPath))
    }
    
    public func groupBy<T>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<T>>) -> QueryChainBuilder<O, R> {
        
        return self.groupBy(GroupBy<O>(keyPath))
    }
    
    public func groupBy<T>(_ keyPath: KeyPath<O, TransformableContainer<O>.Required<T>>) -> QueryChainBuilder<O, R> {
        
        return self.groupBy(GroupBy<O>(keyPath))
    }
    
    public func groupBy<T>(_ keyPath: KeyPath<O, TransformableContainer<O>.Optional<T>>) -> QueryChainBuilder<O, R> {
        
        return self.groupBy(GroupBy<O>(keyPath))
    }
}
