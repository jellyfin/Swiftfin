//
//  Entity.swift
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
import ObjectiveC


// MARK: Entity

/**
 The `Entity<O>` contains `NSEntityDescription` metadata for `CoreStoreObject` subclasses. Pass the `Entity` instances to `CoreStoreSchema` initializer.
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
 - SeeAlso: CoreStoreObject
 */
public final class Entity<O: CoreStoreObject>: DynamicEntity {
    
    /**
     Initializes an `Entity`. Always provide a concrete generic type to `Entity`.
     ```
     Entity<Animal>("Animal")
     ```
     - parameter entityName: the `NSEntityDescription` name to use for the entity
     - parameter isAbstract: set to `true` if the entity is meant to be an abstract class and can only be initialized with subclass types.
     - parameter versionHashModifier: the version hash modifier for the entity. Used to mark or denote an entity as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where, for example, the structure of an entity is unchanged but the format or content of data has changed.)
     - parameter indexes: the compound indexes for the entity as an array of arrays. The arrays contained in the returned array contain `KeyPath`s to properties of the entity.
     - parameter uniqueConstraints: sets uniqueness constraints for the entity. A uniqueness constraint is a set of one or more `KeyPath`s whose value must be unique over the set of instances of that entity. This value forms part of the entity's version hash. Uniqueness constraint violations can be computationally expensive to handle. It is highly suggested that there be only one uniqueness constraint per entity hierarchy. Uniqueness constraints must be defined at the highest level possible, and CoreStore will raise an assertion failure if unique constraints are added to a sub entity.
     */
    public convenience init(
        _ entityName: String,
        isAbstract: Bool = false,
        versionHashModifier: String? = nil,
        indexes: [[PartialKeyPath<O>]] = [],
        uniqueConstraints: [[PartialKeyPath<O>]]
    ) {

        self.init(
            O.self,
            entityName,
            isAbstract: isAbstract,
            versionHashModifier: versionHashModifier,
            indexes: indexes,
            uniqueConstraints: uniqueConstraints
        )
    }

    /**
     Initializes an `Entity`. Always provide a concrete generic type to `Entity`.
     ```
     Entity<Animal>("Animal")
     ```
     - parameter entityName: the `NSEntityDescription` name to use for the entity
     - parameter isAbstract: set to `true` if the entity is meant to be an abstract class and can only be initialized with subclass types.
     - parameter versionHashModifier: the version hash modifier for the entity. Used to mark or denote an entity as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where, for example, the structure of an entity is unchanged but the format or content of data has changed.)
     - parameter indexes: the compound indexes for the entity as an array of arrays. The arrays contained in the returned array contain `KeyPath`s to properties of the entity.
     */
    public convenience init(
        _ entityName: String,
        isAbstract: Bool = false,
        versionHashModifier: String? = nil,
        indexes: [[PartialKeyPath<O>]] = []
    ) {

        self.init(
            O.self,
            entityName,
            isAbstract: isAbstract,
            versionHashModifier: versionHashModifier,
            indexes: indexes
        )
    }
    
    /**
     Initializes an `Entity`.
     ```
     Entity(Animal.self, "Animal")
     ```
     - parameter type: the `DynamicObject` type associated with the entity
     - parameter entityName: the `NSEntityDescription` name to use for the entity
     - parameter isAbstract: set to `true` if the entity is meant to be an abstract class and can only be initialized with subclass types.
     - parameter versionHashModifier: the version hash modifier for the entity. Used to mark or denote an entity as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where, for example, the structure of an entity is unchanged but the format or content of data has changed.)
     - parameter indexes: the compound indexes for the entity as an array of arrays. The arrays contained in the returned array contain KeyPath's to properties of the entity.
     - parameter uniqueConstraints: sets uniqueness constraints for the entity. A uniqueness constraint is a set of one or more `KeyPath`s whose value must be unique over the set of instances of that entity. This value forms part of the entity's version hash. Uniqueness constraint violations can be computationally expensive to handle. It is highly suggested that there be only one uniqueness constraint per entity hierarchy. Uniqueness constraints must be defined at the highest level possible, and CoreStore will raise an assertion failure if unique constraints are added to a sub entity.
     */
    public init(
        _ type: O.Type,
        _ entityName: String,
        isAbstract: Bool = false,
        versionHashModifier: String? = nil,
        indexes: [[PartialKeyPath<O>]] = [],
        uniqueConstraints: [[PartialKeyPath<O>]]
    ) {

        let meta = O.meta
        let toStringArray: ([PartialKeyPath<O>]) -> [KeyPathString] = {
            
            return $0.map {
                
                return (meta[keyPath: $0] as! AnyKeyPathStringConvertible).cs_keyPathString
            }
        }
        super.init(
            type: type,
            entityName: entityName,
            isAbstract: isAbstract,
            versionHashModifier: versionHashModifier,
            indexes: indexes.map(toStringArray),
            uniqueConstraints: uniqueConstraints.map(toStringArray)
        )
    }

    /**
     Initializes an `Entity`.
     ```
     Entity(Animal.self, "Animal")
     ```
     - parameter type: the `DynamicObject` type associated with the entity
     - parameter entityName: the `NSEntityDescription` name to use for the entity
     - parameter isAbstract: set to `true` if the entity is meant to be an abstract class and can only be initialized with subclass types.
     - parameter versionHashModifier: the version hash modifier for the entity. Used to mark or denote an entity as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where, for example, the structure of an entity is unchanged but the format or content of data has changed.)
     - parameter indexes: the compound indexes for the entity as an array of arrays. The arrays contained in the returned array contain KeyPath's to properties of the entity.
     - parameter uniqueConstraints: sets uniqueness constraints for the entity. A uniqueness constraint is a set of one or more `KeyPath`s whose value must be unique over the set of instances of that entity. This value forms part of the entity's version hash. Uniqueness constraint violations can be computationally expensive to handle. It is highly suggested that there be only one uniqueness constraint per entity hierarchy. Uniqueness constraints must be defined at the highest level possible, and CoreStore will raise an assertion failure if unique constraints are added to a sub entity.
     */
    public init(
        _ type: O.Type,
        _ entityName: String,
        isAbstract: Bool = false,
        versionHashModifier: String? = nil,
        indexes: [[PartialKeyPath<O>]] = []
    ) {

        let meta = O.meta
        let toStringArray: ([PartialKeyPath<O>]) -> [KeyPathString] = {

            return $0.map {

                return (meta[keyPath: $0] as! AnyKeyPathStringConvertible).cs_keyPathString
            }
        }
        super.init(
            type: type,
            entityName: entityName,
            isAbstract: isAbstract,
            versionHashModifier: versionHashModifier,
            indexes: indexes.map(toStringArray),
            uniqueConstraints: []
        )
    }
}


// MARK: - DynamicEntity

/**
 Use concrete instances of `Entity<O>` in API that accept `DynamicEntity` arguments.
 */
public /*abstract*/ class DynamicEntity: Hashable {
    
    /**
     Do not use directly.
     */
    public let type: DynamicObject.Type
    
    /**
     Do not use directly.
     */
    public let entityName: EntityName
    
    /**
     Do not use directly.
     */
    public let isAbstract: Bool
    
    /**
     Do not use directly.
     */
    public let versionHashModifier: String?
    
    /**
     Do not use directly.
     */
    public let indexes: [[KeyPathString]]
    
    /**
     Do not use directly.
     */
    public let uniqueConstraints: [[KeyPathString]]
    
    
    // MARK: Equatable
    
    public static func == (lhs: DynamicEntity, rhs: DynamicEntity) -> Bool {
        
        return lhs.type == rhs.type
            && lhs.entityName == rhs.entityName
            && lhs.isAbstract == rhs.isAbstract
            && lhs.versionHashModifier == rhs.versionHashModifier
            && lhs.indexes == rhs.indexes
            && lhs.uniqueConstraints == rhs.uniqueConstraints
    }
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(ObjectIdentifier(self.type))
        hasher.combine(self.entityName)
        hasher.combine(self.isAbstract)
        hasher.combine(self.versionHashModifier ?? "")
    }
    
    
    // MARK: Internal
    
    internal init(
        type: DynamicObject.Type,
        entityName: String,
        isAbstract: Bool,
        versionHashModifier: String?,
        indexes: [[KeyPathString]],
        uniqueConstraints: [[KeyPathString]]
    ) {

        self.type = type
        self.entityName = entityName
        self.isAbstract = isAbstract
        self.versionHashModifier = versionHashModifier
        self.indexes = indexes
        self.uniqueConstraints = uniqueConstraints
    }
}
