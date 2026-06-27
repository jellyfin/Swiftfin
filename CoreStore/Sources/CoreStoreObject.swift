//
//  CoreStoreObject.swift
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
import Foundation


// MARK: - CoreStoreObject

/**
 The `CoreStoreObject` is an abstract class for creating CoreStore-managed objects that are more type-safe and more convenient than `NSManagedObject` subclasses. The model entities for `CoreStoreObject` subclasses are inferred from the Swift declaration themselves; no .xcdatamodeld files are needed. To declare persisted attributes and relationships for the `CoreStoreObject` subclass, declare properties of type `Value.Required<T>`, `Value.Optional<T>` for values, or `Relationship.ToOne<T>`, `Relationship.ToManyOrdered<T>`, `Relationship.ToManyUnordered<T>` for relationships.
 ```
 class Animal: CoreStoreObject {
     let species = Value.Required<String>("species", initial: "")
     let nickname = Value.Optional<String>("nickname")
     let master = Relationship.ToOne<Person>("master")
 }
 
 class Person: CoreStoreObject {
     let name = Value.Required<String>("name", initial: "")
     let pet = Relationship.ToOne<Animal>("pet", inverse: { $0.master })
 }
 ```
 `CoreStoreObject` entities for a model version should be added to `CoreStoreSchema` instance.
 ```
 CoreStoreDefaults.dataStack = DataStack(
     CoreStoreSchema(
         modelVersion: "V1",
         entities: [
             Entity<Animal>("Animal"),
             Entity<Person>("Person")
         ]
     )
 )
 ```
 - SeeAlso: CoreStoreSchema
 - SeeAlso: CoreStoreObject.Value
 - SeeAlso: CoreStoreObject.Relationship
 */
open /*abstract*/ class CoreStoreObject: DynamicObject, Hashable {
    
    /**
     Do not call this directly. This is exposed as public only as a required initializer.
     - Important: subclasses that need a custom initializer should override both `init(rawObject:)` and `init(asMeta:)`, and to call their corresponding super implementations.
     */
    public required init(rawObject: NSManagedObject) {
        
        self.isMeta = false
        self.rawObject = (rawObject as! CoreStoreManagedObject)

        guard Self.meta.needsReflection else {

            return
        }
        self.registerReceiver(
            mirror: Mirror(reflecting: self),
            object: self
        )
    }
    
    /**
     Do not call this directly. This is exposed as public only as a required initializer.
     - Important: subclasses that need a custom initializer should override both `init(rawObject:)` and `init(asMeta:)`, and to call their corresponding super implementations.
     */
    public required init(asMeta: Void) {
        
        self.isMeta = true
        self.rawObject = nil
    }
    
    
    // MARK: Equatable
    
    public static func == (lhs: CoreStoreObject, rhs: CoreStoreObject) -> Bool {
        
        guard lhs.isMeta == rhs.isMeta else {
            
            return false
        }
        if lhs.isMeta {
            
            return lhs.runtimeType() == rhs.runtimeType()
        }
        return lhs.rawObject!.isEqual(rhs.rawObject!)
    }
    
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(self.isMeta)
        hasher.combine(ObjectIdentifier(self))
        hasher.combine(self.rawObject)
    }
    
    
    // MARK: Internal
    
    internal let rawObject: CoreStoreManagedObject?
    internal let isMeta: Bool

    internal lazy var needsReflection: Bool = self.containsLegacyAttributes(
        mirror: Mirror(reflecting: self),
        object: self
    )

    internal class func metaProperties(includeSuperclasses: Bool) -> [PropertyProtocol] {

        func keyPaths(
            _ allKeyPaths: inout [PropertyProtocol],
            for dynamicType: CoreStoreObject.Type
        ) {

            allKeyPaths.append(contentsOf: dynamicType.meta.propertyProtocolsByName())
            guard
                includeSuperclasses,
                case let superType as CoreStoreObject.Type = (dynamicType as AnyClass).superclass(),
                superType != CoreStoreObject.self
                else {

                    return
            }
            keyPaths(&allKeyPaths, for: superType)
        }

        var allKeyPaths: [PropertyProtocol] = []
        keyPaths(&allKeyPaths, for: self)
        return allKeyPaths
    }

    
    // MARK: Private

    private func containsLegacyAttributes(
        mirror: Mirror,
        object: CoreStoreObject
    ) -> Bool {

        if let superclassMirror = mirror.superclassMirror,
            self.containsLegacyAttributes(mirror: superclassMirror, object: object) {

            return true
        }
        for child in mirror.children {

            switch child.value {

            case is AttributeProtocol:
                return true

            case is RelationshipProtocol:
                return true

            default:
                continue
            }
        }
        return false
    }
    
    private func registerReceiver(
        mirror: Mirror,
        object: CoreStoreObject
    ) {

        if let superclassMirror = mirror.superclassMirror {
            
            self.registerReceiver(
                mirror: superclassMirror,
                object: object
            )
        }
        for child in mirror.children {
            
            switch child.value {
                
            case let property as AttributeProtocol:
                property.rawObject = object.rawObject
                    
            case let property as RelationshipProtocol:
                property.rawObject = object.rawObject
                
            default:
                continue
            }
        }
    }

    private func propertyProtocolsByName() -> [PropertyProtocol] {

        Internals.assert(self.isMeta, "'propertyProtocolsByName()' accessed from non-meta instance of \(Internals.typeName(self))")

        let cacheKey = ObjectIdentifier(Self.self)
        if let properties = Static.propertiesCache[cacheKey] {

            return properties
        }
        let values: [PropertyProtocol] = Mirror(reflecting: self)
            .children
            .compactMap({ $0.value as? PropertyProtocol })
        Static.propertiesCache[cacheKey] = values
        return values
    }
}


// MARK: - DynamicObject where Self: CoreStoreObject

extension DynamicObject where Self: CoreStoreObject {
    
    /**
     Returns the `PartialObject` instance for the object, which acts as a fast, type-safe KVC interface for `CoreStoreObject`.
     */
    public func partialObject() -> PartialObject<Self> {
        
        Internals.assert(
            !self.isMeta,
            "Attempted to create a \(Internals.typeName(PartialObject<Self>.self)) from a meta object. Meta objects are only used for querying keyPaths and infering types."
        )
        return PartialObject<Self>(self.rawObject!)
    }


    // MARK: Internal
    
    internal static var meta: Self {
        
        let cacheKey = ObjectIdentifier(self)
        if case let meta as Self = Static.metaCache[cacheKey] {
            
            return meta
        }
        let meta = self.init(asMeta: ())
        Static.metaCache[cacheKey] = meta
        return meta
    }
}


// MARK: - Static

fileprivate enum Static {
    
    // MARK: FilePrivate
    
    fileprivate static var metaCache: [ObjectIdentifier: Any] = [:]
    fileprivate static var propertiesCache: [ObjectIdentifier: [PropertyProtocol]] = [:]
}
