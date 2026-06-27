//
//  GroupBy.swift
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


// MARK: - GroupBy

/**
 The `GroupBy` clause specifies that the result of a query be grouped accoording to the specified key path.
 */
public struct GroupBy<O: DynamicObject>: GroupByClause, QueryClause, Hashable {
    
    /**
     Initializes a `GroupBy` clause with an empty list of key path strings
     */
    public init() {
        
        self.init([])
    }
    
    /**
     Initializes a `GroupBy` clause with a list of key path strings
     
     - parameter keyPath: a key path string to group results with
     - parameter keyPaths: a series of key path strings to group results with
     */
    public init(_ keyPath: KeyPathString, _ keyPaths: KeyPathString...) {
        
        self.init([keyPath] + keyPaths)
    }
    
    /**
     Initializes a `GroupBy` clause with a list of key path strings
     
     - parameter keyPaths: a list of key path strings to group results with
     */
    public init(_ keyPaths: [KeyPathString]) {
        
        self.keyPaths = keyPaths
    }
    
    
    // MARK: GroupByClause
    
    public typealias ObjectType = O
    
    public let keyPaths: [KeyPathString]
    
    
    // MARK: QueryClause
    
    public func applyToFetchRequest<ResultType>(_ fetchRequest: NSFetchRequest<ResultType>) {
        
        if let keyPaths = fetchRequest.propertiesToGroupBy as? [String], keyPaths != self.keyPaths {
            
            Internals.log(
                .warning,
                message: "An existing \"propertiesToGroupBy\" for the \(Internals.typeName(NSFetchRequest<ResultType>.self)) was overwritten by \(Internals.typeName(self)) query clause."
            )
        }
        
        fetchRequest.propertiesToGroupBy = self.keyPaths
    }
    
    
    // MARK: Equatable
    
    public static func == (lhs: GroupBy, rhs: GroupBy) -> Bool {
        
        return lhs.keyPaths == rhs.keyPaths
    }
    
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(self.keyPaths)
    }
}

extension GroupBy where O: NSManagedObject {
    
    /**
     Initializes a `GroupBy` clause with a key path
     
     - parameter keyPath: a key path to group results with
     */
    public init<T>(_ keyPath: KeyPath<O, T>) {
        
        self.init([keyPath._kvcKeyPathString!])
    }
}

extension GroupBy where O: CoreStoreObject {
    
    /**
     Initializes a `GroupBy` clause with a key path
     
     - parameter keyPath: a key path to group results with
     */
    public init<T>(_ keyPath: KeyPath<O, FieldContainer<O>.Stored<T>>) {
        
        self.init([O.meta[keyPath: keyPath].keyPath])
    }
    
    /**
     Initializes a `GroupBy` clause with a key path
     
     - parameter keyPath: a key path to group results with
     */
    public init<T>(_ keyPath: KeyPath<O, FieldContainer<O>.Virtual<T>>) {
        
        self.init([O.meta[keyPath: keyPath].keyPath])
    }
    
    /**
     Initializes a `GroupBy` clause with a key path
     
     - parameter keyPath: a key path to group results with
     */
    public init<T>(_ keyPath: KeyPath<O, FieldContainer<O>.Coded<T>>) {
        
        self.init([O.meta[keyPath: keyPath].keyPath])
    }
}


// MARK: - GroupByClause

/**
 Abstracts the `GroupBy` clause for protocol utilities.
 */
public protocol GroupByClause {
    
    /**
     The `DynamicObject` type associated with the clause
     */
    associatedtype ObjectType: DynamicObject
    
    /**
     The list of key path strings to group results with
     */
    var keyPaths: [KeyPathString] { get }
}


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension GroupBy where O: CoreStoreObject {
    
    public init<T>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<T>>) {
        
        self.init([O.meta[keyPath: keyPath].keyPath])
    }
    
    public init<T>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<T>>) {
        
        self.init([O.meta[keyPath: keyPath].keyPath])
    }
    
    public init<T>(_ keyPath: KeyPath<O, TransformableContainer<O>.Required<T>>) {
        
        self.init([O.meta[keyPath: keyPath].keyPath])
    }
    
    public init<T>(_ keyPath: KeyPath<O, TransformableContainer<O>.Optional<T>>) {
        
        self.init([O.meta[keyPath: keyPath].keyPath])
    }
}
