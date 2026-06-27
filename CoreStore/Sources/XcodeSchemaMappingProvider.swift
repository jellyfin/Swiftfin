//
//  XcodeSchemaMappingProvider.swift
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


// MARK: - XcodeSchemaMappingProvider

/**
 A `SchemaMappingProvider` that tries to infer model migration between two `DynamicSchema` versions by loading an xcmappingmodel file from the specified `Bundle`. Throws `CoreStoreError.mappingModelNotFound` if the xcmappingmodel file cannot be found, or if the xcmappingmodel doesn't resolve the source and destination `DynamicSchema`.
 */
public final class XcodeSchemaMappingProvider: Hashable, SchemaMappingProvider {
    
    /**
     The source model version for the mapping.
     */
    public let sourceVersion: ModelVersion
    
    /**
     The destination model version for the mapping.
     */
    public let destinationVersion: ModelVersion
    
    /**
     The `Bundle` that contains the xcmappingmodel file.
     */
    public let mappingModelBundle: Bundle
    
    /**
     Creates an `XcodeSchemaMappingProvider`
     
     - parameter sourceVersion: the source model version for the mapping
     - parameter destinationVersion: the destination model version for the mapping
     - parameter mappingModelBundle: the `Bundle` that contains the xcmappingmodel file
     */
    public required init(
        from sourceVersion: ModelVersion,
        to destinationVersion: ModelVersion,
        mappingModelBundle: Bundle
    ) {

        self.sourceVersion = sourceVersion
        self.destinationVersion = destinationVersion
        self.mappingModelBundle = mappingModelBundle
    }
    
    
    // MARK: Equatable
    
    public static func == (lhs: XcodeSchemaMappingProvider, rhs: XcodeSchemaMappingProvider) -> Bool {
        
        return lhs.sourceVersion == rhs.sourceVersion
            && lhs.destinationVersion == rhs.destinationVersion
            && lhs.mappingModelBundle == rhs.mappingModelBundle
    }
    
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(self.sourceVersion)
        hasher.combine(self.destinationVersion)
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
        
        if let mappingModel = NSMappingModel(
            from: [self.mappingModelBundle],
            forSourceModel: sourceModel,
            destinationModel: destinationModel) {
            
            return (
                mappingModel,
                .heavyweight(
                    sourceVersion: sourceSchema.modelVersion,
                    destinationVersion: destinationSchema.modelVersion
                )
            )
        }
        throw CoreStoreError.mappingModelNotFound(
            localStoreURL: storage.fileURL,
            targetModel: destinationModel,
            targetModelVersion: destinationSchema.modelVersion
        )
    }
}
