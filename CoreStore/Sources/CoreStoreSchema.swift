//
//  CoreStoreSchema.swift
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


// MARK: - CoreStoreSchema

/**
 The `CoreStoreSchema` describes models written for `CoreStoreObject` Swift class declarations for a particular model version. `CoreStoreObject` entities for a model version should be added to `CoreStoreSchema` instance.
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
         ],
         versionLock: [
             "Animal": [0x2698c812ebbc3b97, 0x751e3fa3f04cf9, 0x51fd460d3babc82, 0x92b4ba735b5a3053],
             "Person": [0xae4060a59f990ef0, 0x8ac83a6e1411c130, 0xa29fea58e2e38ab6, 0x2071bb7e33d77887]
         ]
     )
 )
 ```
 - SeeAlso: CoreStoreObject
 - SeeAlso: Entity
 */
public final class CoreStoreSchema: DynamicSchema {
    
    /**
     Initializes a `CoreStoreSchema`. Using this initializer only if the entities don't need to be assigned to particular "Configurations". To use multiple configurations (for example, to separate entities in different `StorageInterface`s), use the `init(modelVersion:entitiesByConfiguration:versionLock:)` initializer.
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
             ],
             versionLock: [
                 "Animal": [0x2698c812ebbc3b97, 0x751e3fa3f04cf9, 0x51fd460d3babc82, 0x92b4ba735b5a3053],
                 "Person": [0xae4060a59f990ef0, 0x8ac83a6e1411c130, 0xa29fea58e2e38ab6, 0x2071bb7e33d77887]
             ]
         )
     )
     ```
     - parameter modelVersion: the model version for the schema. This string should be unique from other `DynamicSchema`'s model versions.
     - parameter entities: an array of `Entity<T>` pertaining to all `CoreStoreObject` subclasses to be added to the schema version.
     - parameter versionLock: an optional list of `VersionLock` hashes for each entity name in the `entities` array. If any `DynamicEntity` doesn't match its version lock hash, an assertion will be raised.
     */
    public convenience init(
        modelVersion: ModelVersion,
        entities: [DynamicEntity],
        versionLock: VersionLock? = nil
    ) {

        var entityConfigurations: [DynamicEntity: Set<String>] = [:]
        for entity in entities {
            
            entityConfigurations[entity] = []
        }
        self.init(
            modelVersion: modelVersion,
            entityConfigurations: entityConfigurations,
            versionLock: versionLock
        )
    }
    
    /**
     Initializes a `CoreStoreSchema`. Using this initializer if multiple "Configurations" (for example, to separate entities in different `StorageInterface`s) are needed. To add an entity only to the default configuration, assign an empty set to its configurations list. Note that regardless of the set configurations, all entities will be added to the default configuration.
     ```
     class Animal: CoreStoreObject {
         let species = Value.Required<String>("species", initial: "")
         let nickname = Value.Optional<String>("nickname")
     }
     
     class Person: CoreStoreObject {
         let name = Value.Required<String>("name", initial: "")
     }
     
     CoreStoreDefaults.dataStack = DataStack(
         CoreStoreSchema(
             modelVersion: "V1",
             entityConfigurations: [
                 Entity<Animal>("Animal"): [],
                 Entity<Person>("Person"): ["People"]
             ],
             versionLock: [
                 "Animal": [0x2698c812ebbc3b97, 0x751e3fa3f04cf9, 0x51fd460d3babc82, 0x92b4ba735b5a3053],
                 "Person": [0xae4060a59f990ef0, 0x8ac83a6e1411c130, 0xa29fea58e2e38ab6, 0x2071bb7e33d77887]
             ]
         )
     )
     ```
     - parameter modelVersion: the model version for the schema. This string should be unique from other `DynamicSchema`'s model versions.
     - parameter entityConfigurations: a dictionary with `Entity<T>` pertaining to all `CoreStoreObject` subclasses  and the corresponding list of "Configurations" they should be added to. To add an entity only to the default configuration, assign an empty set to its configurations list. Note that regardless of the set configurations, all entities will be added to the default configuration.
     - parameter versionLock: an optional list of `VersionLock` hashes for each entity name in the `entities` array. If any `DynamicEntity` doesn't match its version lock hash, an assertion will be raised.
     */
    public required init(
        modelVersion: ModelVersion,
        entityConfigurations: [DynamicEntity: Set<String>],
        versionLock: VersionLock? = nil
    ) {

        var actualEntitiesByConfiguration: [String: Set<DynamicEntity>] = [:]
        for (entity, configurations) in entityConfigurations {
            
            for configuration in configurations {
                
                var entities: Set<DynamicEntity>
                if let existingEntities = actualEntitiesByConfiguration[configuration] {
                    
                    entities = existingEntities
                }
                else {
                    
                    entities = []
                }
                entities.insert(entity)
                actualEntitiesByConfiguration[configuration] = entities
            }
        }
        let allEntities = Set(entityConfigurations.keys)
        actualEntitiesByConfiguration[DataStack.defaultConfigurationName] = allEntities
        
        Internals.assert(
            Internals.with {
                
                let expectedCount = allEntities.count
                return Set(allEntities.map({ ObjectIdentifier($0.type) })).count == expectedCount
                    && Set(allEntities.map({ $0.entityName })).count == expectedCount
            },
            "Ambiguous entity types or entity names were found in the model. Ensure that the entity types and entity names are unique to each other. Entities: \(allEntities)"
        )
        
        self.modelVersion = modelVersion
        self.entitiesByConfiguration = actualEntitiesByConfiguration
        self.allEntities = allEntities
        
        if let versionLock = versionLock {
            
            Internals.assert(
                versionLock == VersionLock(entityVersionHashesByName: self.rawModel().entityVersionHashesByName),
                "A \(Internals.typeName(VersionLock.self)) was provided for the \(Internals.typeName(CoreStoreSchema.self)) with version \"\(modelVersion)\", but the actual hashes do not match. This may result in unwanted migrations or unusable persistent stores.\nExpected lock values: \(versionLock)\nActual lock values: \(VersionLock(entityVersionHashesByName: self.rawModel().entityVersionHashesByName))"
            )
        }
        else {
            
            #if DEBUG
                Internals.log(
                    .notice,
                    message: "These are hashes for the \(Internals.typeName(CoreStoreSchema.self)) with version name \"\(modelVersion)\". Copy the dictionary below and pass it to the \(Internals.typeName(CoreStoreSchema.self)) initializer's \"versionLock\" argument:\nversionLock: \(VersionLock(entityVersionHashesByName: self.rawModel().entityVersionHashesByName))"
                )
            #endif
        }
    }
    
    
    // MARK: - DynamicSchema
    
    public let modelVersion: ModelVersion
    
    public func rawModel() -> NSManagedObjectModel {
        
        return CoreStoreSchema.barrierQueue.sync(flags: .barrier) {
            
            if let cachedRawModel = self.cachedRawModel {
                
                return cachedRawModel
            }
            let rawModel = NSManagedObjectModel()
            var entityDescriptionsByEntity: [DynamicEntity: NSEntityDescription] = [:]
            var allCustomGettersSetters: [DynamicEntity: [KeyPathString: CoreStoreManagedObject.CustomGetterSetter]] = [:]
            var allCustomInitializers: [DynamicEntity: [KeyPathString: CoreStoreManagedObject.CustomInitializer]] = [:]
            var allFieldCoders: [DynamicEntity: [KeyPathString: Internals.AnyFieldCoder]] = [:]
            for entity in self.allEntities {
                
                let (entityDescription, customGetterSetterByKeyPaths, customInitializerByKeyPaths, fieldCoders) = self.entityDescription(
                    for: entity,
                    initializer: CoreStoreSchema.firstPassCreateEntityDescription(from:in:)
                )
                entityDescriptionsByEntity[entity] = (entityDescription.copy() as! NSEntityDescription)
                allCustomGettersSetters[entity] = customGetterSetterByKeyPaths
                allCustomInitializers[entity] = customInitializerByKeyPaths
                allFieldCoders[entity] = fieldCoders
            }
            CoreStoreSchema.secondPassConnectRelationshipAttributes(for: entityDescriptionsByEntity)
            CoreStoreSchema.thirdPassConnectInheritanceTreeAndIndexes(for: entityDescriptionsByEntity)
            CoreStoreSchema.fourthPassSynthesizeManagedObjectClasses(
                for: entityDescriptionsByEntity,
                allCustomGettersSetters: allCustomGettersSetters,
                allCustomInitializers: allCustomInitializers,
                allFieldCoders: allFieldCoders
            )
            
            rawModel.entities = entityDescriptionsByEntity.values.sorted(by: { $0.name! < $1.name! })
            for (configuration, entities) in self.entitiesByConfiguration {
                
                rawModel.setEntities(
                    entities
                        .map({ entityDescriptionsByEntity[$0]! })
                        .sorted(by: { $0.name! < $1.name! }),
                    forConfigurationName: configuration
                )
            }
            self.cachedRawModel = rawModel
            return rawModel
        }
    }
    
    
    // MARK: Internal
    
    internal let entitiesByConfiguration: [String: Set<DynamicEntity>]
    
    
    // MARK: Private
    
    private static let barrierQueue = DispatchQueue.concurrent("com.coreStore.coreStoreDataModelBarrierQueue", qos: .userInteractive)
    
    private let allEntities: Set<DynamicEntity>
    
    private var entityDescriptionsByEntity: [DynamicEntity: NSEntityDescription] = [:]
    private var customGettersSettersByEntity: [DynamicEntity: [KeyPathString: CoreStoreManagedObject.CustomGetterSetter]] = [:]
    private var customInitializersByEntity: [DynamicEntity: [KeyPathString: CoreStoreManagedObject.CustomInitializer]] = [:]
    private var fieldCodersByEntity: [DynamicEntity: [KeyPathString: Internals.AnyFieldCoder]] = [:]
    private weak var cachedRawModel: NSManagedObjectModel?
    
    private func entityDescription(
        for entity: DynamicEntity,
        initializer: (DynamicEntity, ModelVersion) -> (
            entity: NSEntityDescription,
            customGetterSetterByKeyPaths: [KeyPathString: CoreStoreManagedObject.CustomGetterSetter],
            customInitializerByKeyPaths: [KeyPathString: CoreStoreManagedObject.CustomInitializer],
            fieldCoders: [KeyPathString: Internals.AnyFieldCoder]
        )
    ) -> (
        entity: NSEntityDescription,
        customGetterSetterByKeyPaths: [KeyPathString: CoreStoreManagedObject.CustomGetterSetter],
        customInitializerByKeyPaths: [KeyPathString: CoreStoreManagedObject.CustomInitializer],
        fieldCoders: [KeyPathString: Internals.AnyFieldCoder]
    ) {
        
        if let cachedEntityDescription = self.entityDescriptionsByEntity[entity] {
            
            return (
                cachedEntityDescription,
                self.customGettersSettersByEntity[entity] ?? [:],
                self.customInitializersByEntity[entity] ?? [:],
                self.fieldCodersByEntity[entity] ?? [:]
            )
        }
        let modelVersion = self.modelVersion
        let (entityDescription, customGetterSetterByKeyPaths, customInitializerByKeyPaths, fieldCoders) = withoutActuallyEscaping(
            initializer,
            do: { $0(entity, modelVersion) }
        )
        self.entityDescriptionsByEntity[entity] = entityDescription
        self.customGettersSettersByEntity[entity] = customGetterSetterByKeyPaths
        self.customInitializersByEntity[entity] = customInitializerByKeyPaths
        self.fieldCodersByEntity[entity] = fieldCoders
        return (
            entityDescription,
            customGetterSetterByKeyPaths,
            customInitializerByKeyPaths,
            fieldCoders
        )
    }

    private static func firstPassCreateEntityDescription(
        from entity: DynamicEntity,
        in modelVersion: ModelVersion
    ) -> (
        entity: NSEntityDescription,
        customGetterSetterByKeyPaths: [KeyPathString: CoreStoreManagedObject.CustomGetterSetter],
        customInitializerByKeyPaths: [KeyPathString: CoreStoreManagedObject.CustomInitializer],
        fieldCoders: [KeyPathString: Internals.AnyFieldCoder]
    ) {
        
        let entityDescription = NSEntityDescription()
        entityDescription.coreStoreEntity = entity
        entityDescription.name = entity.entityName
        entityDescription.isAbstract = entity.isAbstract
        entityDescription.versionHashModifier = entity.versionHashModifier
        entityDescription.managedObjectClassName = CoreStoreManagedObject.cs_subclassName(for: entity, in: modelVersion)
        
        var keyPathsByAffectedKeyPaths: [KeyPathString: Set<KeyPathString>] = [:]
        var customInitialValuesByKeyPaths: [KeyPathString: CoreStoreManagedObject.CustomInitializer] = [:]
        var customGetterSetterByKeyPaths: [KeyPathString: CoreStoreManagedObject.CustomGetterSetter] = [:]
        var fieldCoders: [KeyPathString: Internals.AnyFieldCoder] = [:]

        func createProperties(
            for type: CoreStoreObject.Type
        ) -> [NSPropertyDescription] {

            var propertyDescriptions: [NSPropertyDescription] = []
            for property in type.metaProperties(includeSuperclasses: false) {
                
                switch property {

                case let attribute as FieldAttributeProtocol:
                    Internals.assert(
                        !NSManagedObject.instancesRespond(to: Selector(attribute.keyPath)),
                        "Attribute Property name \"\(String(reflecting: entity.type)).\(attribute.keyPath)\" is not allowed because it collides with \"\(String(reflecting: NSManagedObject.self)).\(attribute.keyPath)\""
                    )
                    let entityDescriptionValues = attribute.entityDescriptionValues()
                    let description = NSAttributeDescription()
                    description.name = attribute.keyPath
                    description.attributeType = entityDescriptionValues.attributeType
                    description.isOptional = entityDescriptionValues.isOptional
                    description.defaultValue = entityDescriptionValues.defaultValue
                    description.isTransient = entityDescriptionValues.isTransient
                    description.allowsExternalBinaryDataStorage = entityDescriptionValues.allowsExternalBinaryDataStorage
                    description.versionHashModifier = entityDescriptionValues.versionHashModifier
                    description.renamingIdentifier = entityDescriptionValues.renamingIdentifier

                    let valueTransformer = entityDescriptionValues.valueTransformer
                    description.valueTransformerName = valueTransformer?.transformerName.rawValue

                    propertyDescriptions.append(description)

                    keyPathsByAffectedKeyPaths[attribute.keyPath] = entityDescriptionValues.affectedByKeyPaths
                    customGetterSetterByKeyPaths[attribute.keyPath] = (attribute.getter, attribute.setter)
                    customInitialValuesByKeyPaths[attribute.keyPath] = attribute.initializer
                    fieldCoders[attribute.keyPath] = valueTransformer

                case let relationship as FieldRelationshipProtocol:
                    Internals.assert(
                        !NSManagedObject.instancesRespond(to: Selector(relationship.keyPath)),
                        "Relationship Property name \"\(String(reflecting: entity.type)).\(relationship.keyPath)\" is not allowed because it collides with \"\(String(reflecting: NSManagedObject.self)).\(relationship.keyPath)\""
                    )
                    let entityDescriptionValues = relationship.entityDescriptionValues()
                    let description = NSRelationshipDescription()
                    description.name = relationship.keyPath
                    description.minCount = entityDescriptionValues.minCount
                    description.maxCount = entityDescriptionValues.maxCount
                    description.isOrdered = entityDescriptionValues.isOrdered
                    description.deleteRule = entityDescriptionValues.deleteRule
                    description.versionHashModifier = entityDescriptionValues.versionHashModifier
                    description.renamingIdentifier = entityDescriptionValues.renamingIdentifier
                    propertyDescriptions.append(description)
                    keyPathsByAffectedKeyPaths[relationship.keyPath] = entityDescriptionValues.affectedByKeyPaths
                    
                case let attribute as AttributeProtocol:
                    Internals.assert(
                        !NSManagedObject.instancesRespond(to: Selector(attribute.keyPath)),
                        "Attribute Property name \"\(String(reflecting: entity.type)).\(attribute.keyPath)\" is not allowed because it collides with \"\(String(reflecting: NSManagedObject.self)).\(attribute.keyPath)\""
                    )
                    let entityDescriptionValues = attribute.entityDescriptionValues()
                    let description = NSAttributeDescription()
                    description.name = attribute.keyPath
                    description.attributeType = entityDescriptionValues.attributeType
                    description.isOptional = entityDescriptionValues.isOptional
                    description.defaultValue = entityDescriptionValues.defaultValue
                    description.isTransient = entityDescriptionValues.isTransient
                    description.allowsExternalBinaryDataStorage = entityDescriptionValues.allowsExternalBinaryDataStorage
                    description.versionHashModifier = entityDescriptionValues.versionHashModifier
                    description.renamingIdentifier = entityDescriptionValues.renamingIdentifier
                    propertyDescriptions.append(description)
                    keyPathsByAffectedKeyPaths[attribute.keyPath] = entityDescriptionValues.affectedByKeyPaths
                    customGetterSetterByKeyPaths[attribute.keyPath] = (attribute.getter, attribute.setter)
                    
                case let relationship as RelationshipProtocol:
                    Internals.assert(
                        !NSManagedObject.instancesRespond(to: Selector(relationship.keyPath)),
                        "Relationship Property name \"\(String(reflecting: entity.type)).\(relationship.keyPath)\" is not allowed because it collides with \"\(String(reflecting: NSManagedObject.self)).\(relationship.keyPath)\""
                    )
                    let entityDescriptionValues = relationship.entityDescriptionValues()
                    let description = NSRelationshipDescription()
                    description.name = relationship.keyPath
                    description.minCount = entityDescriptionValues.minCount
                    description.maxCount = entityDescriptionValues.maxCount
                    description.isOrdered = entityDescriptionValues.isOrdered
                    description.deleteRule = entityDescriptionValues.deleteRule
                    description.versionHashModifier = entityDescriptionValues.versionHashModifier
                    description.renamingIdentifier = entityDescriptionValues.renamingIdentifier
                    propertyDescriptions.append(description)
                    keyPathsByAffectedKeyPaths[relationship.keyPath] = entityDescriptionValues.affectedByKeyPaths
                    
                default:
                    continue
                }
            }
            return propertyDescriptions
        }
        entityDescription.properties = createProperties(for: entity.type as! CoreStoreObject.Type)
        entityDescription.keyPathsByAffectedKeyPaths = keyPathsByAffectedKeyPaths
        return (
            entityDescription,
            customGetterSetterByKeyPaths,
            customInitialValuesByKeyPaths,
            fieldCoders
        )
    }
    
    private static func secondPassConnectRelationshipAttributes(
        for entityDescriptionsByEntity: [DynamicEntity: NSEntityDescription]
    ) {

        var relationshipsByNameByEntity: [DynamicEntity: [String: NSRelationshipDescription]] = [:]
        for (entity, entityDescription) in entityDescriptionsByEntity {
            
            relationshipsByNameByEntity[entity] = entityDescription.relationshipsByName
        }

        func findEntity(
            for type: CoreStoreObject.Type
        ) -> DynamicEntity {

            var matchedEntities: Set<DynamicEntity> = []
            for (entity, _) in entityDescriptionsByEntity where entity.type == type {
                
                matchedEntities.insert(entity)
            }
            if matchedEntities.count == 1 {
                
                return matchedEntities.first!
            }
            if matchedEntities.isEmpty {
                
                Internals.abort(
                    "No \(Internals.typeName("Entity<\(type)>")) instance found in the \(Internals.typeName(CoreStoreSchema.self))."
                )
            }
            else {
                
                Internals.abort(
                    "Ambiguous entity types or entity names were found in the model. Ensure that the entity types and entity names are unique to each other. Entities: \(matchedEntities)"
                )
            }
        }
        
        func findInverseRelationshipMatching(
            destinationEntity: DynamicEntity,
            destinationKeyPath: String
        ) -> NSRelationshipDescription {

            for case (destinationKeyPath, let relationshipDescription) in relationshipsByNameByEntity[destinationEntity]! {
                
                return relationshipDescription
            }
            Internals.abort(
                "The inverse relationship for \"\(destinationEntity.type).\(destinationKeyPath)\" could not be found. Make sure to set the `inverse:` initializer argument for one of the paired \(Internals.typeName("Relationship.ToOne<T>")), \(Internals.typeName("Relationship.ToManyOrdered<T>")), or \(Internals.typeName("Relationship.ToManyUnozrdered<T>"))"
            )
        }
        
        for (entity, entityDescription) in entityDescriptionsByEntity {
            
            let relationshipsByName = relationshipsByNameByEntity[entity]!
            let entityType = entity.type as! CoreStoreObject.Type
            for property in entityType.metaProperties(includeSuperclasses: false) {
                
                switch property {

                case let relationship as FieldRelationshipProtocol:
                    let (destinationType, destinationKeyPath) = relationship.entityDescriptionValues().inverse
                    let destinationEntity = findEntity(for: destinationType)
                    let description = relationshipsByName[relationship.keyPath]!
                    description.destinationEntity = entityDescriptionsByEntity[destinationEntity]!

                    if let destinationKeyPath = destinationKeyPath {

                        let inverseRelationshipDescription = findInverseRelationshipMatching(
                            destinationEntity: destinationEntity,
                            destinationKeyPath: destinationKeyPath
                        )
                        description.inverseRelationship = inverseRelationshipDescription

                        inverseRelationshipDescription.inverseRelationship = description
                        inverseRelationshipDescription.destinationEntity = entityDescription

                        description.destinationEntity!.properties = description.destinationEntity!.properties
                    }
                    
                case let relationship as RelationshipProtocol:
                    let (destinationType, destinationKeyPath) = relationship.entityDescriptionValues().inverse
                    let destinationEntity = findEntity(for: destinationType)
                    let description = relationshipsByName[relationship.keyPath]!
                    description.destinationEntity = entityDescriptionsByEntity[destinationEntity]!
                    
                    if let destinationKeyPath = destinationKeyPath {
                        
                        let inverseRelationshipDescription = findInverseRelationshipMatching(
                            destinationEntity: destinationEntity,
                            destinationKeyPath: destinationKeyPath
                        )
                        description.inverseRelationship = inverseRelationshipDescription
                        
                        inverseRelationshipDescription.inverseRelationship = description
                        inverseRelationshipDescription.destinationEntity = entityDescription
                        
                        description.destinationEntity!.properties = description.destinationEntity!.properties
                    }
                    
                default:
                    continue
                }
            }
        }
        for (entity, entityDescription) in entityDescriptionsByEntity {
            
            for (name, relationshipDescription) in entityDescription.relationshipsByName {
                
                Internals.assert(
                    relationshipDescription.destinationEntity != nil,
                    "The destination entity for relationship \"\(entity.type).\(name)\" could not be resolved."
                )
                Internals.assert(
                    relationshipDescription.inverseRelationship != nil,
                    "The inverse relationship for \"\(entity.type).\(name)\" could not be found. Make sure to set the `inverse:` argument of the initializer for one of the paired \(Internals.typeName("Relationship.ToOne<T>")), \(Internals.typeName("Relationship.ToManyOrdered<T>")), or \(Internals.typeName("Relationship.ToManyUnozrdered<T>"))"
                )
            }
        }
    }
    
    private static func thirdPassConnectInheritanceTreeAndIndexes(
        for entityDescriptionsByEntity: [DynamicEntity: NSEntityDescription]
    ) {

        func connectBaseEntity(
            mirror: Mirror,
            entityDescription: NSEntityDescription
        ) {

            guard let superclassMirror = mirror.superclassMirror,
                let superType = superclassMirror.subjectType as? CoreStoreObject.Type,
                superType != CoreStoreObject.self else {
                    
                    return
            }
            for (superEntity, superEntityDescription) in entityDescriptionsByEntity where superEntity.type == superType {
                
                if !superEntityDescription.subentities.contains(entityDescription) {
                    
                    superEntityDescription.subentities.append(entityDescription)
                }
                connectBaseEntity(mirror: superclassMirror, entityDescription: superEntityDescription)
            }
        }
        for (entity, entityDescription) in entityDescriptionsByEntity {
            
            connectBaseEntity(
                mirror: Mirror(reflecting: (entity.type as! CoreStoreObject.Type).meta),
                entityDescription: entityDescription
            )
        }
        for (entity, entityDescription) in entityDescriptionsByEntity {
            
            if entity.uniqueConstraints.contains(where: { !$0.isEmpty }) {

                Internals.assert(
                    entityDescription.superentity == nil,
                    "Uniqueness constraints must be defined at the highest level possible."
                )
                entityDescription.uniquenessConstraints = entity.uniqueConstraints.map { $0.map { $0 as NSString } }
            }
            guard !entity.indexes.isEmpty else {
                
                continue
            }
            defer {
                
                entityDescription.coreStoreEntity = entity // reserialize
            }
            let attributesByName = entityDescription.attributesByName
            entityDescription.indexes = entity.indexes.map { (compoundIndexes) in
                
                return NSFetchIndexDescription.init(
                    name: "_CoreStoreSchema_indexes_\(entityDescription.name!)_\(compoundIndexes.joined(separator: "_"))",
                    elements: compoundIndexes.map { (keyPath) in
                        
                        return NSFetchIndexElementDescription(
                            property: attributesByName[keyPath]!,
                            collationType: .binary
                        )
                    }
                )
            }
        }
    }
    
    private static func fourthPassSynthesizeManagedObjectClasses(
        for entityDescriptionsByEntity: [DynamicEntity: NSEntityDescription],
        allCustomGettersSetters: [DynamicEntity: [KeyPathString: CoreStoreManagedObject.CustomGetterSetter]],
        allCustomInitializers: [DynamicEntity: [KeyPathString: CoreStoreManagedObject.CustomInitializer]],
        allFieldCoders: [DynamicEntity: [KeyPathString: Internals.AnyFieldCoder]]
    ) {
        
        func createManagedObjectSubclass(
            for entityDescription: NSEntityDescription,
            customGetterSetterByKeyPaths: [KeyPathString: CoreStoreManagedObject.CustomGetterSetter]?,
            customInitializers: [KeyPathString: CoreStoreManagedObject.CustomInitializer]?
        ) {
            
            let superEntity = entityDescription.superentity
            let className = entityDescription.managedObjectClassName!
            guard case nil = NSClassFromString(className) as! CoreStoreManagedObject.Type? else {
                
                return
            }
            if let superEntity = superEntity {
                
                createManagedObjectSubclass(
                    for: superEntity,
                    customGetterSetterByKeyPaths: superEntity.coreStoreEntity.flatMap({ allCustomGettersSetters[$0] }),
                    customInitializers: superEntity.coreStoreEntity.flatMap({ allCustomInitializers[$0] })
                )
            }
            let superClass = Internals.with { () -> CoreStoreManagedObject.Type in
                
                if let superClassName = superEntity?.managedObjectClassName,
                    let superClass = NSClassFromString(superClassName) {
                    
                    return superClass as! CoreStoreManagedObject.Type
                }
                return CoreStoreManagedObject.self
            }
            let managedObjectClass: AnyClass = className.withCString {

                return objc_allocateClassPair(superClass, $0, 0)!
            }
            defer {
            
                objc_registerClassPair(managedObjectClass)
            }
            
            func capitalize(_ string: String) -> String {
                
                return string.replacingCharacters(
                    in: Range(uncheckedBounds: (string.startIndex, string.index(after: string.startIndex))),
                    with: String(string[string.startIndex]).uppercased()
                )
            }
            for (attributeName, customGetterSetters) in (customGetterSetterByKeyPaths ?? [:])
                where customGetterSetters.getter != nil || customGetterSetters.setter != nil {
                    
                    if let getter = customGetterSetters.getter {
                        
                        let getterName = "\(attributeName)"
                        guard class_addMethod(
                            managedObjectClass,
                            NSSelectorFromString(getterName),
                            imp_implementationWithBlock(getter),
                            "@@:") else {
                                
                                Internals.abort("Could not dynamically add getter method \"\(getterName)\" to class \(Internals.typeName(managedObjectClass))")
                        }
                    }
                    if let setter = customGetterSetters.setter {
                        
                        let setterName = "set\(capitalize(attributeName)):"
                        guard class_addMethod(
                            managedObjectClass,
                            NSSelectorFromString(setterName),
                            imp_implementationWithBlock(setter),
                            "v@:@") else {
                                
                                Internals.abort("Could not dynamically add setter method \"\(setterName)\" to class \(Internals.typeName(managedObjectClass))")
                        }
                    }
            }
            swizzle_keyPathsForValuesAffectingValueForKey: do {

                let newSelector = NSSelectorFromString("cs_keyPathsForValuesAffectingValueForKey:")
                let keyPathsByAffectedKeyPaths = entityDescription.keyPathsByAffectedKeyPaths
                let keyPathsForValuesAffectingValue: @convention(block) (Any, String) -> Set<String> = { (instance, keyPath) in
                    
                    if let keyPaths = keyPathsByAffectedKeyPaths[keyPath] {
                        
                        return keyPaths
                    }
                    return []
                }
                let origSelector = #selector(CoreStoreManagedObject.keyPathsForValuesAffectingValue(forKey:))
                
                let metaClass: AnyClass = object_getClass(managedObjectClass)!
                let origMethod = class_getClassMethod(managedObjectClass, origSelector)!
                
                let origImp = method_getImplementation(origMethod)
                let newImp = imp_implementationWithBlock(keyPathsForValuesAffectingValue)
                
                if class_addMethod(metaClass, origSelector, newImp, method_getTypeEncoding(origMethod)) {
                    
                    class_replaceMethod(metaClass, newSelector, origImp, method_getTypeEncoding(origMethod))
                }
                else {
                    
                    let newMethod = class_getClassMethod(managedObjectClass, newSelector)!
                    method_exchangeImplementations(origMethod, newMethod)
                }
            }
            swizzle_awakeFromInsert: do {

                let newSelector = NSSelectorFromString("cs_awakeFromInsert")
                let awakeFromInsertValue: @convention(block) (Any) -> Void
                if let customInitializers = customInitializers,
                    !customInitializers.isEmpty {
                    
                    let initializers = Array(customInitializers.values)
                    awakeFromInsertValue = { (instance) in
                        
                        initializers.forEach {
                            
                            $0(instance)
                        }
                    }
                }
                else {
                    
                    awakeFromInsertValue = { _ in }
                }
                let origSelector = #selector(CoreStoreManagedObject.awakeFromInsert)
                
                let origMethod = class_getInstanceMethod(managedObjectClass, origSelector)!
                
                let origImp = method_getImplementation(origMethod)
                let newImp = imp_implementationWithBlock(awakeFromInsertValue)
                
                if class_addMethod(managedObjectClass, origSelector, newImp, method_getTypeEncoding(origMethod)) {
                    
                    class_replaceMethod(managedObjectClass, newSelector, origImp, method_getTypeEncoding(origMethod))
                }
                else {
                    
                    let newMethod = class_getInstanceMethod(managedObjectClass, newSelector)!
                    method_exchangeImplementations(origMethod, newMethod)
                }
            }
        }
        for (dynamicEntity, entityDescription) in entityDescriptionsByEntity {
            
            createManagedObjectSubclass(
                for: entityDescription,
                customGetterSetterByKeyPaths: allCustomGettersSetters[dynamicEntity],
                customInitializers: allCustomInitializers[dynamicEntity]
            )
        }

        allFieldCoders
            .flatMap({ (_, values) in values })
            .reduce(
                into: [:] as [NSValueTransformerName: Internals.AnyFieldCoder],
                { (result, element) in result[element.value.transformerName] = element.value }
            )
            .forEach({ (_, fieldCoder) in fieldCoder.register() })
    }
}
