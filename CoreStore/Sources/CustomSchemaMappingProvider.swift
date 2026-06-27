//
//  CustomSchemaMappingProvider.swift
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


// MARK: - CustomSchemaMappingProvider

/**
 A `SchemaMappingProvider` that accepts custom mappings for some entities. Mappings of entities with no `CustomMapping` provided will be automatically calculated if possible.
 */
public class CustomSchemaMappingProvider: Hashable, SchemaMappingProvider {
    
    /**
     The source model version for the mapping.
     */
    public let sourceVersion: ModelVersion
    
    /**
     The destination model version for the mapping.
     */
    public let destinationVersion: ModelVersion
    
    /**
     Creates a `CustomSchemaMappingProvider`
     
     - parameter sourceVersion: the source model version for the mapping
     - parameter destinationVersion: the destination model version for the mapping
     - parameter entityMappings: a list of `CustomMapping`s. Mappings of entities with no `CustomMapping` provided will be automatically calculated if possible. Any conflicts or ambiguity will raise an assertion.
     */
    public required init(
        from sourceVersion: ModelVersion,
        to destinationVersion: ModelVersion,
        entityMappings: Set<CustomMapping> = []
    ) {

        Internals.assert(
            Internals.with {
                
                let sources = entityMappings.compactMap({ $0.entityMappingSourceEntity })
                let destinations = entityMappings.compactMap({ $0.entityMappingDestinationEntity })
                return sources.count == Set(sources).count
                    && destinations.count == Set(destinations).count
            },
            "Duplicate source/destination entities found in provided \"entityMappings\" argument."
        )
        self.sourceVersion = sourceVersion
        self.destinationVersion = destinationVersion
        self.entityMappings = entityMappings
    }
    
    
    // MARK: - CustomMapping
    
    /**
     Provides the type of mapping for an entity. Mappings of entities with no `CustomMapping` provided will be automatically calculated if possible. Any conflicts or ambiguity will raise an assertion.
     */
    public enum CustomMapping: Hashable {
        
        /**
         The `sourceEntity` is meant to be removed from the source `DynamicSchema` and should not be migrated to the destination `DynamicSchema`.
         */
        case deleteEntity(sourceEntity: EntityName)
        
        /**
         The `destinationEntity` is newly added to the destination `DynamicSchema` and has no mapping from the source `DynamicSchema`.
         */
        case insertEntity(destinationEntity: EntityName)
        
        /**
         The `DynamicSchema`s entity has no changes and can be copied directly from `sourceEntity` to `destinationEntity`.
         */
        case copyEntity(sourceEntity: EntityName, destinationEntity: EntityName)
        
        /**
         The `DynamicSchema`s entity needs transformations from `sourceEntity` to `destinationEntity`. The `transformer` closure will be used to apply the changes. The `CustomMapping.inferredTransformation` method can be used directly as the `transformer` if the changes can be inferred (i.e. lightweight).
         */
        case transformEntity(sourceEntity: EntityName, destinationEntity: EntityName, transformer: Transformer)
        
        /**
         The closure type for `CustomMapping.transformEntity`.
         - parameter sourceObject: a proxy object representing the source entity. The properties can be accessed via keyPath.
         - parameter createDestinationObject: the closure to create the object for the destination entity. The `CustomMapping.inferredTransformation` method can be used directly as the `transformer` if the changes can be inferred (i.e. lightweight). The object is created lazily and executing the closure multiple times will return the same instance. The destination object's properties can be accessed and updated via keyPath.
         */
        public typealias Transformer = (
            _ sourceObject: UnsafeSourceObject,
            _ createDestinationObject: () -> UnsafeDestinationObject
        ) throws(any Swift.Error) -> Void

        /**
         The `CustomMapping.inferredTransformation` method can be used directly as the `transformer` if the changes can be inferred (i.e. lightweight).
         */
        public static func inferredTransformation(
            _ sourceObject: UnsafeSourceObject,
            _ createDestinationObject: () -> UnsafeDestinationObject
        ) throws(any Swift.Error) {

            let destinationObject = createDestinationObject()
            destinationObject.enumerateAttributes { (attribute, sourceAttribute) in
                
                if let sourceAttribute = sourceAttribute {
                    
                    destinationObject[attribute] = sourceObject[sourceAttribute]
                }
            }
        }
        
        
        // MARK: Equatable
        
        public static func == (lhs: CustomMapping, rhs: CustomMapping) -> Bool {
            
            switch (lhs, rhs) {
            
            case (.deleteEntity(let sourceEntity1), .deleteEntity(let sourceEntity2)):
                return sourceEntity1 == sourceEntity2
            
            case (.insertEntity(let destinationEntity1), .insertEntity(let destinationEntity2)):
                return destinationEntity1 == destinationEntity2
            
            case (.copyEntity(let sourceEntity1, let destinationEntity1), .copyEntity(let sourceEntity2, let destinationEntity2)):
                return sourceEntity1 == sourceEntity2
                    && destinationEntity1 == destinationEntity2
            
            case (.transformEntity(let sourceEntity1, let destinationEntity1, _), .transformEntity(let sourceEntity2, let destinationEntity2, _)):
                return sourceEntity1 == sourceEntity2
                    && destinationEntity1 == destinationEntity2
            
            default:
                return false
            }
        }
        
        
        // MARK: Hashable
        
        public func hash(into hasher: inout Hasher) {
            
            switch self {
            
            case .deleteEntity(let sourceEntity):
                hasher.combine(0)
                hasher.combine(sourceEntity)
            
            case .insertEntity(let destinationEntity):
                hasher.combine(1)
                hasher.combine(destinationEntity)
            
            case .copyEntity(let sourceEntity, let destinationEntity):
                hasher.combine(2)
                hasher.combine(sourceEntity)
                hasher.combine(destinationEntity)
            
            case .transformEntity(let sourceEntity, let destinationEntity, _):
                hasher.combine(3)
                hasher.combine(sourceEntity)
                hasher.combine(destinationEntity)
            }
        }
        
        
        // MARK: FilePrivate
        
        fileprivate var entityMappingSourceEntity: EntityName? {
            
            switch self {
            
            case .deleteEntity(let sourceEntity),
                 .copyEntity(let sourceEntity, _),
                 .transformEntity(let sourceEntity, _, _):
                return sourceEntity
            
            case .insertEntity:
                return nil
            }
        }
        
        fileprivate var entityMappingDestinationEntity: EntityName? {
            
            switch self {
            
            case .insertEntity(let destinationEntity),
                 .copyEntity(_, let destinationEntity),
                 .transformEntity(_, let destinationEntity, _):
                return destinationEntity
            
            case .deleteEntity:
                return nil
            }
        }
    }
    
    
    // MARK: - UnsafeSourceObject
    
    /**
     The read-only proxy object used for the source object in a mapping's `Transformer` closure. Properties can be accessed either by keyPath string or by `NSAttributeDescription`.
     */
    public final class UnsafeSourceObject {
        
        /**
         Accesses the property value via its keyPath.
         */
        public subscript(attribute: KeyPathString) -> Any? {
            
            return self.rawObject.getValue(forKvcKey: attribute)
        }
        
        /**
         Accesses the property value via its `NSAttributeDescription`, which can be accessed from the `enumerateAttributes(_:)` method.
         */
        public subscript(attribute: NSAttributeDescription) -> Any? {
            
            return self.rawObject.getValue(forKvcKey: attribute.name)
        }
        
        /**
         Enumerates the all `NSAttributeDescription`s. The `attribute` argument can be used as the subscript key to access the property.
         */
        public func enumerateAttributes(_ closure: (_ attribute: NSAttributeDescription) -> Void) {
            
            func enumerate(_ entity: NSEntityDescription, _ closure: (NSAttributeDescription) -> Void) {
                
                if let superEntity = entity.superentity {
                    
                    enumerate(superEntity, closure)
                }
                for case let attribute as NSAttributeDescription in entity.properties {
                    
                    closure(attribute)
                }
            }
            enumerate(self.rawObject.entity, closure)
        }
        
        
        // MARK: Internal
        
        internal init(_ rawObject: NSManagedObject) {
            
            self.rawObject = rawObject
        }
        
        
        // MARK: Private
        
        private let rawObject: NSManagedObject
    }
    
    
    // MARK: - UnsafeDestinationObject
    
    /**
     The read-write proxy object used for the destination object that can be created in a mapping's `Transformer` closure. Properties can be accessed and mutated either through keyPath string or by `NSAttributeDescription`.
     */
    public final class UnsafeDestinationObject {
        
        /**
         Accesses or mutates the property value via its keyPath.
         */
        public subscript(attribute: KeyPathString) -> Any? {
            
            get { return self.rawObject.getValue(forKvcKey: attribute) }
            set { self.rawObject.setValue(newValue, forKvcKey: attribute) }
        }
        
        /**
         Accesses or mutates the property value via its `NSAttributeDescription`, which can be accessed from the `enumerateAttributes(_:)` method.
         */
        public subscript(attribute: NSAttributeDescription) -> Any? {
            
            get { return self.rawObject.getValue(forKvcKey: attribute.name) }
            set { self.rawObject.setValue(newValue, forKvcKey: attribute.name) }
        }
        
        /**
         Enumerates the all `NSAttributeDescription`s. The `attribute` argument can be used as the subscript key to access and mutate the property. The `sourceAttribute` can be used to access properties from the source `UnsafeSourceObject`.
         */
        public func enumerateAttributes(_ closure: (_ attribute: NSAttributeDescription, _ sourceAttribute: NSAttributeDescription?) -> Void) {
            
            func enumerate(_ entity: NSEntityDescription, _ closure: (_ attribute: NSAttributeDescription, _ sourceAttribute: NSAttributeDescription?) -> Void) {
                
                if let superEntity = entity.superentity {
                    
                    enumerate(superEntity, closure)
                }
                for case let attribute as NSAttributeDescription in entity.properties {
                    
                    closure(attribute, self.sourceAttributesByDestinationKey[attribute.name])
                }
            }
            enumerate(self.rawObject.entity, closure)
        }
        
        
        // MARK: Internal
        
        internal init(_ rawObject: NSManagedObject, _ sourceAttributesByDestinationKey: [KeyPathString: NSAttributeDescription]) {
            
            self.rawObject = rawObject
            self.sourceAttributesByDestinationKey = sourceAttributesByDestinationKey
        }
        
        
        // MARK: FilePrivate
        
        fileprivate let rawObject: NSManagedObject
        fileprivate let sourceAttributesByDestinationKey: [KeyPathString: NSAttributeDescription]
    }
    
    
    // MARK: Equatable
    
    public static func == (lhs: CustomSchemaMappingProvider, rhs: CustomSchemaMappingProvider) -> Bool {
        
        return lhs.sourceVersion == rhs.sourceVersion
            && lhs.destinationVersion == rhs.destinationVersion
    }
    
    
    // MARK: Hashable
    
    public func hash(into hasher: inout Hasher) {
        
        hasher.combine(self.sourceVersion)
        hasher.combine(self.destinationVersion)
        hasher.combine(ObjectIdentifier(Self.self))
    }
    
    
    // MARK: SchemaMappingProvider
    
    public func cs_createMappingModel(
        from sourceSchema: DynamicSchema,
        to destinationSchema: DynamicSchema,
        storage: LocalStorage
    ) throws(CoreStoreError) -> (
        mappingModel: NSMappingModel,
        migrationType: MigrationType
    ) {

        let sourceModel = sourceSchema.rawModel()
        let destinationModel = destinationSchema.rawModel()
        
        let mappingModel = NSMappingModel()
        
        let (deleteMappings, insertMappings, copyMappings, transformMappings) = self.resolveEntityMappings(
            sourceModel: sourceModel,
            destinationModel: destinationModel
        )
        func expression(forSource sourceEntity: NSEntityDescription) -> NSExpression {
            
            return NSExpression(format: "FETCH(FUNCTION($\(NSMigrationManagerKey), \"fetchRequestForSourceEntityNamed:predicateString:\" , \"\(sourceEntity.name!)\", \"\(NSPredicate(value: true))\"), FUNCTION($\(NSMigrationManagerKey), \"\(#selector(getter: NSMigrationManager.sourceContext))\"), \(false))")
        }
        
        let sourceEntitiesByName = sourceModel.entitiesByName
        let destinationEntitiesByName = destinationModel.entitiesByName
        
        var entityMappings: [NSEntityMapping] = []
        for case .deleteEntity(let sourceEntityName) in deleteMappings {
            
            let sourceEntity = sourceEntitiesByName[sourceEntityName]!
            
            let entityMapping = NSEntityMapping()
            entityMapping.sourceEntityName = sourceEntity.name
            entityMapping.sourceEntityVersionHash = sourceEntity.versionHash
            entityMapping.mappingType = .removeEntityMappingType
            entityMapping.sourceExpression = expression(forSource: sourceEntity)
            
            entityMappings.append(entityMapping)
        }
        for case .insertEntity(let destinationEntityName) in insertMappings {
            
            let destinationEntity = destinationEntitiesByName[destinationEntityName]!
            
            let entityMapping = NSEntityMapping()
            entityMapping.destinationEntityName = destinationEntity.name
            entityMapping.destinationEntityVersionHash = destinationEntity.versionHash
            entityMapping.mappingType = .addEntityMappingType
            entityMapping.attributeMappings = autoreleasepool { () -> [NSPropertyMapping] in
                
                var attributeMappings: [NSPropertyMapping] = []
                for (_, destinationAttribute) in destinationEntity.attributesByName {
                    
                    let propertyMapping = NSPropertyMapping()
                    propertyMapping.name = destinationAttribute.name
                    attributeMappings.append(propertyMapping)
                }
                return attributeMappings
            }
            entityMapping.relationshipMappings = autoreleasepool { () -> [NSPropertyMapping] in
                
                var relationshipMappings: [NSPropertyMapping] = []
                for (_, destinationRelationship) in destinationEntity.relationshipsByName {
                    
                    let propertyMapping = NSPropertyMapping()
                    propertyMapping.name = destinationRelationship.name
                    relationshipMappings.append(propertyMapping)
                }
                return relationshipMappings
            }
            entityMappings.append(entityMapping)
        }
        for case .copyEntity(let sourceEntityName, let destinationEntityName) in copyMappings {
            
            let sourceEntity = sourceEntitiesByName[sourceEntityName]!
            let destinationEntity = destinationEntitiesByName[destinationEntityName]!
            
            let entityMapping = NSEntityMapping()
            entityMapping.sourceEntityName = sourceEntity.name
            entityMapping.sourceEntityVersionHash = sourceEntity.versionHash
            entityMapping.destinationEntityName = destinationEntity.name
            entityMapping.destinationEntityVersionHash = destinationEntity.versionHash
            entityMapping.mappingType = .copyEntityMappingType
            entityMapping.sourceExpression = expression(forSource: sourceEntity)
            entityMapping.attributeMappings = autoreleasepool { () -> [NSPropertyMapping] in
                
                let sourceAttributes = sourceEntity.cs_resolveAttributeNames()
                let destinationAttributes = destinationEntity.cs_resolveAttributeRenamingIdentities()
                
                var attributeMappings: [NSPropertyMapping] = []
                for (renamingIdentifier, destination) in destinationAttributes {
                    
                    let sourceAttribute = sourceAttributes[renamingIdentifier]!.attribute
                    let destinationAttribute = destination.attribute
                    let propertyMapping = NSPropertyMapping()
                    propertyMapping.name = destinationAttribute.name
                    propertyMapping.valueExpression = NSExpression(format: "FUNCTION($\(NSMigrationSourceObjectKey), \"\(#selector(NSManagedObject.value(forKey:)))\", \"\(sourceAttribute.name)\")")
                    attributeMappings.append(propertyMapping)
                }
                return attributeMappings
            }
            entityMapping.relationshipMappings = autoreleasepool { () -> [NSPropertyMapping] in
                
                let sourceRelationships = sourceEntity.cs_resolveRelationshipNames()
                let destinationRelationships = destinationEntity.cs_resolveRelationshipRenamingIdentities()
                var relationshipMappings: [NSPropertyMapping] = []
                for (renamingIdentifier, destination) in destinationRelationships {
                    
                    let sourceRelationship = sourceRelationships[renamingIdentifier]!.relationship
                    let destinationRelationship = destination.relationship
                    let sourceRelationshipName = sourceRelationship.name
                    
                    let propertyMapping = NSPropertyMapping()
                    propertyMapping.name = destinationRelationship.name
                    propertyMapping.valueExpression = NSExpression(format: "FUNCTION($\(NSMigrationManagerKey), \"destinationInstancesForSourceRelationshipNamed:sourceInstances:\", \"\(sourceRelationshipName)\", FUNCTION($\(NSMigrationSourceObjectKey), \"\(#selector(NSManagedObject.value(forKey:)))\", \"\(sourceRelationshipName)\"))")
                    relationshipMappings.append(propertyMapping)
                }
                return relationshipMappings
            }
            entityMappings.append(entityMapping)
        }
        for case .transformEntity(let sourceEntityName, let destinationEntityName, let transformEntity) in transformMappings {
            
            let sourceEntity = sourceEntitiesByName[sourceEntityName]!
            let destinationEntity = destinationEntitiesByName[destinationEntityName]!
            
            let entityMapping = NSEntityMapping()
            entityMapping.sourceEntityName = sourceEntity.name
            entityMapping.sourceEntityVersionHash = sourceEntity.versionHash
            entityMapping.destinationEntityName = destinationEntity.name
            entityMapping.destinationEntityVersionHash = destinationEntity.versionHash
            entityMapping.mappingType = .customEntityMappingType
            entityMapping.sourceExpression = expression(forSource: sourceEntity)
            entityMapping.entityMigrationPolicyClassName = NSStringFromClass(CustomEntityMigrationPolicy.self)
            
            var userInfo: [AnyHashable: Any] = [
                CustomEntityMigrationPolicy.UserInfoKey.transformer: transformEntity
            ]
            autoreleasepool {
                
                let sourceAttributes = sourceEntity.cs_resolveAttributeNames()
                let destinationAttributes = destinationEntity.cs_resolveAttributeRenamingIdentities()
                
                let transformedRenamingIdentifiers = Set(destinationAttributes.keys)
                    .intersection(sourceAttributes.keys)
                
                var sourceAttributesByDestinationKey: [KeyPathString: NSAttributeDescription] = [:]
                for renamingIdentifier in transformedRenamingIdentifiers {
                    
                    let sourceAttribute = sourceAttributes[renamingIdentifier]!.attribute
                    let destinationAttribute = destinationAttributes[renamingIdentifier]!.attribute
                    sourceAttributesByDestinationKey[destinationAttribute.name] = sourceAttribute
                }
                userInfo[CustomEntityMigrationPolicy.UserInfoKey.sourceAttributesByDestinationKey] = sourceAttributesByDestinationKey
            }
            entityMapping.relationshipMappings = autoreleasepool { () -> [NSPropertyMapping] in
                
                let sourceRelationships = sourceEntity.cs_resolveRelationshipNames()
                let destinationRelationships = destinationEntity.cs_resolveRelationshipRenamingIdentities()
                let transformedRenamingIdentifiers = Set(destinationRelationships.keys)
                    .intersection(sourceRelationships.keys)
                
                var relationshipMappings: [NSPropertyMapping] = []
                for renamingIdentifier in transformedRenamingIdentifiers {
                    
                    let sourceRelationship = sourceRelationships[renamingIdentifier]!.relationship
                    let destinationRelationship = destinationRelationships[renamingIdentifier]!.relationship
                    let sourceRelationshipName = sourceRelationship.name
                    let destinationRelationshipName = destinationRelationship.name
                    
                    let propertyMapping = NSPropertyMapping()
                    propertyMapping.name = destinationRelationshipName
                    propertyMapping.valueExpression = NSExpression(format: "FUNCTION($\(NSMigrationManagerKey), \"destinationInstancesForSourceRelationshipNamed:sourceInstances:\", \"\(sourceRelationshipName)\", FUNCTION($\(NSMigrationSourceObjectKey), \"\(#selector(NSManagedObject.value(forKey:)))\", \"\(sourceRelationshipName)\"))")
                    relationshipMappings.append(propertyMapping)
                }
                return relationshipMappings
            }
            entityMapping.userInfo = userInfo
            entityMappings.append(entityMapping)
        }
        
        mappingModel.entityMappings = entityMappings
        return (
            mappingModel,
            .heavyweight(
                sourceVersion: self.sourceVersion,
                destinationVersion: self.destinationVersion
            )
        )
    }
    
    
    // MARK: Private
    
    // MARK: - CustomEntityMigrationPolicy
    
    private final class CustomEntityMigrationPolicy: NSEntityMigrationPolicy {
        
        // MARK: NSEntityMigrationPolicy
        
        override func createDestinationInstances(
            forSource sInstance: NSManagedObject,
            in mapping: NSEntityMapping,
            manager: NSMigrationManager
        ) throws(any Swift.Error) {

            let userInfo = mapping.userInfo!
            let transformer = userInfo[CustomEntityMigrationPolicy.UserInfoKey.transformer]! as! CustomMapping.Transformer
            let sourceAttributesByDestinationKey = userInfo[CustomEntityMigrationPolicy.UserInfoKey.sourceAttributesByDestinationKey] as! [KeyPathString: NSAttributeDescription]
            
            var destinationObject: UnsafeDestinationObject?
            try transformer(
                UnsafeSourceObject(sInstance),
                {
                    if let destinationObject = destinationObject {
                        
                        return destinationObject
                    }
                    let rawObject = NSEntityDescription.insertNewObject(
                        forEntityName: mapping.destinationEntityName!,
                        into: manager.destinationContext
                    )
                    destinationObject = UnsafeDestinationObject(rawObject, sourceAttributesByDestinationKey)
                    return destinationObject!
                }
            )
            if let dInstance = destinationObject?.rawObject {
                
                manager.associate(sourceInstance: sInstance, withDestinationInstance: dInstance, for: mapping)
            }
        }
        
        override func createRelationships(
            forDestination dInstance: NSManagedObject,
            in mapping: NSEntityMapping,
            manager: NSMigrationManager
        ) throws(any Swift.Error) {

            try super.createRelationships(forDestination: dInstance, in: mapping, manager: manager)
        }
        
        
        // MARK: FilePrivate
        
        fileprivate enum UserInfoKey {
            
            fileprivate static let transformer = "CoreStore.CustomEntityMigrationPolicy.transformer"
            fileprivate static let sourceAttributesByDestinationKey = "CoreStore.CustomEntityMigrationPolicy.sourceAttributesByDestinationKey"
        }
    }
    
    
    // MARK: -
    
    private let entityMappings: Set<CustomMapping>
    
    private func resolveEntityMappings(
        sourceModel: NSManagedObjectModel,
        destinationModel: NSManagedObjectModel
    ) -> (
        delete: Set<CustomMapping>,
        insert: Set<CustomMapping>,
        copy: Set<CustomMapping>,
        transform: Set<CustomMapping>
    ) {

        var deleteMappings: Set<CustomMapping> = []
        var insertMappings: Set<CustomMapping> = []
        var copyMappings: Set<CustomMapping> = []
        var transformMappings: Set<CustomMapping> = []
        var allMappedSourceKeys: [KeyPathString: KeyPathString] = [:]
        var allMappedDestinationKeys: [KeyPathString: KeyPathString] = [:]
        
        let sourceRenamingIdentifiers = sourceModel.cs_resolveNames()
        let sourceEntityNames = sourceModel.entitiesByName
        let destinationRenamingIdentifiers = destinationModel.cs_resolveRenamingIdentities()
        let destinationEntityNames = destinationModel.entitiesByName
        
        let removedRenamingIdentifiers = Set(sourceRenamingIdentifiers.keys)
            .subtracting(destinationRenamingIdentifiers.keys)
        let addedRenamingIdentifiers = Set(destinationRenamingIdentifiers.keys)
            .subtracting(sourceRenamingIdentifiers.keys)
        let transformedRenamingIdentifiers = Set(destinationRenamingIdentifiers.keys)
            .subtracting(addedRenamingIdentifiers)
            .subtracting(removedRenamingIdentifiers)
        
        // First pass: resolve source-destination entities
        for mapping in self.entityMappings {
            
            switch mapping {
            
            case .deleteEntity(let sourceEntity):
                Internals.assert(
                    sourceEntityNames[sourceEntity] != nil,
                    "A \(Internals.typeName(CustomMapping.self)) with value '\(mapping)' passed to \(Internals.typeName(CustomSchemaMappingProvider.self)) could not be mapped to any \(Internals.typeName(NSEntityDescription.self)) from the source \(Internals.typeName(NSManagedObjectModel.self))."
                )
                Internals.assert(
                    allMappedSourceKeys[sourceEntity] == nil,
                    "Duplicate \(Internals.typeName(CustomMapping.self))s found for source entity name \"\(sourceEntity)\" in \(Internals.typeName(CustomSchemaMappingProvider.self))."
                )
                deleteMappings.insert(mapping)
                allMappedSourceKeys[sourceEntity] = ""
            
            case .insertEntity(let destinationEntity):
                Internals.assert(
                    destinationEntityNames[destinationEntity] != nil,
                    "A \(Internals.typeName(CustomMapping.self)) with value '\(mapping)' passed to \(Internals.typeName(CustomSchemaMappingProvider.self)) could not be mapped to any \(Internals.typeName(NSEntityDescription.self)) from the destination \(Internals.typeName(NSManagedObjectModel.self))."
                )
                Internals.assert(
                    allMappedDestinationKeys[destinationEntity] == nil,
                    "Duplicate \(Internals.typeName(CustomMapping.self))s found for destination entity name \"\(destinationEntity)\" in \(Internals.typeName(CustomSchemaMappingProvider.self))."
                )
                insertMappings.insert(mapping)
                allMappedDestinationKeys[destinationEntity] = ""
            
            case .transformEntity(let sourceEntity, let destinationEntity, _):
                Internals.assert(
                    sourceEntityNames[sourceEntity] != nil,
                    "A \(Internals.typeName(CustomMapping.self)) with value '\(mapping)' passed to \(Internals.typeName(CustomSchemaMappingProvider.self)) could not be mapped to any \(Internals.typeName(NSEntityDescription.self)) from the source \(Internals.typeName(NSManagedObjectModel.self))."
                )
                Internals.assert(
                    destinationEntityNames[destinationEntity] != nil,
                    "A \(Internals.typeName(CustomMapping.self)) with value '\(mapping)' passed to \(Internals.typeName(CustomSchemaMappingProvider.self)) could not be mapped to any \(Internals.typeName(NSEntityDescription.self)) from the destination \(Internals.typeName(NSManagedObjectModel.self))."
                )
                Internals.assert(
                    allMappedSourceKeys[sourceEntity] == nil,
                    "Duplicate \(Internals.typeName(CustomMapping.self))s found for source entity name \"\(sourceEntity)\" in \(Internals.typeName(CustomSchemaMappingProvider.self))."
                )
                Internals.assert(
                    allMappedDestinationKeys[destinationEntity] == nil,
                    "Duplicate \(Internals.typeName(CustomMapping.self))s found for destination entity name \"\(destinationEntity)\" in \(Internals.typeName(CustomSchemaMappingProvider.self))."
                )
                transformMappings.insert(mapping)
                allMappedSourceKeys[sourceEntity] = destinationEntity
                allMappedDestinationKeys[destinationEntity] = sourceEntity
            
            case .copyEntity(let sourceEntity, let destinationEntity):
                Internals.assert(
                    sourceEntityNames[sourceEntity] != nil,
                    "A \(Internals.typeName(CustomMapping.self)) with value '\(mapping)' passed to \(Internals.typeName(CustomSchemaMappingProvider.self)) could not be mapped to any \(Internals.typeName(NSEntityDescription.self)) from the source \(Internals.typeName(NSManagedObjectModel.self))."
                )
                Internals.assert(
                    destinationEntityNames[destinationEntity] != nil,
                    "A \(Internals.typeName(CustomMapping.self)) with value '\(mapping)' passed to \(Internals.typeName(CustomSchemaMappingProvider.self)) could not be mapped to any \(Internals.typeName(NSEntityDescription.self)) from the destination \(Internals.typeName(NSManagedObjectModel.self))."
                )
                Internals.assert(
                    sourceEntityNames[sourceEntity]!.versionHash == destinationEntityNames[destinationEntity]!.versionHash,
                    "A \(Internals.typeName(CustomMapping.self)) with value '\(mapping)' was passed to \(Internals.typeName(CustomSchemaMappingProvider.self)) but the \(Internals.typeName(NSEntityDescription.self))'s \"versionHash\" of the source and destination entities do not match."
                )
                Internals.assert(
                    allMappedSourceKeys[sourceEntity] == nil,
                    "Duplicate \(Internals.typeName(CustomMapping.self))s found for source entity name \"\(sourceEntity)\" in \(Internals.typeName(CustomSchemaMappingProvider.self))."
                )
                Internals.assert(
                    allMappedDestinationKeys[destinationEntity] == nil,
                    "Duplicate \(Internals.typeName(CustomMapping.self))s found for destination entity name \"\(destinationEntity)\" in \(Internals.typeName(CustomSchemaMappingProvider.self))."
                )
                copyMappings.insert(mapping)
                allMappedSourceKeys[sourceEntity] = destinationEntity
                allMappedDestinationKeys[destinationEntity] = sourceEntity
            }
        }
        for renamingIdentifier in transformedRenamingIdentifiers {
            
            let sourceEntity = sourceRenamingIdentifiers[renamingIdentifier]!.entity
            let destinationEntity = destinationRenamingIdentifiers[renamingIdentifier]!.entity
            let sourceEntityName = sourceEntity.name!
            let destinationEntityName = destinationEntity.name!
            switch (allMappedSourceKeys[sourceEntityName], allMappedDestinationKeys[destinationEntityName]) {
            
            case (nil, nil):
                if sourceEntity.versionHash == destinationEntity.versionHash {
                    
                    copyMappings.insert(
                        .copyEntity(
                            sourceEntity: sourceEntityName,
                            destinationEntity: destinationEntityName
                        )
                    )
                } else {
                    
                    transformMappings.insert(
                        .transformEntity(
                            sourceEntity: sourceEntityName,
                            destinationEntity: destinationEntityName,
                            transformer: CustomMapping.inferredTransformation
                        )
                    )
                }
                allMappedSourceKeys[sourceEntityName] = destinationEntityName
                allMappedDestinationKeys[destinationEntityName] = sourceEntityName
            
            case (""?, nil):
                insertMappings.insert(.insertEntity(destinationEntity: destinationEntityName))
                allMappedDestinationKeys[destinationEntityName] = ""
            
            case (nil, ""?):
                deleteMappings.insert(.deleteEntity(sourceEntity: sourceEntityName))
                allMappedSourceKeys[sourceEntityName] = ""
            
            default:
                continue
            }
        }
        for renamingIdentifier in removedRenamingIdentifiers {
            
            let sourceEntity = sourceRenamingIdentifiers[renamingIdentifier]!.entity
            let sourceEntityName = sourceEntity.name!
            switch allMappedSourceKeys[sourceEntityName] {
            
            case nil:
                deleteMappings.insert(.deleteEntity(sourceEntity: sourceEntityName))
                allMappedSourceKeys[sourceEntityName] = ""
            
            default:
                continue
            }
        }
        for renamingIdentifier in addedRenamingIdentifiers {
            
            let destinationEntity = destinationRenamingIdentifiers[renamingIdentifier]!.entity
            let destinationEntityName = destinationEntity.name!
            switch allMappedDestinationKeys[destinationEntityName] {
            
            case nil:
                insertMappings.insert(.insertEntity(destinationEntity: destinationEntityName))
                allMappedDestinationKeys[destinationEntityName] = ""
            
            default:
                continue
            }
        }
        return (deleteMappings, insertMappings, copyMappings, transformMappings)
    }
}
