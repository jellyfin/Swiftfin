//
//  Where.Expression.swift
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


// MARK: - WhereExpressionTrait

/**
 Used only for `Where.Expression` type constraints. Currently supports `SingleTarget` and `CollectionTarget`.
 */
public protocol WhereExpressionTrait {}


// MARK: - Where

extension Where {

    // MARK: - Expression

    /**
     Type-safe keyPath chain usable in query/fetch expressions.
     ```
     let expression: Where<Pet>.Expression = (\.master ~ \.name)
     let owner = dataStack.fetchOne(
        From<Pet>().where(expression == "John")
     )
     ```
     */
    public struct Expression<T: WhereExpressionTrait, V>: CustomStringConvertible, KeyPathStringConvertible {

        /**
         Currently supports `SingleTarget` and `CollectionTarget`.
         */
        public typealias Trait = T


        // MARK: AnyKeyPathStringConvertible

        public let cs_keyPathString: String


        // MARK: KeyPathStringConvertible

        public typealias ObjectType = O
        public typealias DestinationValueType = V


        // MARK: CustomStringConvertible

        public var description: String {

            return self.cs_keyPathString
        }


        // MARK: Internal

        internal init(_ component: String) {

            self.cs_keyPathString = component
        }

        internal init(_ component1: String, _ component2: String) {

            self.cs_keyPathString = component1 + "." + component2
        }
    }


    // MARK: - SingleTarget

    /**
     Used only for `Where.Expression` type constraints. Specifies that this `Where.Expression` type pertains to an attribute property expression.
     */
    public enum SingleTarget: WhereExpressionTrait {}


    // MARK: - CollectionTarget

    /**
     Used only for `Where.Expression` type constraints. Specifies that this `Where.Expression` type pertains to a to-many relationship expression.
     */
    public enum CollectionTarget: WhereExpressionTrait {}
}


// MARK: - ~ (Where.Expression Creation Operators)

// MARK: ~ where D: NSManagedObject

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let owner = dataStack.fetchOne(From<Pet>().where((\.master ~ \.name) == "John"))
 ```
 */
public func ~<O: NSManagedObject, D: NSManagedObject, V: AllowedObjectiveCKeyPathValue>(
    _ lhs: KeyPath<O, D>,
    _ rhs: KeyPath<D, V>
) -> Where<O>.Expression<Where<O>.SingleTarget, V> {

    return .init(
        lhs.cs_keyPathString,
        rhs.cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let owner = dataStack.fetchOne(From<Pet>().where((\.master ~ \.name) == "John"))
 ```
 */
public func ~ <O: NSManagedObject, D: NSManagedObject, V: AllowedObjectiveCKeyPathValue>(
    _ lhs: KeyPath<O, D?>,
    _ rhs: KeyPath<D, V>
) -> Where<O>.Expression<Where<O>.SingleTarget, V> {

    return .init(
        lhs.cs_keyPathString,
        rhs.cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let happyPets = dataStack.fetchAll(From<Pet>().where((\.master ~ \.pets).count() > 1))
 ```
 */
public func ~ <O: NSManagedObject, D: NSManagedObject, V: AllowedObjectiveCToManyRelationshipKeyPathValue>(
    _ lhs: KeyPath<O, D>,
    _ rhs: KeyPath<D, V>
) -> Where<O>.Expression<Where<O>.CollectionTarget, V> {

    return .init(
        lhs.cs_keyPathString,
        rhs.cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let happyPets = dataStack.fetchAll(From<Pet>().where((\.master ~ \.pets).count() > 1))
 ```
 */
public func ~ <O: NSManagedObject, D: NSManagedObject, V: AllowedObjectiveCToManyRelationshipKeyPathValue>(
    _ lhs: KeyPath<O, D?>,
    _ rhs: KeyPath<D, V>
) -> Where<O>.Expression<Where<O>.CollectionTarget, V> {

    return .init(
        lhs.cs_keyPathString,
        rhs.cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let johnsSonInLaw = dataStack.fetchOne(From<Person>().where((\.spouse ~ \.father ~ \.name) == "John"))
 ```
 */
public func ~ <O: NSManagedObject, D: NSManagedObject, T, V: AllowedObjectiveCKeyPathValue>(
    _ lhs: Where<O>.Expression<T, D>,
    _ rhs: KeyPath<D, V>
) -> Where<O>.Expression<T, V> {

    return .init(
        lhs.cs_keyPathString,
        rhs.cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let johnsSonInLaw = dataStack.fetchOne(From<Person>().where((\.spouse ~ \.father ~ \.name) == "John"))
 ```
 */
public func ~ <O: NSManagedObject, D: NSManagedObject, T, V: AllowedObjectiveCKeyPathValue>(
    _ lhs: Where<O>.Expression<T, D?>,
    _ rhs: KeyPath<D, V>
) -> Where<O>.Expression<T, V> {

    return .init(
        lhs.cs_keyPathString,
        rhs.cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let spouseHasSiblings = dataStack.fetchOne(From<Person>().where((\.spouse ~ \.father ~ \.children).count() > 0))
 ```
 */
public func ~ <O: NSManagedObject, D: NSManagedObject, T, V: AllowedObjectiveCToManyRelationshipKeyPathValue>(
    _ lhs: Where<O>.Expression<T, D>,
    _ rhs: KeyPath<D, V>
) -> Where<O>.Expression<Where<O>.CollectionTarget, V> {

    return .init(
        lhs.cs_keyPathString,
        rhs.cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let spouseHasSiblings = dataStack.fetchOne(From<Person>().where((\.spouse ~ \.father ~ \.children).count() > 0))
 ```
 */
public func ~ <O: NSManagedObject, D: NSManagedObject, T, V: AllowedObjectiveCToManyRelationshipKeyPathValue>(
    _ lhs: Where<O>.Expression<T, D?>,
    _ rhs: KeyPath<D, V>
) -> Where<O>.Expression<Where<O>.CollectionTarget, V> {

    return .init(
        lhs.cs_keyPathString,
        rhs.cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let spousesWithBadNamingSense = dataStack.fetchAll(From<Person>().where((\.spouse ~ \.pets ~ \.name).any() == "Spot"))
 ```
 */
public func ~ <O: NSManagedObject, D: NSManagedObject, T, C: AllowedObjectiveCToManyRelationshipKeyPathValue, V: AllowedObjectiveCKeyPathValue>(
    _ lhs: Where<O>.Expression<T, C>,
    _ rhs: KeyPath<D, V>
) -> Where<O>.Expression<Where<O>.CollectionTarget, V> {

    return .init(
        lhs.cs_keyPathString,
        rhs.cs_keyPathString
    )
}


// MARK: - ~ where D: CoreStoreObject

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let owner = dataStack.fetchOne(From<Pet>().where((\.$master ~ \.$name) == "John"))
 ```
 */
public func ~ <O: CoreStoreObject, D: FieldRelationshipToOneType, K: KeyPathStringConvertible>(
    _ lhs: KeyPath<O, FieldContainer<O>.Relationship<D>>,
    _ rhs: KeyPath<D.DestinationObjectType, K>
) -> Where<O>.Expression<Where<O>.SingleTarget, K.DestinationValueType> where K.ObjectType == D.DestinationObjectType {

    return .init(
        O.meta[keyPath: lhs].cs_keyPathString,
        D.DestinationObjectType.meta[keyPath: rhs].cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let owner = dataStack.fetchOne(From<Pet>().where((\.master ~ \.name) == "John"))
 ```
 */
public func ~ <O: CoreStoreObject, D: CoreStoreObject, T, K: KeyPathStringConvertible>(_ lhs: Where<O>.Expression<T, D>, _ rhs: KeyPath<D, K>) -> Where<O>.Expression<T, K.DestinationValueType> where K.ObjectType == D {

    return .init(
        lhs.cs_keyPathString,
        D.meta[keyPath: rhs].cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let owner = dataStack.fetchOne(From<Pet>().where((\.master ~ \.name) == "John"))
 ```
 */
public func ~ <O: CoreStoreObject, D: CoreStoreObject, T, K: KeyPathStringConvertible>(_ lhs: Where<O>.Expression<T, D?>, _ rhs: KeyPath<D, K>) -> Where<O>.Expression<T, K.DestinationValueType> where K.ObjectType == D {

    return .init(
        lhs.cs_keyPathString,
        D.meta[keyPath: rhs].cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let happyPets = dataStack.fetchAll(From<Pet>().where((\.$master ~ \.$pets).count() > 1))
 ```
 */
public func ~ <O: CoreStoreObject, D: FieldRelationshipToOneType, K: ToManyRelationshipKeyPathStringConvertible>(_ lhs: KeyPath<O, FieldContainer<O>.Relationship<D>>, _ rhs: KeyPath<D.DestinationObjectType, K>) -> Where<O>.Expression<Where<O>.CollectionTarget, K.DestinationValueType> where K.ObjectType == D.DestinationObjectType {

    return .init(
        O.meta[keyPath: lhs].cs_keyPathString,
        D.DestinationObjectType.meta[keyPath: rhs].cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let happyPets = dataStack.fetchAll(From<Pet>().where((\.master ~ \.pets).count() > 1))
 ```
 */
public func ~ <O: CoreStoreObject, D: CoreStoreObject, T, K: ToManyRelationshipKeyPathStringConvertible>(_ lhs: Where<O>.Expression<T, D>, _ rhs: KeyPath<D, K>) -> Where<O>.Expression<Where<O>.CollectionTarget, K.DestinationValueType> where K.ObjectType == O {

    return .init(
        lhs.cs_keyPathString,
        D.meta[keyPath: rhs].cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let happyPets = dataStack.fetchAll(From<Pet>().where((\.master ~ \.pets).count() > 1))
 ```
 */
public func ~ <O: CoreStoreObject, D: CoreStoreObject, T, K: ToManyRelationshipKeyPathStringConvertible>(_ lhs: Where<O>.Expression<T, D?>, _ rhs: KeyPath<D, K>) -> Where<O>.Expression<Where<O>.CollectionTarget, K.DestinationValueType> where K.ObjectType == O {

    return .init(
        lhs.cs_keyPathString,
        D.meta[keyPath: rhs].cs_keyPathString
    )
}

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
 ```
 let spousesWithBadNamingSense = dataStack.fetchAll(From<Pet>().where((\.master ~ \.pets ~ \.name).any() == "Spot"))
 ```
 */
public func ~ <O: CoreStoreObject, D: CoreStoreObject, T, KC: ToManyRelationshipKeyPathStringConvertible, KV: ToManyRelationshipKeyPathStringConvertible>(_ lhs: Where<O>.Expression<T, KC>, _ rhs: KeyPath<D, KV>) -> Where<O>.Expression<Where<O>.CollectionTarget, KV.DestinationValueType> where KC.ObjectType == O, KV.ObjectType == D {

    return .init(
        lhs.cs_keyPathString,
        D.meta[keyPath: rhs].cs_keyPathString
    )
}


// MARK: - Where.Expression where V: QueryableAttributeType

/**
 Creates a `Where` clause by comparing if an expression is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where((\.master ~ \.name) == "John"))
 ```
 */
public func == <O, T, V: QueryableAttributeType>(_ lhs: Where<O>.Expression<T, V>, _ rhs: V) -> Where<O> {

    return Where<O>(lhs.cs_keyPathString, isEqualTo: rhs)
}

/**
 Creates a `Where` clause by comparing if an expression is not equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where((\.master ~ \.name) != "John"))
 ```
 */
public func != <O, T, V: QueryableAttributeType>(_ lhs: Where<O>.Expression<T, V>, _ rhs: V) -> Where<O> {

    return !Where<O>(lhs.cs_keyPathString, isEqualTo: rhs)
}

/**
 Creates a `Where` clause by checking if a sequence contains a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(["John", "Joe"] ~= (\.master ~ \.name))
 ```
 */
public func ~= <O, T, V: QueryableAttributeType, S: Sequence>(_ sequence: S, _ expression: Where<O>.Expression<T, V>) -> Where<O> where S.Iterator.Element == V {

    return Where<O>(expression.cs_keyPathString, isMemberOf: sequence)
}


// MARK: - Where.Expression where V: QueryableAttributeType & Comparable

/**
 Creates a `Where` clause by comparing if an expression is less than a value
 ```
 let lonelyDog = dataStack.fetchOne(From<Dog>().where((\.master ~ \.pets).count() < 2))
 ```
 */
public func < <O, T, V: QueryableAttributeType & Comparable>(_ lhs: Where<O>.Expression<T, V>, _ rhs: V) -> Where<O> {

    return  Where<O>(expression: lhs, function: "<", operand: rhs)
}

/**
 Creates a `Where` clause by comparing if an expression is less than or equal to a value
 ```
 let lonelyDog = dataStack.fetchOne(From<Dog>().where((\.master ~ \.pets).count() <= 1)
 ```
 */
public func <= <O, T, V: QueryableAttributeType & Comparable>(_ lhs: Where<O>.Expression<T, V>, _ rhs: V) -> Where<O> {

    return  Where<O>(expression: lhs, function: "<=", operand: rhs)
}

/**
 Creates a `Where` clause by comparing if an expression is greater than a value
 ```
 let happyDog = dataStack.fetchOne(From<Dog>().where((\.master ~ \.pets).count() > 1)
 ```
 */
public func > <O, T, V: QueryableAttributeType & Comparable>(_ lhs: Where<O>.Expression<T, V>, _ rhs: V) -> Where<O> {

    return  Where<O>(expression: lhs, function: ">", operand: rhs)
}

/**
 Creates a `Where` clause by comparing if an expression is greater than or equal to a value
 ```
 let happyDog = dataStack.fetchOne(From<Dog>().where((\.master ~ \.pets).count() >= 2)
 ```
 */
public func >= <O, T, V: QueryableAttributeType & Comparable>(_ lhs: Where<O>.Expression<T, V>, _ rhs: V) -> Where<O> {

    return  Where<O>(expression: lhs, function: ">=", operand: rhs)
}


// MARK: - Where.Expression where V: Optional<QueryableAttributeType>

/**
 Creates a `Where` clause by comparing if an expression is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where((\.master ~ \.name) == "John"))
 ```
 */
public func == <O, T, V: QueryableAttributeType>(_ lhs: Where<O>.Expression<T, V?>, _ rhs: V) -> Where<O> {

    return Where<O>(lhs.cs_keyPathString, isEqualTo: rhs)
}

/**
 Creates a `Where` clause by comparing if an expression is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where((\.master ~ \.name) == "John"))
 ```
 */
public func == <O, T, V: QueryableAttributeType>(_ lhs: Where<O>.Expression<T, V?>, _ rhs: V?) -> Where<O> {

    return Where<O>(lhs.cs_keyPathString, isEqualTo: rhs)
}

/**
 Creates a `Where` clause by comparing if an expression is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where((\.master ~ \.name) != "John"))
 ```
 */
public func != <O, T, V: QueryableAttributeType>(_ lhs: Where<O>.Expression<T, V?>, _ rhs: V) -> Where<O> {

    return !Where<O>(lhs.cs_keyPathString, isEqualTo: rhs)
}

/**
 Creates a `Where` clause by comparing if an expression is equal to a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where((\.master ~ \.name) != "John"))
 ```
 */
public func != <O, T, V: QueryableAttributeType>(_ lhs: Where<O>.Expression<T, V?>, _ rhs: V?) -> Where<O> {

    return !Where<O>(lhs.cs_keyPathString, isEqualTo: rhs)
}

/**
 Creates a `Where` clause by checking if a sequence contains a value
 ```
 let dog = dataStack.fetchOne(From<Dog>().where(["John", "Joe"] ~= (\.master ~ \.name))
 ```
 */
public func ~= <O, T, V: QueryableAttributeType, S: Sequence>(_ sequence: S, _ expression: Where<O>.Expression<T, V?>) -> Where<O> where S.Iterator.Element == V {

    return Where<O>(expression.cs_keyPathString, isMemberOf: sequence)
}


// MARK: - Where.Expression where V: Optional<QueryableAttributeType & Comparable>

/**
 Creates a `Where` clause by comparing if an expression is less than a value
 ```
 let childsPet = dataStack.fetchOne(From<Dog>().where((\.master ~ \.age) < 10))
 ```
 */
public func < <O, T, V: QueryableAttributeType & Comparable>(_ lhs: Where<O>.Expression<T, V?>, _ rhs: V) -> Where<O> {

    return Where<O>(expression: lhs, function: "<", operand: rhs)
}

/**
 Creates a `Where` clause by comparing if an expression is less than or equal to a value
 ```
 let childsPet = dataStack.fetchOne(From<Dog>().where((\.master ~ \.age) <= 10))
 ```
 */
public func <= <O, T, V: QueryableAttributeType & Comparable>(_ lhs: Where<O>.Expression<T, V?>, _ rhs: V?) -> Where<O> {

    return Where<O>(expression: lhs, function: "<=", operand: rhs)
}

/**
 Creates a `Where` clause by comparing if an expression is greater than a value
 ```
 let teensPet = dataStack.fetchOne(From<Dog>().where((\.master ~ \.age) > 10))
 ```
 */
public func > <O, T, V: QueryableAttributeType & Comparable>(_ lhs: Where<O>.Expression<T, V?>, _ rhs: V) -> Where<O> {

    return Where<O>(expression: lhs, function: ">", operand: rhs)
}

/**
 Creates a `Where` clause by comparing if an expression is greater than or equal to a value
 ```
 let teensPet = dataStack.fetchOne(From<Dog>().where((\.master ~ \.age) >= 10))
 ```
 */
public func >= <O, T, V: QueryableAttributeType & Comparable>(_ lhs: Where<O>.Expression<T, V?>, _ rhs: V?) -> Where<O> {

    return Where<O>(expression: lhs, function: ">=", operand: rhs)
}


// MARK: - KeyPath where Root: NSManagedObject, Value: AllowedObjectiveCToManyRelationshipKeyPathValue

extension KeyPath where Root: NSManagedObject, Value: AllowedObjectiveCToManyRelationshipKeyPathValue {

    /**
     Creates a `Where.Expression` clause for COUNT
     ```
     let dogsWithPlaymates = dataStack.fetchAll(From<Dog>().where((\.master ~ \.pets).count() > 1))
     ```
     */
    public func count() -> Where<Root>.Expression<Where<Root>.CollectionTarget, Int> {

        return .init(self.cs_keyPathString, "@count")
    }
}

// MARK: - Where.Expression where O: NSManagedObject, T == Where<O>.CollectionTarget, V: AllowedObjectiveCToManyRelationshipKeyPathValue

extension Where.Expression where O: NSManagedObject, T == Where<O>.CollectionTarget, V: AllowedObjectiveCToManyRelationshipKeyPathValue {

    /**
     Creates a `Where.Expression` clause for COUNT
     ```
     let dogsWithPlaymates = dataStack.fetchAll(From<Dog>().where((\.master ~ \.pets).count() > 1))
     ```
     */
    public func count() -> Where<O>.Expression<T, Int> {

        return .init(self.cs_keyPathString, "@count")
    }
}


// MARK: - Where.Expression where O: NSManagedObject, T == Where<O>.CollectionTarget, V: AllowedObjectiveCKeyPathValue

extension Where.Expression where O: NSManagedObject, T == Where<O>.CollectionTarget, V: AllowedObjectiveCKeyPathValue {

    /**
     Creates a `Where.Expression` clause for ANY
     ```
     let dogsWithBadNamingSense = dataStack.fetchAll(From<Dog>().where((\.master ~ \.pets ~ \.name).any() > "Spot"))
     ```
     */
    public func any() -> Where<O>.Expression<T, V> {

        return .init("ANY " + self.cs_keyPathString)
    }

    /**
     Creates a `Where.Expression` clause for ALL
     ```
     let allPlaymatePuppies = dataStack.fetchAll(From<Dog>().where((\.master ~ \.pets ~ \.age).all() > 5))
     ```
     */
    public func all() -> Where<O>.Expression<T, V> {

        return .init("ALL " + self.cs_keyPathString)
    }

    /**
     Creates a `Where.Expression` clause for NONE
     ```
     let dogs = dataStack.fetchAll(From<Dog>().where((\.master ~ \.pets ~ \.name).any() > "Spot"))
     ```
     */
    public func none() -> Where<O>.Expression<T, V> {

        return .init("NONE " + self.cs_keyPathString)
    }
}


// MARK: - KeyPath where Root: CoreStoreObject, Value: AllowedObjectiveCToManyRelationshipKeyPathValue

extension KeyPath where Root: CoreStoreObject, Value: ToManyRelationshipKeyPathStringConvertible {

    /**
     Creates a `Where.Expression` clause for COUNT
     ```
     let dogsWithPlaymates = dataStack.fetchAll(From<Dog>().where((\.master ~ \.pets).count() > 1))
     ```
     */
    public func count() -> Where<Root>.Expression<Where<Root>.CollectionTarget, Int> {

        return .init(Root.meta[keyPath: self].cs_keyPathString, "@count")
    }
}


// MARK: - Where.Expression where O: CoreStoreObject, T == Where<O>.CollectionTarget

extension Where.Expression where O: CoreStoreObject, T == Where<O>.CollectionTarget {

    /**
     Creates a `Where.Expression` clause for COUNT
     ```
     let dogsWithPlaymates = dataStack.fetchAll(From<Dog>().where((\.master ~ \.pets).count() > 1))
     ```
     */
    public func count() -> Where<O>.Expression<T, Int> {

        return .init(self.cs_keyPathString, "@count")
    }

    /**
     Creates a `Where.Expression` clause for ANY
     ```
     let dogsWithBadNamingSense = dataStack.fetchAll(From<Dog>().where((\.master ~ \.pets ~ \.name).any() > "Spot"))
     ```
     */
    public func any() -> Where<O>.Expression<T, V> {

        return .init("ANY " + self.cs_keyPathString)
    }

    /**
     Creates a `Where.Expression` clause for ALL
     ```
     let allPlaymatePuppies = dataStack.fetchAll(From<Dog>().where((\.master ~ \.pets ~ \.age).all() > 5))
     ```
     */
    public func all() -> Where<O>.Expression<T, V> {

        return .init("ALL " + self.cs_keyPathString)
    }

    /**
     Creates a `Where.Expression` clause for NONE
     ```
     let dogs = dataStack.fetchAll(From<Dog>().where((\.master ~ \.pets ~ \.name).any() > "Spot"))
     ```
     */
    public func none() -> Where<O>.Expression<T, V> {

        return .init("NONE " + self.cs_keyPathString)
    }
}


// MARK: - Where

extension Where {

    // MARK: FilePrivate

    fileprivate init<T, V: QueryableAttributeType & Comparable>(expression: Where<O>.Expression<T, V>, function: String, operand: V) {

        self.init("\(expression.cs_keyPathString) \(function) %@", operand.cs_toQueryableNativeType())
    }

    fileprivate init<T, V: QueryableAttributeType & Comparable>(expression: Where<O>.Expression<T, V?>, function: String, operand: V) {

        self.init("\(expression.cs_keyPathString) \(function) %@", operand.cs_toQueryableNativeType())
    }

    fileprivate init<T, V: QueryableAttributeType & Comparable>(expression: Where<O>.Expression<T, V>, function: String, operand: V?) {

        if let operand = operand {

            self.init("\(expression.cs_keyPathString) \(function) %@", operand.cs_toQueryableNativeType())
        }
        else {

            self.init("\(expression.cs_keyPathString) \(function) nil")
        }
    }

    fileprivate init<T, V: QueryableAttributeType & Comparable>(expression: Where<O>.Expression<T, V?>, function: String, operand: V?) {

        if let operand = operand {

            self.init("\(expression.cs_keyPathString) \(function) %@", operand.cs_toQueryableNativeType())
        }
        else {

            self.init("\(expression.cs_keyPathString) \(function) nil")
        }
    }
}


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func ~ <O: CoreStoreObject, D: CoreStoreObject, K: KeyPathStringConvertible>(_ lhs: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, _ rhs: KeyPath<D, K>) -> Where<O>.Expression<Where<O>.SingleTarget, K.DestinationValueType> where K.ObjectType == D {

    return .init(
        O.meta[keyPath: lhs].cs_keyPathString,
        D.meta[keyPath: rhs].cs_keyPathString
    )
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public func ~ <O: CoreStoreObject, D: CoreStoreObject, K: ToManyRelationshipKeyPathStringConvertible>(_ lhs: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, _ rhs: KeyPath<D, K>) -> Where<O>.Expression<Where<O>.CollectionTarget, K.DestinationValueType> where K.ObjectType == D {

    return .init(
        O.meta[keyPath: lhs].cs_keyPathString,
        D.meta[keyPath: rhs].cs_keyPathString
    )
}
