//
//  InferredSchemaMappingProvider.swift
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


// MARK: - InferredSchemaMappingProvider

/**
 A `SchemaMappingProvider` that tries to infer model migration between two `DynamicSchema` versions by searching all `xcmappingmodel`s from `Bundle.allBundles` or by relying on lightweight migration if possible. Throws an error if lightweight migration is impossible for the two `DynamicSchema`. This mapping is automatically used as a fallback mapping provider, even if no mapping providers are explicitly declared in the `StorageInterface`.
 - Note: For security reasons, `InferredSchemaMappingProvider` will not search `Bundle.allFrameworks` by default. If the `xcmappingmodel`s are bundled within a framework, use `XcodeSchemaMappingProvider` instead and provide `Bundle(for: <a class in the framework>` to its initializer.
 */
public final class InferredSchemaMappingProvider: Hashable, SchemaMappingProvider {
    
    // MARK: Equatable
    
    public static func == (lhs: InferredSchemaMappingProvider, rhs: InferredSchemaMappingProvider) -> Bool {
        
        return true
    }
    
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

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
        
        if let mappingModel = NSMappingModel(
            from: Bundle.allBundles,
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
        do {
            
            let mappingModel = try NSMappingModel.inferredMappingModel(
                forSourceModel: sourceModel,
                destinationModel: destinationModel
            )
            return (
                mappingModel,
                .lightweight(
                    sourceVersion: sourceSchema.modelVersion,
                    destinationVersion: destinationSchema.modelVersion
                )
            )
        }
        catch {

            let coreStoreError = CoreStoreError(error)
            Internals.log(
                coreStoreError,
                "\(Internals.typeName(self)) failed to find migration mappings from version model \"\(sourceSchema.modelVersion)\" to \"\(destinationSchema.modelVersion)\" in the \(Internals.typeName(storage)) at URL \"\(storage.fileURL)\". The local storage may be corrupt or the \(Internals.typeName(storage)) initializer may be missing the correct \(Internals.typeName(SchemaMappingProvider.self))"
            )
            throw coreStoreError
        }
    }
}
