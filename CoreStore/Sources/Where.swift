//
//  Where.swift
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


// MARK: - Where

/**
 The `Where` clause specifies the conditions for a fetch or a query.
 */
public struct Where<O: DynamicObject>: WhereClauseType, FetchClause, QueryClause, DeleteClause, Hashable {
    
    /**
     Combines two `Where` predicates together using `AND` operator
     */
    public static func && (
        left: Where<O>,
        right: Where<O>
    ) -> Where<O> {

        return Where<O>(
            NSCompoundPredicate(
                type: .and,
                subpredicates: [left.predicate, right.predicate]
            )
        )
    }

    /**
     Combines two `Where` predicates together using `OR` operator
     */
    public static func || (
        left: Where<O>,
        right: Where<O>
    ) -> Where<O> {

        return Where<O>(
            NSCompoundPredicate(
                type: .or,
                subpredicates: [left.predicate, right.predicate]
            )
        )
    }
    
    /**
     Inverts the predicate of a `Where` clause using `NOT` operator
     */
    public static prefix func ! (
        clause: Where<O>
    ) -> Where<O> {

        return Where<O>(
            NSCompoundPredicate(
                type: .not,
                subpredicates: [clause.predicate]
            )
        )
    }
        
    /**
     Combines two `Where` predicates together using `AND` operator.
     - returns: `left` if `right` is `nil`, otherwise equivalent to `(left && right)`
     */
    public static func &&? (
        left: Where<O>,
        right: Where<O>?
    ) -> Where<O> {

        if let right = right {
            
            return left && right
        }
        return left
    }
    
    /**
     Combines two `Where` predicates together using `AND` operator.
     - returns: `right` if `left` is `nil`, otherwise equivalent to `(left && right)`
     */
    public static func &&? (
        left: Where<O>?,
        right: Where<O>
    ) -> Where<O> {

        if let left = left {
            
            return left && right
        }
        return right
    }
    
    /**
     Combines two `Where` predicates together using `OR` operator.
     - returns: `left` if `right` is `nil`, otherwise equivalent to `(left || right)`
     */
    public static func ||? (
        left: Where<O>,
        right: Where<O>?
    ) -> Where<O> {

        if let right = right {
            
            return left || right
        }
        return left
    }
    
    /**
     Combines two `Where` predicates together using `OR` operator.
     - returns: `right` if `left` is `nil`, otherwise equivalent to `(left || right)`
     */
    public static func ||? (
        left: Where<O>?,
        right: Where<O>
    ) -> Where<O> {

        if let left = left {
            
            return left || right
        }
        return right
    }
    
    /**
     Initializes a `Where` clause with a predicate that always evaluates to `true`
     */
    public init() {
        
        self.init(true)
    }

    /**
     Initializes a `Where` clause with an existing `Where` clause.

     - parameter clause: the existing `Where` clause.
     */
    public init(
        _ clause: Where<O>
    ) {

        self.init(clause.predicate)
    }
    
    /**
     Initializes a `Where` clause with a predicate that always evaluates to the specified boolean value
     
     - parameter value: the boolean value for the predicate
     */
    public init(
        _ value: Bool
    ) {

        self.init(NSPredicate(value: value))
    }
    
    /**
     Initializes a `Where` clause with a predicate using the specified string format and arguments
     
     - parameter format: the format string for the predicate
     - parameter args: the arguments for `format`
     */
    public init(
        _ format: String,
        _ args: Any...
    ) {

        self.init(NSPredicate(format: format, argumentArray: args))
    }
    
    /**
     Initializes a `Where` clause with a predicate using the specified string format and arguments
     
     - parameter format: the format string for the predicate
     - parameter argumentArray: the arguments for `format`
     */
    public init(
        _ format: String,
        argumentArray: [Any]?
    ) {

        self.init(NSPredicate(format: format, argumentArray: argumentArray))
    }
    
    /**
     Initializes a `Where` clause that compares equality to `nil`
     
     - parameter keyPath: the keyPath to compare with
     - parameter null: the arguments for the `==` operator
     */
    public init(
        _ keyPath: KeyPathString,
        isEqualTo null: Void?
    ) {

        self.init(NSPredicate(format: "\(keyPath) == nil"))
    }

    /**
     Initializes a `Where` clause that compares equality

     - parameter keyPath: the keyPath to compare with
     - parameter value: the arguments for the `==` operator
     */
    public init<V: FieldStorableType>(
        _ keyPath: KeyPathString,
        isEqualTo value: V
    ) {

        var nilPredicate: NSPredicate {
            
            return NSPredicate(
                format: "\(keyPath) == nil"
            )
        }
        var valuePredicate: NSPredicate {
            
            return NSPredicate(
                format: "\(keyPath) == %@",
                argumentArray: [value.cs_toFieldStoredNativeType() as Any]
            )
        }
        switch value {

#if swift(>=5.7)
        case let optionalValue as any FieldOptionalType:
            switch optionalValue.cs_wrappedValue {
                
            case nil,
                is NSNull:
                self.init(nilPredicate)
                
            case _?:
                self.init(valuePredicate)
            }

#else
        case nil:
            self.init(nilPredicate)

#endif

        case is NSNull:
            self.init(nilPredicate)

        case _:
            self.init(valuePredicate)
        }
    }

    /**
     Initializes a `Where` clause that compares equality

     - parameter keyPath: the keyPath to compare with
     - parameter value: the arguments for the `==` operator
     */
    @_disfavoredOverload
    public init<U: QueryableAttributeType>(
        _ keyPath: KeyPathString,
        isEqualTo value: U?
    ) {

        switch value {

        case nil,
             is NSNull:
            self.init(
                NSPredicate(
                    format: "\(keyPath) == nil"
                )
            )

        case let value?:
            self.init(
                NSPredicate(
                    format: "\(keyPath) == %@",
                    argumentArray: [value.cs_toQueryableNativeType()]
                )
            )
        }
    }
    
    /**
     Initializes a `Where` clause that compares equality
     
     - parameter keyPath: the keyPath to compare with
     - parameter object: the arguments for the `==` operator
     */
    public init<Other: DynamicObject>(
        _ keyPath: KeyPathString,
        isEqualTo object: Other?
    ) {

        switch object {
            
        case nil:
            self.init(
                NSPredicate(
                    format: "\(keyPath) == nil"
                )
            )

        case let object?:
            self.init(
                NSPredicate(
                    format: "\(keyPath) == %@",
                    argumentArray: [object.cs_id()]
                )
            )
        }
    }
    
    /**
     Initializes a `Where` clause that compares equality
     
     - parameter keyPath: the keyPath to compare with
     - parameter objectID: the arguments for the `==` operator
     */
    public init(
        _ keyPath: KeyPathString,
        isEqualTo objectID: NSManagedObjectID
    ) {

        self.init(
            NSPredicate(
                format: "\(keyPath) == %@",
                argumentArray: [objectID]
            )
        )
    }

    /**
     Initializes a `Where` clause that compares membership

     - parameter keyPath: the keyPath to compare with
     - parameter list: the sequence to check membership of
     */
    public init<S: Sequence>(
        _ keyPath: KeyPathString,
        isMemberOf list: S
    ) where S.Iterator.Element: FieldStorableType {

        self.init(
            NSPredicate(
                format: "\(keyPath) IN %@",
                list.map({ $0.cs_toFieldStoredNativeType() }) as NSArray
            )
        )
    }
    
    /**
     Initializes a `Where` clause that compares membership
     
     - parameter keyPath: the keyPath to compare with
     - parameter list: the sequence to check membership of
     */
    @_disfavoredOverload
    public init<S: Sequence>(
        _ keyPath: KeyPathString,
        isMemberOf list: S
    ) where S.Iterator.Element: QueryableAttributeType {

        self.init(
            NSPredicate(
                format: "\(keyPath) IN %@",
                list.map({ $0.cs_toQueryableNativeType() }) as NSArray
            )
        )
    }
    
    /**
     Initializes a `Where` clause that compares membership
     
     - parameter keyPath: the keyPath to compare with
     - parameter list: the sequence to check membership of
     */
    public init<S: Sequence>(
        _ keyPath: KeyPathString,
        isMemberOf list: S
    ) where S.Iterator.Element: DynamicObject {

        self.init(
            NSPredicate(
                format: "\(keyPath) IN %@",
                list.map({ $0.cs_id() }) as NSArray
            )
        )
    }
    
    /**
     Initializes a `Where` clause that compares membership
     
     - parameter keyPath: the keyPath to compare with
     - parameter list: the sequence to check membership of
     */
    public init<S: Sequence>(
        _ keyPath: KeyPathString,
        isMemberOf list: S
    ) where S.Iterator.Element: NSManagedObjectID {

        self.init(
            NSPredicate(
                format: "\(keyPath) IN %@",
                list.map({ $0 }) as NSArray
            )
        )
    }
    
    
    // MARK: AnyWhereClause
    
    public let predicate: NSPredicate
    
    public init(_ predicate: NSPredicate) {
        
        self.predicate = predicate
    }
    
    
    // MARK: WhereClauseType
    
    public typealias ObjectType = O
    
    
    // MARK: FetchClause, QueryClause, DeleteClause
    
    public func applyToFetchRequest<ResultType>(
        _ fetchRequest: NSFetchRequest<ResultType>
    ) {

        if let predicate = fetchRequest.predicate, predicate != self.predicate {
            
            Internals.log(
                .warning,
                message: "An existing predicate for the \(Internals.typeName(fetchRequest)) was overwritten by \(Internals.typeName(self)) query clause."
            )
        }
        
        fetchRequest.predicate = self.predicate
    }
    
    
    // MARK: Equatable
    
    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {

        return lhs.predicate == rhs.predicate
    }
    
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(self.predicate)
    }
}


// MARK: - Where where O: NSManagedObject

extension Where where O: NSManagedObject {
    
    /**
     Initializes a `Where` clause that compares equality to `nil`
     
     - parameter keyPath: the keyPath to compare with
     - parameter null: the arguments for the `==` operator
     */
    public init<V: QueryableAttributeType>(
        _ keyPath: KeyPath<O, V>,
        isEqualTo null: Void?
    ) {

        self.init(
            keyPath._kvcKeyPathString!,
            isEqualTo: null
        )
    }
    
    /**
     Initializes a `Where` clause that compares equality to `nil`
     
     - parameter keyPath: the keyPath to compare with
     - parameter null: the arguments for the `==` operator
     */
    public init<D: DynamicObject>(
        _ keyPath: KeyPath<O, D>,
        isEqualTo null: Void?
    ) {

        self.init(
            keyPath._kvcKeyPathString!,
            isEqualTo: null
        )
    }
    
    /**
     Initializes a `Where` clause that compares equality
     
     - parameter keyPath: the keyPath to compare with
     - parameter value: the arguments for the `==` operator
     */
    public init<V: QueryableAttributeType>(
        _ keyPath: KeyPath<O, V>,
        isEqualTo value: V?
    ) {

        self.init(
            keyPath._kvcKeyPathString!,
            isEqualTo: value
        )
    }
    
    /**
     Initializes a `Where` clause that compares equality
     
     - parameter keyPath: the keyPath to compare with
     - parameter value: the arguments for the `==` operator
     */
    public init<D: DynamicObject>(
        _ keyPath: KeyPath<O, D>,
        isEqualTo value: D?
    ) {

        self.init(
            keyPath._kvcKeyPathString!,
            isEqualTo: value
        )
    }
    
    /**
     Initializes a `Where` clause that compares equality
     
     - parameter keyPath: the keyPath to compare with
     - parameter objectID: the arguments for the `==` operator
     */
    public init<D: DynamicObject>(
        _ keyPath: KeyPath<O, D>,
        isEqualTo objectID: NSManagedObjectID
    ) {

        self.init(
            keyPath._kvcKeyPathString!,
            isEqualTo: objectID
        )
    }
    
    /**
     Initializes a `Where` clause that compares membership
     
     - parameter keyPath: the keyPath to compare with
     - parameter list: the sequence to check membership of
     */
    public init<V: QueryableAttributeType, S: Sequence>(
        _ keyPath: KeyPath<O, V>,
        isMemberOf list: S
    ) where S.Iterator.Element == V {

        self.init(
            keyPath._kvcKeyPathString!,
            isMemberOf: list
        )
    }
    
    /**
     Initializes a `Where` clause that compares membership
     
     - parameter keyPath: the keyPath to compare with
     - parameter list: the sequence to check membership of
     */
    public init<D: DynamicObject, S: Sequence>(
        _ keyPath: KeyPath<O, D>,
        isMemberOf list: S
    ) where S.Iterator.Element == D {

        self.init(
            keyPath._kvcKeyPathString!,
            isMemberOf: list
        )
    }
    
    /**
     Initializes a `Where` clause that compares membership
     
     - parameter keyPath: the keyPath to compare with
     - parameter list: the sequence to check membership of
     */
    public init<D: DynamicObject, S: Sequence>(
        _ keyPath: KeyPath<D, O>,
        isMemberOf list: S
    ) where S.Iterator.Element: NSManagedObjectID {

        self.init(
            keyPath._kvcKeyPathString!,
            isMemberOf: list
        )
    }
}


// MARK: - Where where O: CoreStoreObject

extension Where where O: CoreStoreObject {

    /**
     Initializes a `Where` clause that compares equality

     - parameter keyPath: the keyPath to compare with
     - parameter value: the arguments for the `==` operator
     */
    public init<V>(
        _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
        isEqualTo value: V
    ) {

        self.init(
            O.meta[keyPath: keyPath].keyPath,
            isEqualTo: value
        )
    }

    /**
     Initializes a `Where` clause that compares equality

     - parameter keyPath: the keyPath to compare with
     - parameter value: the arguments for the `==` operator
     */
    public init<V: FieldRelationshipToOneType>(
        _ keyPath: KeyPath<O, FieldContainer<O>.Relationship<V>>,
        isEqualTo value: V.DestinationObjectType?
    ) {

        self.init(
            O.meta[keyPath: keyPath].keyPath,
            isEqualTo: value
        )
    }
    
    /**
     Initializes a `Where` clause that compares equality to `nil`
     
     - parameter keyPath: the keyPath to compare with
     - parameter null: the arguments for the `==` operator
     */
    public init<V>(
        _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
        isEqualTo null: Void?
    ) {

        self.init(
            O.meta[keyPath: keyPath].keyPath,
            isEqualTo: null
        )
    }
    
    /**
     Initializes a `Where` clause that compares equality to `nil`
     
     - parameter keyPath: the keyPath to compare with
     - parameter null: the arguments for the `==` operator
     */
    public init<V: FieldRelationshipToOneType>(
        _ keyPath: KeyPath<O, FieldContainer<O>.Relationship<V>>,
        isEqualTo null: Void?
    ) {

        self.init(
            O.meta[keyPath: keyPath].keyPath,
            isEqualTo: null
        )
    }
    
    /**
     Initializes a `Where` clause that compares membership
     
     - parameter keyPath: the keyPath to compare with
     - parameter list: the sequence to check membership of
     */
    public init<V, S: Sequence>(
        _ keyPath: KeyPath<O, FieldContainer<O>.Stored<V>>,
        isMemberOf list: S
    ) where S.Iterator.Element == V {

        self.init(
            O.meta[keyPath: keyPath].keyPath,
            isMemberOf: list
        )
    }
    
    /**
     Initializes a `Where` clause that compares membership
     
     - parameter keyPath: the keyPath to compare with
     - parameter list: the sequence to check membership of
     */
    public init<V: FieldRelationshipToOneType, S: Sequence>(
        _ keyPath: KeyPath<O, FieldContainer<O>.Relationship<V>>,
        isMemberOf list: S
    ) where S.Iterator.Element == V.DestinationObjectType {

        self.init(
            O.meta[keyPath: keyPath].keyPath,
            isMemberOf: list
        )
    }
    
    /**
     Initializes a `Where` clause that compares membership
     
     - parameter keyPath: the keyPath to compare with
     - parameter list: the sequence to check membership of
     */
    public init<V: FieldRelationshipToOneType, S: Sequence>(
        _ keyPath: KeyPath<O, FieldContainer<O>.Relationship<V>>,
        isMemberOf list: S
    ) where S.Iterator.Element: NSManagedObjectID {

        self.init(
            O.meta[keyPath: keyPath].keyPath,
            isMemberOf: list
        )
    }
    
    /**
     Initializes a `Where` clause from a closure
     
     - parameter condition: closure that returns the `Where` clause
     */
    public init(
        _ condition: (O) -> Where<O>
    ) {

        self = condition(O.meta)
    }
}


// MARK: - Sequence where Iterator.Element: WhereClauseType

extension Sequence where Iterator.Element: WhereClauseType {
    
    /**
     Combines multiple `Where` predicates together using `AND` operator
     */
    public func combinedByAnd() -> Where<Iterator.Element.ObjectType> {
        
        return Where(
            NSCompoundPredicate(
                type: .and,
                subpredicates: self.map({ $0.predicate })
            )
        )
    }
    
    /**
     Combines multiple `Where` predicates together using `OR` operator
     */
    public func combinedByOr() -> Where<Iterator.Element.ObjectType> {
        
        return Where(
            NSCompoundPredicate(
                type: .or,
                subpredicates: self.map({ $0.predicate })
            )
        )
    }
}


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension Where where O: CoreStoreObject {
    
    public init<V>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<V>>, isEqualTo value: V?) {
        
        self.init(O.meta[keyPath: keyPath].keyPath, isEqualTo: value)
    }
    
    public init<V>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<V>>, isEqualTo value: V?) {
        
        self.init(O.meta[keyPath: keyPath].keyPath, isEqualTo: value)
    }
    
    public init<V>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<V>>, isEqualTo null: Void?) {
        
        self.init(O.meta[keyPath: keyPath].keyPath, isEqualTo: null)
    }
    
    public init<D>(_ keyPath: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, isEqualTo null: Void?) {
        
        self.init(O.meta[keyPath: keyPath].keyPath, isEqualTo: null)
    }
    
    public init<D>(_ keyPath: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, isEqualTo value: D?) {
        
        self.init(O.meta[keyPath: keyPath].keyPath, isEqualTo: value)
    }
    
    public init<D>(_ keyPath: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, isEqualTo objectID: NSManagedObjectID) {
        
        self.init(O.meta[keyPath: keyPath].keyPath, isEqualTo: objectID)
    }
    
    public init<V, S: Sequence>(_ keyPath: KeyPath<O, ValueContainer<O>.Required<V>>, isMemberOf list: S) where S.Iterator.Element == V {
        
        self.init(O.meta[keyPath: keyPath].keyPath, isMemberOf: list)
    }
    
    public init<V, S: Sequence>(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<V>>, isMemberOf list: S) where S.Iterator.Element == V {
        
        self.init(O.meta[keyPath: keyPath].keyPath, isMemberOf: list)
    }
    
    public init<D, S: Sequence>(_ keyPath: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, isMemberOf list: S) where S.Iterator.Element == D {
        
        self.init(O.meta[keyPath: keyPath].keyPath, isMemberOf: list)
    }
    
    public init<D, S: Sequence>(_ keyPath: KeyPath<O, RelationshipContainer<O>.ToOne<D>>, isMemberOf list: S) where S.Iterator.Element: NSManagedObjectID {
        
        self.init(O.meta[keyPath: keyPath].keyPath, isMemberOf: list)
    }
}
