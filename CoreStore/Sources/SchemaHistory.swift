//
//  SchemaHistory.swift
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


// MARK: - SchemaHistory

/**
 The `SchemaHistory` encapsulates multiple `DynamicSchema` across multiple model versions. It contains all model history and is used by the `DataStack` to 
 */
public final class SchemaHistory: ExpressibleByArrayLiteral {
    
    /**
     The version string for the current model version. The `DataStack` will try to migrate all `StorageInterface`s added to itself to this version, following the version steps provided by the `migrationChain`.
     */
    public let currentModelVersion: ModelVersion
    
    /**
     The schema for the current model version. The `DataStack` will try to migrate all `StorageInterface`s added to itself to this version, following the version steps provided by the `migrationChain`.
     */
    public var currentSchema: DynamicSchema {
        
        return self.schema(for: self.currentModelVersion)!
    }
    
    /**
     The version string for the current model version. The `DataStack` will try to migrate all `StorageInterface`s added to itself to this version, following the version steps provided by the `migrationChain`.
     */
    public let migrationChain: MigrationChain
    
    /**
     Convenience initializer for a `SchemaHistory` created from a single xcdatamodeld file.
     - parameter xcodeDataModeld: a tuple returned from the `XcodeDataModelSchema.from(modelName:bundle:migrationChain:)` method.
     - parameter migrationChain: the `MigrationChain` that indicates the sequence of model versions to be used as the order for progressive migrations. If not specified, will default to a non-migrating data stack.
     */
    public convenience init(
        _ xcodeDataModeld: (
            allSchema: [XcodeDataModelSchema],
            currentModelVersion: ModelVersion
        ),
        migrationChain: MigrationChain = nil
    ) {

        self.init(
            allSchema: xcodeDataModeld.allSchema,
            migrationChain: migrationChain,
            exactCurrentModelVersion: xcodeDataModeld.currentModelVersion
        )
    }
    
    /**
     Initializes a `SchemaHistory` with a list of `DynamicSchema` and a `MigrationChain` to describe the order of progressive migrations.
     - parameter schema: a `DynamicSchema` that represents a model version
     - parameter otherSchema: a list of `DynamicSchema` that represent other model versions
     - parameter migrationChain: the `MigrationChain` that indicates the sequence of model versions to be used as the order for progressive migrations. If not specified, will default to a non-migrating data stack.
     - parameter exactCurrentModelVersion: an optional string to explicitly select the current model version string. This is useful if the `DataStack` should load a non-latest model version (usually to prepare data before migration). If not provided, the current model version will be computed from the `MigrationChain`.
     */
    public convenience init(
        _ schema: DynamicSchema,
        _ otherSchema: DynamicSchema...,
        migrationChain: MigrationChain = nil,
        exactCurrentModelVersion: String? = nil
    ) {

        self.init(
            allSchema: [schema] + otherSchema,
            migrationChain: migrationChain,
            exactCurrentModelVersion: exactCurrentModelVersion
        )
    }
    
    /**
     Initializes a `SchemaHistory` with a list of `DynamicSchema` and a `MigrationChain` to describe the order of progressive migrations.
     - parameter allSchema: a list of `DynamicSchema` that represent model versions
     - parameter migrationChain: the `MigrationChain` that indicates the sequence of model versions to be used as the order for progressive migrations. If not specified, will default to a non-migrating data stack.
     - parameter exactCurrentModelVersion: an optional string to explicitly select the current model version string. This is useful if the `DataStack` should load a non-latest model version (usually to prepare data before migration). If not provided, the current model version will be computed from the `MigrationChain`.
     */
    public required init(
        allSchema: [DynamicSchema],
        migrationChain: MigrationChain = nil,
        exactCurrentModelVersion: String? = nil
    ) {

        if allSchema.isEmpty {
            
            Internals.abort("The \"allSchema\" argument of the \(Internals.typeName(SchemaHistory.self)) initializer cannot be empty.")
        }
        Internals.assert(
            migrationChain.isValid,
            "Invalid migration chain passed to the \(Internals.typeName(SchemaHistory.self)). Check that the model versions' order are correct and that no repetitions or ambiguities exist."
        )
        var schemaByVersion: [ModelVersion: DynamicSchema] = [:]
        for schema in allSchema {
            
            let modelVersion = schema.modelVersion
            Internals.assert(
                schemaByVersion[modelVersion] == nil,
                "Multiple model schema found for model version \"\(modelVersion)\"."
            )
            schemaByVersion[modelVersion] = schema
        }
        let modelVersions = Set(schemaByVersion.keys)
        let currentModelVersion: ModelVersion
        if let exactCurrentModelVersion = exactCurrentModelVersion {
            
            if !migrationChain.isEmpty && !migrationChain.contains(exactCurrentModelVersion) {
                
                Internals.abort("An \"exactCurrentModelVersion\" argument was provided to \(Internals.typeName(SchemaHistory.self)) initializer but a matching schema could not be found from the provided \(Internals.typeName(MigrationChain.self)).")
            }
            if schemaByVersion[exactCurrentModelVersion] == nil {
                
                Internals.abort("An \"exactCurrentModelVersion\" argument was provided to \(Internals.typeName(SchemaHistory.self)) initializer but a matching schema could not be found from the \(Internals.typeName(DynamicSchema.self)) list.")
            }
            currentModelVersion = exactCurrentModelVersion
        }
        else if migrationChain.isEmpty && schemaByVersion.count == 1 {
            
            currentModelVersion = schemaByVersion.keys.first!
        }
        else {
            
            let candidateVersions = modelVersions.intersection(migrationChain.leafVersions)
            switch candidateVersions.count {
                
            case 0:
                Internals.abort("None of the \(Internals.typeName(MigrationChain.self)) leaf versions provided to the \(Internals.typeName(SchemaHistory.self)) initializer matches any scheme from the \(Internals.typeName(DynamicSchema.self)) list.")
                
            case 1:
                currentModelVersion = candidateVersions.first!
                
            default:
                Internals.abort("Could not resolve the \(Internals.typeName(SchemaHistory.self)) current model version because the \(Internals.typeName(MigrationChain.self)) have ambiguous leaf versions: \(candidateVersions)")
            }
        }
        
        self.schemaByVersion = schemaByVersion
        self.migrationChain = migrationChain
        self.currentModelVersion = currentModelVersion
        self.rawModel = schemaByVersion[currentModelVersion]!.rawModel()
    }
    
    
    // MARK: ExpressibleByArrayLiteral
    
    public typealias Element = DynamicSchema
    
    public convenience init(arrayLiteral elements: DynamicSchema...) {

        self.init(
            allSchema: elements,
            migrationChain: MigrationChain(elements.map({ $0.modelVersion })),
            exactCurrentModelVersion: nil
        )
    }
    
    
    // MARK: Internal
    
    internal let schemaByVersion: [ModelVersion: DynamicSchema]
    internal let rawModel: NSManagedObjectModel
    
    internal private(set) lazy var entityDescriptionsByEntityIdentifier: [Internals.EntityIdentifier: NSEntityDescription] = Internals.with { [unowned self] in
        
        var mapping: [Internals.EntityIdentifier: NSEntityDescription] = [:]
        self.rawModel.entities.forEach { (entityDescription) in
            
            let entityIdentifier = Internals.EntityIdentifier(entityDescription)
            mapping[entityIdentifier] = entityDescription
        }
        return mapping
    }
    
    internal func rawModel(for modelVersion: ModelVersion) -> NSManagedObjectModel? {
        
        if modelVersion == self.currentModelVersion {
            
            return self.rawModel
        }
        return self.schemaByVersion[modelVersion]?.rawModel()
    }
    
    internal func schema(for modelVersion: ModelVersion) -> DynamicSchema? {
        
        return self.schemaByVersion[modelVersion]
    }
    
    internal func schema(for storeMetadata: [String: Any]) -> DynamicSchema? {
        
        guard let modelHashes = storeMetadata[NSStoreModelVersionHashesKey] as! [String: Data]? else {
            
            return nil
        }
        for (_, schema) in self.schemaByVersion {
            
            let rawModel = schema.rawModel()
            if modelHashes == rawModel.entityVersionHashesByName {
                
                return schema
            }
        }
        return nil
    }
    
    internal func mergedModels() -> [NSManagedObjectModel] {
        
        return self.schemaByVersion.values.map({ $0.rawModel() })
    }
}
