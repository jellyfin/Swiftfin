//
//  CoreStoreObject+Querying.swift
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
import Foundation

// MARK: - FieldContainer.Stored

extension FieldContainer.Stored {

    /**
     Creates a `Where` clause by comparing if a property is equal to a value
     ```
     let person = dataStack.fetchOne(From<Person>().where({ $0.nickname == "John" }))
     ```
     */
    public static func == (
        _ attribute: Self,
        _ value: V
    ) -> Where<O> {

        return Where(
            attribute.keyPath,
            isEqualTo: value
        )
    }

    /**
     Creates a `Where` clause by comparing if a property is not equal to a value
     ```
     let person = dataStack.fetchOne(From<Person>().where({ $0.nickname != "John" }))
     ```
     */
    public static func != (
        _ attribute: Self,
        _ value: V
    ) -> Where<O> {

        return !Where(
            attribute.keyPath,
            isEqualTo: value
        )
    }

    /**
     Creates a `Where` clause by comparing if a property is less than a value
     ```
     let person = dataStack.fetchOne(From<Person>().where({ $0.age < 20 }))
     ```
     */
    public static func < (
        _ attribute: Self,
        _ value: V
    ) -> Where<O> {

        return Where(
            "%K < %@",
            attribute.keyPath,
            value.cs_toFieldStoredNativeType() as Any
        )
    }

    /**
     Creates a `Where` clause by comparing if a property is greater than a value
     ```
     let person = dataStack.fetchOne(From<Person>().where({ $0.age > 20 }))
     ```
     */
    public static func > (
        _ attribute: Self,
        _ value: V
    ) -> Where<O> {

        return Where(
            "%K > %@",
            attribute.keyPath,
            value.cs_toFieldStoredNativeType() as Any
        )
    }

    /**
     Creates a `Where` clause by comparing if a property is less than or equal to a value
     ```
     let person = dataStack.fetchOne(From<Person>().where({ $0.age <= 20 }))
     ```
     */
    public static func <= (
        _ attribute: Self,
        _ value: V
    ) -> Where<O> {

        return Where(
            "%K <= %@",
            attribute.keyPath,
            value.cs_toFieldStoredNativeType() as Any
        )
    }

    /**
     Creates a `Where` clause by comparing if a property is greater than or equal to a value
     ```
     let person = dataStack.fetchOne(From<Person>().where({ $0.age >= 20 }))
     ```
     */
    public static func >= (
        _ attribute: Self,
        _ value: V
    ) -> Where<O> {

        return Where(
            "%K >= %@",
            attribute.keyPath,
            value.cs_toFieldStoredNativeType() as Any
        )
    }

    /**
     Creates a `Where` clause by checking if a sequence contains the value of a property
     ```
     let dog = dataStack.fetchOne(From<Dog>().where({ ["Pluto", "Snoopy", "Scooby"] ~= $0.nickname }))
     ```
     */
    public static func ~= <S: Sequence>(
        _ sequence: S,
        _ attribute: Self
    ) -> Where<O> where S.Iterator.Element == V {

        return Where(
            attribute.keyPath,
            isMemberOf: sequence
        )
    }
}

// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension ValueContainer.Required {
    
    public static func == (_ attribute: ValueContainer<O>.Required<V>, _ value: V) -> Where<O> {
        
        return Where(attribute.keyPath, isEqualTo: value)
    }
    
    public static func != (_ attribute: ValueContainer<O>.Required<V>, _ value: V) -> Where<O> {
        
        return !Where(attribute.keyPath, isEqualTo: value)
    }
    
    public static func < (_ attribute: ValueContainer<O>.Required<V>, _ value: V) -> Where<O> {
        
        return Where("%K < %@", attribute.keyPath, value.cs_toQueryableNativeType())
    }
    
    public static func > (_ attribute: ValueContainer<O>.Required<V>, _ value: V) -> Where<O> {
        
        return Where("%K > %@", attribute.keyPath, value.cs_toQueryableNativeType())
    }
    
    public static func <= (_ attribute: ValueContainer<O>.Required<V>, _ value: V) -> Where<O> {
        
        return Where("%K <= %@", attribute.keyPath, value.cs_toQueryableNativeType())
    }
    
    public static func >= (_ attribute: ValueContainer<O>.Required<V>, _ value: V) -> Where<O> {
        
        return Where("%K >= %@", attribute.keyPath, value.cs_toQueryableNativeType())
    }
    
    public static func ~= <S: Sequence>(_ sequence: S, _ attribute: ValueContainer<O>.Required<V>) -> Where<O> where S.Iterator.Element == V {
        
        return Where(attribute.keyPath, isMemberOf: sequence)
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension ValueContainer.Optional {
    
    public static func == (_ attribute: ValueContainer<O>.Optional<V>, _ value: V?) -> Where<O> {
        
        return Where(attribute.keyPath, isEqualTo: value)
    }
    
    public static func != (_ attribute: ValueContainer<O>.Optional<V>, _ value: V?) -> Where<O> {
        
        return !Where(attribute.keyPath, isEqualTo: value)
    }
    
    public static func < (_ attribute: ValueContainer<O>.Optional<V>, _ value: V?) -> Where<O> {
        
        if let value = value {
            
            return Where("%K < %@", attribute.keyPath, value.cs_toQueryableNativeType())
        }
        else {
            
            return Where("%K < nil", attribute.keyPath)
        }
    }
    
    public static func > (_ attribute: ValueContainer<O>.Optional<V>, _ value: V?) -> Where<O> {
        
        if let value = value {
            
            return Where("%K > %@", attribute.keyPath, value.cs_toQueryableNativeType())
        }
        else {
            
            return Where("%K > nil", attribute.keyPath)
        }
    }
    
    public static func <= (_ attribute: ValueContainer<O>.Optional<V>, _ value: V?) -> Where<O> {
        
        if let value = value {
            
            return Where("%K <= %@", attribute.keyPath, value.cs_toQueryableNativeType())
        }
        else {
            
            return Where("%K <= nil", attribute.keyPath)
        }
    }
    
    public static func >= (_ attribute: ValueContainer<O>.Optional<V>, _ value: V?) -> Where<O> {
        
        if let value = value {
            
            return Where("%K >= %@", attribute.keyPath, value.cs_toQueryableNativeType())
        }
        else {
            
            return Where("%K >= nil", attribute.keyPath)
        }
    }
    
    public static func ~= <S: Sequence>(_ sequence: S, _ attribute: ValueContainer<O>.Optional<V>) -> Where<O> where S.Iterator.Element == V {
        
        return Where(attribute.keyPath, isMemberOf: sequence)
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension RelationshipContainer.ToOne {
    
    public static func == (_ relationship: RelationshipContainer<O>.ToOne<D>, _ object: D?) -> Where<O> {
        
        return Where(relationship.keyPath, isEqualTo: object)
    }
    
    public static func != (_ relationship: RelationshipContainer<O>.ToOne<D>, _ object: D?) -> Where<O> {
        
        return !Where(relationship.keyPath, isEqualTo: object)
    }
    
    public static func ~= <S: Sequence>(_ sequence: S, _ relationship: RelationshipContainer<O>.ToOne<D>) -> Where<O> where S.Iterator.Element == D {
        
        return Where(relationship.keyPath, isMemberOf: sequence)
    }
}
