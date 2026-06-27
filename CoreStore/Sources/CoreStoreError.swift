//
//  CoreStoreError.swift
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


// MARK: - CoreStoreError

/**
 All errors thrown from CoreStore are expressed in `CoreStoreError` enum values.
 */
public enum CoreStoreError: Error, CustomNSError, Hashable {
    
    /**
     A failure occured because of an unknown error.
     */
    case unknown
    
    /**
     The `NSPersistentStore` could not be initialized because another store existed at the specified `NSURL`.
     */
    case differentStorageExistsAtURL(existingPersistentStoreURL: URL)
    
    /**
     An `NSMappingModel` could not be found for a specific source and destination model versions.
     */
    case mappingModelNotFound(localStoreURL: URL, targetModel: NSManagedObjectModel, targetModelVersion: String)
    
    /**
     Progressive migrations are disabled for a store, but an `NSMappingModel` could not be found for a specific source and destination model versions.
     */
    case progressiveMigrationRequired(localStoreURL: URL)

    /**
     The `LocalStorage` was configured with `.allowSynchronousLightweightMigration`, but the model can only be migrated asynchronously.
     */
    case asynchronousMigrationRequired(localStoreURL: URL, NSError: NSError)
    
    /**
     An internal SDK call failed with the specified `NSError`.
     */
    case internalError(NSError: NSError)
    
    /**
     The transaction was terminated by a user-thrown `Error`.
     */
    case userError(error: Error)
    
    /**
     The transaction was cancelled by the user.
     */
    case userCancelled

    /**
     Attempted to perform a fetch but could not find any related persistent store.
     */
    case persistentStoreNotFound(entity: DynamicObject.Type)

    /**
     Casts any `Error` to a known `CoreStoreError`, or wraps it in `CoreStoreError.internalError(NSError:)`.
     */
    public init(_ error: Error?) {

        guard let error = error else {

            self = .unknown
            return
        }
        switch error {

        case let error as CoreStoreError:
            self = error

        case let error as NSError:
            self = .internalError(NSError: error)

        default:
            self = .unknown
        }
    }
    
    
    // MARK: CustomNSError
    
    public static var errorDomain: String {
        
        return CoreStoreErrorDomain
    }
    
    public var errorCode: Int {
    
        switch self {
            
        case .unknown:
            return CoreStoreErrorCode.unknownError.rawValue
            
        case .differentStorageExistsAtURL:
            return CoreStoreErrorCode.differentStorageExistsAtURL.rawValue
            
        case .mappingModelNotFound:
            return CoreStoreErrorCode.mappingModelNotFound.rawValue
            
        case .progressiveMigrationRequired:
            return CoreStoreErrorCode.progressiveMigrationRequired.rawValue

        case .asynchronousMigrationRequired:
            return CoreStoreErrorCode.asynchronousMigrationRequired.rawValue
            
        case .internalError:
            return CoreStoreErrorCode.internalError.rawValue
            
        case .userError:
            return CoreStoreErrorCode.userError.rawValue
            
        case .userCancelled:
            return CoreStoreErrorCode.userCancelled.rawValue

        case .persistentStoreNotFound:
            return CoreStoreErrorCode.persistentStoreNotFound.rawValue
        }
    }
    
    public var errorUserInfo: [String : Any] {
        
        switch self {
            
        case .unknown:
            return [:]
            
        case .differentStorageExistsAtURL(let existingPersistentStoreURL):
            return [
                "existingPersistentStoreURL": existingPersistentStoreURL
            ]
            
        case .mappingModelNotFound(let localStoreURL, let targetModel, let targetModelVersion):
            return [
                "localStoreURL": localStoreURL,
                "targetModel": targetModel,
                "targetModelVersion": targetModelVersion
            ]
            
        case .progressiveMigrationRequired(let localStoreURL):
            return [
                "localStoreURL": localStoreURL
            ]

        case .asynchronousMigrationRequired(let localStoreURL, let nsError):
            return [
                "localStoreURL": localStoreURL,
                "NSError": nsError
            ]
            
        case .internalError(let nsError):
            return [
                "NSError": nsError
            ]
            
        case .userError(let error):
            return [
                "Error": error
            ]
            
        case .userCancelled:
            return [:]

        case .persistentStoreNotFound(let entity):
            return [
                "entity": entity
            ]
        }
    }
    
    
    // MARK: Equatable
    
    public static func == (lhs: CoreStoreError, rhs: CoreStoreError) -> Bool {
        
        switch (lhs, rhs) {
            
        case (.unknown, .unknown):
            return true
            
        case (.differentStorageExistsAtURL(let url1), .differentStorageExistsAtURL(let url2)):
            return url1 == url2
            
        case (.mappingModelNotFound(let url1, let model1, let version1), .mappingModelNotFound(let url2, let model2, let version2)):
            return url1 == url2 && model1 == model2 && version1 == version2
            
        case (.progressiveMigrationRequired(let url1), .progressiveMigrationRequired(let url2)):
            return url1 == url2

        case (.asynchronousMigrationRequired(let url1, let NSError1), .asynchronousMigrationRequired(let url2, let NSError2)):
            return url1 == url2
                && NSError1.isEqual(NSError2)
            
        case (.internalError(let NSError1), .internalError(let NSError2)):
            return NSError1.isEqual(NSError2)
            
        case (.userError(let error1), .userError(let error2)):
            switch (error1, error2) {
            
            case (let error1 as NSError, let error2 as NSError):
                return error1.isEqual(error2)
            }
            
        case (.userCancelled, .userCancelled):
            return true

        case (.persistentStoreNotFound(let entity1), .persistentStoreNotFound(let entity2)):
            return entity1 == entity2
            
        default:
            return false
        }
    }
    
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(self._code)
        switch self {

        case .unknown:
            break

        case .differentStorageExistsAtURL(let existingPersistentStoreURL):
            hasher.combine(existingPersistentStoreURL)

        case .mappingModelNotFound(let localStoreURL, let targetModel, let targetModelVersion):
            hasher.combine(localStoreURL)
            hasher.combine(targetModel)
            hasher.combine(targetModelVersion)

        case .progressiveMigrationRequired(let localStoreURL):
            hasher.combine(localStoreURL)

        case .asynchronousMigrationRequired(let localStoreURL, let nsError):
            hasher.combine(localStoreURL)
            hasher.combine(nsError)

        case .internalError(let nsError):
            hasher.combine(nsError)

        case .userError(let error):
            hasher.combine(error as NSError)

        case .persistentStoreNotFound(let entity):
            hasher.combine(ObjectIdentifier(entity))

        case .userCancelled:
            break
        }
    }
}


// MARK: - CoreStoreErrorDomain

/**
 The `NSError` error domain string for `CSError`.
 */
@nonobjc
public let CoreStoreErrorDomain = "com.corestore.error"


// MARK: - CoreStoreErrorCode

/**
 The `NSError` error codes for `CoreStoreErrorDomain`.
 */
public enum CoreStoreErrorCode: Int {
    
    /**
     A failure occured because of an unknown error.
     */
    case unknownError
    
    /**
     The `NSPersistentStore` could note be initialized because another store existed at the specified `NSURL`.
     */
    case differentStorageExistsAtURL
    
    /**
     An `NSMappingModel` could not be found for a specific source and destination model versions.
     */
    case mappingModelNotFound
    
    /**
     Progressive migrations are disabled for a store, but an `NSMappingModel` could not be found for a specific source and destination model versions.
     */
    case progressiveMigrationRequired

    /**
     The `LocalStorage` was configured with `.allowSynchronousLightweightMigration`, but the model can only be migrated asynchronously.
     */
    case asynchronousMigrationRequired
    
    /**
     An internal SDK call failed with the specified "NSError" userInfo key.
     */
    case internalError
    
    /**
     The transaction was terminated by a user-thrown `Error` specified by "Error" userInfo key.
     */
    case userError
    
    /**
     The transaction was cancelled by the user.
     */
    case userCancelled

    /**
     Attempted to perform a fetch but could not find any related persistent store.
     */
    case persistentStoreNotFound
}


// MARK: - NSError

extension NSError {
    
    // MARK: Internal
    
    internal var isCoreDataMigrationError: Bool {
        
        guard self.domain == CocoaError.errorDomain else {
            
            return false
        }
        switch CocoaError.Code(rawValue: self.code) {
            
        case CocoaError.Code.persistentStoreIncompatibleSchema,
             CocoaError.Code.persistentStoreIncompatibleVersionHash,
             CocoaError.Code.migrationMissingSourceModel,
             CocoaError.Code.migration:
            return true
            
        default:
            return false
        }
    }
}
