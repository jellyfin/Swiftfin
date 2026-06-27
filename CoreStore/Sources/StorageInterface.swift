//
//  StorageInterface.swift
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


// MARK: - StorageInterface

/**
 The `StorageInterface` represents the data store managed (or to be managed) by the `DataStack`. When added to the `DataStack`, the `StorageInterface` serves as the interface for the `NSPersistentStore`. This may be a database file, an in-memory store, etc.
 */
public protocol StorageInterface: AnyObject {
    
    /**
     The string identifier for the `NSPersistentStore`'s `type` property. This is the same string CoreStore will use to create the `NSPersistentStore` from the `NSPersistentStoreCoordinator`'s `addPersistentStoreWithType(...)` method.
     */
    static var storeType: String { get }
    
    /**
     The configuration name in the model file
     */
    var configuration: ModelConfiguration { get }
    
    /**
     The options dictionary for the `NSPersistentStore`
     */
    var storeOptions: [AnyHashable: Any]? { get }
    
    
    // MARK: Internal (Do not call these directly)
    
    /**
     Do not call directly. Used by the `DataStack` internally.
     */
    func cs_didAddToDataStack(_ dataStack: DataStack)
    
    /**
     Do not call directly. Used by the `DataStack` internally.
     */
    func cs_didRemoveFromDataStack(_ dataStack: DataStack)
}


// MARK: - LocalStorageOptions

/**
 The `LocalStorageOptions` provides settings that tells the `DataStack` how to setup the persistent store for `LocalStorage` implementers.
 */
public struct LocalStorageOptions: OptionSet, ExpressibleByNilLiteral {
    
    /**
     Tells the `DataStack` that the store should not be migrated or recreated, and should simply fail on model mismatch
     */
    public static let none: LocalStorageOptions = []
    
    /**
     Tells the `DataStack` to delete and recreate the store on model mismatch, otherwise exceptions will be thrown on failure instead
     */
    public static let recreateStoreOnModelMismatch: LocalStorageOptions = .init(rawValue: 1 << 0)
    
    /**
     Tells the `DataStack` to prevent progressive migrations for the store
     */
    public static let preventProgressiveMigration: LocalStorageOptions = .init(rawValue: 1 << 1)
    
    /**
     Tells the `DataStack` to allow lightweight migration for the store when added synchronously
     */
    public static let allowSynchronousLightweightMigration: LocalStorageOptions = .init(rawValue: 1 << 2)
    
    
    
    // MARK: OptionSetType
    
    public init(rawValue: Int) {
        
        self.rawValue = rawValue
    }
    
    
    // MARK: RawRepresentable
    
    public let rawValue: Int
    
    
    // MARK: ExpressibleByNilLiteral
    
    public init(nilLiteral: ()) {
        
        self.rawValue = 0
    }
}


// MARK: - LocalStorage

/**
 The `LocalStorage` represents `StorageInterface`s that are backed by local files.
 */
public protocol LocalStorage: StorageInterface {
    
    /**
     The `NSURL` that points to the store file
     */
    var fileURL: URL { get }
    
    /**
     An array of `SchemaMappingProvider`s that provide the complete mapping models for custom migrations.
     */
    var migrationMappingProviders: [SchemaMappingProvider] { get }
    
    /**
     Options that tell the `DataStack` how to setup the persistent store
     */
    var localStorageOptions: LocalStorageOptions { get }
    
    /**
     The options dictionary for the specified `LocalStorageOptions`
     */
    func dictionary(
        forOptions options: LocalStorageOptions
    ) -> [AnyHashable: Any]?

    /**
     Called by the `DataStack` to perform checkpoint operations on the storage. (SQLite stores for example, can convert the database's WAL journaling mode to DELETE to force a checkpoint)
     */
    func cs_finalizeStorageAndWait(
        soureModelHint: NSManagedObjectModel
    ) throws(any Swift.Error)

    /**
     Called by the `DataStack` to perform actual deletion of the store file from disk. **Do not call directly!** The `sourceModel` argument is a hint for the existing store's model version. Implementers can use the `sourceModel` to perform necessary store operations. (SQLite stores for example, can convert WAL journaling mode to DELETE before deleting)
     */
    func cs_eraseStorageAndWait(
        metadata: [String: Any], 
        soureModelHint: NSManagedObjectModel?
    ) throws(any Swift.Error)
}

extension LocalStorage {
    
    internal func matchesPersistentStore(_ persistentStore: NSPersistentStore) -> Bool {
        
        return persistentStore.type == Self.storeType
            && persistentStore.configurationName == (self.configuration ?? DataStack.defaultConfigurationName)
            && persistentStore.url == self.fileURL
    }
}
