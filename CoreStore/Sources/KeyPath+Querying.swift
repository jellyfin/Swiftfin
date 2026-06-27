//
//  KeyPath+Querying.swift
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


// MARK: - KeyPath where Root: NSManagedObject, Value: QueryableAttributeType & Equatable

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.nickname == "John"))
 ```
 */
public func == <O: NSManagedObject, V: QueryableAttributeType & Equatable>(
    _ keyPath: KeyPath<O, V>,
    _ value: V
) -> Where<O> {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: value
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.nickname != "John"))
 ```
 */
public func != <O: NSManagedObject, V: QueryableAttributeType & Equatable>(
    _ keyPath: KeyPath<O, V>,
    _ value: V
) -> Where<O> {

    return !Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: value
    )
}

/**
 Creates a `Where` clause by checking if a sequence contains the value of a property
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(["Pluto", "Snoopy", "Scooby"] ~= \.nickname))
 ```
 */
public func ~= <O: NSManagedObject, V: QueryableAttributeType & Equatable, S: Sequence>(
    _ sequence: S,
    _ keyPath: KeyPath<O, V>
) -> Where<O> where S.Iterator.Element == V {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isMemberOf: sequence
    )
}


// MARK: - KeyPath where Root: NSManagedObject, Value: Optional<QueryableAttributeType & Equatable>

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.nickname == "John"))
 ```
 */
public func == <O: NSManagedObject, V: QueryableAttributeType & Equatable>(
    _ keyPath: KeyPath<O, Optional<V>>,
    _ value: V?
) -> Where<O> {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: value
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.nickname != "John"))
 ```
 */
public func != <O: NSManagedObject, V: QueryableAttributeType & Equatable>(
    _ keyPath: KeyPath<O, Optional<V>>,
    _ value: V?
) -> Where<O> {

    return !Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: value
    )
}

/**
 Creates a `Where` clause by checking if a sequence contains the value of a property
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(["Pluto", "Snoopy", "Scooby"] ~= \.nickname))
 ```
 */
public func ~= <O: NSManagedObject, V: QueryableAttributeType & Equatable, S: Sequence>(
    _ sequence: S,
    _ keyPath: KeyPath<O, Optional<V>>
) -> Where<O> where S.Iterator.Element == V {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isMemberOf: sequence
    )
}


// MARK: - KeyPath where Root: NSManagedObject, Value: QueryableAttributeType & Comparable

/**
 Creates a `Where` clause by comparing if a property is less than a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.age < 20))
 ```
 */
public func < <O: NSManagedObject, V: QueryableAttributeType & Comparable>(
    _ keyPath: KeyPath<O, V>,
    _ value: V
) -> Where<O> {

    return Where<O>(
        "%K < %@",
        keyPath._kvcKeyPathString!,
        value.cs_toQueryableNativeType()
    )
}

/**
 Creates a `Where` clause by comparing if a property is greater than a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.age > 20))
 ```
 */
public func > <O: NSManagedObject, V: QueryableAttributeType & Comparable>(
    _ keyPath: KeyPath<O, V>,
    _ value: V
) -> Where<O> {

    return Where<O>(
        "%K > %@",
        keyPath._kvcKeyPathString!,
        value.cs_toQueryableNativeType()
    )
}

/**
 Creates a `Where` clause by comparing if a property is less than or equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.age <= 20))
 ```
 */
public func <= <O: NSManagedObject, V: QueryableAttributeType & Comparable>(
    _ keyPath: KeyPath<O, V>,
    _ value: V
) -> Where<O> {

    return Where<O>(
        "%K <= %@",
        keyPath._kvcKeyPathString!,
        value.cs_toQueryableNativeType()
    )
}

/**
 Creates a `Where` clause by comparing if a property is greater than or equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.age >= 20))
 ```
 */
public func >= <O: NSManagedObject, V: QueryableAttributeType & Comparable>(
    _ keyPath: KeyPath<O, V>,
    _ value: V
) -> Where<O> {

    return Where<O>(
        "%K >= %@",
        keyPath._kvcKeyPathString!,
        value.cs_toQueryableNativeType()
    )
}


// MARK: - KeyPath where Root: NSManagedObject, Value: Optional<QueryableAttributeType & Comparable>

/**
 Creates a `Where` clause by comparing if a property is less than a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.age < 20))
 ```
 */
public func < <O: NSManagedObject, V: QueryableAttributeType & Comparable>(
    _ keyPath: KeyPath<O, Optional<V>>,
    _ value: V?
) -> Where<O> {

    if let value = value {
        
        return Where<O>(
            "%K < %@",
            keyPath._kvcKeyPathString!,
            value.cs_toQueryableNativeType()
        )
    }
    else {
        
        return Where<O>(
            "%K < nil",
            keyPath._kvcKeyPathString!
        )
    }
}

/**
 Creates a `Where` clause by comparing if a property is greater than a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.age > 20))
 ```
 */
public func > <O: NSManagedObject, V: QueryableAttributeType & Comparable>(
    _ keyPath: KeyPath<O, Optional<V>>,
    _ value: V?
) -> Where<O> {

    if let value = value {
        
        return Where<O>(
            "%K > %@",
            keyPath._kvcKeyPathString!,
            value.cs_toQueryableNativeType()
        )
    }
    else {
        
        return Where<O>(
            "%K > nil",
            keyPath._kvcKeyPathString!
        )
    }
}

/**
 Creates a `Where` clause by comparing if a property is less than or equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.age <= 20))
 ```
 */
public func <= <O: NSManagedObject, V: QueryableAttributeType & Comparable>(
    _ keyPath: KeyPath<O, Optional<V>>,
    _ value: V?
) -> Where<O> {

    if let value = value {
        
        return Where<O>(
            "%K <= %@",
            keyPath._kvcKeyPathString!,
            value.cs_toQueryableNativeType()
        )
    }
    else {
        
        return Where<O>(
            "%K <= nil",
            keyPath._kvcKeyPathString!
        )
    }
}

/**
 Creates a `Where` clause by comparing if a property is greater than or equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.age >= 20))
 ```
 */
public func >= <O: NSManagedObject, V: QueryableAttributeType & Comparable>(
    _ keyPath: KeyPath<O, Optional<V>>,
    _ value: V?
) -> Where<O> {

    if let value = value {
        
        return Where<O>(
            "%K >= %@",
            keyPath._kvcKeyPathString!,
            value.cs_toQueryableNativeType()
        )
    }
    else {
        
        return Where<O>(
            "%K >= nil",
            keyPath._kvcKeyPathString!
        )
    }
}


// MARK: - KeyPath where Root: NSManagedObject, Value: NSManagedObject

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master == john))
 ```
 */
public func == <O: NSManagedObject, D: NSManagedObject>(
    _ keyPath: KeyPath<O, D>,
    _ object: D
) -> Where<O> {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: object
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master != john))
 ```
 */
public func != <O: NSManagedObject, D: NSManagedObject>(
    _ keyPath: KeyPath<O, D>,
    _ object: D
) -> Where<O> {

    return !Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: object
    )
}

/**
 Creates a `Where` clause by checking if a sequence contains a value of a property
 ```
 let dog = dataStack.fetchOne(From<Dog>().where([john, bob, joe] ~= \.master))
 ```
 */
public func ~= <O: NSManagedObject, D: NSManagedObject, S: Sequence>(
    _ sequence: S,
    _ keyPath: KeyPath<O, D>
) -> Where<O> where S.Iterator.Element == D {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isMemberOf: sequence
    )
}

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master == john))
 ```
 */
public func == <O: NSManagedObject, D: NSManagedObject>(
    _ keyPath: KeyPath<O, D>,
    _ objectID: NSManagedObjectID
) -> Where<O> {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: objectID
    )
}

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master == john))
 ```
 */
public func == <O: ObjectRepresentation, D: NSManagedObject>(
    _ keyPath: KeyPath<O, D>,
    _ object: O
) -> Where<O> where O.ObjectType: NSManagedObject {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: object.cs_id()
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master != john))
 ```
 */
public func != <O: NSManagedObject, D: NSManagedObject>(
    _ keyPath: KeyPath<O, D>,
    _ objectID: NSManagedObjectID
) -> Where<O> {

    return !Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: objectID
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master != john))
 ```
 */
public func != <O: ObjectRepresentation, D: NSManagedObject>(
    _ keyPath: KeyPath<O, D>,
    _ object: O
) -> Where<O> where O.ObjectType: NSManagedObject {

    return !Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: object.cs_id()
    )
}

/**
 Creates a `Where` clause by checking if a sequence contains a value of a property
 ```
 let dog = dataStack.fetchOne(From<Dog>().where([john, bob, joe] ~= \.master))
 ```
 */
public func ~= <O: NSManagedObject, D: NSManagedObject, S: Sequence>(
    _ sequence: S,
    _ keyPath: KeyPath<O, D>
) -> Where<O> where S.Iterator.Element == NSManagedObjectID {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isMemberOf: sequence
    )
}


// MARK: - KeyPath where Root: NSManagedObject, Value: Optional<NSManagedObject>

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master == john))
 ```
 */
public func == <O: NSManagedObject, D: NSManagedObject>(
    _ keyPath: KeyPath<O, Optional<D>>,
    _ object: D?
) -> Where<O> {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: object
    )
}

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master == john))
 ```
 */
public func == <O: ObjectRepresentation, D: NSManagedObject>(
    _ keyPath: KeyPath<O, Optional<D>>,
    _ object: O?
) -> Where<O> where O.ObjectType: NSManagedObject {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: object?.cs_toRaw()
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master != john))
 ```
 */
public func != <O: NSManagedObject, D: NSManagedObject>(
    _ keyPath: KeyPath<O, Optional<D>>,
    _ object: D?
) -> Where<O> {

    return !Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: object
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master != john))
 ```
 */
public func != <O: ObjectRepresentation, D: NSManagedObject>(
    _ keyPath: KeyPath<O, Optional<D>>,
    _ object: O?
) -> Where<O> where O.ObjectType: NSManagedObject {

    return !Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: object?.cs_toRaw()
    )
}

/**
 Creates a `Where` clause by checking if a sequence contains a value of a property
 ```
 let dog = dataStack.fetchOne(From<Dog>().where([john, bob, joe] ~= \.master))
 ```
 */
public func ~= <O: NSManagedObject, D: NSManagedObject, S: Sequence>(
    _ sequence: S,
    _ keyPath: KeyPath<O, Optional<D>>
) -> Where<O> where S.Iterator.Element == D {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isMemberOf: sequence
    )
}

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master == john))
 ```
 */
public func == <O: NSManagedObject, D: NSManagedObject>(
    _ keyPath: KeyPath<O, Optional<D>>,
    _ objectID: NSManagedObjectID
) -> Where<O> {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: objectID
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master != john))
 ```
 */
public func != <O: NSManagedObject, D: NSManagedObject>(
    _ keyPath: KeyPath<O, Optional<D>>,
    _ objectID: NSManagedObjectID
) -> Where<O> {

    return !Where<O>(
        keyPath._kvcKeyPathString!,
        isEqualTo: objectID
    )
}

/**
 Creates a `Where` clause by checking if a sequence contains a value of a property
 ```
 let dog = dataStack.fetchOne(From<Dog>().where([john, bob, joe] ~= \.master))
 ```
 */
public func ~= <O: NSManagedObject, D: NSManagedObject, S: Sequence>(
    _ sequence: S,
    _ keyPath: KeyPath<O, Optional<D>>
) -> Where<O> where S.Iterator.Element == NSManagedObjectID {

    return Where<O>(
        keyPath._kvcKeyPathString!,
        isMemberOf: sequence
    )
}


// MARK: - KeyPath where Root: CoreStoreObject, Value: FieldContainer<Root>.Stored<QueryableAttributeType & Equatable>

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.$nickname == "John"))
 ```
 */
public func == <O, V>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
    _ value: V
) -> Where<O> {

    return Where<O>(
        keyPath,
        isEqualTo: value
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.$nickname != "John"))
 ```
 */
public func != <O, V>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
    _ value: V
) -> Where<O> {

    return !Where<O>(
        keyPath,
        isEqualTo: value
    )
}

/**
 Creates a `Where` clause by checking if a sequence contains the value of a property
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(["Pluto", "Snoopy", "Scooby"] ~= \.nickname))
 ```
 */
public func ~= <O, V, S: Sequence>(
    _ sequence: S,
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>
) -> Where<O> where S.Iterator.Element == V {

    return Where<O>(
        O.meta[keyPath: keyPath].keyPath,
        isMemberOf: sequence
    )
}


// MARK: - KeyPath where Root: CoreStoreObject, Value: FieldContainer<Root>.Stored<QueryableAttributeType & Comparable>

/**
 Creates a `Where` clause by comparing if a property is less than a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.$age < 20))
 ```
 */
public func < <O, V: Comparable>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
    _ value: V
) -> Where<O> {

    return Where<O>(
        "%K < %@",
        O.meta[keyPath: keyPath].keyPath,
        value.cs_toFieldStoredNativeType() as! V.FieldStoredNativeType
    )
}

/**
 Creates a `Where` clause by comparing if a property is less than a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.$age < 20))
 ```
 */
public func < <O, V: FieldOptionalType>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
    _ value: V
) -> Where<O> where V.Wrapped: Comparable {

    return Where<O>(
        "%K < %@",
        O.meta[keyPath: keyPath].keyPath,
        value.cs_toFieldStoredNativeType() as! V.FieldStoredNativeType
    )
}

/**
 Creates a `Where` clause by comparing if a property is greater than a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.$age > 20))
 ```
 */
public func > <O, V: Comparable>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
    _ value: V
) -> Where<O> {

    return Where<O>(
        "%K > %@",
        O.meta[keyPath: keyPath].keyPath,
        value.cs_toFieldStoredNativeType() as! V.FieldStoredNativeType
    )
}

/**
 Creates a `Where` clause by comparing if a property is greater than a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.$age > 20))
 ```
 */
public func > <O, V: FieldOptionalType>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
    _ value: V
) -> Where<O> where V.Wrapped: Comparable {

    return Where<O>(
        "%K > %@",
        O.meta[keyPath: keyPath].keyPath,
        value.cs_toFieldStoredNativeType() as! V.FieldStoredNativeType
    )
}

/**
 Creates a `Where` clause by comparing if a property is less than or equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.$age <= 20))
 ```
 */
public func <= <O, V: Comparable>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
    _ value: V
) -> Where<O> {

    return Where<O>(
        "%K <= %@",
        O.meta[keyPath: keyPath].keyPath,
        value.cs_toFieldStoredNativeType() as! V.FieldStoredNativeType
    )
}

/**
 Creates a `Where` clause by comparing if a property is less than or equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.$age <= 20))
 ```
 */
public func <= <O, V: FieldOptionalType>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
    _ value: V
) -> Where<O> where V.Wrapped: Comparable {

    return Where<O>(
        "%K <= %@",
        O.meta[keyPath: keyPath].keyPath,
        value.cs_toFieldStoredNativeType() as! V.FieldStoredNativeType
    )
}

/**
 Creates a `Where` clause by comparing if a property is greater than or equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.$age >= 20))
 ```
 */
public func >= <O, V: Comparable>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
    _ value: V
) -> Where<O> {

    return Where<O>(
        "%K >= %@",
        O.meta[keyPath: keyPath].keyPath,
        value.cs_toFieldStoredNativeType() as! V.FieldStoredNativeType
    )
}

/**
 Creates a `Where` clause by comparing if a property is greater than or equal to a value
 ```
 let person = dataStack.fetchOne(From<Person>().where(\.$age >= 20))
 ```
 */
public func >= <O, V: FieldOptionalType>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
    _ value: V
) -> Where<O> where V.Wrapped: Comparable {

    return Where<O>(
        "%K >= %@",
        O.meta[keyPath: keyPath].keyPath,
        value.cs_toFieldStoredNativeType() as! V.FieldStoredNativeType
    )
}


// MARK: - KeyPath where Root: CoreStoreObject, Value: FieldContainer<Root>.Relationship<CoreStoreObject>

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.$master == john))
 ```
 */
public func == <O, D: FieldRelationshipToOneType>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Relationship<D>>,
    _ object: D.DestinationObjectType?
) -> Where<O> {

    return Where<O>(
        O.meta[keyPath: keyPath].keyPath,
        isEqualTo: object
    )
}

/**
 Creates a `Where` clause by comparing if a property is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master == john))
 ```
 */
public func == <O, D: FieldRelationshipToOneType, R: ObjectRepresentation>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Relationship<D>>,
    _ object: R?
) -> Where<O> where D.DestinationObjectType == R.ObjectType {

    return Where<O>(
        O.meta[keyPath: keyPath].keyPath,
        isEqualTo: object?.objectID()
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.$master != john))
 ```
 */
public func != <O, D: FieldRelationshipToOneType>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Relationship<D>>,
    _ object: D.DestinationObjectType?
) -> Where<O> {

    return !Where<O>(
        O.meta[keyPath: keyPath].keyPath,
        isEqualTo: object
    )
}

/**
 Creates a `Where` clause by comparing if a property is not equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(\.master != john))
 ```
 */
public func != <O, D: FieldRelationshipToOneType, R: ObjectRepresentation>(
    _ keyPath: KeyPath<O, FieldContainer<O>.Relationship<D>>,
    _ object: R?
) -> Where<O> where D.DestinationObjectType == R.ObjectType {

    return !Where<O>(
        O.meta[keyPath: keyPath].keyPath,
        isEqualTo: object?.objectID()
    )
}

/**
 Creates a `Where` clause by checking if a sequence contains a value of a property
 ```
 let dog = dataStack.fetchOne(From<Dog>().where([john, bob, joe] ~= \.$master))
 ```
 */
public func ~= <O, D: FieldRelationshipToOneType, S: Sequence>(
    _ sequence: S,
    _ keyPath: KeyPath<O, FieldContainer<O>.Relationship<D>>
) -> Where<O> where S.Iterator.Element == D.DestinationObjectType {

    return Where<O>(
        O.meta[keyPath: keyPath].keyPath,
        isMemberOf: sequence
    )
}


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func == <O, V>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<V>>, _ value: V) -> Where<O> {

    return Where<O>(O.meta[keyPath: keyPath].keyPath, isEqualTo: value)
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func != <O, V>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<V>>, _ value: V) -> Where<O> {
    
    return !Where<O>(O.meta[keyPath: keyPath].keyPath, isEqualTo: value)
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func ~= <O, V, S: Sequence>(_ sequence: S, _ keyPath: KeyPath<O, ValueContainer<O>.Required<V>>) -> Where<O> where S.Iterator.Element == V {
    
    return Where<O>(O.meta[keyPath: keyPath].keyPath, isMemberOf: sequence)
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func == <O, V>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<V>>, _ value: V?) -> Where<O> {
    
    return Where<O>(O.meta[keyPath: keyPath].keyPath, isEqualTo: value)
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func != <O, V>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<V>>, _ value: V?) -> Where<O> {
    
    return !Where<O>(O.meta[keyPath: keyPath].keyPath, isEqualTo: value)
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func ~= <O, V, S: Sequence>(_ sequence: S, _ keyPath: KeyPath<O, ValueContainer<O>.Optional<V>>) -> Where<O> where S.Iterator.Element == V {
    
    return Where<O>(O.meta[keyPath: keyPath].keyPath, isMemberOf: sequence)
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func < <O, V: Comparable>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<V>>, _ value: V) -> Where<O> {
    
    return Where<O>("%K < %@", O.meta[keyPath: keyPath].keyPath, value.cs_toQueryableNativeType())
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func > <O, V: Comparable>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<V>>, _ value: V) -> Where<O> {
    
    return Where<O>("%K > %@", O.meta[keyPath: keyPath].keyPath, value.cs_toQueryableNativeType())
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func <= <O, V: Comparable>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<V>>, _ value: V) -> Where<O> {
    
    return Where<O>("%K <= %@", O.meta[keyPath: keyPath].keyPath, value.cs_toQueryableNativeType())
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func >= <O, V: Comparable>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<V>>, _ value: V) -> Where<O> {
    
    return Where<O>("%K >= %@", O.meta[keyPath: keyPath].keyPath, value.cs_toQueryableNativeType())
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func < <O, V>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<V>>, _ value: V?) -> Where<O> {
    
    if let value = value {

        return Where<O>("%K < %@", O.meta[keyPath: keyPath].keyPath, value.cs_toQueryableNativeType())
    }
    else {

        return Where<O>("%K < nil", O.meta[keyPath: keyPath].keyPath)
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func > <O, V>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<V>>, _ value: V?) -> Where<O> {
    
    if let value = value {
        
        return Where<O>("%K > %@", O.meta[keyPath: keyPath].keyPath, value.cs_toQueryableNativeType())
    }
    else {
        
        return Where<O>("%K > nil", O.meta[keyPath: keyPath].keyPath)
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func <= <O, V>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<V>>, _ value: V?) -> Where<O> {
    
    if let value = value {
        
        return Where<O>("%K <= %@", O.meta[keyPath: keyPath].keyPath, value.cs_toQueryableNativeType())
    }
    else {
        
        return Where<O>("%K <= nil", O.meta[keyPath: keyPath].keyPath)
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func >= <O, V>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<V>>, _ value: V?) -> Where<O> {
    
    if let value = value {
        
        return Where<O>("%K >= %@", O.meta[keyPath: keyPath].keyPath, value.cs_toQueryableNativeType())
    }
    else {
        
        return Where<O>("%K >= nil", O.meta[keyPath: keyPath].keyPath)
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func == <O, D>(_ keyPath: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, _ object: D) -> Where<O> {
    
    return Where<O>(O.meta[keyPath: keyPath].keyPath, isEqualTo: object)
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func == <O, D>(_ keyPath: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, _ object: D?) -> Where<O> {
    
    return Where<O>(O.meta[keyPath: keyPath].keyPath, isEqualTo: object)
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func != <O, D>(_ keyPath: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, _ object: D) -> Where<O> {
    
    return !Where<O>(O.meta[keyPath: keyPath].keyPath, isEqualTo: object)
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func != <O, D>(_ keyPath: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, _ object: D?) -> Where<O> {
    
    return !Where<O>(O.meta[keyPath: keyPath].keyPath, isEqualTo: object)
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func ~= <O, D, S: Sequence>(_ sequence: S, _ keyPath: KeyPath<O, RelationshipContainer<O>.ToOne<D>>) -> Where<O> where S.Iterator.Element == D {
    
    return Where<O>(O.meta[keyPath: keyPath].keyPath, isMemberOf: sequence)
}
