//
//  SQLiteStore.swift
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


// MARK: - SQLiteStore

/**
 A storage interface that is backed by an SQLite database.
 
 - Warning: The default SQLite file location for the `LegacySQLiteStore` and `SQLiteStore` are different. If the app was depending on CoreStore's default directories prior to 2.0.0, make sure to use the `SQLiteStore.legacy(...)` factory methods to create the `SQLiteStore` instead of using initializers directly.
 */
public final class SQLiteStore: LocalStorage {
    
    /**
     Initializes an SQLite store interface from the given SQLite file URL. When this instance is passed to the `DataStack`'s `addStorage()` methods, a new SQLite file will be created if it does not exist.
     
     - parameter fileURL: the local file URL for the target SQLite persistent store. Note that if you have multiple configurations, you will need to specify a different `fileURL` explicitly for each of them.
     - parameter configuration: an optional configuration name from the model file. If not specified, defaults to `nil`, the "Default" configuration. Note that if you have multiple configurations, you will need to specify a different `fileURL` explicitly for each of them.
     - parameter migrationMappingProviders: an array of `SchemaMappingProviders` that provides the complete mapping models for custom migrations. All lightweight inferred mappings and/or migration mappings provided by *xcmappingmodel files are automatically used as fallback (as `InferredSchemaMappingProvider`) and may be omitted from the array.
     - parameter localStorageOptions: When the `SQLiteStore` is passed to the `DataStack`'s `addStorage()` methods, tells the `DataStack` how to setup the persistent store. Defaults to `.none`.
     */
    public init(
        fileURL: URL,
        configuration: ModelConfiguration = nil,
        migrationMappingProviders: [SchemaMappingProvider] = [],
        localStorageOptions: LocalStorageOptions = nil
    ) {

        self.fileURL = fileURL
        self.configuration = configuration
        self.migrationMappingProviders = migrationMappingProviders
        self.localStorageOptions = localStorageOptions
    }
    
    /**
     Initializes an SQLite store interface from the given SQLite file name. When this instance is passed to the `DataStack`'s `addStorage()` methods, a new SQLite file will be created if it does not exist.
     
     - Warning: The default SQLite file location for the `LegacySQLiteStore` and `SQLiteStore` are different. If the app was depending on CoreStore's default directories prior to 2.0.0, make sure to use the `SQLiteStore.legacy(...)` factory methods to create the `SQLiteStore` instead of using initializers directly.
     - parameter fileName: the local filename for the SQLite persistent store in the "Application Support/<bundle id>" directory (or the "Caches/<bundle id>" directory on tvOS). Note that if you have multiple configurations, you will need to specify a different `fileName` explicitly for each of them.
     - parameter configuration: an optional configuration name from the model file. If not specified, defaults to `nil`, the "Default" configuration. Note that if you have multiple configurations, you will need to specify a different `fileName` explicitly for each of them.
     - parameter migrationMappingProviders: an array of `SchemaMappingProviders` that provides the complete mapping models for custom migrations. All lightweight inferred mappings and/or migration mappings provided by *xcmappingmodel files are automatically used as fallback (as `InferredSchemaMappingProvider`) and may be omitted from the array.
     - parameter localStorageOptions: When the `SQLiteStore` is passed to the `DataStack`'s `addStorage()` methods, tells the `DataStack` how to setup the persistent store. Defaults to `.None`.
     */
    public init(
        fileName: String,
        configuration: ModelConfiguration = nil,
        migrationMappingProviders: [SchemaMappingProvider] = [],
        localStorageOptions: LocalStorageOptions = nil
    ) {

        self.fileURL = SQLiteStore.defaultRootDirectory
            .appendingPathComponent(fileName, isDirectory: false)
        self.configuration = configuration
        self.migrationMappingProviders = migrationMappingProviders
        self.localStorageOptions = localStorageOptions
    }
    
    /**
     Initializes an `SQLiteStore` with an all-default settings: a `fileURL` pointing to a "<Application name>.sqlite" file in the "Application Support/<bundle id>" directory (or the "Caches/<bundle id>" directory on tvOS), a `nil` `configuration` pertaining to the "Default" configuration, a `migrationMappingProviders` set to empty, and `localStorageOptions` set to `.AllowProgresiveMigration`.
     
     - Warning: The default SQLite file location for the `LegacySQLiteStore` and `SQLiteStore` are different. If the app was depending on CoreStore's default directories prior to 2.0.0, make sure to use the `SQLiteStore.legacy(...)` factory methods to create the `SQLiteStore` instead of using initializers directly.
     */
    public init() {
        
        self.fileURL = SQLiteStore.defaultFileURL
        self.configuration = nil
        self.migrationMappingProviders = []
        self.localStorageOptions = nil
    }
    
    /**
     Initializes an SQLite store interface from the given SQLite file name. When this instance is passed to the `DataStack`'s `addStorage()` methods, a new SQLite file will be created if it does not exist.
     
     - Warning: The default SQLite file location for the `LegacySQLiteStore` and `SQLiteStore` are different. If the app was depending on CoreStore's default directories prior to 2.0.0, make sure to use the `SQLiteStore.legacy(...)` factory methods to create the `SQLiteStore` instead of using initializers directly.
     - parameter legacyFileName: the local filename for the SQLite persistent store in the "Application Support" directory (or the "Caches" directory on tvOS). Note that if you have multiple configurations, you will need to specify a different `fileName` explicitly for each of them.
     - parameter configuration: an optional configuration name from the model file. If not specified, defaults to `nil`, the "Default" configuration. Note that if you have multiple configurations, you will need to specify a different `fileName` explicitly for each of them.
     - parameter migrationMappingProviders: an array of `SchemaMappingProviders` that provides the complete mapping models for custom migrations. All lightweight inferred mappings and/or migration mappings provided by *xcmappingmodel files are automatically used as fallback (as `InferredSchemaMappingProvider`) and may be omitted from the array.
     - parameter localStorageOptions: When the `SQLiteStore` is passed to the `DataStack`'s `addStorage()` methods, tells the `DataStack` how to setup the persistent store. Defaults to `.None`.
     */
    public static func legacy(
        fileName: String,
        configuration: ModelConfiguration = nil,
        migrationMappingProviders: [SchemaMappingProvider] = [],
        localStorageOptions: LocalStorageOptions = nil
    ) -> SQLiteStore {

        return SQLiteStore(
            fileURL: SQLiteStore.legacyDefaultRootDirectory
                .appendingPathComponent(fileName, isDirectory: false),
            configuration: configuration,
            migrationMappingProviders: migrationMappingProviders,
            localStorageOptions: localStorageOptions
        )
    }
    
    /**
     Initializes an `LegacySQLiteStore` with an all-default settings: a `fileURL` pointing to a "<Application name>.sqlite" file in the "Application Support" directory (or the "Caches" directory on tvOS), a `nil` `configuration` pertaining to the "Default" configuration, a `migrationMappingProviders` set to empty, and `localStorageOptions` set to `.AllowProgresiveMigration`.
     
     - Warning: The default SQLite file location for the `LegacySQLiteStore` and `SQLiteStore` are different. If the app was depending on CoreStore's default directories prior to 2.0.0, make sure to use the `SQLiteStore.legacy(...)` factory methods to create the `SQLiteStore` instead of using initializers directly.
     */
    public static func legacy() -> SQLiteStore {
        
        return SQLiteStore(
            fileURL: SQLiteStore.legacyDefaultFileURL,
            configuration: nil,
            migrationMappingProviders: [],
            localStorageOptions: nil
        )
    }
    
    /**
     Queries the file size (in bytes) of the store, or `nil` if the file does not exist yet
     */
    public func fileSize() -> UInt64? {
        
        guard let attribute = try? FileManager.default.attributesOfItem(atPath: self.fileURL.path),
            let sizeAttribute = attribute[.size],
            let fileSize = sizeAttribute as? NSNumber else {
                
                return nil
        }
        return fileSize.uint64Value
    }
    
    
    // MARK: StorageInterface
    
    /**
     The string identifier for the `NSPersistentStore`'s `type` property. For `SQLiteStore`s, this is always set to `NSSQLiteStoreType`.
     */
    public static let storeType = NSSQLiteStoreType
    
    /**
     The configuration name in the model file
     */
    public let configuration: ModelConfiguration
    
    /**
     The options dictionary for the `NSPersistentStore`. For `SQLiteStore`s, this is always set to 
     ```
     [NSSQLitePragmasOption: ["journal_mode": "WAL"]]
     ```
     */
    public let storeOptions: [AnyHashable: Any]? = [
        NSSQLitePragmasOption: ["journal_mode": "WAL"],
        NSBinaryStoreInsecureDecodingCompatibilityOption: true
    ]
    
    /**
     Do not call directly. Used by the `DataStack` internally.
     */
    public func cs_didAddToDataStack(_ dataStack: DataStack) {
        
        self.dataStack = dataStack
    }
    
    /**
     Do not call directly. Used by the `DataStack` internally.
     */
    public func cs_didRemoveFromDataStack(_ dataStack: DataStack) {
        
        self.dataStack = nil
    }
    
    
    // MAKR: LocalStorage
    
    /**
     The `NSURL` that points to the SQLite file
     */
    public let fileURL: URL
    
    /**
     An array of `SchemaMappingProviders` that provides the complete mapping models for custom migrations.
     */
    public let migrationMappingProviders: [SchemaMappingProvider]
    
    /**
     Options that tell the `DataStack` how to setup the persistent store
     */
    public var localStorageOptions: LocalStorageOptions
    
    /**
     The options dictionary for the specified `LocalStorageOptions`
     */
    public func dictionary(
        forOptions options: LocalStorageOptions
    ) -> [AnyHashable: Any]? {

        if options == .none {
            
            return self.storeOptions
        }
        
        var storeOptions = self.storeOptions ?? [:]
        if options.contains(.allowSynchronousLightweightMigration) {
            
            storeOptions[NSMigratePersistentStoresAutomaticallyOption] = true
            storeOptions[NSInferMappingModelAutomaticallyOption] = true
        }
        return storeOptions
    }
    
    /**
     Called by the `DataStack` to perform checkpoint operations on the storage. For `SQLiteStore`, this converts the database's WAL journaling mode to DELETE to force a checkpoint.
     */
    public func cs_finalizeStorageAndWait(
        soureModelHint: NSManagedObjectModel
    ) throws(any Swift.Error) {

        _ = try withExtendedLifetime(NSPersistentStoreCoordinator(managedObjectModel: soureModelHint)) { (coordinator: NSPersistentStoreCoordinator) in
            
            var storeOptions = self.storeOptions ?? [:]
            storeOptions[NSSQLitePragmasOption] = ["journal_mode": "DELETE"]
            try coordinator.addPersistentStore(
                ofType: Self.storeType,
                configurationName: self.configuration,
                at: fileURL,
                options: storeOptions
            )
        }
        _ = try? FileManager.default.removeItem(atPath: "\(self.fileURL.path)-shm")
    }
    
    /**
     Called by the `DataStack` to perform actual deletion of the store file from disk. Do not call directly! The `sourceModel` argument is a hint for the existing store's model version. For `SQLiteStore`, this converts the database's WAL journaling mode to DELETE before deleting the file.
     */
    public func cs_eraseStorageAndWait(
        metadata: [String: Any],
        soureModelHint: NSManagedObjectModel?
    ) throws(any Swift.Error) {

        func deleteFiles(
            storeURL: URL,
            extraFiles: [String] = []
        ) throws(any Swift.Error) {

            let fileManager = FileManager.default
            let extraFiles: [String] = [
                storeURL.path.appending("-wal"),
                storeURL.path.appending("-shm")
            ]
            do {
                
                let trashURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
                    .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.CoreStore.DataStack", isDirectory: true)
                    .appendingPathComponent("trash", isDirectory: true)
                try fileManager.createDirectory(
                    at: trashURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                
                let temporaryFileURL = trashURL.appendingPathComponent(UUID().uuidString, isDirectory: false)
                try fileManager.moveItem(at: storeURL, to: temporaryFileURL)
                
                let extraTemporaryFiles = extraFiles.map { (extraFile) -> String in
                    
                    let temporaryFile = trashURL.appendingPathComponent(UUID().uuidString, isDirectory: false).path
                    if let _ = try? fileManager.moveItem(atPath: extraFile, toPath: temporaryFile) {
                        
                        return temporaryFile
                    }
                    return extraFile
                }
                DispatchQueue.global(qos: .background).async {

                    let fileManager = FileManager.default
                    _ = try? fileManager.removeItem(at: temporaryFileURL)
                    extraTemporaryFiles.forEach({ _ = try? fileManager.removeItem(atPath: $0) })
                }
            }
            catch {
                
                try fileManager.removeItem(at: storeURL)
                extraFiles.forEach({ _ = try? fileManager.removeItem(atPath: $0) })
            }
        }
        
        let fileURL = self.fileURL
        try Internals.autoreleasepool {
            
            if let soureModel = soureModelHint ?? NSManagedObjectModel.mergedModel(from: nil, forStoreMetadata: metadata) {
                
                let journalUpdatingCoordinator = NSPersistentStoreCoordinator(managedObjectModel: soureModel)
                var storeOptions = self.storeOptions ?? [:]
                storeOptions[NSSQLitePragmasOption] = ["journal_mode": "DELETE"]
                let store = try journalUpdatingCoordinator.addPersistentStore(
                    ofType: Self.storeType,
                    configurationName: self.configuration,
                    at: fileURL,
                    options: storeOptions
                )
                try journalUpdatingCoordinator.remove(store)
            }
            try deleteFiles(storeURL: fileURL)
        }
    }
    
    
    // MARK: Internal
    
    internal static let defaultRootDirectory: URL = Internals.with {
        
        #if os(tvOS)
            let systemDirectorySearchPath = FileManager.SearchPathDirectory.cachesDirectory
        #else
            let systemDirectorySearchPath = FileManager.SearchPathDirectory.applicationSupportDirectory
        #endif
        
        let defaultSystemDirectory = FileManager.default.urls(
                for: systemDirectorySearchPath,
                in: .userDomainMask).first!
        
        return defaultSystemDirectory.appendingPathComponent(
            Bundle.main.bundleIdentifier ?? "com.CoreStore.DataStack",
            isDirectory: true
        )
    }
    
    internal static let defaultFileURL = SQLiteStore.defaultRootDirectory
        .appendingPathComponent(
            (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "CoreData",
            isDirectory: false
        )
        .appendingPathExtension("sqlite")
    
    internal static let legacyDefaultRootDirectory: URL = Internals.with {
        
        #if os(tvOS)
            let systemDirectorySearchPath = FileManager.SearchPathDirectory.cachesDirectory
        #else
            let systemDirectorySearchPath = FileManager.SearchPathDirectory.applicationSupportDirectory
        #endif
        
        return FileManager.default.urls(
            for: systemDirectorySearchPath,
            in: .userDomainMask).first!
    }
    
    internal static let legacyDefaultFileURL = Internals.with {
        
        return SQLiteStore.legacyDefaultRootDirectory
        .appendingPathComponent(DataStack.applicationName, isDirectory: false)
        .appendingPathExtension("sqlite")
    }
    
    
    // MARK: Private
    
    private weak var dataStack: DataStack?
}
