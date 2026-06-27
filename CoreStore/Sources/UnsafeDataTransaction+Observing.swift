//
//  UnsafeDataTransaction+Observing.swift
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

extension UnsafeDataTransaction {
    
    /**
     Creates an `ObjectMonitor` for the specified `DynamicObject`. Multiple `ObjectObserver`s may then register themselves to be notified when changes are made to the `DynamicObject`.
     
     - parameter object: the `DynamicObject` to observe changes from
     - returns: an `ObjectMonitor` that monitors changes to `object`
     */
    public func monitorObject<O: DynamicObject>(
        _ object: O
    ) -> ObjectMonitor<O> {

        return .init(objectID: object.cs_id(), context: self.unsafeContext())
    }
    
    /**
     Creates a `ListMonitor` for a list of `DynamicObject`s that satisfy the specified fetch clauses. Multiple `ListObserver`s may then register themselves to be notified when changes are made to the list.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: a `ListMonitor` instance that monitors changes to the list
     */
    public func monitorList<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) -> ListMonitor<O> {

        return self.monitorList(from, fetchClauses)
    }
    
    /**
     Creates a `ListMonitor` for a list of `DynamicObject`s that satisfy the specified fetch clauses. Multiple `ListObserver`s may then register themselves to be notified when changes are made to the list.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: a `ListMonitor` instance that monitors changes to the list
     */
    public func monitorList<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) -> ListMonitor<O> {

        Internals.assert(
            fetchClauses.filter { $0 is OrderBy<O> }.count > 0,
            "A ListMonitor requires an OrderBy clause."
        )
        
        return ListMonitor(
            unsafeTransaction: self,
            from: from,
            sectionBy: nil,
            applyFetchClauses: { fetchRequest in
                
                fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }
            }
        )
    }
    
    /**
     Asynchronously creates a `ListMonitor` for a list of `DynamicObject`s that satisfy the specified `FetchChainableBuilderType` built from a chain of clauses. Since `NSFetchedResultsController` greedily locks the persistent store on initial fetch, you may prefer this method instead of the synchronous counterpart to avoid deadlocks while background updates/saves are being executed.
     
     ```
     transaction.monitorList(
         { (monitor) in
             self.monitor = monitor
         },
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter createAsynchronously: the closure that receives the created `ListMonitor` instance
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - returns: a `ListMonitor` for a list of `DynamicObject`s that satisfy the specified `FetchChainableBuilderType`
     */
    public func monitorList<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) -> ListMonitor<B.ObjectType> {

        return self.monitorList(clauseChain.from, clauseChain.fetchClauses)
    }
    
    /**
     Asynchronously creates a `ListMonitor` for a list of `DynamicObject`s that satisfy the specified fetch clauses. Multiple `ListObserver`s may then register themselves to be notified when changes are made to the list. Since `NSFetchedResultsController` greedily locks the persistent store on initial fetch, you may prefer this method instead of the synchronous counterpart to avoid deadlocks while background updates/saves are being executed.
     
     - parameter createAsynchronously: the closure that receives the created `ListMonitor` instance
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     */
    public func monitorList<O>(
        createAsynchronously: @escaping (ListMonitor<O>) -> Void,
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) {

        self.monitorList(createAsynchronously: createAsynchronously, from, fetchClauses)
    }
    
    /**
     Asynchronously creates a `ListMonitor` for a list of `DynamicObject`s that satisfy the specified fetch clauses. Multiple `ListObserver`s may then register themselves to be notified when changes are made to the list. Since `NSFetchedResultsController` greedily locks the persistent store on initial fetch, you may prefer this method instead of the synchronous counterpart to avoid deadlocks while background updates/saves are being executed.
     
     - parameter createAsynchronously: the closure that receives the created `ListMonitor` instance
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     */
    public func monitorList<O>(
        createAsynchronously: @escaping (ListMonitor<O>) -> Void,
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    )  {

        Internals.assert(
            fetchClauses.filter { $0 is OrderBy<O> }.count > 0,
            "A ListMonitor requires an OrderBy clause."
        )
        
        _ = ListMonitor(
            unsafeTransaction: self,
            from: from,
            sectionBy: nil,
            applyFetchClauses: { fetchRequest in
                
                fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }
            },
            createAsynchronously: createAsynchronously
        )
    }

    /**
     Asynchronously creates a `ListMonitor` for a list of `DynamicObject`s that satisfy the specified `FetchChainableBuilderType` built from a chain of clauses. Since `NSFetchedResultsController` greedily locks the persistent store on initial fetch, you may prefer this method instead of the synchronous counterpart to avoid deadlocks while background updates/saves are being executed.

     ```
     dataStack.monitorList(
         createAsynchronously: { (monitor) in
             self.monitor = monitor
         },
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter createAsynchronously: the closure that receives the created `ListMonitor` instance
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     */
    public func monitorList<B: FetchChainableBuilderType>(
        createAsynchronously: @escaping (ListMonitor<B.ObjectType>) -> Void,
        _ clauseChain: B
    ) {

        self.monitorList(
            createAsynchronously: createAsynchronously,
            clauseChain.from,
            clauseChain.fetchClauses
        )
    }
    
    /**
     Creates a `ListMonitor` for a sectioned list of `DynamicObject`s that satisfy the specified fetch clauses. Multiple `ListObserver`s may then register themselves to be notified when changes are made to the list.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter sectionBy: a `SectionBy` clause indicating the keyPath for the attribute to use when sorting the list into sections.
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: a `ListMonitor` instance that monitors changes to the list
     */
    public func monitorSectionedList<O>(
        _ from: From<O>,
        _ sectionBy: SectionBy<O>,
        _ fetchClauses: FetchClause...
    ) -> ListMonitor<O> {

        return self.monitorSectionedList(from, sectionBy, fetchClauses)
    }
    
    /**
     Creates a `ListMonitor` for a sectioned list of `DynamicObject`s that satisfy the specified fetch clauses. Multiple `ListObserver`s may then register themselves to be notified when changes are made to the list.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter sectionBy: a `SectionBy` clause indicating the keyPath for the attribute to use when sorting the list into sections.
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: a `ListMonitor` instance that monitors changes to the list
     */
    public func monitorSectionedList<O>(
        _ from: From<O>,
        _ sectionBy: SectionBy<O>,
        _ fetchClauses: [FetchClause]
    ) -> ListMonitor<O> {

        Internals.assert(
            fetchClauses.filter { $0 is OrderBy<O> }.count > 0,
            "A ListMonitor requires an OrderBy clause."
        )
        
        return ListMonitor(
            unsafeTransaction: self,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: { fetchRequest in
                
                fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }
            }
        )
    }
    
    /**
     Creates a `ListMonitor` for a sectioned list of `DynamicObject`s that satisfy the specified `SectionMonitorBuilderType` built from a chain of clauses.
     ```
     let monitor = transaction.monitorSectionedList(
         From<MyPersonEntity>()
             .sectionBy(\.age, { "\($0!) years old" })
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `SectionMonitorBuilderType` built from a chain of clauses
     - returns: a `ListMonitor` for a list of `DynamicObject`s that satisfy the specified `SectionMonitorBuilderType`
     */
    public func monitorSectionedList<B: SectionMonitorBuilderType>(
        _ clauseChain: B
    ) -> ListMonitor<B.ObjectType> {

        return self.monitorSectionedList(
            clauseChain.from,
            clauseChain.sectionBy,
            clauseChain.fetchClauses
        )
    }
    
    /**
     Asynchronously creates a `ListMonitor` for a sectioned list of `DynamicObject`s that satisfy the specified fetch clauses. Multiple `ListObserver`s may then register themselves to be notified when changes are made to the list. Since `NSFetchedResultsController` greedily locks the persistent store on initial fetch, you may prefer this method instead of the synchronous counterpart to avoid deadlocks while background updates/saves are being executed.
     
     - parameter createAsynchronously: the closure that receives the created `ListMonitor` instance
     - parameter from: a `From` clause indicating the entity type
     - parameter sectionBy: a `SectionBy` clause indicating the keyPath for the attribute to use when sorting the list into sections.
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     */
    public func monitorSectionedList<O>(
        createAsynchronously: @escaping (ListMonitor<O>) -> Void,
        _ from: From<O>,
        _ sectionBy: SectionBy<O>,
        _ fetchClauses: FetchClause...
    ) {

        self.monitorSectionedList(createAsynchronously: createAsynchronously, from, sectionBy, fetchClauses)
    }
    
    /**
     Asynchronously creates a `ListMonitor` for a sectioned list of `DynamicObject`s that satisfy the specified fetch clauses. Multiple `ListObserver`s may then register themselves to be notified when changes are made to the list. Since `NSFetchedResultsController` greedily locks the persistent store on initial fetch, you may prefer this method instead of the synchronous counterpart to avoid deadlocks while background updates/saves are being executed.
     
     - parameter createAsynchronously: the closure that receives the created `ListMonitor` instance
     - parameter from: a `From` clause indicating the entity type
     - parameter sectionBy: a `SectionBy` clause indicating the keyPath for the attribute to use when sorting the list into sections.
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     */
    public func monitorSectionedList<O>(
        createAsynchronously: @escaping (ListMonitor<O>) -> Void,
        _ from: From<O>,
        _ sectionBy: SectionBy<O>,
        _ fetchClauses: [FetchClause]
    ) {
        
        Internals.assert(
            fetchClauses.filter { $0 is OrderBy<O> }.count > 0,
            "A ListMonitor requires an OrderBy clause."
        )
        
        _ = ListMonitor(
            unsafeTransaction: self,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: { fetchRequest in
                
                fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }
            },
            createAsynchronously: createAsynchronously
        )
    }
    
    /**
     Asynchronously creates a `ListMonitor` for a sectioned list of `DynamicObject`s that satisfy the specified `SectionMonitorBuilderType` built from a chain of clauses.
     ```
     transaction.monitorSectionedList(
         { (monitor) in
             self.monitor = monitor
         },
         From<MyPersonEntity>()
             .sectionBy(\.age, { "\($0!) years old" })
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter createAsynchronously: the closure that receives the created `ListMonitor` instance
     - parameter clauseChain: a `SectionMonitorBuilderType` built from a chain of clauses
     */
    public func monitorSectionedList<B: SectionMonitorBuilderType>(
        createAsynchronously: @escaping (ListMonitor<B.ObjectType>) -> Void,
        _ clauseChain: B
    ) {
        
        self.monitorSectionedList(
            createAsynchronously: createAsynchronously,
            clauseChain.from,
            clauseChain.sectionBy,
            clauseChain.fetchClauses
        )
    }
}
