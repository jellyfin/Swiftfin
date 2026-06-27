//
//  DynamicObject.swift
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


// MARK: - DynamicObject

/**
 All CoreStore's utilities are designed around `DynamicObject` instances. `NSManagedObject` and `CoreStoreObject` instances all conform to `DynamicObject`.
 */
public protocol DynamicObject: AnyObject {
    
    /**
     The object ID for this instance
     */
    typealias ObjectID = NSManagedObjectID
    
    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_forceCreate(
        entityDescription: NSEntityDescription,
        into context: NSManagedObjectContext,
        assignTo store: NSPersistentStore
    ) -> Self

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_snapshotDictionary(
        id: ObjectID,
        context: NSManagedObjectContext
    ) -> [String: Any]?

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_fromRaw(
        object: NSManagedObject
    ) -> Self

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_matches(
        object: NSManagedObject
    ) -> Bool

    /**
     Used internally by CoreStore. Do not call directly.
     */
    func cs_toRaw() -> NSManagedObject
    
    /**
     Used internally by CoreStore. Do not call directly.
     */
    func cs_id() -> ObjectID
}

extension DynamicObject {
    
    // MARK: Internal
    
    internal func runtimeType() -> Self.Type {
        
        // Self.self does not return runtime-created types
        return object_getClass(self)! as! Self.Type
    }
}


// MARK: - NSManagedObject

extension NSManagedObject: DynamicObject {
    
    // MARK: DynamicObject
    
    public class func cs_forceCreate(
        entityDescription: NSEntityDescription,
        into context: NSManagedObjectContext,
        assignTo store: NSPersistentStore
    ) -> Self {

        let object = self.init(entity: entityDescription, insertInto: context)
        defer {
            
            context.assign(object, to: store)
        }
        return object
    }

    public class func cs_snapshotDictionary(
        id: ObjectID,
        context: NSManagedObjectContext
    ) -> [String: Any]? {

        guard let object = context.fetchExisting(id) as NSManagedObject? else {

            return nil
        }
        let rawObject = object.cs_toRaw()
        var dictionary = rawObject.dictionaryWithValues(forKeys: Array(rawObject.entity.attributesByName.keys))
        for case (let key, let target as NSManagedObject) in rawObject.dictionaryWithValues(forKeys: Array(rawObject.entity.relationshipsByName.keys)) {

            dictionary[key] = target.objectID
        }
        return dictionary
    }
    
    public class func cs_fromRaw(object: NSManagedObject) -> Self {

#if swift(>=5.9)
        return unsafeDowncast(object, to: self)

#else
        // unsafeDowncast fails debug assertion starting Swift 5.2
        return _unsafeUncheckedDowncast(object, to: self)

#endif
    }
    
    public static func cs_matches(
        object: NSManagedObject
    ) -> Bool {

        return object.isKind(of: self)
    }
    
    public func cs_toRaw() -> NSManagedObject {
        
        return self
    }
    
    public func cs_id() -> ObjectID {
        
        return self.objectID
    }
}


// MARK: - CoreStoreObject

extension CoreStoreObject {
    
    // MARK: DynamicObject
    
    public class func cs_forceCreate(
        entityDescription: NSEntityDescription,
        into context: NSManagedObjectContext,
        assignTo store: NSPersistentStore
    ) -> Self {

        let type = NSClassFromString(entityDescription.managedObjectClassName!)! as! NSManagedObject.Type
        let object = type.init(entity: entityDescription, insertInto: context)
        defer {
            
            context.assign(object, to: store)
        }
        return self.cs_fromRaw(object: object)
    }

    public class func cs_snapshotDictionary(
        id: ObjectID,
        context: NSManagedObjectContext
    ) -> [String: Any]? {

        var values: [KeyPathString: Any] = [:]
        if self.meta.needsReflection {

            func initializeAttributes(
                mirror: Mirror,
                object: Self,
                into attributes: inout [KeyPathString: Any]
            ) {

                if let superClassMirror = mirror.superclassMirror {

                    initializeAttributes(
                        mirror: superClassMirror,
                        object: object,
                        into: &attributes
                    )
                }
                for child in mirror.children {

                    switch child.value {

                    case let property as FieldAttributeProtocol:
                        Internals.assert(
                            object.rawObject?.isRunningInAllowedQueue() == true,
                            "Attempted to access \(Internals.typeName(type(of: property).dynamicObjectType))'s value outside it's designated queue."
                        )
                        attributes[property.keyPath] = type(of: property).read(
                            field: property,
                            for: object.rawObject!
                        )

                    case let property as FieldRelationshipProtocol:
                        Internals.assert(
                            object.rawObject?.isRunningInAllowedQueue() == true,
                            "Attempted to access \(Internals.typeName(type(of: property).dynamicObjectType))'s value outside it's designated queue."
                        )
                        attributes[property.keyPath] = type(of: property).valueForSnapshot(
                            field: property,
                            for: object.rawObject!
                        )

                    case let property as AttributeProtocol:
                        attributes[property.keyPath] = property.valueForSnapshot

                    case let property as RelationshipProtocol:
                        attributes[property.keyPath] = property.valueForSnapshot

                    default:
                        continue
                    }
                }
            }
            guard let object = context.fetchExisting(id) as CoreStoreObject? else {

                return nil
            }
            initializeAttributes(
                mirror: Mirror(reflecting: object),
                object: object as! Self,
                into: &values
            )
        }
        else {

            guard
                let object = context.fetchExisting(id) as CoreStoreObject?,
                let rawObject = object.rawObject,
                !rawObject.isDeleted
            else {

                return nil
            }
            for property in self.metaProperties(includeSuperclasses: true) {

                switch property {

                case let property as FieldAttributeProtocol:
                    Internals.assert(
                        object.rawObject?.isRunningInAllowedQueue() == true,
                        "Attempted to access \(Internals.typeName(type(of: property).dynamicObjectType))'s value outside it's designated queue."
                    )
                    values[property.keyPath] = type(of: property).read(
                        field: property,
                        for: rawObject
                    )

                case let property as FieldRelationshipProtocol:
                    Internals.assert(
                        object.rawObject?.isRunningInAllowedQueue() == true,
                        "Attempted to access \(Internals.typeName(type(of: property).dynamicObjectType))'s value outside it's designated queue."
                    )
                    values[property.keyPath] = type(of: property).valueForSnapshot(
                        field: property,
                        for: object.rawObject!
                    )

                default:
                    continue
                }
            }
        }
        return values
    }
    
    public class func cs_fromRaw(object: NSManagedObject) -> Self {
        
        if let coreStoreObject = object.coreStoreObject {
            
            return unsafeDowncast(coreStoreObject, to: self)
        }
        func forceTypeCast<T: CoreStoreObject>(
            _ type: AnyClass,
            to: T.Type
        ) -> T.Type {

            return type as! T.Type
        }
        let coreStoreObject = forceTypeCast(object.entity.dynamicObjectType!, to: self).init(rawObject: object)
        object.coreStoreObject = coreStoreObject
        return coreStoreObject
    }
    
    public static func cs_matches(
        object: NSManagedObject
    ) -> Bool {

        guard let type = object.entity.coreStoreEntity?.type else {
            
            return false
        }
        return (self as AnyClass).isSubclass(of: type as AnyClass)
    }
    
    public func cs_toRaw() -> NSManagedObject {
        
        return self.rawObject!
    }
    
    public func cs_id() -> ObjectID {
        
        return self.rawObject!.objectID
    }
}
