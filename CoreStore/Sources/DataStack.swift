//
//  DataStack.swift
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

/**
 The `DataStack` encapsulates the data model for the Core Data stack. Each `DataStack` can have multiple data stores, usually specified as a "Configuration" in the model editor. Behind the scenes, the DataStack manages its own `NSPersistentStoreCoordinator`, a root `NSManagedObjectContext` for disk saves, and a shared `NSManagedObjectContext` designed as a read-only model interface for `NSManagedObjects`.
 */
public final class DataStack: Equatable {
    
    /**
     The resolved application name, used by the `DataStack` as the default Xcode model name (.xcdatamodel filename) if not explicitly provided.
     */
    public static let applicationName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "CoreData"
    
    /**
     Convenience initializer for `DataStack` that creates a `SchemaHistory` from the model with the specified `modelName` in the specified `bundle`.
     
     - parameter xcodeModelName: the name of the (.xcdatamodeld) model file. If not specified, the application name (CFBundleName) will be used if it exists, or "CoreData" if it the bundle name was not set (e.g. in Unit Tests).
     - parameter bundle: an optional bundle to load .xcdatamodeld models from. If not specified, the main bundle will be used.
     - parameter migrationChain: the `MigrationChain` that indicates the sequence of model versions to be used as the order for progressive migrations. If not specified, will default to a non-migrating data stack.
     */
    public convenience init(
        xcodeModelName: XcodeDataModelFileName = DataStack.applicationName,
        bundle: Bundle = Bundle.main,
        migrationChain: MigrationChain = nil
    ) {
        
        self.init(
            schemaHistory: SchemaHistory(
                XcodeDataModelSchema.from(
                    modelName: xcodeModelName,
                    bundle: bundle,
                    migrationChain: migrationChain
                ),
                migrationChain: migrationChain
            )
        )
    }
    
    /**
     Convenience initializer for `DataStack` that creates a `SchemaHistory` from a list of `DynamicSchema` versions.
     ```
     CoreStoreDefaults.dataStack = DataStack(
         XcodeDataModelSchema(modelName: "MyModelV1"),
         CoreStoreSchema(
             modelVersion: "MyModelV2",
             entities: [
                 Entity<Animal>("Animal"),
                 Entity<Person>("Person")
             ]
         ),
         migrationChain: ["MyModelV1", "MyModelV2"]
     )
     ```
     - parameter schema: an instance of `DynamicSchema`
     - parameter otherSchema: a list of other `DynamicSchema` instances that represent present/previous/future model versions, in any order
     - parameter migrationChain: the `MigrationChain` that indicates the sequence of model versions to be used as the order for progressive migrations. If not specified, will default to a non-migrating data stack.
     */
    public convenience init(
        _ schema: DynamicSchema,
        _ otherSchema: DynamicSchema...,
        migrationChain: MigrationChain = nil
    ) {
        
        self.init(
            schemaHistory: SchemaHistory(
                allSchema: [schema] + otherSchema,
                migrationChain: migrationChain
            )
        )
    }
    
    /**
     Initializes a `DataStack` from a `SchemaHistory` instance.
     ```
     CoreStoreDefaults.dataStack = DataStack(
         schemaHistory: SchemaHistory(
             XcodeDataModelSchema(modelName: "MyModelV1"),
             CoreStoreSchema(
                 modelVersion: "MyModelV2",
                 entities: [
                     Entity<Animal>("Animal"),
                     Entity<Person>("Person")
                 ]
             ),
             migrationChain: ["MyModelV1", "MyModelV2"]
         )
     )
     ```
     - parameter schemaHistory: the `SchemaHistory` for the stack
     */
    public required init(
        schemaHistory: SchemaHistory
    ) {

        self.coordinator = NSPersistentStoreCoordinator(managedObjectModel: schemaHistory.rawModel)
        self.rootSavingContext = NSManagedObjectContext.rootSavingContextForCoordinator(self.coordinator)
        self.mainContext = NSManagedObjectContext.mainContextForRootContext(self.rootSavingContext)
        self.schemaHistory = schemaHistory
        
        self.rootSavingContext.parentStack = self
        
        self.mainContext.isDataStackContext = true
    }
    
    /**
     Returns the `DataStack`'s current model version. `StorageInterface`s added to the stack will be migrated to this version.
     */
    public var modelVersion: String {
        
        return self.schemaHistory.currentModelVersion
    }
    
    /**
     Returns the `DataStack`'s current model schema. `StorageInterface`s added to the stack will be migrated to this version.
     */
    public var modelSchema: DynamicSchema {
        
        return self.schemaHistory.schemaByVersion[self.schemaHistory.currentModelVersion]!
    }
    
    /**
     Returns the entity name-to-class type mapping from the `DataStack`'s model.
     */
    public func entityTypesByName(
        for type: NSManagedObject.Type
    ) -> [EntityName: NSManagedObject.Type] {
        
        var entityTypesByName: [EntityName: NSManagedObject.Type] = [:]
        for (entityIdentifier, entityDescription) in self.schemaHistory.entityDescriptionsByEntityIdentifier {
            
            switch entityIdentifier.category {
                
            case .coreData:
                let actualType = NSClassFromString(entityDescription.managedObjectClassName!)! as! NSManagedObject.Type
                if (actualType as AnyClass).isSubclass(of: type) {
                    
                    entityTypesByName[entityDescription.name!] = actualType
                }
                
            case .coreStore:
                continue
            }
        }
        return entityTypesByName
    }
    
    /**
     Returns the entity name-to-class type mapping from the `DataStack`'s model.
     */
    public func entityTypesByName(
        for type: CoreStoreObject.Type
    ) -> [EntityName: CoreStoreObject.Type] {
        
        var entityTypesByName: [EntityName: CoreStoreObject.Type] = [:]
        for (entityIdentifier, entityDescription) in self.schemaHistory.entityDescriptionsByEntityIdentifier {
            
            switch entityIdentifier.category {
                
            case .coreData:
                continue
                
            case .coreStore:
                guard let anyEntity = entityDescription.coreStoreEntity else {
                    
                    continue
                }
                let actualType = anyEntity.type
                if (actualType as AnyClass).isSubclass(of: type) {
                    
                    entityTypesByName[entityDescription.name!] = (actualType as! CoreStoreObject.Type)
                }
            }
        }
        return entityTypesByName
    }
    
    /**
     Returns the `NSEntityDescription` for the specified `NSManagedObject` subclass.
     */
    public func entityDescription(
        for type: NSManagedObject.Type
    ) -> NSEntityDescription? {
        
        return self.entityDescription(for: Internals.EntityIdentifier(type))
    }
    
    /**
     Returns the `NSEntityDescription` for the specified `CoreStoreObject` subclass.
     */
    public func entityDescription(
        for type: CoreStoreObject.Type
    ) -> NSEntityDescription? {
        
        return self.entityDescription(for: Internals.EntityIdentifier(type))
    }
    
    /**
     Returns the `NSManagedObjectID` for the specified object URI if it exists in the persistent store.
     */
    public func objectID(
        forURIRepresentation url: URL
    ) -> NSManagedObjectID? {
        
        return self.coordinator.managedObjectID(forURIRepresentation: url)
    }
    
    /**
     Creates an `SQLiteStore` with default parameters and adds it to the stack. This method blocks until completion.
     ```
     try dataStack.addStorageAndWait()
     ```
     - throws: a `CoreStoreError` value indicating the failure
     - returns: the local SQLite storage added to the stack
     */
    @discardableResult
    public func addStorageAndWait() throws(CoreStoreError) -> SQLiteStore {

        return try self.addStorageAndWait(SQLiteStore())
    }
    
    /**
     Adds a `StorageInterface` to the stack and blocks until completion.
     ```
     try dataStack.addStorageAndWait(InMemoryStore(configuration: "Config1"))
     ```
     - parameter storage: the `StorageInterface`
     - throws: a `CoreStoreError` value indicating the failure
     - returns: the `StorageInterface` added to the stack
     */
    @discardableResult
    public func addStorageAndWait<T: StorageInterface>(
        _ storage: T
    ) throws(CoreStoreError) -> T {

        do {
            
            return try self.coordinator.performSynchronously {
                
                if let _ = self.persistentStoreForStorage(storage) {
                    
                    return storage
                }
                _ = try self.createPersistentStoreFromStorage(
                    storage,
                    finalURL: nil,
                    finalStoreOptions: storage.storeOptions
                )
                return storage
            }
        }
        catch {
            
            Internals.log(
                error,
                "Failed to add \(Internals.typeName(storage)) to the stack."
            )
            throw error
        }
    }
    
    /**
     Adds a `LocalStorage` to the stack and blocks until completion.
     ```
     try dataStack.addStorageAndWait(SQLiteStore(configuration: "Config1"))
     ```
     - parameter storage: the local storage
     - throws: a `CoreStoreError` value indicating the failure
     - returns: the local storage added to the stack. Note that this may not always be the same instance as the parameter argument if a previous `LocalStorage` was already added at the same URL and with the same configuration.
     */
    @discardableResult
    public func addStorageAndWait<T: LocalStorage>(
        _ storage: T
    ) throws(CoreStoreError) -> T {

        return try self.coordinator.performSynchronously {
            
            let fileURL = storage.fileURL
            Internals.assert(
                fileURL.isFileURL,
                "The specified store URL for the \"\(Internals.typeName(storage))\" is invalid: \"\(fileURL)\""
            )
            
            if let _ = self.persistentStoreForStorage(storage) {
                
                return storage
            }
            
            if let persistentStore = self.coordinator.persistentStore(for: fileURL as URL) {
                
                if let existingStorage = persistentStore.storageInterface as? T,
                    storage.matchesPersistentStore(persistentStore) {
                    
                    return existingStorage
                }
                
                let error = CoreStoreError.differentStorageExistsAtURL(existingPersistentStoreURL: fileURL)
                Internals.log(
                    error,
                    "Failed to add \(Internals.typeName(storage)) at \"\(fileURL)\" because a different \(Internals.typeName(NSPersistentStore.self)) at that URL already exists."
                )
                throw error
            }
            
            do {
                
                var localStorageOptions = storage.localStorageOptions
                localStorageOptions.remove(.recreateStoreOnModelMismatch)
                
                let storeOptions = storage.dictionary(forOptions: localStorageOptions)
                do {
                    
                    try FileManager.default.createDirectory(
                        at: fileURL.deletingLastPathComponent(),
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    _ = try self.createPersistentStoreFromStorage(
                        storage,
                        finalURL: fileURL,
                        finalStoreOptions: storeOptions
                    )
                    return storage
                }
                catch let error as NSError where storage.localStorageOptions.contains(.recreateStoreOnModelMismatch) && error.isCoreDataMigrationError {
                    
                    let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                        ofType: type(of: storage).storeType,
                        at: fileURL,
                        options: storeOptions
                    )
                    try storage.cs_eraseStorageAndWait(
                        metadata: metadata,
                        soureModelHint: self.schemaHistory.schema(for: metadata)?.rawModel()
                    )
                    let finalStoreOptions = storage.dictionary(forOptions: storage.localStorageOptions)
                    _ = try self.createPersistentStoreFromStorage(
                        storage,
                        finalURL: fileURL,
                        finalStoreOptions: finalStoreOptions
                    )
                    return storage
                }
                catch let error as NSError where storage.localStorageOptions.contains(.allowSynchronousLightweightMigration) && error.isCoreDataMigrationError {

                    let storeError = CoreStoreError.asynchronousMigrationRequired(
                        localStoreURL: fileURL,
                        NSError: error
                    )
                    Internals.log(
                        storeError,
                        "Failed to add \(Internals.typeName(storage)) to the stack."
                    )
                    throw storeError
                }
            }
            catch {
                
                let storeError = CoreStoreError(error)
                Internals.log(
                    storeError,
                    "Failed to add \(Internals.typeName(storage)) to the stack."
                )
                throw storeError
            }
        }
    }
    
    /**
     Prepares deinitializing the `DataStack` by removing all persistent stores. This is not necessary, but can help silence SQLite warnings when actively releasing and recreating `DataStack`s.
     - parameter completion: the closure to execute after all persistent stores are removed
     */
    public func unsafeRemoveAllPersistentStores(
        completion: @escaping () -> Void = {}
    ) {
        
        let coordinator = self.coordinator
        coordinator.performAsynchronously {
            
            withExtendedLifetime(coordinator) { coordinator in
                
                coordinator.persistentStores.forEach {
                    
                    _ = try? coordinator.remove($0)
                }
            }
            DispatchQueue.main.async(execute: completion)
        }
    }
    
    /**
     Prepares deinitializing the `DataStack` by removing all persistent stores. This is not necessary, but can help silence SQLite warnings when actively releasing and recreating `DataStack`s.
     */
    public func unsafeRemoveAllPersistentStoresAndWait() {
        
        let coordinator = self.coordinator
        coordinator.performSynchronously {
            
            withExtendedLifetime(coordinator) { coordinator in
                
                coordinator.persistentStores.forEach {
                    
                    _ = try? coordinator.remove($0)
                }
            }
        }
    }
    
    
    // MARK: 3rd Party Utilities
    
    /**
     Allow external libraries to store custom data in the `DataStack`. App code should rarely have a need for this.
     ```
     enum Static {
        static var myDataKey: Void?
     }
     CoreStoreDefaults.dataStack.userInfo[&Static.myDataKey] = myObject
     ```
     - Important: Do not use this method to store thread-sensitive data.
     */
    public let userInfo = UserInfo()
    
    
    // MARK: Equatable
    
    public static func == (lhs: DataStack, rhs: DataStack) -> Bool {
        
        return lhs === rhs
    }
    
    
    // MARK: Internal
    
    internal static var defaultConfigurationName = "PF_DEFAULT_CONFIGURATION_NAME"
    
    internal let coordinator: NSPersistentStoreCoordinator
    internal let rootSavingContext: NSManagedObjectContext
    internal let mainContext: NSManagedObjectContext
    internal let schemaHistory: SchemaHistory
    internal let childTransactionQueue = DispatchQueue.serial("com.coreStore.dataStack.childTransactionQueue", qos: .utility)
    internal let storeMetadataLock: NSRecursiveLock = .init()
    internal let migrationQueue: OperationQueue = Internals.with {
        
        let migrationQueue = OperationQueue()
        migrationQueue.maxConcurrentOperationCount = 1
        migrationQueue.name = "com.coreStore.migrationOperationQueue"
        migrationQueue.qualityOfService = .utility
        migrationQueue.underlyingQueue = DispatchQueue.serial("com.coreStore.migrationQueue", qos: .userInitiated)
        return migrationQueue
    }
    
    internal func persistentStoreForStorage(
        _ storage: StorageInterface
    ) -> NSPersistentStore? {
        
        return self.coordinator.persistentStores
            .filter { $0.storageInterface === storage }
            .first
    }
    
    internal func persistentStores(
        for entityIdentifier: Internals.EntityIdentifier
    ) -> [NSPersistentStore]? {

        self.storeMetadataLock.lock()
        defer {
            self.storeMetadataLock.unlock()
        }
        return self.finalConfigurationsByEntityIdentifier[entityIdentifier]?
            .map({ self.persistentStoresByFinalConfiguration[$0]! }) ?? []
    }
    
    internal func persistentStore(
        for entityIdentifier: Internals.EntityIdentifier,
        configuration: ModelConfiguration,
        inferStoreIfPossible: Bool
    ) -> (store: NSPersistentStore?, isAmbiguous: Bool) {

        self.storeMetadataLock.lock()
        defer {
            self.storeMetadataLock.unlock()
        }
        let configurationsForEntity = self.finalConfigurationsByEntityIdentifier[entityIdentifier] ?? []
        if let configuration = configuration {

            if configurationsForEntity.contains(configuration) {

                return (store: self.persistentStoresByFinalConfiguration[configuration], isAmbiguous: false)
            }
            else if !inferStoreIfPossible {

                return (store: nil, isAmbiguous: false)
            }
        }

        switch configurationsForEntity.count {

        case 0:
            return (store: nil, isAmbiguous: false)

        case 1 where inferStoreIfPossible:
            return (store: self.persistentStoresByFinalConfiguration[configurationsForEntity.first!], isAmbiguous: false)

        default:
            return (store: nil, isAmbiguous: true)
        }
    }
    
    internal func createPersistentStoreFromStorage(
        _ storage: StorageInterface,
        finalURL: URL?,
        finalStoreOptions: [AnyHashable: Any]?
    ) throws(any Swift.Error) -> NSPersistentStore {

        let persistentStore = try self.coordinator.addPersistentStore(
            ofType: type(of: storage).storeType,
            configurationName: storage.configuration,
            at: finalURL,
            options: finalStoreOptions
        )
        persistentStore.storageInterface = storage

        do {

            self.storeMetadataLock.lock()
            defer {
                self.storeMetadataLock.unlock()
            }
            
            let configurationName = persistentStore.configurationName
            self.persistentStoresByFinalConfiguration[configurationName] = persistentStore
            for entityDescription in (self.coordinator.managedObjectModel.entities(forConfigurationName: configurationName) ?? []) {
                
                let managedObjectClassName = entityDescription.managedObjectClassName!
                Internals.assert(
                    NSClassFromString(managedObjectClassName) != nil,
                    "The class \(Internals.typeName(managedObjectClassName)) for the entity \(Internals.typeName(entityDescription.name)) does not exist. Check if the subclass type and module name are properly configured."
                )
                let entityIdentifier = Internals.EntityIdentifier(entityDescription)
                if self.finalConfigurationsByEntityIdentifier[entityIdentifier] == nil {
                    
                    self.finalConfigurationsByEntityIdentifier[entityIdentifier] = []
                }
                self.finalConfigurationsByEntityIdentifier[entityIdentifier]?.insert(configurationName)
            }
        }
        storage.cs_didAddToDataStack(self)
        return persistentStore
    }
    
    internal func entityDescription(
        for entityIdentifier: Internals.EntityIdentifier
    ) -> NSEntityDescription? {
        
        return self.schemaHistory.entityDescriptionsByEntityIdentifier[entityIdentifier]
    }
    
    
    // MARK: Private
    
    private var persistentStoresByFinalConfiguration = [String: NSPersistentStore]()
    private var finalConfigurationsByEntityIdentifier = [Internals.EntityIdentifier: Set<String>]()
    
    deinit {
        
        self.unsafeRemoveAllPersistentStores()
    }
}
