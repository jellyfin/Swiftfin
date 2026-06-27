//
//  ObjectSnapshot.swift
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

#if canImport(UIKit)
import UIKit

#elseif canImport(AppKit)
import AppKit

#endif


// MARK: - ObjectSnapshot

/**
 The `ObjectSnapshot` is a full copy of a `DynamicObject`'s properties at a given point in time. This is useful especially when keeping thread-safe state values, in ViewModels for example. Since this is a value type, any changes in this `struct` does not affect the actual object.
 */
@dynamicMemberLookup
public struct ObjectSnapshot<O: DynamicObject>: ObjectRepresentation, Hashable, @unchecked Sendable {

    // MARK: Public

    public func dictionaryForValues() -> [String: Any] {

        return self.values
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
        return ObjectSnapshot<O>(objectID: self.id, context: context)
    }
    
    public func asSnapshot(in transaction: BaseDataTransaction) -> ObjectSnapshot<O>? {
        
        let context = transaction.unsafeContext()
        return ObjectSnapshot<O>(objectID: self.id, context: context)
    }


    // MARK: Equatable

    public static func == (_ lhs: Self, _ rhs: Self) -> Bool {

        return lhs.id == rhs.id
            && (lhs.generation == rhs.generation || lhs.valuesRef == rhs.valuesRef)
    }


    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(self.id)
        hasher.combine(self.valuesRef)
    }


    // MARK: Internal

    internal init?(objectID: O.ObjectID, context: NSManagedObjectContext) {

        guard let values = O.cs_snapshotDictionary(id: objectID, context: context) else {

            return nil
        }
        self.id = objectID
        self.context = context
        self.values = values
        self.generation = .init()
    }
    
    internal var cs_objectID: O.ObjectID {
        
        return self.objectID()
    }


    // MARK: FilePrivate

    fileprivate var values: [String: Any] {
        
        didSet {
            
            self.generation = .init()
        }
    }


    // MARK: Private

    private let id: O.ObjectID
    private let context: NSManagedObjectContext
    
    private var generation: UUID

    private var valuesRef: NSDictionary {

        return self.values as NSDictionary
    }
}


// MARK: - ObjectSnapshot where O: NSManagedObject

extension ObjectSnapshot where O: NSManagedObject {

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<V: AllowedObjectiveCKeyPathValue>(dynamicMember member: KeyPath<O, V>) -> V! {

        get {

            let key = String(keyPath: member)
            return self.values[key] as! V?
        }
        set  {

            let key = String(keyPath: member)
            self.values[key] = newValue
        }
    }
}


// MARK: - ObjectSnapshot where O: CoreStoreObject

extension ObjectSnapshot where O: CoreStoreObject {

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, FieldContainer<OBase>.Stored<V>>
    ) -> V {

        get {

            let key = String(keyPath: member)
            return self.values[key] as! V
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = newValue
        }
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, FieldContainer<OBase>.Virtual<V>>
    ) -> V {

        get {

            let key = String(keyPath: member)
            return self.values[key] as! V
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = newValue
        }
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, FieldContainer<OBase>.Coded<V>>
    ) -> V {

        get {

            let key = String(keyPath: member)
            return self.values[key] as! V
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = newValue
        }
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, FieldContainer<OBase>.Relationship<V>>
    ) -> V.PublishedType {

        get {

            let key = String(keyPath: member)
            let context = self.context
            let snapshotValue = self.values[key] as! V.SnapshotValueType
            return V.cs_toPublishedType(from: snapshotValue, in: context)
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = V.cs_toSnapshotType(from: newValue)
        }
    }
}


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension ObjectSnapshot where O: CoreStoreObject {
    
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, ValueContainer<OBase>.Required<V>>
    ) -> V {

        get {

            let key = String(keyPath: member)
            return self.values[key] as! V
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = newValue
        }
    }

    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, ValueContainer<OBase>.Optional<V>>
    ) -> V? {

        get {

            let key = String(keyPath: member)
            return self.values[key] as? V
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = newValue
        }
    }
    
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, TransformableContainer<OBase>.Required<V>>
    ) -> V {

        get {

            let key = String(keyPath: member)
            return self.values[key] as! V
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = newValue
        }
    }
    
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, TransformableContainer<OBase>.Optional<V>>
    ) -> V? {

        get {

            let key = String(keyPath: member)
            return self.values[key] as? V
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = newValue
        }
    }
    
    public subscript<OBase, D>(
        dynamicMember member: KeyPath<O, RelationshipContainer<OBase>.ToOne<D>>
    ) -> ObjectPublisher<D>? {

        get {

            let key = String(keyPath: member)
            guard let id = self.values[key] as? D.ObjectID else {

                return nil
            }
            return self.context.objectPublisher(objectID: id)
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = newValue?.objectID()
        }
    }
    
    public subscript<OBase, D>(
        dynamicMember member: KeyPath<O, RelationshipContainer<OBase>.ToManyOrdered<D>>
    ) -> [ObjectPublisher<D>] {

        get {

            let key = String(keyPath: member)
            let context = self.context
            let ids = self.values[key] as! [D.ObjectID]
            return ids.map(context.objectPublisher(objectID:))
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = newValue.map({ $0.objectID() })
        }
    }
    
    public subscript<OBase, D>(
        dynamicMember member: KeyPath<O, RelationshipContainer<OBase>.ToManyUnordered<D>>
    ) -> Set<ObjectPublisher<D>> {

        get {

            let key = String(keyPath: member)
            let context = self.context
            let ids = self.values[key] as! Set<D.ObjectID>
            return Set(ids.map(context.objectPublisher(objectID:)))
        }
        set {

            let key = String(keyPath: member)
            self.values[key] = Set(newValue.map({ $0.objectID() }))
        }
    }
}
