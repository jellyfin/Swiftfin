//
//  ObjectPublisher.swift
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


// MARK: - ObjectPublisher

/**
 The `ObjectPublisher` tracks changes to a single `DynamicObject` instance. Objects that need to be notified of `ObjectPublisher` changes may register themselves to its `addObserver(_:_:)` method:
 ```
 let objectPublisher = CoreStoreDefaults.dataStack.objectPublisher(object)
 objectPublisher.addObserver(self) { (objectPublisher) in
     // Handle changes
 }
 ```
 The created `ObjectPublisher` instance needs to be held on (retained) for as long as the object needs to be observed.

 Observers registered via `addObserver(_:_:)` are not retained. `ObjectPublisher` only keeps a `weak` reference to all observers, thus keeping itself free from retain-cycles.

 The `ObjectPublisher`'s `snapshot` value is a lazy copy operation that extracts all property values at a specific point time. This cached copy is invalidated right before the `ObjectPublisher` broadcasts any changes to its observers.
 */
@dynamicMemberLookup
public final class ObjectPublisher<O: DynamicObject>: ObjectRepresentation, Hashable {

    // MARK: Public (Accessors)
    /**
     A snapshot of the latest state of this list. Returns `nil` if the object has been deleted.
     */
    public var snapshot: ObjectSnapshot<O>? {

        return self.lazySnapshot
    }

    /**
     The actual `DynamicObject` instance. Becomes `nil` if the object has been deleted.
     */
    public private(set) lazy var object: O? = self.context.fetchExisting(self.id)



    // MARK: Public (Observers)

    /**
     Registers an object as an observer to be notified when changes to the `ObjectPublisher`'s snapshot occur.

     To prevent retain-cycles, `ObjectPublisher` only keeps `weak` references to its observers.

     For thread safety, this method needs to be called from the main thread. An assertion failure will occur (on debug builds only) if called from any thread other than the main thread.

     Calling `addObserver(_:_:)` multiple times on the same observer is safe.

     - parameter observer: an object to become owner of the specified `callback`
     - parameter notifyInitial: if `true`, the callback is executed immediately with the current publisher state. Otherwise only succeeding updates will notify the observer. Default value is `false`.
     - parameter callback: the closure to execute when changes occur
     */
    public func addObserver<T: AnyObject>(
        _ observer: T,
        notifyInitial: Bool = false,
        _ callback: @escaping (ObjectPublisher<O>) -> Void
    ) {

        Internals.assert(
            Thread.isMainThread,
            "Attempted to add an observer of type \(Internals.typeName(observer)) outside the main thread."
        )
        self.observers.setObject(
            Internals.Closure({ callback($0.objectPublisher) }),
            forKey: observer
        )
        _ = self.lazySnapshot
        
        if notifyInitial {
            
            callback(self)
        }
    }
    
    /**
     Registers an object as an observer to be notified when changes to the `ObjectPublisher`'s snapshot occur.

     To prevent retain-cycles, `ObjectPublisher` only keeps `weak` references to its observers.

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
            _ objectPublisher: ObjectPublisher<O>,
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
        _ = self.lazySnapshot
        
        if notifyInitial {
            
            callback(self, initialSourceIdentifier)
        }
    }

    /**
     Unregisters an object from receiving notifications for changes to the `ObjectPublisher`'s snapshot.

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
    
    
    // MARK: AnyObjectRepresentation
    
    public func objectID() -> O.ObjectID {
        
        return self.id
    }
    
    public func cs_dataStack() -> DataStack? {
        
        return self.context.parentStack
    }
    
    
    // MARK: ObjectRepresentation

    public typealias ObjectType = O
    
    public func asPublisher(in dataStack: DataStack) -> ObjectPublisher<O> {
        
        let context = dataStack.unsafeContext()
        if self.context == context {
            
            return self
        }
        return context.objectPublisher(objectID: self.id)
    }

    public func asReadOnly(in dataStack: DataStack) -> O? {

        return dataStack.unsafeContext().fetchExisting(self.id)
    }
    
    public func asEditable(in transaction: BaseDataTransaction) -> O? {
        
        return transaction.unsafeContext().fetchExisting(self.id)
    }
    
    public func asSnapshot(in dataStack: DataStack) -> ObjectSnapshot<O>? {
        
        let context = dataStack.unsafeContext()
        if self.context == context {
            
            return self.lazySnapshot
        }
        return ObjectSnapshot<O>(objectID: self.id, context: context)
    }
    
    public func asSnapshot(in transaction: BaseDataTransaction) -> ObjectSnapshot<O>? {
        
        let context = transaction.unsafeContext()
        if self.context == context {
            
            return self.lazySnapshot
        }
        return ObjectSnapshot<O>(objectID: self.id, context: context)
    }


    // MARK: Equatable

    public static func == (_ lhs: ObjectPublisher, _ rhs: ObjectPublisher) -> Bool {

        return lhs.id == rhs.id
            && lhs.context == rhs.context
    }


    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(self.id)
        hasher.combine(self.context)
    }


    // MARK: Internal
    
    internal var cs_objectID: O.ObjectID {
        
        return self.objectID()
    }

    internal static func createUncached(objectID: O.ObjectID, context: NSManagedObjectContext) -> ObjectPublisher<O> {

        return self.init(
            objectID: objectID,
            context: context,
            initializer: ObjectSnapshot<O>.init(objectID:context:)
        )
    }

    deinit {

        self.context.objectsDidChangeObserver(remove: self)
        self.observers.removeAllObjects()
    }


    // MARK: FilePrivate
    
    fileprivate typealias ObserverClosureType = Internals.Closure<(objectPublisher: ObjectPublisher<O>, sourceIdentifier: Any?), Void>

    fileprivate init(objectID: O.ObjectID, context: NSManagedObjectContext, initializer: @escaping (NSManagedObjectID, NSManagedObjectContext) -> ObjectSnapshot<O>?) {

        self.id = objectID
        self.context = context
        self.$lazySnapshot.initialize { [weak self] in

            guard let self = self else {

                return initializer(objectID, context)
            }
            context.objectsDidChangeObserver(for: self).addObserver(self) { [weak self] (updatedIDs, deletedIDs) in

                guard let self = self else {

                    return
                }
                if deletedIDs.contains(objectID) {

                    self.object = nil

                    self.$lazySnapshot.reset({ nil })
                    self.notifyObservers(sourceIdentifier: self.context.saveMetadata)
                }
                else if updatedIDs.contains(objectID) {

                    self.$lazySnapshot.reset({ initializer(objectID, context) })
                    self.notifyObservers(sourceIdentifier: self.context.saveMetadata)
                }
            }
            return initializer(objectID, context)
        }
    }


    // MARK: Private
    
    private let id: O.ObjectID
    private let context: NSManagedObjectContext

    @Internals.LazyNonmutating(uninitialized: ())
    private var lazySnapshot: ObjectSnapshot<O>?
    
    private lazy var observers: NSMapTable<AnyObject, ObserverClosureType> = .weakToStrongObjects()

    private func notifyObservers(sourceIdentifier: Any?) {

        guard let enumerator = self.observers.objectEnumerator() else {

            return
        }
        let arguments: ObserverClosureType.Arguments = (
            objectPublisher: self,
            sourceIdentifier: sourceIdentifier
        )
        for closure in enumerator {

            (closure as! ObserverClosureType).invoke(with: arguments)
        }
    }
}


// MARK: - ObjectPublisher where O: NSManagedObject

extension ObjectPublisher where O: NSManagedObject {

    // MARK: Public

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<V: AllowedObjectiveCKeyPathValue>(dynamicMember member: KeyPath<O, V>) -> V! {

        return self.snapshot?[dynamicMember: member]
    }
}


// MARK: - ObjectPublisher where O: CoreStoreObject

extension ObjectPublisher where O: CoreStoreObject {

    // MARK: Public

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(dynamicMember member: KeyPath<O, FieldContainer<OBase>.Stored<V>>) -> V? {

        guard
            let object = self.object,
            let rawObject = object.rawObject
            else {

                return nil
        }
        Internals.assert(
            rawObject.isRunningInAllowedQueue() == true,
            "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
        )
        let field = object[keyPath: member]
        return type(of: field).read(field: field, for: rawObject) as! V?
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(dynamicMember member: KeyPath<O, FieldContainer<OBase>.Virtual<V>>) -> V? {

        guard
            let object = self.object,
            let rawObject = object.rawObject
            else {

                return nil
        }
        Internals.assert(
            rawObject.isRunningInAllowedQueue() == true,
            "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
        )
        let field = object[keyPath: member]
        return type(of: field).read(field: field, for: rawObject) as! V?
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(dynamicMember member: KeyPath<O, FieldContainer<OBase>.Coded<V>>) -> V? {

        guard
            let object = self.object,
            let rawObject = object.rawObject
            else {

                return nil
        }
        Internals.assert(
            rawObject.isRunningInAllowedQueue() == true,
            "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
        )
        let field = object[keyPath: member]
        return type(of: field).read(field: field, for: rawObject) as! V?
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(dynamicMember member: KeyPath<O, FieldContainer<OBase>.Relationship<V>>) -> V.PublishedType? {

        guard
            let object = self.object,
            let rawObject = object.rawObject
            else {

                return nil
        }
        Internals.assert(
            rawObject.isRunningInAllowedQueue() == true,
            "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
        )
        let field = object[keyPath: member]
        let snapshotValue = V.cs_valueForSnapshot(from: rawObject.objectIDs(forRelationshipNamed: field.keyPath))
        return V.cs_toPublishedType(from: snapshotValue, in: self.context)
     }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<V>(dynamicMember member: KeyPath<O, V>) -> V? {

        return self.object?[keyPath: member]
    }
}


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension ObjectPublisher where O: CoreStoreObject {
    
    public subscript<OBase, V>(dynamicMember member: KeyPath<O, ValueContainer<OBase>.Required<V>>) -> V? {

        return self.object?[keyPath: member].value
    }
    
    
    public subscript<OBase, V>(dynamicMember member: KeyPath<O, ValueContainer<OBase>.Optional<V>>) -> V? {

        return self.object?[keyPath: member].value
    }
    
    public subscript<OBase, V>(dynamicMember member: KeyPath<O, TransformableContainer<OBase>.Required<V>>) -> V? {

        return self.object?[keyPath: member].value
    }
    
    public subscript<OBase, V>(dynamicMember member: KeyPath<O, TransformableContainer<OBase>.Optional<V>>) -> V? {

        return self.object?[keyPath: member].value
    }
    
    public subscript<OBase, D>(dynamicMember member: KeyPath<O, RelationshipContainer<OBase>.ToOne<D>>) -> D? {

        return self.object?[keyPath: member].value
    }
    
    public subscript<OBase, D>(dynamicMember member: KeyPath<O, RelationshipContainer<OBase>.ToManyOrdered<D>>) -> [D]? {

        return self.object?[keyPath: member].value
    }
    
    public subscript<OBase, D>(dynamicMember member: KeyPath<O, RelationshipContainer<OBase>.ToManyUnordered<D>>) -> Set<D>? {

        return self.object?[keyPath: member].value
    }
}
