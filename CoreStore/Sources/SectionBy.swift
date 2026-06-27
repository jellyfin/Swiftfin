//
//  SectionBy.swift
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


// MARK: - SectionBy

/**
 The `SectionBy` clause indicates the key path to use to group the `ListMonitor` objects into sections. An optional closure can also be provided to transform the value into an appropriate section index title:
 ```
 let monitor = dataStack.monitorSectionedList(
     From<Person>(),
     SectionBy("age") { "Age \($0)" },
     OrderBy(.ascending("lastName"))
 )
 ```
 */
public struct SectionBy<O: DynamicObject> {
    
    /**
     Initializes a `SectionBy` clause with the key path to use to group `ListMonitor` objects into sections
     
     - parameter sectionKeyPath: the key path to use to group the objects into sections
     */
    public init(_ sectionKeyPath: KeyPathString) {
        
        self.init(
            sectionKeyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    /**
     Initializes a `SectionBy` clause with the key path to use to group `ListMonitor` objects into sections, and a closure to transform the value for the key path to an appropriate section index title
     
     - Important: Some utilities (such as `ListMonitor`s) may keep `SectionBy`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter sectionKeyPath: the key path to use to group the objects into sections
     - parameter sectionIndexTransformer: a closure to transform the value for the key path to an appropriate section index title
     */
    public init(
        _ sectionKeyPath: KeyPathString,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) {
        
        self.sectionKeyPath = sectionKeyPath
        self.sectionIndexTransformer = sectionIndexTransformer
    }
    
    
    // MARK: Internal
    
    internal let sectionKeyPath: KeyPathString
    internal let sectionIndexTransformer: (_ sectionName: String?) -> String?
}


// MARK: - SectionBy where O: NSManagedObject

extension SectionBy where O: NSManagedObject {
    
    /**
     Initializes a `SectionBy` clause with the key path to use to group `ListMonitor` objects into sections
     
     - parameter sectionKeyPath: the key path to use to group the objects into sections
     */
    public init<T>(_ sectionKeyPath: KeyPath<O, T>) {
        
        self.init(
            sectionKeyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    /**
     Initializes a `SectionBy` clause with the key path to use to group `ListMonitor` objects into sections, and a closure to transform the value for the key path to an appropriate section index title
     
     - Important: Some utilities (such as `ListMonitor`s) may keep `SectionBy`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter sectionKeyPath: the key path to use to group the objects into sections
     - parameter sectionIndexTransformer: a closure to transform the value for the key path to an appropriate section index title
     */
    public init<T>(
        _ sectionKeyPath: KeyPath<O, T>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) {
        
        self.init(
            sectionKeyPath._kvcKeyPathString!,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
}


// MARK: - SectionBy where O: CoreStoreObject

extension SectionBy where O: CoreStoreObject {

    /**
     Initializes a `SectionBy` clause with the key path to use to group `ListMonitor` objects into sections

     - parameter sectionKeyPath: the key path to use to group the objects into sections
     */
    public init<T>(_ sectionKeyPath: KeyPath<O, FieldContainer<O>.Stored<T>>) {

        self.init(
            sectionKeyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }

    /**
     Initializes a `SectionBy` clause with the key path to use to group `ListMonitor` objects into sections

     - parameter sectionKeyPath: the key path to use to group the objects into sections
     */
    public init<T>(_ sectionKeyPath: KeyPath<O, FieldContainer<O>.Virtual<T>>) {

        self.init(
            sectionKeyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }

    /**
     Initializes a `SectionBy` clause with the key path to use to group `ListMonitor` objects into sections

     - parameter sectionKeyPath: the key path to use to group the objects into sections
     */
    public init<T>(_ sectionKeyPath: KeyPath<O, FieldContainer<O>.Coded<T>>) {

        self.init(
            sectionKeyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }

    /**
     Initializes a `SectionBy` clause with the key path to use to group `ListMonitor` objects into sections, and a closure to transform the value for the key path to an appropriate section index title

     - Important: Some utilities (such as `ListMonitor`s) may keep `SectionBy`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter sectionKeyPath: the key path to use to group the objects into sections
     - parameter sectionIndexTransformer: a closure to transform the value for the key path to an appropriate section index title
     */
    public init<T>(
        _ sectionKeyPath: KeyPath<O, FieldContainer<O>.Stored<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) {

        self.init(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }

    /**
     Initializes a `SectionBy` clause with the key path to use to group `ListMonitor` objects into sections, and a closure to transform the value for the key path to an appropriate section index title

     - Important: Some utilities (such as `ListMonitor`s) may keep `SectionBy`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter sectionKeyPath: the key path to use to group the objects into sections
     - parameter sectionIndexTransformer: a closure to transform the value for the key path to an appropriate section index title
     */
    public init<T>(
        _ sectionKeyPath: KeyPath<O, FieldContainer<O>.Virtual<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) {

        self.init(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }

    /**
     Initializes a `SectionBy` clause with the key path to use to group `ListMonitor` objects into sections, and a closure to transform the value for the key path to an appropriate section index title

     - Important: Some utilities (such as `ListMonitor`s) may keep `SectionBy`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter sectionKeyPath: the key path to use to group the objects into sections
     - parameter sectionIndexTransformer: a closure to transform the value for the key path to an appropriate section index title
     */
    public init<T>(
        _ sectionKeyPath: KeyPath<O, FieldContainer<O>.Coded<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) {

        self.init(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
}


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension SectionBy {
    
    public init<T>(_ sectionKeyPath: KeyPath<O, ValueContainer<O>.Required<T>>) {
        
        self.init(
            sectionKeyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    public init<T>(_ sectionKeyPath: KeyPath<O, ValueContainer<O>.Optional<T>>) {
        
        self.init(
            sectionKeyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    public init<T>(_ sectionKeyPath: KeyPath<O, TransformableContainer<O>.Required<T>>) {
        
        self.init(
            sectionKeyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    public init<T>(_ sectionKeyPath: KeyPath<O, TransformableContainer<O>.Optional<T>>) {
        
        self.init(
            sectionKeyPath,
            sectionIndexTransformer: { _ in nil }
        )
    }
    
    public init<T>(
        _ sectionKeyPath: KeyPath<O, ValueContainer<O>.Required<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) {
        
        self.init(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
    
    public init<T>(
        _ sectionKeyPath: KeyPath<O, ValueContainer<O>.Optional<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) {
        
        self.init(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
    
    public init<T>(
        _ sectionKeyPath: KeyPath<O, TransformableContainer<O>.Required<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) {
        
        self.init(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
    
    public init<T>(
        _ sectionKeyPath: KeyPath<O, TransformableContainer<O>.Optional<T>>,
        sectionIndexTransformer: @escaping (_ sectionName: String?) -> String?
    ) {
        
        self.init(
            O.meta[keyPath: sectionKeyPath].keyPath,
            sectionIndexTransformer: sectionIndexTransformer
        )
    }
}
