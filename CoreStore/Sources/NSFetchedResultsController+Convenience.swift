//
//  NSManagedObject+Convenience.swift
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
     Utility for creating an `NSFetchedResultsController` from the `DataStack`. This is useful when an `NSFetchedResultsController` is preferred over the overhead of `ListMonitor`s abstraction.
     - Note: It is the caller's responsibility to call `performFetch()` on the created `NSFetchedResultsController`.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter sectionBy: a `SectionBy` clause indicating the keyPath for the attribute to use when sorting the list into sections
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: an `NSFetchedResultsController` that observes the `DataStack`
     */
    @nonobjc
    public func createFetchedResultsController<O: NSManagedObject>(
        _ from: From<O>,
        _ sectionBy: SectionBy<O>,
        _ fetchClauses: FetchClause...
    ) -> NSFetchedResultsController<O> {

        return Internals.createFRC(
            fromContext: self.mainContext,
            from: from,
            sectionBy: sectionBy,
            fetchClauses: fetchClauses
        )
    }
    
    /**
     Utility for creating an `NSFetchedResultsController` from a `DataStack`. This is useful when an `NSFetchedResultsController` is preferred over the overhead of `ListMonitor`s abstraction.
     - Note: It is the caller's responsibility to call `performFetch()` on the created `NSFetchedResultsController`.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter sectionBy: a `SectionBy` clause indicating the keyPath for the attribute to use when sorting the list into sections
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: an `NSFetchedResultsController` that observes the `DataStack`
     */
    @nonobjc
    public func createFetchedResultsController<O: NSManagedObject>(
        _ from: From<O>,
        _ sectionBy: SectionBy<O>,
        _ fetchClauses: [FetchClause]
    ) -> NSFetchedResultsController<O> {

        return Internals.createFRC(
            fromContext: self.mainContext,
            from: from,
            sectionBy: sectionBy,
            fetchClauses: fetchClauses
        )
    }
    
    /**
     Utility for creating an `NSFetchedResultsController` from the `DataStack`. This is useful when an `NSFetchedResultsController` is preferred over the overhead of `ListMonitor`s abstraction.
     - Note: It is the caller's responsibility to call `performFetch()` on the created `NSFetchedResultsController`.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: an `NSFetchedResultsController` that observes the `DataStack`
     */
    @nonobjc
    public func createFetchedResultsController<O: NSManagedObject>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) -> NSFetchedResultsController<O> {

        return Internals.createFRC(
            fromContext: self.mainContext,
            from: from,
            sectionBy: nil,
            fetchClauses: fetchClauses
        )
    }
    
    /**
     Utility for creating an `NSFetchedResultsController` from the `DataStack`. This is useful when an `NSFetchedResultsController` is preferred over the overhead of `ListMonitor`s abstraction.
     - Note: It is the caller's responsibility to call `performFetch()` on the created `NSFetchedResultsController`.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: an `NSFetchedResultsController` that observes the `DataStack`
     */
    @nonobjc
    public func createFetchedResultsController<O: NSManagedObject>(
        forDataStack dataStack: DataStack,
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) -> NSFetchedResultsController<O> {

        return Internals.createFRC(
            fromContext: self.mainContext,
            from: from,
            sectionBy: nil,
            fetchClauses: fetchClauses
        )
    }
}


// MARK: - UnsafeDataTransaction

extension UnsafeDataTransaction {
    
    /**
     Utility for creating an `NSFetchedResultsController` from the `UnsafeDataTransaction`. This is useful when an `NSFetchedResultsController` is preferred over the overhead of `ListMonitor`s abstraction.
     - Note: It is the caller's responsibility to call `performFetch()` on the created `NSFetchedResultsController`.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter sectionBy: a `SectionBy` clause indicating the keyPath for the attribute to use when sorting the list into sections
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: an `NSFetchedResultsController` that observes the `UnsafeDataTransaction`
     */
    @nonobjc
    public func createFetchedResultsController<O: NSManagedObject>(
        _ from: From<O>,
        _ sectionBy: SectionBy<O>,
        _ fetchClauses: FetchClause...
    ) -> NSFetchedResultsController<O> {

        return Internals.createFRC(
            fromContext: self.context,
            from: from,
            sectionBy: sectionBy,
            fetchClauses: fetchClauses
        )
    }
    
    /**
     Utility for creating an `NSFetchedResultsController` from the `UnsafeDataTransaction`. This is useful when an `NSFetchedResultsController` is preferred over the overhead of `ListMonitor`s abstraction.
     - Note: It is the caller's responsibility to call `performFetch()` on the created `NSFetchedResultsController`.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter sectionBy: a `SectionBy` clause indicating the keyPath for the attribute to use when sorting the list into sections
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: an `NSFetchedResultsController` that observes the `UnsafeDataTransaction`
     */
    @nonobjc
    public func createFetchedResultsController<O: NSManagedObject>(
        _ from: From<O>,
        _ sectionBy: SectionBy<O>,
        _ fetchClauses: [FetchClause]
    ) -> NSFetchedResultsController<O> {

        return Internals.createFRC(
            fromContext: self.context,
            from: from,
            sectionBy: sectionBy,
            fetchClauses: fetchClauses
        )
    }
    
    /**
     Utility for creating an `NSFetchedResultsController` from the `UnsafeDataTransaction`. This is useful when an `NSFetchedResultsController` is preferred over the overhead of `ListMonitor`s abstraction.
     - Note: It is the caller's responsibility to call `performFetch()` on the created `NSFetchedResultsController`.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: an `NSFetchedResultsController` that observes the `UnsafeDataTransaction`
     */
    @nonobjc
    public func createFetchedResultsController<O: NSManagedObject>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) -> NSFetchedResultsController<O> {

        return Internals.createFRC(
            fromContext: self.context,
            from: from,
            sectionBy: nil,
            fetchClauses: fetchClauses
        )
    }
    
    /**
     Utility for creating an `NSFetchedResultsController` from the `UnsafeDataTransaction`. This is useful when an `NSFetchedResultsController` is preferred over the overhead of `ListMonitor`s abstraction.
     - Note: It is the caller's responsibility to call `performFetch()` on the created `NSFetchedResultsController`.
     
     - parameter from: a `From` clause indicating the entity type
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - returns: an `NSFetchedResultsController` that observes the `UnsafeDataTransaction`
     */
    @nonobjc
    public func createFetchedResultsController<O: NSManagedObject>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) -> NSFetchedResultsController<O> {

        return Internals.createFRC(
            fromContext: self.context,
            from: from,
            sectionBy: nil,
            fetchClauses: fetchClauses
        )
    }
}



// MARK: - Internals

extension Internals {

    // MARK: FilePrivate

    fileprivate static func createFRC<O: NSManagedObject>(
        fromContext context: NSManagedObjectContext,
        from: From<O>,
        sectionBy: SectionBy<O>? = nil,
        fetchClauses: [FetchClause]
    ) -> NSFetchedResultsController<O> {

        let controller = Internals.CoreStoreFetchedResultsController(
            context: context,
            fetchRequest: Internals.CoreStoreFetchRequest(),
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: { (fetchRequest) in

                fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

                Internals.assert(
                    fetchRequest.sortDescriptors?.isEmpty == false,
                    "An \(Internals.typeName(NSFetchedResultsController<O>.self)) requires a sort information. Specify from a \(Internals.typeName(OrderBy<O>.self)) clause or any custom \(Internals.typeName(FetchClause.self)) that provides a sort descriptor."
                )
            }
        )
        return controller.dynamicCast()
    }
}
