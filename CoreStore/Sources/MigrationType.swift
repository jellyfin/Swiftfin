//
//  MigrationType.swift
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


// MARK: - MigrationType

/**
 The `MigrationType` specifies the type of migration required for a store.
 */
public enum MigrationType: Hashable {
    
    /**
     Indicates that the persistent store matches the latest model version and no migration is needed
     */
    case none(version: ModelVersion)
    
    /**
     Indicates that the persistent store does not match the latest model version but Core Data can infer the mapping model, so a lightweight migration is needed
     */
    case lightweight(sourceVersion: ModelVersion, destinationVersion: ModelVersion)
    
    /**
     Indicates that the persistent store does not match the latest model version and Core Data could not infer a mapping model, so a custom migration is needed
     */
    case heavyweight(sourceVersion: ModelVersion, destinationVersion: ModelVersion)
    
    /**
     Returns the source model version for the migration type. If no migration is required, `sourceVersion` will be equal to the `destinationVersion`.
     */
    public var sourceVersion: ModelVersion {
        
        switch self {
            
        case .none(let version):
            return version
            
        case .lightweight(let sourceVersion, _):
            return sourceVersion
            
        case .heavyweight(let sourceVersion, _):
            return sourceVersion
        }
    }
    
    /**
     Returns the destination model version for the migration type. If no migration is required, `destinationVersion` will be equal to the `sourceVersion`.
     */
    public var destinationVersion: ModelVersion {
        
        switch self {
            
        case .none(let version):
            return version
            
        case .lightweight(_, let destinationVersion):
            return destinationVersion
            
        case .heavyweight(_, let destinationVersion):
            return destinationVersion
        }
    }
    
    /**
     Returns `true` if the `MigrationType` is a lightweight migration. Used as syntactic sugar.
     */
    public var isLightweightMigration: Bool {
        
        if case .lightweight = self {
            
            return true
        }
        return false
    }
    
    /**
     Returns `true` if the `MigrationType` is a heavyweight migration. Used as syntactic sugar.
     */
    public var isHeavyweightMigration: Bool {
        
        if case .heavyweight = self {
            
            return true
        }
        return false
    }
    
    /**
     Returns `true` if the `MigrationType` is either a lightweight or a heavyweight migration. Returns `false` if no migrations specified.
     */
    public var hasMigration: Bool {
        
        switch self {
            
        case .none:         return false
        case .lightweight:  return true
        case .heavyweight:  return true
        }
    }
    
    
    // MARK: Equatable
    
    public static func == (lhs: MigrationType, rhs: MigrationType) -> Bool {
        
        switch (lhs, rhs) {
            
        case (.none(let version1), .none(let version2)):
            return version1 == version2
            
        case (.lightweight(let source1, let destination1), .lightweight(let source2, let destination2)):
            return source1 == source2 && destination1 == destination2
            
        case (.heavyweight(let source1, let destination1), .heavyweight(let source2, let destination2)):
            return source1 == source2 && destination1 == destination2
            
        default:
            return false
        }
    }
    
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(self.hasMigration)
        hasher.combine(self.isHeavyweightMigration)
        switch self {
            
        case .none(let version):
            hasher.combine(version)
            
        case .lightweight(let sourceVersion, let destinationVersion):
            hasher.combine(sourceVersion)
            hasher.combine(destinationVersion)
            
        case .heavyweight(let sourceVersion, let destinationVersion):
            hasher.combine(sourceVersion)
            hasher.combine(destinationVersion)
        }
    }
}
