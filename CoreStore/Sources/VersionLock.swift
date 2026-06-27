//
//  VersionLock.swift
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


// MARK: - VersionLock

/**
 The `VersionLock` contains the version hashes for entities. This is then passed to the `CoreStoreSchema`, which contains all entities for the store. An assertion will be raised if any `Entity` doesn't match the version hash.
 ```
 class Animal: CoreStoreObject {
     let species = Value.Required<String>("species", initial: "")
     let nickname = Value.Optional<String>("nickname")
     let master = Relationship.ToOne<Person>("master")
 }
 class Person: CoreStoreObject {
     let name = Value.Required<String>("name", initial: "")
     let pet = Relationship.ToOne<Animal>("pet", inverse: { $0.master })
 }
 
 CoreStoreDefaults.dataStack = DataStack(
     CoreStoreSchema(
         modelVersion: "V1",
         entities: [
             Entity<Animal>("Animal"),
             Entity<Person>("Person")
         ],
         versionLock: [
             "Animal": [0x2698c812ebbc3b97, 0x751e3fa3f04cf9, 0x51fd460d3babc82, 0x92b4ba735b5a3053],
             "Person": [0xae4060a59f990ef0, 0x8ac83a6e1411c130, 0xa29fea58e2e38ab6, 0x2071bb7e33d77887]
         ]
     )
 )
 ```
 */
public struct VersionLock: ExpressibleByDictionaryLiteral, Equatable {
    
    /**
     The value type for the dictionary initializer, which is `UInt64`
     */
    public typealias HashElement = UInt64
    
    /**
     The `Data` hash for each entity name.
     */
    public let hashesByEntityName: [EntityName: Data]
    
    /**
     Initializes a `VersionLock` with the version hash for each entity name.
     */
    public init(_ intArrayByEntityName: [EntityName: [HashElement]]) {
        
        self.init(keyValues: intArrayByEntityName.map({ $0 }))
    }
    
    
    // MARK: ExpressibleByDictionaryLiteral
    
    public typealias Key = EntityName
    public typealias Value = [HashElement]
    
    public init(dictionaryLiteral elements: (EntityName, [HashElement])...) {
        
        self.init(keyValues: elements)
    }
    
    
    // MARK: Equatable
    
    public static func == (lhs: VersionLock, rhs: VersionLock) -> Bool {
        
        return lhs.hashesByEntityName == rhs.hashesByEntityName
    }
    
    
    // MARK: Internal
    
    internal init(entityVersionHashesByName: [String: Data]) {
        
        self.hashesByEntityName = entityVersionHashesByName
    }
    
    
    // MARK: Private
    
    private init(keyValues: [(EntityName, [HashElement])]) {
        
        var hashesByEntityName: [EntityName: Data] = [:]
        for (entityName, intArray) in keyValues {

            hashesByEntityName[entityName] = intArray.withUnsafeBufferPointer(Data.init(buffer:))
        }
        self.hashesByEntityName = hashesByEntityName
    }
}



