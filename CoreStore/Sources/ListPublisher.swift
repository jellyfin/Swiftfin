//
//  ListPublisher.swift
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

import CoreData


// MARK: - ListPublisher

/**
 `ListPublisher` tracks a diffable list of `DynamicObject` instances. Unlike `ListMonitor`s, `ListPublisher` are more lightweight and access objects lazily. Objects that need to be notified of `ListPublisher` changes may register themselves to its `addObserver(_:_:)` method:
 ```
 let listPublisher = CoreStoreDefaults.dataStack.listPublisher(
     From<Person>()
         .where(\.title == "Engineer")
         .orderBy(.ascending(\.lastName))
 )
 listPublisher.addObserver(self) { (listPublisher) in
     // Handle changes
 }
 ```
 The `ListPublisher` instance needs to be held on (retained) for as long as the list needs to be observed.
 Observers registered via `addObserver(_:_:)` are not retained. `ListPublisher` only keeps a `weak` reference to all observers, thus keeping itself free from retain-cycles.
 
 `ListPublisher`s may optionally be created with sections:
 ```
 let listPublisher = CoreStoreDefaults.dataStack.listPublisher(
     From<Person>()
         .sectionBy(\.age") { "Age \($0)" }
         .where(\.title == "Engineer")
         .orderBy(.ascending(\.lastName))
 )
 ```
 All access to the `ListPublisher` items should be done via its `snapshot` value, which is a `struct` of type `ListSnapshot<O>`. `ListSnapshot`s are also designed to work well with `DiffableDataSource.TableViewAdapter`s and `DiffableDataSource.CollectionViewAdapter`s. For detailed examples, refer to the documentation for `DiffableDataSource.TableViewAdapter` and `DiffableDataSource.CollectionViewAdapter`.
 */
public final class ListPublisher<O: DynamicObject>: Hashable {

    // MARK: Public (Accessors)

    /**
     The `DynamicObject` type associated with this list
     */
    public typealias ObjectType = O

    /**
     The type for the section IDs
     */
    public typealias SectionID = ListSnapshot<O>.SectionID

    /**
     The type for the item IDs
     */
    public typealias ItemID = ListSnapshot<O>.ItemID

    /**
     A snapshot of the latest state of this list
     */
    public private(set) var snapshot: ListSnapshot<O> = .init()


    // MARK: Public (Observers)

    /**
     Registers an object as an observer to be notified when changes to the `ListPublisher`'s snapshot occur.

     To prevent retain-cycles, `ListPublisher` only keeps `weak` references to its observers.

     For thread safety, this method needs to be called from the main thread. An assertion failure will occur (on debug builds only) if called from any thread other than the main thread.

     Calling `addObserver(_:_:)` multiple times on the same observer is safe.

     - parameter observer: an object to become owner of the specified `callback`
     - parameter notifyInitial: if `true`, the callback is executed immediately with the current publisher state. Otherwise only succeeding updates will notify the observer. Default value is `false`.
     - parameter callback: the closure to execute when changes occur
     */
    public func addObserver<T: AnyObject>(
        _ observer: T,
        notifyInitial: Bool = false,
        _ callback: @escaping (ListPublisher<O>) -> Void
    ) {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to add an observer of type \(Internals.typeName(observer)) outside the main thread."
        )
        self.observers.setObject(
            Internals.Closure({ callback($0.listPublisher) }),
            forKey: observer
        )
        if notifyInitial {
            
            callback(self)
        }
    }
    
    /**
     Registers an object as an observer to be notified when changes to the `ListPublisher`'s snapshot occur.

     To prevent retain-cycles, `ListPublisher` only keeps `weak` references to its observers.

     For thread safety, this method needs to be called from the main thread. An assertion failure will occur (on debug builds only) if called from any thread other than the main thread.

     Calling `addObserver(_:_:)` multiple times on the same observer is safe.

     - parameter observer: an object to become owner of the specified `callback`
     - parameter notifyInitial: if `true`, the callback is executed immediately with the current publisher state. Otherwise only succeeding updates will notify the observer. Default value is `false`.
     - parameter initialSourceIdentifier: an optional value that identifies the initial callback invocation if `notifyInitial` is `true`.
     - parameter callback: the closure to execute when changes occur
     */
    public func addObserver<T: AnyObject>(
        _ observer: T,
        notifyInitial: Bool = false,
        initialSourceIdentifier: Any? = nil,
        _ callback: @escaping (
            _ listPublisher: ListPublisher<O>,
            _ sourceIdentifier: Any?
        ) -> Void
    ) {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to add an observer of type \(Internals.typeName(observer)) outside the main thread."
        )
        self.observers.setObject(
            Internals.Closure(callback),
            forKey: observer
        )
        if notifyInitial {
            
            callback(self, initialSourceIdentifier)
        }
    }

    /**
     Unregisters an object from receiving notifications for changes to the `ListPublisher`'s snapshot.

     For thread safety, this method needs to be called from the main thread. An assertion failure will occur (on debug builds only) if called from any thread other than the main thread.

     - parameter observer: the object whose notifications will be unregistered
     */
    public func removeObserver<T: AnyObject>(_ observer: T) {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to remove an observer of type \(Internals.typeName(observer)) outside the main thread."
        )
        self.observers.removeObject(forKey: observer)
    }


    // MARK: Public (Refetching)

    /**
     Asks the `ListPublisher` to refetch its objects using the specified `FetchChainableBuilderType`. Unlike `ListMonitor`s, a `ListPublisher`'s `refetch(...)` executes immediately.
     ```
     try listPublisher.refetch(
         From<MyPersonEntity>()
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `FetchChainableBuilderType` built from a chain of clauses
     - parameter sourceIdentifier: an optional value that identifies the source of this transaction. This identifier will be passed to the change notifications and callers can use it for custom handling that depends on the source.
     */
    public func refetch<B: FetchChainableBuilderType>(
        _ clauseChain: B,
        sourceIdentifier: Any? = nil
    ) throws(any Swift.Error) where B.ObjectType == O {

        try self.refetch(
            from: clauseChain.from,
            sectionBy: nil,
            applyFetchClauses: { (fetchRequest) in

                clauseChain.fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }
            },
            sourceIdentifier: sourceIdentifier
        )
    }

    /**
    Asks the `ListPublisher` to refetch its objects using the specified `SectionMonitorBuilderType`. Unlike `ListMonitor`s, a `ListPublisher`'s `refetch(...)` executes immediately.
     ```
     try listPublisher.refetch(
         From<MyPersonEntity>()
             .sectionBy(\.age, { "\($0!) years old" })
             .where(\.age > 18)
             .orderBy(.ascending(\.age))
     )
     ```
     - parameter clauseChain: a `SectionMonitorBuilderType` built from a chain of clauses
     - parameter sourceIdentifier: an optional value that identifies the source of this transaction. This identifier will be passed to the change notifications and callers can use it for custom handling that depends on the source.
     */
    public func refetch<B: SectionMonitorBuilderType>(
        _ clauseChain: B,
        sourceIdentifier: Any? = nil
    ) throws(any Swift.Error) where B.ObjectType == O {

        try self.refetch(
            from: clauseChain.from,
            sectionBy: clauseChain.sectionBy,
            applyFetchClauses: { (fetchRequest) in

                clauseChain.fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }
            },
            sourceIdentifier: sourceIdentifier
        )
    }
    
    /**
     Used internally by CoreStore. Do not call directly.
     */
    public func cs_dataStack() -> DataStack? {
        
        return self.context.parentStack
    }


    // MARK: Public (3rd Party Utilities)

    /**
     Allow external libraries to store custom data in the `ListPublisher`. App code should rarely have a need for this.
     ```
     enum Static {
         static var myDataKey: Void?
     }
     monitor.userInfo[&Static.myDataKey] = myObject
     ```
     - Important: Do not use this method to store thread-sensitive data.
     */
    public let userInfo = UserInfo()


    // MARK: Equatable

    public static func == (_ lhs: ListPublisher, _ rhs: ListPublisher) -> Bool {

        return lhs === rhs
    }


    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(ObjectIdentifier(self))
    }


    // MARK: Internal
    
    internal private(set) lazy var context: NSManagedObjectContext = self.fetchedResultsController.managedObjectContext

    internal convenience init(
        dataStack: DataStack,
        from: From<ObjectType>,
        sectionBy: SectionBy<ObjectType>?,
        applyFetchClauses: @escaping (_ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void
    ) {

        self.init(
            context: dataStack.mainContext,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses,
            createAsynchronously: nil
        )
    }

    internal convenience init(
        dataStack: DataStack,
        from: From<ObjectType>,
        sectionBy: SectionBy<ObjectType>?,
        applyFetchClauses: @escaping (_ fetchRequest:  Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void,
        createAsynchronously: @escaping (ListPublisher<ObjectType>) -> Void
    ) {

        self.init(
            context: dataStack.mainContext,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses,
            createAsynchronously: createAsynchronously
        )
    }

    internal convenience init(
        unsafeTransaction: UnsafeDataTransaction,
        from: From<ObjectType>,
        sectionBy: SectionBy<ObjectType>?,
        applyFetchClauses: @escaping (_ fetchRequest:  Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void
    ) {

        self.init(
            context: unsafeTransaction.context,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses,
            createAsynchronously: nil
        )
    }

    internal convenience init(
        unsafeTransaction: UnsafeDataTransaction,
        from: From<ObjectType>,
        sectionBy: SectionBy<ObjectType>?,
        applyFetchClauses: @escaping (_ fetchRequest:  Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void,
        createAsynchronously: @escaping (ListPublisher<ObjectType>) -> Void
    ) {

        self.init(
            context: unsafeTransaction.context,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses,
            createAsynchronously: createAsynchronously
        )
    }

    internal func refetch(
        from: From<O>,
        sectionBy: SectionBy<O>?,
        applyFetchClauses: @escaping (_ fetchRequest:  Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void,
        sourceIdentifier: Any?
    ) throws(any Swift.Error) {

        let (newFetchedResultsController, newFetchedResultsControllerDelegate) = Self.recreateFetchedResultsController(
            context: self.fetchedResultsController.managedObjectContext,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses
        )
        self.query = (
            from: from,
            sectionBy: sectionBy,
            sectionIndexTransformer: sectionBy?.sectionIndexTransformer ?? { _ in nil },
            applyFetchClauses: applyFetchClauses
        )
        (self.fetchedResultsController, self.fetchedResultsControllerDelegate) = (newFetchedResultsController, newFetchedResultsControllerDelegate)

        newFetchedResultsControllerDelegate.handler = self
        
        newFetchedResultsController.managedObjectContext.saveMetadata = .init(
            isSavingSynchronously: true,
            sourceIdentifier: sourceIdentifier
        )
        try newFetchedResultsController.performFetchFromSpecifiedStores()
        newFetchedResultsController.managedObjectContext.saveMetadata = nil
    }

    deinit {

        self.fetchedResultsControllerDelegate.fetchedResultsController = nil
        self.observers.removeAllObjects()
    }
    
    
    // MARK: FilePrivate
    
    fileprivate typealias ObserverClosureType = Internals.Closure<(listPublisher: ListPublisher<O>, sourceIdentifier: Any?), Void>
    
    fileprivate func set(
        snapshot: ListSnapshot<O>,
        sourceIdentifier: Any?
    )  {

        self.snapshot = snapshot
        self.notifyObservers(sourceIdentifier: sourceIdentifier)
    }
    
    
    // MARK: Private

    private var query: (
        from: From<O>,
        sectionBy: SectionBy<O>?,
        sectionIndexTransformer: (_ sectionName: KeyPathString?) -> String?,
        applyFetchClauses: (_ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void
    )

    private var fetchedResultsController: Internals.CoreStoreFetchedResultsController
    private var fetchedResultsControllerDelegate: Internals.FetchedDiffableDataSourceSnapshotDelegate
    private var observerForWillChangePersistentStore: Internals.NotificationObserver!
    private var observerForDidChangePersistentStore: Internals.NotificationObserver!

    private lazy var observers: NSMapTable<AnyObject, ObserverClosureType> = .weakToStrongObjects()

    private static func recreateFetchedResultsController(
        context: NSManagedObjectContext,
        from: From<ObjectType>,
        sectionBy: SectionBy<ObjectType>?,
        applyFetchClauses: @escaping (_ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void
    ) -> (
        controller: Internals.CoreStoreFetchedResultsController,
        delegate: Internals.FetchedDiffableDataSourceSnapshotDelegate
    ) {

        let fetchRequest = Internals.CoreStoreFetchRequest<NSManagedObject>()
        fetchRequest.fetchLimit = 0
        fetchRequest.resultType = .managedObjectResultType
        fetchRequest.includesPendingChanges = false
        fetchRequest.shouldRefreshRefetchedObjects = true

        let fetchedResultsController = Internals.CoreStoreFetchedResultsController(
            context: context,
            fetchRequest: fetchRequest,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses
        )

        let fetchedResultsControllerDelegate = Internals.FetchedDiffableDataSourceSnapshotDelegate()
        fetchedResultsControllerDelegate.fetchedResultsController = fetchedResultsController

        return (fetchedResultsController, fetchedResultsControllerDelegate)
    }

    private init(
        context: NSManagedObjectContext,
        from: From<ObjectType>,
        sectionBy: SectionBy<ObjectType>?,
        applyFetchClauses: @escaping (_ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void,
        createAsynchronously: ((ListPublisher<ObjectType>) -> Void)?
    ) {

        self.query = (
            from: from,
            sectionBy: sectionBy,
            sectionIndexTransformer: sectionBy?.sectionIndexTransformer ?? { _ in nil },
            applyFetchClauses: applyFetchClauses
        )
        (self.fetchedResultsController, self.fetchedResultsControllerDelegate) = Self.recreateFetchedResultsController(
            context: context,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses
        )

        self.fetchedResultsControllerDelegate.handler = self

        try! self.fetchedResultsController.performFetchFromSpecifiedStores()
    }

    private func notifyObservers(sourceIdentifier: Any?) {

        guard let enumerator = self.observers.objectEnumerator() else {

            return
        }
        let arguments: ObserverClosureType.Arguments = (
            listPublisher: self,
            sourceIdentifier: sourceIdentifier
        )
        for closure in enumerator {

            (closure as! ObserverClosureType).invoke(with: arguments)
        }
    }
}


// MARK: - ListPublisher: FetchedDiffableDataSourceSnapshotHandler

extension ListPublisher: FetchedDiffableDataSourceSnapshotHandler {

    // MARK: FetchedDiffableDataSourceSnapshotHandler
    
    internal var sectionIndexTransformer: (_ sectionName: KeyPathString?) -> String? {
        
        return self.query.sectionIndexTransformer
    }

    internal func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: Internals.DiffableDataSourceSnapshot
    ) {

        let context = controller.managedObjectContext
        self.set(
            snapshot: .init(
                diffableSnapshot: snapshot,
                context: context
            ),
            sourceIdentifier: context.saveMetadata?.sourceIdentifier
        )
    }
}
