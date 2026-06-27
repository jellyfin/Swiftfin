//
//  DataStack+Migration.swift
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


// MARK: - DataStack

extension DataStack {
    
    /**
     Asynchronously adds a `StorageInterface` to the stack. Migrations are also initiated by default.
     ```
     dataStack.addStorage(
         InMemoryStore(configuration: "Config1"),
         completion: { result in
             switch result {
             case .success(let storage): // ...
             case .failure(let error): // ...
             }
         }
     )
     ```
     - parameter storage: the storage
     - parameter completion: the closure to be executed on the main queue when the process completes, either due to success or failure. The closure's `SetupResult` argument indicates the result. Note that the `StorageInterface` associated to the `SetupResult.success` may not always be the same instance as the parameter argument if a previous `StorageInterface` was already added at the same URL and with the same configuration.
     */
    public func addStorage<T>(
        _ storage: T,
        completion: @escaping (SetupResult<T>) -> Void
    ) {

        self.coordinator.performAsynchronously {
            
            if let _ = self.persistentStoreForStorage(storage) {
                
                DispatchQueue.main.async {
                    
                    completion(.success(storage))
                }
                return
            }
            
            do {
                
                _ = try self.createPersistentStoreFromStorage(
                    storage,
                    finalURL: nil,
                    finalStoreOptions: storage.storeOptions
                )
                
                DispatchQueue.main.async {
                    
                    completion(.success(storage))
                }
            }
            catch {
                
                let storeError = CoreStoreError(error)
                Internals.log(
                    storeError,
                    "Failed to add \(Internals.typeName(storage)) to the stack."
                )
                DispatchQueue.main.async {
                    
                    completion(.failure(storeError))
                }
            }
        }
    }
    
    /**
     Asynchronously adds a `LocalStorage` to the stack. Migrations are also initiated by default.
     ```
     let migrationProgress = dataStack.addStorage(
         SQLiteStore(fileName: "core_data.sqlite", configuration: "Config1"),
         completion: { result in
             switch result {
             case .success(let storage): // ...
             case .failure(let error): // ...
             }
         }
     )
     ```
     - parameter storage: the local storage
     - parameter completion: the closure to be executed on the main queue when the process completes, either due to success or failure. The closure's `SetupResult` argument indicates the result. Note that the `LocalStorage` associated to the `SetupResult.success` may not always be the same instance as the parameter argument if a previous `LocalStorage` was already added at the same URL and with the same configuration.
     - returns: a `Progress` instance if a migration has started, or `nil` if either no migrations are required or if a failure occured.
     */
    public func addStorage<T: LocalStorage>(
        _ storage: T,
        completion: @escaping (SetupResult<T>) -> Void
    ) -> Progress? {

        let fileURL = storage.fileURL
        Internals.assert(
            fileURL.isFileURL,
            "The specified URL for the \(Internals.typeName(storage)) is invalid: \"\(fileURL)\""
        )
        
        return self.coordinator.performSynchronously {
            
            if let _ = self.persistentStoreForStorage(storage) {
                
                DispatchQueue.main.async {
                    
                    completion(.success(storage))
                }
                return nil
            }
            
            if let persistentStore = self.coordinator.persistentStore(for: fileURL as URL) {
                
                if let existingStorage = persistentStore.storageInterface as? T,
                    storage.matchesPersistentStore(persistentStore) {
                    
                    DispatchQueue.main.async {
                        
                        completion(.success(existingStorage))
                    }
                    return nil
                }
                
                let error = CoreStoreError.differentStorageExistsAtURL(existingPersistentStoreURL: fileURL)
                Internals.log(
                    error,
                    "Failed to add \(Internals.typeName(storage)) at \"\(fileURL)\" because a different \(Internals.typeName(NSPersistentStore.self)) at that URL already exists."
                )
                DispatchQueue.main.async {
                    
                    completion(.failure(error))
                }
                return nil
            }
            
            do {
                
                try FileManager.default.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                    ofType: type(of: storage).storeType,
                    at: fileURL as URL,
                    options: storage.storeOptions
                )
                
                return self.upgradeStorageIfNeeded(
                    storage,
                    metadata: metadata,
                    completion: { (result) -> Void in
                        
                        if case .failure(.internalError(let error)) = result {
                            
                            if storage.localStorageOptions.contains(.recreateStoreOnModelMismatch) && error.isCoreDataMigrationError {
                                
                                do {
                                    
                                    try storage.cs_eraseStorageAndWait(
                                        metadata: metadata,
                                        soureModelHint: self.schemaHistory.schema(for: metadata)?.rawModel()
                                    )
                                    _ = try self.addStorageAndWait(storage)
                                    
                                    DispatchQueue.main.async {
                                        
                                        completion(.success(storage))
                                    }
                                }
                                catch {
                                    
                                    completion(.failure(CoreStoreError(error)))
                                }
                                return
                            }
                            
                            completion(.failure(CoreStoreError(error)))
                            return
                        }
                        
                        do {
                            
                            _ = try self.addStorageAndWait(storage)
                            
                            DispatchQueue.main.async {
                                
                                completion(.success(storage))
                            }
                        }
                        catch {
                            
                            completion(.failure(CoreStoreError(error)))
                        }
                    }
                )
            }
            catch let error as NSError
                where error.code == NSFileReadNoSuchFileError && error.domain == NSCocoaErrorDomain {
                    
                    do {
                        
                        _ = try self.addStorageAndWait(storage)
                        
                        DispatchQueue.main.async {
                            
                            completion(.success(storage))
                        }
                    }
                    catch {
                        
                        DispatchQueue.main.async {
                            
                            completion(.failure(CoreStoreError(error)))
                        }
                    }
                    return nil
            }
            catch {
                
                let storeError = CoreStoreError(error)
                Internals.log(
                    storeError,
                    "Failed to load SQLite \(Internals.typeName(NSPersistentStore.self)) metadata."
                )
                DispatchQueue.main.async {
                    
                    completion(.failure(storeError))
                }
                return nil
            }
        }
    }
    
    /**
     Migrates a local storage to match the `DataStack`'s managed object model version. This method does NOT add the migrated store to the data stack.
     
     - parameter storage: the local storage
     - parameter completion: the closure to be executed on the main queue when the migration completes, either due to success or failure. The closure's `MigrationResult` argument indicates the result.
     - throws: a `CoreStoreError` value indicating the failure
     - returns: a `Progress` instance if a migration has started, or `nil` is no migrations are required
     */
    public func upgradeStorageIfNeeded<T: LocalStorage>(
        _ storage: T,
        completion: @escaping (MigrationResult) -> Void
    ) throws(CoreStoreError) -> Progress? {

        return try self.coordinator.performSynchronously {
            
            let fileURL = storage.fileURL
            do {
                
                Internals.assert(
                    self.persistentStoreForStorage(storage) == nil,
                    "Attempted to migrate an already added \(Internals.typeName(storage)) at URL \"\(fileURL)\""
                )
                
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                    ofType: type(of: storage).storeType,
                    at: fileURL as URL,
                    options: storage.storeOptions
                )
                return self.upgradeStorageIfNeeded(
                    storage,
                    metadata: metadata,
                    completion: completion
                )
            }
            catch {
                
                let metadataError = CoreStoreError(error)
                Internals.log(
                    metadataError,
                    "Failed to load \(Internals.typeName(storage)) metadata from URL \"\(fileURL)\"."
                )
                throw metadataError
            }
        }
    }
    
    /**
     Checks the migration steps required for the storage to match the `DataStack`'s managed object model version.
     
     - parameter storage: the local storage
     - throws: a `CoreStoreError` value indicating the failure
     - returns: a `MigrationType` array indicating the migration steps required for the store, or an empty array if the file does not exist yet. Otherwise, an error is thrown if either inspection of the store failed, or if no mapping model was found/inferred.
     */
    public func requiredMigrationsForStorage<T: LocalStorage>(
        _ storage: T
    ) throws(CoreStoreError) -> [MigrationType] {

        return try self.coordinator.performSynchronously {
            
            let fileURL = storage.fileURL
            
            Internals.assert(
                self.persistentStoreForStorage(storage) == nil,
                "Attempted to query required migrations for an already added \(Internals.typeName(storage)) at URL \"\(fileURL)\""
            )
            do {
                
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                    ofType: type(of: storage).storeType,
                    at: fileURL as URL,
                    options: storage.storeOptions
                )
                
                guard let migrationSteps = self.computeMigrationFromStorage(storage, metadata: metadata) else {
                    
                    let error = CoreStoreError.mappingModelNotFound(
                        localStoreURL: fileURL,
                        targetModel: self.schemaHistory.rawModel,
                        targetModelVersion: self.modelVersion
                    )
                    Internals.log(
                        error,
                        "Failed to find migration steps from the \(Internals.typeName(storage)) at URL \"\(fileURL)\" to version model \"\(self.modelVersion)\"."
                    )
                    throw error
                }
                
                if migrationSteps.count > 1 && storage.localStorageOptions.contains(.preventProgressiveMigration) {
                    
                    let error = CoreStoreError.progressiveMigrationRequired(localStoreURL: fileURL)
                    Internals.log(
                        error,
                        "Failed to find migration mapping from the \(Internals.typeName(storage)) at URL \"\(fileURL)\" to version model \"\(self.modelVersion)\" without requiring progessive migrations."
                    )
                    throw error
                }
                
                return migrationSteps.map { $0.migrationType }
            }
            catch let error as NSError
                where error.code == NSFileReadNoSuchFileError && error.domain == NSCocoaErrorDomain {
                    
                    return []
            }
            catch {
                
                let metadataError = CoreStoreError(error)
                Internals.log(
                    metadataError,
                    "Failed to load \(Internals.typeName(storage)) metadata from URL \"\(fileURL)\"."
                )
                throw metadataError
            }
        }
    }
    
    
    // MARK: Private
    
    private func upgradeStorageIfNeeded<T: LocalStorage>(
        _ storage: T,
        metadata: [String: Any],
        completion: @escaping (MigrationResult) -> Void
    ) -> Progress? {

        guard let migrationSteps = self.computeMigrationFromStorage(storage, metadata: metadata) else {
            
            let error = CoreStoreError.mappingModelNotFound(
                localStoreURL: storage.fileURL,
                targetModel: self.schemaHistory.rawModel,
                targetModelVersion: self.modelVersion
            )
            Internals.log(
                error,
                "Failed to find migration steps from \(Internals.typeName(storage)) at URL \"\(storage.fileURL)\" to version model \"\(self.schemaHistory.rawModel)\"."
            )
            
            DispatchQueue.main.async {
                
                completion(.failure(error))
            }
            return nil
        }
        
        let numberOfMigrations: Int64 = Int64(migrationSteps.count)
        if numberOfMigrations == 0 {
            
            DispatchQueue.main.async {
                
                completion(.success([]))
                return
            }
            return nil
        }
        else if numberOfMigrations > 1 && storage.localStorageOptions.contains(.preventProgressiveMigration) {
            
            let error = CoreStoreError.progressiveMigrationRequired(localStoreURL: storage.fileURL)
            Internals.log(
                error,
                "Failed to find migration mapping from the \(Internals.typeName(storage)) at URL \"\(storage.fileURL)\" to version model \"\(self.modelVersion)\" without requiring progessive migrations."
            )
            DispatchQueue.main.async {
                
                completion(.failure(error))
            }
            return nil
        }
        
        let migrationTypes = migrationSteps.map { $0.migrationType }
        var migrationResult: MigrationResult?
        var operations = [Operation]()
        var cancelled = false
        
        let progress = Progress(parent: nil, userInfo: nil)
        progress.totalUnitCount = numberOfMigrations
        
        for (sourceModel, destinationModel, mappingModel, migrationType) in migrationSteps {
            
            progress.becomeCurrent(withPendingUnitCount: 1)
            
            let childProgress = Progress(parent: progress, userInfo: nil)
            childProgress.totalUnitCount = 100
            
            operations.append(
                BlockOperation { [weak self] in
                    
                    guard let self = self, !cancelled else {
                        
                        return
                    }
                    
                    autoreleasepool {
                        
                        do {
                            
                            try self.startMigrationForStorage(
                                storage,
                                sourceModel: sourceModel,
                                destinationModel: destinationModel,
                                mappingModel: mappingModel,
                                migrationType: migrationType,
                                progress: childProgress
                            )
                        }
                        catch {
                        
                            let migrationError = CoreStoreError(error)
                            Internals.log(
                                migrationError,
                                "Failed to migrate version model \"\(migrationType.sourceVersion)\" to version \"\(migrationType.destinationVersion)\"."
                            )
                            migrationResult = .failure(migrationError)
                            cancelled = true
                        }
                    }
                    
                    DispatchQueue.main.async {
                        
                        withExtendedLifetime(childProgress) { (_: Progress) -> Void in }
                    }
                }
            )
            
            progress.resignCurrent()
        }
        
        let migrationOperation = BlockOperation()
        migrationOperation.qualityOfService = .utility
        operations.forEach { migrationOperation.addDependency($0) }
        migrationOperation.addExecutionBlock { () -> Void in
            
            DispatchQueue.main.async {
                
                progress.setProgressHandler(nil)
                completion(migrationResult ?? .success(migrationTypes))
                return
            }
        }
        
        operations.append(migrationOperation)
        
        self.migrationQueue.addOperations(operations, waitUntilFinished: false)
        
        return progress
    }
    
    private func computeMigrationFromStorage<T: LocalStorage>(
        _ storage: T,
        metadata: [String: Any]
    ) -> [(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel, mappingModel: NSMappingModel, migrationType: MigrationType)]? {

        let schemaHistory = self.schemaHistory
        if schemaHistory.rawModel.isConfiguration(withName: storage.configuration, compatibleWithStoreMetadata: metadata) {

            return []
        }

        guard let initialSchema = schemaHistory.schema(for: metadata) else {

            return nil
        }
        var currentVersion = initialSchema.modelVersion
        let migrationChain: MigrationChain = schemaHistory.migrationChain.isEmpty
            ? [currentVersion: schemaHistory.currentModelVersion]
            : schemaHistory.migrationChain

        var migrationSteps = [(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel, mappingModel: NSMappingModel, migrationType: MigrationType)]()

        while let nextVersion = migrationChain.nextVersionFrom(currentVersion),
            let sourceSchema = schemaHistory.schema(for: currentVersion),
            sourceSchema.modelVersion != schemaHistory.currentModelVersion,
            let destinationSchema = schemaHistory.schema(for: nextVersion) {

                let mappingProviders = storage.migrationMappingProviders
                do {

                    try withExtendedLifetime((sourceSchema.rawModel(), destinationSchema.rawModel())) {

                        let (sourceModel, destinationModel) = $0
                        let mapping = try mappingProviders.findMapping(
                            sourceSchema: sourceSchema,
                            destinationSchema: destinationSchema,
                            storage: storage
                        )
                        migrationSteps.append(
                            (
                                sourceModel: sourceModel,
                                destinationModel: destinationModel,
                                mappingModel: mapping.mappingModel,
                                migrationType: mapping.migrationType
                            )
                        )
                    }
                }
                catch {

                    return nil
                }
                currentVersion = nextVersion
        }

        if migrationSteps.last?.destinationModel == schemaHistory.rawModel {

            return migrationSteps
        }

        return nil
    }
    
    private func startMigrationForStorage<T: LocalStorage>(
        _ storage: T,
        sourceModel: NSManagedObjectModel,
        destinationModel: NSManagedObjectModel,
        mappingModel: NSMappingModel,
        migrationType: MigrationType,
        progress: Progress
    ) throws(CoreStoreError) {

        do {
            
            try storage.cs_finalizeStorageAndWait(soureModelHint: sourceModel)
        }
        catch {
            
            throw CoreStoreError(error)
        }
        
        let fileURL = storage.fileURL
        if case .lightweight = migrationType {

            do {

                let timerQueue = DispatchQueue(
                    label: "DataStack.lightweightMigration.timerQueue",
                    qos: .utility,
                    attributes: []
                )
                let estimatedTime: TimeInterval = 60 * 3 // 3 mins
                let interval: TimeInterval = 1
                let fakeTotalUnitCount: Float = 0.9 * Float(progress.totalUnitCount)
                var fakeProgress: Float = 0
                
                var recursiveCheck: () -> Void = {}
                recursiveCheck = { [weak timerQueue] in
                    
                    guard let timerQueue = timerQueue, fakeProgress < 1 else {
                        
                        return
                    }
                    progress.completedUnitCount = Int64(fakeTotalUnitCount * fakeProgress)
                    fakeProgress += Float(interval / estimatedTime)
                    
                    timerQueue.asyncAfter(
                        deadline: .now() + interval,
                        execute: recursiveCheck
                    )
                }
                timerQueue.async(execute: recursiveCheck)
                
                _ = try withExtendedLifetime(NSPersistentStoreCoordinator(managedObjectModel: destinationModel)) { (coordinator: NSPersistentStoreCoordinator) in
                    
                    try coordinator.addPersistentStoreSynchronously(
                        type(of: storage).storeType,
                        configuration: storage.configuration,
                        URL: fileURL,
                        options: storage.dictionary(
                            forOptions: storage.localStorageOptions.union(.allowSynchronousLightweightMigration)
                        )
                    )
                }
                timerQueue.sync {
                    
                    fakeProgress = 1
                }
                _ = try? storage.cs_finalizeStorageAndWait(soureModelHint: destinationModel)
                progress.completedUnitCount = progress.totalUnitCount
                return
            }
            catch {

                // Lightweight migration failed somehow. Proceed using InferedMappingModel below
            }
        }
        let fileManager = FileManager.default
        let temporaryDirectoryURL = fileManager.temporaryDirectory
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.CoreStore.DataStack")
            .appendingPathComponent(ProcessInfo().globallyUniqueString)

        try! fileManager.createDirectory(
            at: temporaryDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let externalStorageFolderName = ".\(fileURL.deletingPathExtension().lastPathComponent)_SUPPORT"
        let temporaryExternalStorageURL = temporaryDirectoryURL.appendingPathComponent(
            externalStorageFolderName,
            isDirectory: true
        )
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(
            fileURL.lastPathComponent,
            isDirectory: false
        )
        
        let migrationManager = Internals.MigrationManager(
            sourceModel: sourceModel,
            destinationModel: destinationModel,
            progress: progress
        )
        
        do {
            
            try migrationManager.migrateStore(
                from: fileURL,
                sourceType: type(of: storage).storeType,
                options: nil,
                with: mappingModel,
                toDestinationURL: temporaryFileURL,
                destinationType: type(of: storage).storeType,
                destinationOptions: nil
            )
            let temporaryStorage = SQLiteStore(
                fileURL: temporaryFileURL,
                configuration: storage.configuration,
                migrationMappingProviders: storage.migrationMappingProviders,
                localStorageOptions: storage.localStorageOptions
            )
            try temporaryStorage.cs_finalizeStorageAndWait(soureModelHint: destinationModel)
        }
        catch {
            
            _ = try? fileManager.removeItem(at: temporaryFileURL)
            throw CoreStoreError(error)
        }
        
        do {
            
            try fileManager.replaceItem(
                at: fileURL,
                withItemAt: temporaryFileURL,
                backupItemName: nil,
                options: [],
                resultingItemURL: nil
            )
            if fileManager.fileExists(atPath: temporaryExternalStorageURL.path) {
                
                let externalStorageURL = fileURL
                    .deletingLastPathComponent()
                    .appendingPathComponent(externalStorageFolderName, isDirectory: true)
                try fileManager.replaceItem(
                    at: externalStorageURL,
                    withItemAt: temporaryExternalStorageURL,
                    backupItemName: nil,
                    options: [],
                    resultingItemURL: nil
                )
            }
            
            progress.completedUnitCount = progress.totalUnitCount
        }
        catch {
            
            _ = try? fileManager.removeItem(at: temporaryFileURL)
            _ = try? fileManager.removeItem(at: temporaryExternalStorageURL)
            throw CoreStoreError(error)
        }
    }
}


// MARK: - FilePrivate

extension Array where Element == SchemaMappingProvider {
    
    func findMapping(
        sourceSchema: DynamicSchema,
        destinationSchema: DynamicSchema,
        storage: LocalStorage
    ) throws(CoreStoreError) -> (mappingModel: NSMappingModel, migrationType: MigrationType) {

        for element in self {
            
            switch element {
                
            case let element as CustomSchemaMappingProvider
                where element.sourceVersion == sourceSchema.modelVersion && element.destinationVersion == destinationSchema.modelVersion:
                return try element.cs_createMappingModel(from: sourceSchema, to: destinationSchema, storage: storage)
                
            case let element as XcodeSchemaMappingProvider
                where element.sourceVersion == sourceSchema.modelVersion && element.destinationVersion == destinationSchema.modelVersion:
                return try element.cs_createMappingModel(from: sourceSchema, to: destinationSchema, storage: storage)
                
            default:
                continue
            }
        }
        return try InferredSchemaMappingProvider()
            .cs_createMappingModel(from: sourceSchema, to: destinationSchema, storage: storage)
    }
}
