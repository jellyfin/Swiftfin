//
//  ListMonitor.swift
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


// MARK: - ListMonitor

/**
 The `ListMonitor` monitors changes to a list of `DynamicObject` instances. Observers that implement the `ListObserver` protocol may then register themselves to the `ListMonitor`'s `addObserver(_:)` method:
 ```
 let monitor = dataStack.monitorList(
     From<Person>(),
     Where("title", isEqualTo: "Engineer"),
     OrderBy(.ascending("lastName"))
 )
 monitor.addObserver(self)
 ```
 The `ListMonitor` instance needs to be held on (retained) for as long as the list needs to be observed.
 Observers registered via `addObserver(_:)` are not retained. `ListMonitor` only keeps a `weak` reference to all observers, thus keeping itself free from retain-cycles.
 
 Lists created with `monitorList(...)` keep a single-section list of objects, where each object can be accessed by index:
 ```
 let firstPerson: MyPersonEntity = monitor[0]
 ```
 Accessing the list with an index above the valid range will raise an exception.
 
 Creating a sectioned-list is also possible with the `monitorSectionedList(...)` method:
 ```
 let monitor = dataStack.monitorSectionedList(
     From<Person>(),
     SectionBy("age") { "Age \($0)" },
     Where("title", isEqualTo: "Engineer"),
     OrderBy(.ascending("lastName"))
 )
 monitor.addObserver(self)
 ```
 Objects from `ListMonitor`s created this way can be accessed either by an `IndexPath` or a tuple:
 ```
 let indexPath = IndexPath(forItem: 3, inSection: 2)
 let person1 = monitor[indexPath]
 let person2 = monitor[2, 3]
 ```
 In the example above, both `person1` and `person2` will contain the object at section=2, index=3.
 */
public final class ListMonitor<O: DynamicObject>: Hashable {
    
    // MARK: Public (Accessors)
    
    /**
     The type for the objects contained bye the `ListMonitor`
     */
    public typealias ObjectType = O
    
    /**
     Returns the object at the given index within the first section. This subscript indexer is typically used for `ListMonitor`s created with `monitorList(_:)`.
     
     - parameter index: the index of the object. Using an index above the valid range will raise an exception.
     - returns: the `DynamicObject` at the specified index
     */
    public subscript(index: Int) -> O {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        if self.isSectioned {
            
            return O.cs_fromRaw(object: (self.fetchedResultsController.fetchedObjects as NSArray?)![index] as! NSManagedObject)
        }
        return self[0, index]
    }
    
    /**
     Returns the object at the given index, or `nil` if out of bounds. This subscript indexer is typically used for `ListMonitor`s created with `monitorList(_:)`.
     
     - parameter index: the index for the object. Using an index above the valid range will return `nil`.
     - returns: the `DynamicObject` at the specified index, or `nil` if out of bounds
     */
    public subscript(safeIndex index: Int) -> O? {
        
        if self.isSectioned {
            
            let fetchedObjects = (self.fetchedResultsController.fetchedObjects as NSArray?)!
            if index < fetchedObjects.count && index >= 0 {
                
                return O.cs_fromRaw(object: fetchedObjects[index] as! NSManagedObject)
            }
            return nil
        }
        return self[safeSectionIndex: 0, safeItemIndex: index]
    }
    
    /**
     Returns the object at the given `sectionIndex` and `itemIndex`. This subscript indexer is typically used for `ListMonitor`s created with `monitorSectionedList(_:)`.
     
     - parameter sectionIndex: the section index for the object. Using a `sectionIndex` with an invalid range will raise an exception.
     - parameter itemIndex: the index for the object within the section. Using an `itemIndex` with an invalid range will raise an exception.
     - returns: the `DynamicObject` at the specified section and item index
     */
    public subscript(sectionIndex: Int, itemIndex: Int) -> O {
        
        return self[IndexPath(indexes: [sectionIndex, itemIndex])]
    }
    
    /**
     Returns the object at the given section and item index, or `nil` if out of bounds. This subscript indexer is typically used for `ListMonitor`s created with `monitorSectionedList(_:)`.
     
     - parameter sectionIndex: the section index for the object. Using a `sectionIndex` with an invalid range will return `nil`.
     - parameter itemIndex: the index for the object within the section. Using an `itemIndex` with an invalid range will return `nil`.
     - returns: the `DynamicObject` at the specified section and item index, or `nil` if out of bounds
     */
    public subscript(safeSectionIndex sectionIndex: Int, safeItemIndex itemIndex: Int) -> O? {
        
        guard let section = self.sectionInfo(safelyAt: sectionIndex) else {
            
            return nil
        }
        guard itemIndex >= 0 && itemIndex < section.numberOfObjects else {
            
            return nil
        }
        return self[IndexPath(indexes: [sectionIndex, itemIndex])]
    }
    
    /**
     Returns the object at the given `IndexPath`. This subscript indexer is typically used for `ListMonitor`s created with `monitorSectionedList(_:)`.
     
     - parameter indexPath: the `IndexPath` for the object. Using an `indexPath` with an invalid range will raise an exception.
     - returns: the `DynamicObject` at the specified index path
     */
    public subscript(indexPath: IndexPath) -> O {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        return O.cs_fromRaw(object: self.fetchedResultsController.object(at: indexPath))
    }
    
    /**
     Returns the object at the given `IndexPath`, or `nil` if out of bounds. This subscript indexer is typically used for `ListMonitor`s created with `monitorSectionedList(_:)`.
     
     - parameter indexPath: the `IndexPath` for the object. Using an `indexPath` with an invalid range will return `nil`.
     - returns: the `DynamicObject` at the specified index path, or `nil` if out of bounds
     */
    public subscript(safeIndexPath indexPath: IndexPath) -> O? {
        
        return self[
            safeSectionIndex: indexPath[0],
            safeItemIndex: indexPath[1]
        ]
    }
    
    /**
     Checks if the `ListMonitor` has at least one section
     
     - returns: `true` if at least one section exists, `false` otherwise
     */
    public func hasSections() -> Bool {
        
        return self.sections().count > 0
    }
    
    /**
     Checks if the `ListMonitor` has at least one object in any section.
     
     - returns: `true` if at least one object in any section exists, `false` otherwise
     */
    public func hasObjects() -> Bool {
        
        return self.numberOfObjects() > 0
    }
    
    /**
     Checks if the `ListMonitor` has at least one object the specified section.
     
     - parameter section: the section index. Using an index outside the valid range will return `false`.
     - returns: `true` if at least one object in the specified section exists, `false` otherwise
     */
    public func hasObjects(in section: Int) -> Bool {
        
        return self.numberOfObjects(safelyIn: section)! > 0
    }
    
    /**
     Returns the number of sections
     
     - returns: the number of sections
     */
    public func numberOfSections() -> Int {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    /**
     Returns the number of objects in all sections
     
     - returns: the number of objects in all sections
     */
    public func numberOfObjects() -> Int {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        return (self.fetchedResultsController.fetchedObjects as NSArray?)?.count ?? 0
    }
    
    /**
     Returns the number of objects in the specified section
     
     - parameter section: the section index. Using an index outside the valid range will raise an exception.
     - returns: the number of objects in the specified section
     */
    public func numberOfObjects(in section: Int) -> Int {
        
        return self.sectionInfo(at: section).numberOfObjects
    }
    
    /**
     Returns the number of objects in the specified section, or `nil` if out of bounds.
     
     - parameter section: the section index. Using an index outside the valid range will return `nil`.
     - returns: the number of objects in the specified section
     */
    public func numberOfObjects(safelyIn section: Int) -> Int? {
        
        return self.sectionInfo(safelyAt: section)?.numberOfObjects
    }
    
    /**
     Returns the `NSFetchedResultsSectionInfo` for the specified section
     
     - parameter section: the section index. Using an index outside the valid range will raise an exception.
     - returns: the `NSFetchedResultsSectionInfo` for the specified section
     */
    public func sectionInfo(at section: Int) -> NSFetchedResultsSectionInfo {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        return self.fetchedResultsController.sections![section]
    }
    
    /**
     Returns the `NSFetchedResultsSectionInfo` for the specified section, or `nil` if out of bounds.
     
     - parameter section: the section index. Using an index outside the valid range will return `nil`.
     - returns: the `NSFetchedResultsSectionInfo` for the specified section, or `nil` if the section index is out of bounds.
     */
    public func sectionInfo(safelyAt section: Int) -> NSFetchedResultsSectionInfo? {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        guard section >= 0 else {
            
            return nil
        }
        guard let sections = self.fetchedResultsController.sections, section < sections.count else {
            
            return nil
        }
        return sections[section]
    }
    
    /**
     Returns the `NSFetchedResultsSectionInfo`s for all sections
     
     - returns: the `NSFetchedResultsSectionInfo`s for all sections
     */
    public func sections() -> [NSFetchedResultsSectionInfo] {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        return self.fetchedResultsController.sections ?? []
    }
    
    /**
     Returns the target section for a specified "Section Index" title and index.
     
     - parameter sectionIndexTitle: the title of the Section Index
     - parameter sectionIndex: the index of the Section Index
     - returns: the target section for the specified "Section Index" title and index.
     */
    public func targetSection(forSectionIndexTitle sectionIndexTitle: String, at sectionIndex: Int) -> Int {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        return self.fetchedResultsController.section(forSectionIndexTitle: sectionIndexTitle, at: sectionIndex)
    }
    
    /**
     Returns the section index titles for all sections
     
     - returns: the section index titles for all sections
     */
    public func sectionIndexTitles() -> [String] {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        return self.fetchedResultsController.sectionIndexTitles
    }
    
    /**
     Returns the index of the `DynamicObject` if it exists in the `ListMonitor`'s fetched objects, or `nil` if not found.
     
     - parameter object: the `DynamicObject` to search the index of
     - returns: the index of the `DynamicObject` if it exists in the `ListMonitor`'s fetched objects, or `nil` if not found.
     */
    public func index(of object: O) -> Int? {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        if self.isSectioned {
            
            return (self.fetchedResultsController.fetchedObjects as NSArray?)?.index(of: object.cs_toRaw())
        }
        return self.fetchedResultsController.indexPath(forObject: object.cs_toRaw())?[1]
    }
    
    /**
     Returns the `IndexPath` of the `DynamicObject` if it exists in the `ListMonitor`'s fetched objects, or `nil` if not found.
     
     - parameter object: the `DynamicObject` to search the index of
     - returns: the `IndexPath` of the `DynamicObject` if it exists in the `ListMonitor`'s fetched objects, or `nil` if not found.
     */
    public func indexPath(of object: O) -> IndexPath? {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        return self.fetchedResultsController.indexPath(forObject: object.cs_toRaw())
    }
    
    
    // MARK: Public (Observers)
    
    /**
     Registers a `ListObserver` to be notified when changes to the receiver's list occur.
     
     To prevent retain-cycles, `ListMonitor` only keeps `weak` references to its observers.
     
     For thread safety, this method needs to be called from the main thread. An assertion failure will occur (on debug builds only) if called from any thread other than the main thread.
     
     Calling `addObserver(_:)` multiple times on the same observer is safe, as `ListMonitor` unregisters previous notifications to the observer before re-registering them.
     
     - parameter observer: a `ListObserver` to send change notifications to
     */
    public func addObserver<U: ListObserver>(_ observer: U) where U.ListEntityType == O {
        
        self.unregisterObserver(observer)
        self.registerObserver(
            observer,
            willChange: { (observer, monitor) in
                
                observer.listMonitorWillChange(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didChange: { (observer, monitor) in
                
                observer.listMonitorDidChange(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            willRefetch: { (observer, monitor) in
                
                observer.listMonitorWillRefetch(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didRefetch: { (observer, monitor) in
                
                observer.listMonitorDidRefetch(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            }
        )
    }
    
    /**
     Registers a `ListObjectObserver` to be notified when changes to the receiver's list occur.
     
     To prevent retain-cycles, `ListMonitor` only keeps `weak` references to its observers.
     
     For thread safety, this method needs to be called from the main thread. An assertion failure will occur (on debug builds only) if called from any thread other than the main thread.
     
     Calling `addObserver(_:)` multiple times on the same observer is safe, as `ListMonitor` unregisters previous notifications to the observer before re-registering them.
     
     - parameter observer: a `ListObjectObserver` to send change notifications to
     */
    public func addObserver<U: ListObjectObserver>(_ observer: U) where U.ListEntityType == O {
        
        self.unregisterObserver(observer)
        self.registerObserver(
            observer,
            willChange: { (observer, monitor) in
                
                observer.listMonitorWillChange(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didChange: { (observer, monitor) in
                
                observer.listMonitorDidChange(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            willRefetch: { (observer, monitor) in
                
                observer.listMonitorWillRefetch(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didRefetch: { (observer, monitor) in
                
                observer.listMonitorDidRefetch(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            }
        )
        self.registerObserver(
            observer,
            didInsertObject: { (observer, monitor, object, toIndexPath) in
                
                observer.listMonitor(
                    monitor,
                    didInsertObject: object,
                    toIndexPath: toIndexPath,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didDeleteObject: { (observer, monitor, object, fromIndexPath) in
                
                observer.listMonitor(
                    monitor,
                    didDeleteObject: object,
                    fromIndexPath: fromIndexPath,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didUpdateObject: { (observer, monitor, object, atIndexPath) in
                
                observer.listMonitor(
                    monitor,
                    didUpdateObject: object,
                    atIndexPath: atIndexPath,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didMoveObject: { (observer, monitor, object, fromIndexPath, toIndexPath) in
                
                observer.listMonitor(
                    monitor,
                    didMoveObject: object,
                    fromIndexPath: fromIndexPath,
                    toIndexPath: toIndexPath,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            }
        )
    }
    
    /**
     Registers a `ListSectionObserver` to be notified when changes to the receiver's list occur.
     
     To prevent retain-cycles, `ListMonitor` only keeps `weak` references to its observers.
     
     For thread safety, this method needs to be called from the main thread. An assertion failure will occur (on debug builds only) if called from any thread other than the main thread.
     
     Calling `addObserver(_:)` multiple times on the same observer is safe, as `ListMonitor` unregisters previous notifications to the observer before re-registering them.
     
     - parameter observer: a `ListSectionObserver` to send change notifications to
     */
    public func addObserver<U: ListSectionObserver>(_ observer: U) where U.ListEntityType == O {
        
        self.unregisterObserver(observer)
        self.registerObserver(
            observer,
            willChange: { (observer, monitor) in
                
                observer.listMonitorWillChange(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didChange: { (observer, monitor) in
                
                observer.listMonitorDidChange(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            willRefetch: { (observer, monitor) in
                
                observer.listMonitorWillRefetch(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didRefetch: { (observer, monitor) in
                
                observer.listMonitorDidRefetch(
                    monitor,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            }
        )
        self.registerObserver(
            observer,
            didInsertObject: { (observer, monitor, object, toIndexPath) in
                
                observer.listMonitor(
                    monitor,
                    didInsertObject: object,
                    toIndexPath: toIndexPath,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didDeleteObject: { (observer, monitor, object, fromIndexPath) in
                
                observer.listMonitor(
                    monitor,
                    didDeleteObject: object,
                    fromIndexPath: fromIndexPath,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didUpdateObject: { (observer, monitor, object, atIndexPath) in
                
                observer.listMonitor(
                    monitor,
                    didUpdateObject: object,
                    atIndexPath: atIndexPath,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didMoveObject: { (observer, monitor, object, fromIndexPath, toIndexPath) in
                
                observer.listMonitor(
                    monitor,
                    didMoveObject: object,
                    fromIndexPath: fromIndexPath,
                    toIndexPath: toIndexPath,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            }
        )
        self.registerObserver(
            observer,
            didInsertSection: { (observer, monitor, sectionInfo, toIndex) in
                
                observer.listMonitor(
                    monitor,
                    didInsertSection: sectionInfo,
                    toSectionIndex: toIndex,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            },
            didDeleteSection: { (observer, monitor, sectionInfo, fromIndex) in
                
                observer.listMonitor(
                    monitor,
                    didDeleteSection: sectionInfo,
                    fromSectionIndex: fromIndex,
                    sourceIdentifier: monitor.fetchedResultsController.managedObjectContext.saveMetadata?.sourceIdentifier
                )
            }
        )
    }
    
    /**
     Unregisters a `ListObserver` from receiving notifications for changes to the receiver's list.
     
     For thread safety, this method needs to be called from the main thread. An assertion failure will occur (on debug builds only) if called from any thread other than the main thread.
     
     - parameter observer: a `ListObserver` to unregister notifications to
     */
    public func removeObserver<U: ListObserver>(_ observer: U) where U.ListEntityType == O {
        
        self.unregisterObserver(observer)
    }
    
    
    // MARK: Public (Refetching)
    
    /**
     Returns `true` if a call to `refetch(...)` was made to the `ListMonitor` and is currently waiting for the fetching to complete. Returns `false` otherwise.
     */
    public private(set) var isPendingRefetch = false
    
    /**
     Asks the `ListMonitor` to refetch its objects using the specified series of `FetchClause`s. Note that this method does not execute the fetch immediately; the actual fetching will happen after the `NSFetchedResultsController`'s last `controllerDidChangeContent(_:)` notification completes.
     
     `refetch(...)` broadcasts `listMonitorWillRefetch(...)` to its observers immediately, and then `listMonitorDidRefetch(...)` after the new fetch request completes.
     
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - parameter sourceIdentifier: an optional value that identifies the source of this transaction. This identifier will be passed to the change notifications and callers can use it for custom handling that depends on the source.
     - Important: Starting CoreStore 4.0, all `FetchClause`s required by the `ListMonitor` should be provided in the arguments list of `refetch(...)`.
     */
    public func refetch(
        _ fetchClauses: FetchClause...,
        sourceIdentifier: Any? = nil
    ) {
        
        self.refetch(
            fetchClauses,
            sourceIdentifier: sourceIdentifier
        )
    }
    
    /**
     Asks the `ListMonitor` to refetch its objects using the specified series of `FetchClause`s. Note that this method does not execute the fetch immediately; the actual fetching will happen after the `NSFetchedResultsController`'s last `controllerDidChangeContent(_:)` notification completes.
     
     `refetch(...)` broadcasts `listMonitorWillRefetch(...)` to its observers immediately, and then `listMonitorDidRefetch(...)` after the new fetch request completes.
     
     - parameter fetchClauses: a series of `FetchClause` instances for fetching the object list. Accepts `Where`, `OrderBy`, and `Tweak` clauses.
     - parameter sourceIdentifier: an optional value that identifies the source of this transaction. This identifier will be passed to the change notifications and callers can use it for custom handling that depends on the source.
     - Important: Starting CoreStore 4.0, all `FetchClause`s required by the `ListMonitor` should be provided in the arguments list of `refetch(...)`.
     */
    public func refetch(
        _ fetchClauses: [FetchClause],
        sourceIdentifier: Any? = nil
    ) {
        
        self.refetch(
            { (fetchRequest) in
                
                fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }
            },
            sourceIdentifier: sourceIdentifier
        )
    }
    
    
    // MARK: Public (3rd Party Utilities)
    
    /**
     Allow external libraries to store custom data in the `ListMonitor`. App code should rarely have a need for this.
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
    
    public static func == (lhs: ListMonitor<O>, rhs: ListMonitor<O>) -> Bool {
        
        return lhs.fetchedResultsController === rhs.fetchedResultsController
    }
    
    public static func == <T, U>(lhs: ListMonitor<T>, rhs: ListMonitor<U>) -> Bool {
        
        return lhs.fetchedResultsController === rhs.fetchedResultsController
    }
    
    public static func ~= (lhs: ListMonitor<O>, rhs: ListMonitor<O>) -> Bool {
        
        return lhs.fetchedResultsController === rhs.fetchedResultsController
    }
    
    public static func ~= <T, U>(lhs: ListMonitor<T>, rhs: ListMonitor<U>) -> Bool {
        
        return lhs.fetchedResultsController === rhs.fetchedResultsController
    }
    
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(ObjectIdentifier(self))
    }
    
    
    // MARK: Internal
    
    internal convenience init(
        dataStack: DataStack,
        from: From<O>,
        sectionBy: SectionBy<O>?,
        applyFetchClauses: @escaping (_ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void
    ) {
        
        self.init(
            context: dataStack.mainContext,
            transactionQueue: dataStack.childTransactionQueue,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses,
            createAsynchronously: nil
        )
    }
    
    internal convenience init(
        dataStack: DataStack,
        from: From<O>,
        sectionBy: SectionBy<O>?,
        applyFetchClauses: @escaping (_ fetchRequest:  Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void,
        createAsynchronously: @escaping (ListMonitor<O>) -> Void
    ) {
        
        self.init(
            context: dataStack.mainContext,
            transactionQueue: dataStack.childTransactionQueue,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses,
            createAsynchronously: createAsynchronously
        )
    }
    
    internal convenience init(
        unsafeTransaction: UnsafeDataTransaction,
        from: From<O>,
        sectionBy: SectionBy<O>?,
        applyFetchClauses: @escaping (_ fetchRequest:  Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void
    ) {
        
        self.init(
            context: unsafeTransaction.context,
            transactionQueue: unsafeTransaction.transactionQueue,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses,
            createAsynchronously: nil
        )
    }
    
    internal convenience init(
        unsafeTransaction: UnsafeDataTransaction,
        from: From<O>,
        sectionBy: SectionBy<O>?,
        applyFetchClauses: @escaping (_ fetchRequest:  Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void,
        createAsynchronously: @escaping (ListMonitor<O>) -> Void
    ) {
        
        self.init(
            context: unsafeTransaction.context,
            transactionQueue: unsafeTransaction.transactionQueue,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses,
            createAsynchronously: createAsynchronously
        )
    }
    
    internal func registerChangeNotification(
        _ notificationKey: UnsafeRawPointer,
        name: Notification.Name,
        toObserver observer: AnyObject,
        callback: @escaping (_ monitor: ListMonitor<O>) -> Void
    ) {
        
        Internals.setAssociatedRetainedObject(
            Internals.NotificationObserver(
                notificationName: name,
                object: self,
                closure: { [weak self] (note) -> Void in
                    
                    guard let self = self else {
                        
                        return
                    }
                    callback(self)
                }
            ),
            forKey: notificationKey,
            inObject: observer
        )
    }
    
    internal func registerObjectNotification(
        _ notificationKey: UnsafeRawPointer,
        name: Notification.Name,
        toObserver observer: AnyObject,
        callback: @escaping (
            _ monitor: ListMonitor<O>,
            _ object: O,
            _ indexPath: IndexPath?,
            _ newIndexPath: IndexPath?
        ) -> Void) {
        
        Internals.setAssociatedRetainedObject(
            Internals.NotificationObserver(
                notificationName: name,
                object: self,
                closure: { [weak self] (note) -> Void in
                    
                    guard let self = self,
                        let userInfo = note.userInfo,
                        let rawObject = userInfo[String(describing: NSManagedObject.self)] as? NSManagedObject else {
                            
                            return
                    }
                    callback(
                        self,
                        O.cs_fromRaw(object: rawObject),
                        userInfo[String(describing: IndexPath.self)] as? IndexPath,
                        userInfo["\(String(describing: IndexPath.self)).New"] as? IndexPath
                    )
                }
            ),
            forKey: notificationKey,
            inObject: observer
        )
    }
    
    internal func registerSectionNotification(
        _ notificationKey: UnsafeRawPointer,
        name: Notification.Name,
        toObserver observer: AnyObject,
        callback: @escaping (
            _ monitor: ListMonitor<O>,
            _ sectionInfo: NSFetchedResultsSectionInfo,
            _ sectionIndex: Int
        ) -> Void
    ) {
        
        Internals.setAssociatedRetainedObject(
            Internals.NotificationObserver(
                notificationName: name,
                object: self,
                closure: { [weak self] (note) -> Void in
                    
                    guard let self = self,
                        let userInfo = note.userInfo,
                        let sectionInfo = userInfo[String(describing: NSFetchedResultsSectionInfo.self)] as? NSFetchedResultsSectionInfo,
                        let sectionIndex = (userInfo[String(describing: NSNumber.self)] as? NSNumber)?.intValue else {
                            
                            return
                    }
                    callback(self, sectionInfo, sectionIndex)
                }
            ),
            forKey: notificationKey,
            inObject: observer
        )
    }
    
    internal func registerObserver<U: AnyObject>(
        _ observer: U,
        willChange: @escaping (
            _ observer: U,
            _ monitor: ListMonitor<O>
        ) -> Void,
        didChange: @escaping (
            _ observer: U,
            _ monitor: ListMonitor<O>
        ) -> Void,
        willRefetch: @escaping (
            _ observer: U,
            _ monitor: ListMonitor<O>
        ) -> Void,
        didRefetch: @escaping (
            _ observer: U,
            _ monitor: ListMonitor<O>
        ) -> Void) {
        
        Internals.assert(
            Thread.isMainThread,
            "Attempted to add an observer of type \(Internals.typeName(observer)) outside the main thread."
        )
        self.registerChangeNotification(
            &self.willChangeListKey,
            name: Notification.Name.listMonitorWillChangeList,
            toObserver: observer,
            callback: { [weak observer] (monitor) -> Void in
                
                guard let observer = observer else {
                    
                    return
                }
                willChange(observer, monitor)
            }
        )
        self.registerChangeNotification(
            &self.didChangeListKey,
            name: Notification.Name.listMonitorDidChangeList,
            toObserver: observer,
            callback: { [weak observer] (monitor) -> Void in
                
                guard let observer = observer else {
                    
                    return
                }
                didChange(observer, monitor)
            }
        )
        self.registerChangeNotification(
            &self.willRefetchListKey,
            name: Notification.Name.listMonitorWillRefetchList,
            toObserver: observer,
            callback: { [weak observer] (monitor) -> Void in
                
                guard let observer = observer else {
                    
                    return
                }
                willRefetch(observer, monitor)
            }
        )
        self.registerChangeNotification(
            &self.didRefetchListKey,
            name: Notification.Name.listMonitorDidRefetchList,
            toObserver: observer,
            callback: { [weak observer] (monitor) -> Void in
                
                guard let observer = observer else {
                    
                    return
                }
                didRefetch(observer, monitor)
            }
        )
    }
    
    internal func registerObserver<U: AnyObject>(
        _ observer: U,
        didInsertObject: @escaping (
            _ observer: U,
            _ monitor: ListMonitor<O>,
            _ object: O, 
            _ toIndexPath: IndexPath
        ) -> Void,
        didDeleteObject: @escaping (
            _ observer: U,
            _ monitor: ListMonitor<O>,
            _ object: O,
            _ fromIndexPath: IndexPath
        ) -> Void,
        didUpdateObject: @escaping (
            _ observer: U,
            _ monitor: ListMonitor<O>,
            _ object: O,
            _ atIndexPath: IndexPath
        ) -> Void,
        didMoveObject: @escaping (
            _ observer: U,
            _ monitor: ListMonitor<O>,
            _ object: O,
            _ fromIndexPath: IndexPath,
            _ toIndexPath: IndexPath
        ) -> Void) {
        
        Internals.assert(
            Thread.isMainThread,
            "Attempted to add an observer of type \(Internals.typeName(observer)) outside the main thread."
        )
        
        self.registerObjectNotification(
            &self.didInsertObjectKey,
            name: Notification.Name.listMonitorDidInsertObject,
            toObserver: observer,
            callback: { [weak observer] (monitor, object, indexPath, newIndexPath) -> Void in
                
                guard let observer = observer else {
                    
                    return
                }
                didInsertObject(observer, monitor, object, newIndexPath!)
            }
        )
        self.registerObjectNotification(
            &self.didDeleteObjectKey,
            name: Notification.Name.listMonitorDidDeleteObject,
            toObserver: observer,
            callback: { [weak observer] (monitor, object, indexPath, newIndexPath) -> Void in
                
                guard let observer = observer else {
                    
                    return
                }
                didDeleteObject(observer, monitor, object, indexPath!)
            }
        )
        self.registerObjectNotification(
            &self.didUpdateObjectKey,
            name: Notification.Name.listMonitorDidUpdateObject,
            toObserver: observer,
            callback: { [weak observer] (monitor, object, indexPath, newIndexPath) -> Void in
                
                guard let observer = observer else {
                    
                    return
                }
                didUpdateObject(observer, monitor, object, indexPath!)
            }
        )
        self.registerObjectNotification(
            &self.didMoveObjectKey,
            name: Notification.Name.listMonitorDidMoveObject,
            toObserver: observer,
            callback: { [weak observer] (monitor, object, indexPath, newIndexPath) -> Void in
                
                guard let observer = observer else {
                    
                    return
                }
                didMoveObject(observer, monitor, object, indexPath!, newIndexPath!)
            }
        )
    }
    
    internal func registerObserver<U: AnyObject>(
        _ observer: U,
        didInsertSection: @escaping (
            _ observer: U,
            _ monitor: ListMonitor<O>,
            _ sectionInfo: NSFetchedResultsSectionInfo,
            _ toIndex: Int
        ) -> Void,
        didDeleteSection: @escaping (
            _ observer: U,
            _ monitor: ListMonitor<O>,
            _ sectionInfo: NSFetchedResultsSectionInfo,
            _ fromIndex: Int
        ) -> Void) {
        
        Internals.assert(
            Thread.isMainThread,
            "Attempted to add an observer of type \(Internals.typeName(observer)) outside the main thread."
        )
        
        self.registerSectionNotification(
            &self.didInsertSectionKey,
            name: Notification.Name.listMonitorDidInsertSection,
            toObserver: observer,
            callback: { [weak observer] (monitor, sectionInfo, sectionIndex) -> Void in
                
                guard let observer = observer else {
                    
                    return
                }
                didInsertSection(observer, monitor, sectionInfo, sectionIndex)
            }
        )
        self.registerSectionNotification(
            &self.didDeleteSectionKey,
            name: Notification.Name.listMonitorDidDeleteSection,
            toObserver: observer,
            callback: { [weak observer] (monitor, sectionInfo, sectionIndex) -> Void in
                
                guard let observer = observer else {
                    
                    return
                }
                didDeleteSection(observer, monitor, sectionInfo, sectionIndex)
            }
        )
    }
    
    internal func unregisterObserver(_ observer: AnyObject) {
        
        Internals.assert(
            Thread.isMainThread,
            "Attempted to remove an observer of type \(Internals.typeName(observer)) outside the main thread."
        )
        let nilValue: AnyObject? = nil
        Internals.setAssociatedRetainedObject(nilValue, forKey: &self.willChangeListKey, inObject: observer)
        Internals.setAssociatedRetainedObject(nilValue, forKey: &self.didChangeListKey, inObject: observer)
        Internals.setAssociatedRetainedObject(nilValue, forKey: &self.willRefetchListKey, inObject: observer)
        Internals.setAssociatedRetainedObject(nilValue, forKey: &self.didRefetchListKey, inObject: observer)
        
        Internals.setAssociatedRetainedObject(nilValue, forKey: &self.didInsertObjectKey, inObject: observer)
        Internals.setAssociatedRetainedObject(nilValue, forKey: &self.didDeleteObjectKey, inObject: observer)
        Internals.setAssociatedRetainedObject(nilValue, forKey: &self.didUpdateObjectKey, inObject: observer)
        Internals.setAssociatedRetainedObject(nilValue, forKey: &self.didMoveObjectKey, inObject: observer)
        
        Internals.setAssociatedRetainedObject(nilValue, forKey: &self.didInsertSectionKey, inObject: observer)
        Internals.setAssociatedRetainedObject(nilValue, forKey: &self.didDeleteSectionKey, inObject: observer)
    }
    
    internal func refetch(
        _ applyFetchClauses: @escaping (_ fetchRequest:  Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void,
        sourceIdentifier: Any?
    ) {
        
        Internals.assert(
            Thread.isMainThread,
            "Attempted to refetch a \(Internals.typeName(self)) outside the main thread."
        )
        
        if !self.isPendingRefetch {
            
            self.isPendingRefetch = true
            
            NotificationCenter.default.post(
                name: Notification.Name.listMonitorWillRefetchList,
                object: self
            )
        }
        self.applyFetchClauses = applyFetchClauses
        
        self.taskGroup.notify(queue: .main) { [weak self] () -> Void in
            
            guard let self = self else {
                
                return
            }
            
            let (newFetchedResultsController, newFetchedResultsControllerDelegate) = Self.recreateFetchedResultsController(
                context: self.fetchedResultsController.managedObjectContext,
                from: self.from,
                sectionBy: self.sectionBy,
                applyFetchClauses: self.applyFetchClauses
            )
            newFetchedResultsControllerDelegate.enabled = false
            newFetchedResultsControllerDelegate.handler = self
            
            self.transactionQueue.async { [weak self] in
                
                guard let self = self else {
                    
                    return
                }
                do {

                    try newFetchedResultsController.performFetchFromSpecifiedStores()
                }
                catch {

                    // DataStack may have been deallocated
                    return
                }
                self.fetchedResultsControllerDelegate.taskGroup.notify(queue: .main) {
                    
                    self.fetchedResultsControllerDelegate.enabled = false
                }
                newFetchedResultsControllerDelegate.taskGroup.notify(queue: .main) { [weak self] () -> Void in
                    
                    guard let self = self else {
                        
                        return
                    }
                    
                    (self.fetchedResultsController, self.fetchedResultsControllerDelegate) = (newFetchedResultsController, newFetchedResultsControllerDelegate)
                    newFetchedResultsControllerDelegate.enabled = true
                    
                    self.isPendingRefetch = false
                    
                    newFetchedResultsController.managedObjectContext.saveMetadata = .init(
                        isSavingSynchronously: false,
                        sourceIdentifier: sourceIdentifier
                    )
                    NotificationCenter.default.post(
                        name: Notification.Name.listMonitorDidRefetchList,
                        object: self
                    )
                    newFetchedResultsController.managedObjectContext.saveMetadata = nil
                }
            }
        }
    }
    
    deinit {
        
        self.fetchedResultsControllerDelegate.fetchedResultsController = nil
        self.isPersistentStoreChanging = false
    }
    
    
    // MARK: Private
    
    fileprivate var fetchedResultsController: Internals.CoreStoreFetchedResultsController
    fileprivate let taskGroup = DispatchGroup()
    internal let sectionByIndexTransformer: (_ sectionName: KeyPathString?) -> String?
    
    private let isSectioned: Bool
    
    private var willChangeListKey: Void?
    private var didChangeListKey: Void?
    private var willRefetchListKey: Void?
    private var didRefetchListKey: Void?
    
    private var didInsertObjectKey: Void?
    private var didDeleteObjectKey: Void?
    private var didUpdateObjectKey: Void?
    private var didMoveObjectKey: Void?
    
    private var didInsertSectionKey: Void?
    private var didDeleteSectionKey: Void?
    
    private var fetchedResultsControllerDelegate: Internals.FetchedResultsControllerDelegate
    private var observerForWillChangePersistentStore: Internals.NotificationObserver!
    private var observerForDidChangePersistentStore: Internals.NotificationObserver!
    private let transactionQueue: DispatchQueue
    private var applyFetchClauses: (_ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void
    
    private var isPersistentStoreChanging: Bool = false {
        
        didSet {
            
            let newValue = self.isPersistentStoreChanging
            guard newValue != oldValue else {
                
                return
            }
            
            if newValue {
                
                self.taskGroup.enter()
            }
            else {
                
                self.taskGroup.leave()
            }
        }
    }
    
    private static func recreateFetchedResultsController(
        context: NSManagedObjectContext,
        from: From<O>,
        sectionBy: SectionBy<O>?,
        applyFetchClauses: @escaping (_ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void
    ) -> (
        controller: Internals.CoreStoreFetchedResultsController,
        delegate: Internals.FetchedResultsControllerDelegate
    ) {
        
        let fetchRequest = Internals.CoreStoreFetchRequest<NSManagedObject>()
        fetchRequest.fetchLimit = 0
        fetchRequest.resultType = .managedObjectResultType
        fetchRequest.fetchBatchSize = 20
        fetchRequest.includesPendingChanges = false
        fetchRequest.shouldRefreshRefetchedObjects = true
        
        let fetchedResultsController = Internals.CoreStoreFetchedResultsController(
            context: context,
            fetchRequest: fetchRequest,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses
        )
        
        let fetchedResultsControllerDelegate = Internals.FetchedResultsControllerDelegate()
        fetchedResultsControllerDelegate.fetchedResultsController = fetchedResultsController
        
        return (fetchedResultsController, fetchedResultsControllerDelegate)
    }
    
    private let from: From<O>
    private let sectionBy: SectionBy<O>?
    
    private init(
        context: NSManagedObjectContext,
        transactionQueue: DispatchQueue,
        from: From<O>,
        sectionBy: SectionBy<O>?,
        applyFetchClauses: @escaping (_ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void,
        createAsynchronously: ((ListMonitor<O>) -> Void)?
    ) {
        
        self.isSectioned = (sectionBy != nil)
        self.from = from
        self.sectionBy = sectionBy
        (self.fetchedResultsController, self.fetchedResultsControllerDelegate) = Self.recreateFetchedResultsController(
            context: context,
            from: from,
            sectionBy: sectionBy,
            applyFetchClauses: applyFetchClauses
        )
        
        if let sectionIndexTransformer = sectionBy?.sectionIndexTransformer {
            
            self.sectionByIndexTransformer = sectionIndexTransformer
        }
        else {
            
            self.sectionByIndexTransformer = { _ in nil }
        }
        self.transactionQueue = transactionQueue
        self.applyFetchClauses = applyFetchClauses
        self.fetchedResultsControllerDelegate.handler = self
        
        guard let coordinator = context.parentStack?.coordinator else {
            
            return
        }
        
        self.observerForWillChangePersistentStore = Internals.NotificationObserver(
            notificationName: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange,
            object: coordinator,
            queue: OperationQueue.main,
            closure: { [weak self] (note) -> Void in
                
                guard let self = self else {
                    
                    return
                }
                
                self.isPersistentStoreChanging = true
                
                guard let removedStores = (note.userInfo?[NSRemovedPersistentStoresKey] as? [NSPersistentStore]).flatMap(Set.init),
                    !Set(self.fetchedResultsController.typedFetchRequest.safeAffectedStores() ?? []).intersection(removedStores).isEmpty else {
                        
                        return
                }
                self.refetch(self.applyFetchClauses, sourceIdentifier: nil)
            }
        )
        
        self.observerForDidChangePersistentStore = Internals.NotificationObserver(
            notificationName: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange,
            object: coordinator,
            queue: OperationQueue.main,
            closure: { [weak self] (note) -> Void in
                
                guard let self = self else {
                    
                    return
                }
                
                if !self.isPendingRefetch {
                    
                    let previousStores = Set(self.fetchedResultsController.typedFetchRequest.safeAffectedStores() ?? [])
                    let currentStores = previousStores
                        .subtracting(note.userInfo?[NSRemovedPersistentStoresKey] as? [NSPersistentStore] ?? [])
                        .union(note.userInfo?[NSAddedPersistentStoresKey] as? [NSPersistentStore] ?? [])
                    
                    if previousStores != currentStores {
                        
                        self.refetch(self.applyFetchClauses, sourceIdentifier: nil)
                    }
                }
                
                self.isPersistentStoreChanging = false
            }
        )
        
        if let createAsynchronously = createAsynchronously {
            
            transactionQueue.async {
                
                try! self.fetchedResultsController.performFetchFromSpecifiedStores()
                self.taskGroup.notify(queue: .main) {
                    
                    createAsynchronously(self)
                }
            }
        }
        else {
            
            try! self.fetchedResultsController.performFetchFromSpecifiedStores()
        }
    }
}

    
// MARK: - ListMonitor where O: NSManagedObject

extension ListMonitor where O: NSManagedObject {
    
    /**
     Returns all objects in all sections
     
     - returns: all objects in all sections
     */
    public func objectsInAllSections() -> [O] {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        return (self.fetchedResultsController.dynamicCast() as NSFetchedResultsController<O>).fetchedObjects ?? []
    }
    
    /**
     Returns all objects in the specified section
     
     - parameter section: the section index. Using an index outside the valid range will raise an exception.
     - returns: all objects in the specified section
     */
    public func objects(in section: Int) -> [O] {
        
        return (self.sectionInfo(at: section).objects as! [O]?) ?? []
    }
    
    /**
     Returns all objects in the specified section, or `nil` if out of bounds.
     
     - parameter section: the section index. Using an index outside the valid range will return `nil`.
     - returns: all objects in the specified section
     */
    public func objects(safelyIn section: Int) -> [O]? {
        
        return self.sectionInfo(safelyAt: section)?.objects as! [O]?
    }
}


// MARK: - ListMonitor where O: CoreStoreObject

extension ListMonitor where O: CoreStoreObject {
    
    /**
     Returns all objects in all sections
     
     - returns: all objects in all sections
     */
    public func objectsInAllSections() -> [O] {
        
        Internals.assert(
            !self.isPendingRefetch || Thread.isMainThread,
            "Attempted to access a \(Internals.typeName(self)) outside the main thread while a refetch is in progress."
        )
        return (self.fetchedResultsController.fetchedObjects ?? [])
            .map(O.cs_fromRaw)
    }
    
    /**
     Returns all objects in the specified section
     
     - parameter section: the section index. Using an index outside the valid range will raise an exception.
     - returns: all objects in the specified section
     */
    public func objects(in section: Int) -> [O] {
        
        return (self.sectionInfo(at: section).objects ?? [])
            .map({ O.cs_fromRaw(object: $0 as! NSManagedObject) })
    }
    
    /**
     Returns all objects in the specified section, or `nil` if out of bounds.
     
     - parameter section: the section index. Using an index outside the valid range will return `nil`.
     - returns: all objects in the specified section
     */
    public func objects(safelyIn section: Int) -> [O]? {
        
        return (self.sectionInfo(safelyAt: section)?.objects)?
            .map({ O.cs_fromRaw(object: $0 as! NSManagedObject) })
    }
}


// MARK: - ListMonitor: FetchedResultsControllerHandler

extension ListMonitor: FetchedResultsControllerHandler {
    
    // MARK: FetchedResultsControllerHandler
    
    internal var sectionIndexTransformer: (_ sectionName: KeyPathString?) -> String? {
        
        return self.sectionByIndexTransformer
    }
    
    internal func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeObject anObject: Any,
        atIndexPath indexPath: IndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        
        switch type {
            
        case .insert:
            NotificationCenter.default.post(
                name: Notification.Name.listMonitorDidInsertObject,
                object: self,
                userInfo: [
                    String(describing: NSManagedObject.self): anObject,
                    "\(String(describing: IndexPath.self)).New": newIndexPath!
                ]
            )
            
        case .delete:
            NotificationCenter.default.post(
                name: Notification.Name.listMonitorDidDeleteObject,
                object: self,
                userInfo: [
                    String(describing: NSManagedObject.self): anObject,
                    String(describing: IndexPath.self): indexPath!
                ]
            )
            
        case .update:
            NotificationCenter.default.post(
                name: Notification.Name.listMonitorDidUpdateObject,
                object: self,
                userInfo: [
                    String(describing: NSManagedObject.self): anObject,
                    String(describing: IndexPath.self): indexPath!
                ]
            )
            
        case .move:
            NotificationCenter.default.post(
                name: Notification.Name.listMonitorDidMoveObject,
                object: self,
                userInfo: [
                    String(describing: NSManagedObject.self): anObject,
                    String(describing: IndexPath.self): indexPath!,
                    "\(String(describing: IndexPath.self)).New": newIndexPath!
                ]
            )
            
        @unknown default:
            fatalError()
        }
    }
    
    internal func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType
    ) {
        
        switch type {
            
        case .insert:
            NotificationCenter.default.post(
                name: Notification.Name.listMonitorDidInsertSection,
                object: self,
                userInfo: [
                    String(describing: NSFetchedResultsSectionInfo.self): sectionInfo,
                    String(describing: NSNumber.self): NSNumber(value: sectionIndex)
                ]
            )
            
        case .delete:
            NotificationCenter.default.post(
                name: Notification.Name.listMonitorDidDeleteSection,
                object: self,
                userInfo: [
                    String(describing: NSFetchedResultsSectionInfo.self): sectionInfo,
                    String(describing: NSNumber.self): NSNumber(value: sectionIndex)
                ]
            )
            
        default:
            break
        }
    }
    
    internal func controllerWillChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        
        self.taskGroup.enter()
        NotificationCenter.default.post(
            name: Notification.Name.listMonitorWillChangeList,
            object: self
        )
    }
    
   internal func controllerDidChangeContent(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>
   ) {
    
        defer {
            
            self.taskGroup.leave()
        }
        NotificationCenter.default.post(
            name: Notification.Name.listMonitorDidChangeList,
            object: self
        )
    }
}


// MARK: - Notification Keys

extension Notification.Name {
    
    fileprivate static let listMonitorWillChangeList = Notification.Name(rawValue: "listMonitorWillChangeList")
    fileprivate static let listMonitorDidChangeList = Notification.Name(rawValue: "listMonitorDidChangeList")
    fileprivate static let listMonitorWillRefetchList = Notification.Name(rawValue: "listMonitorWillRefetchList")
    fileprivate static let listMonitorDidRefetchList = Notification.Name(rawValue: "listMonitorDidRefetchList")
    fileprivate static let listMonitorDidInsertObject = Notification.Name(rawValue: "listMonitorDidInsertObject")
    fileprivate static let listMonitorDidDeleteObject = Notification.Name(rawValue: "listMonitorDidDeleteObject")
    fileprivate static let listMonitorDidUpdateObject = Notification.Name(rawValue: "listMonitorDidUpdateObject")
    fileprivate static let listMonitorDidMoveObject = Notification.Name(rawValue: "listMonitorDidMoveObject")
    fileprivate static let listMonitorDidInsertSection = Notification.Name(rawValue: "listMonitorDidInsertSection")
    fileprivate static let listMonitorDidDeleteSection = Notification.Name(rawValue: "listMonitorDidDeleteSection")
}
