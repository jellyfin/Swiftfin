//
//  InMemoryStore.swift
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


// MARK: - InMemoryStore

/**
 A storage interface that is backed only in memory.
 */
public final class InMemoryStore: StorageInterface {
    
    /**
     Initializes an `InMemoryStore` for the specified configuration
     - parameter configuration: an optional configuration name from the model file. If not specified, defaults to `nil`, the "Default" configuration.
     */
    public init(configuration: ModelConfiguration) {
    
        self.configuration = configuration
    }
    
    /**
     Initializes an `InMemoryStore` with the "Default" configuration
     */
    public init() {
        
        self.configuration = nil
    }
    
    
    // MARK: StorageInterface
    
    /**
     The string identifier for the `NSPersistentStore`'s `type` property. For `InMemoryStore`s, this is always set to `NSInMemoryStoreType`.
     */
    public static let storeType = NSInMemoryStoreType
    
    /**
     The configuration name in the model file
     */
    public let configuration: ModelConfiguration
    
    /**
     The options dictionary for the `NSPersistentStore`. For `InMemoryStore`s, this is always set to `nil`.
     */
    public let storeOptions: [AnyHashable: Any]? = nil
    
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
    
    
    // MARK: Private
    
    private weak var dataStack: DataStack?
}
