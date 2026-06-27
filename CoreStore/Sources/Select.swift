//
//  Select.swift
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
import CoreGraphics
import CoreData


// MARK: - SelectResultType

/**
 The `SelectResultType` protocol is implemented by return types supported by the `Select` clause.
 */
public protocol SelectResultType {}


// MARK: - SelectAttributesResultType

/**
 The `SelectAttributesResultType` protocol is implemented by return types supported by the `queryAttributes(...)` methods.
 */
public protocol SelectAttributesResultType: SelectResultType {
    
    static func cs_fromQueryResultsNativeType(
        _ result: [Any]
    ) -> [[String: Any]]
}


// MARK: - SelectTerm

/**
 The `SelectTerm` is passed to the `Select` clause to indicate the attributes/aggregate keys to be queried.
 */
public enum SelectTerm<O: DynamicObject>: ExpressibleByStringLiteral, Hashable {
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying an entity attribute. A shorter way to do the same is to assign from the string keypath directly:
     ```
     let fullName = dataStack.queryValue(
         From<MyPersonEntity>(),
         Select<String>(.attribute("fullName")),
         Where("employeeID", isEqualTo: 1111)
     )
     ```
     is equivalent to:
     ```
     let fullName = dataStack.queryValue(
         From<MyPersonEntity>(),
         Select<String>("fullName"),
         Where("employeeID", isEqualTo: 1111)
     )
     ```
     - parameter keyPath: the attribute name
     - returns: a `SelectTerm` to a `Select` clause for querying an entity attribute
     */
    public static func attribute(
        _ keyPath: KeyPathString
    ) -> SelectTerm<O> {

        return ._attribute(keyPath)
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the average value of an attribute.
     ```
     let averageAge = dataStack.queryValue(
         From<MyPersonEntity>(),
         Select<Int>(.average("age"))
     )
     ```
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "average(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the average value of an attribute
     */
    public static func average(
        _ keyPath: KeyPathString,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return ._aggregate(
            function: "average:",
            keyPath: keyPath,
            alias: alias ?? "average(\(keyPath))",
            nativeType: .decimalAttributeType
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for a count query.
     ```
     let numberOfEmployees = dataStack.queryValue(
         From<MyPersonEntity>(),
         Select<Int>(.count("employeeID"))
     )
     ```
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "count(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for a count query
     */
    public static func count(
        _ keyPath: KeyPathString,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return ._aggregate(
            function: "count:",
            keyPath: keyPath,
            alias: alias ?? "count(\(keyPath))",
            nativeType: .integer64AttributeType
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the maximum value for an attribute.
     ```
     let maximumAge = dataStack.queryValue(
         From<MyPersonEntity>(),
         Select<Int>(.maximum("age"))
     )
     ```
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "max(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the maximum value for an attribute
     */
    public static func maximum(
        _ keyPath: KeyPathString,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return ._aggregate(
            function: "max:",
            keyPath: keyPath,
            alias: alias ?? "max(\(keyPath))",
            nativeType: .undefinedAttributeType
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the minimum value for an attribute.
     ```
     let minimumAge = dataStack.queryValue(
         From<MyPersonEntity>(),
         Select<Int>(.minimum("age"))
     )
     ```
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "min(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the minimum value for an attribute
     */
    public static func minimum(
        _ keyPath: KeyPathString,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return ._aggregate(
            function: "min:",
            keyPath: keyPath,
            alias: alias ?? "min(\(keyPath))",
            nativeType: .undefinedAttributeType
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the sum value for an attribute.
     ```
     let totalAge = dataStack.queryValue(
         From<MyPersonEntity>(),
         Select<Int>(.sum("age"))
     )
     ```
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "sum(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the sum value for an attribute
     */
    public static func sum(
        _ keyPath: KeyPathString,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return ._aggregate(
            function: "sum:",
            keyPath: keyPath,
            alias: alias ?? "sum(\(keyPath))",
            nativeType: .decimalAttributeType
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the `NSManagedObjectID`.
     ```
     let objectID = dataStack.queryValue(
         From<MyPersonEntity>(),
         Select<NSManagedObjectID>(),
         Where("employeeID", isEqualTo: 1111)
     )
     ```
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "objecID" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the sum value for an attribute
     */
    public static func objectID(
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return ._identity(
            alias: alias ?? "objectID",
            nativeType: .objectIDAttributeType
        )
    }
    
    
    // MARK: ExpressibleByStringLiteral
    
    public init(stringLiteral value: KeyPathString) {
        
        self = ._attribute(value)
    }
    
    public init(unicodeScalarLiteral value: KeyPathString) {
        
        self = ._attribute(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: KeyPathString) {
        
        self = ._attribute(value)
    }
    
    
    // MARK: Equatable
    
    public static func == (
        lhs: SelectTerm<O>,
        rhs: SelectTerm<O>
    ) -> Bool {

        switch (lhs, rhs) {
            
        case (._attribute(let keyPath1), ._attribute(let keyPath2)):
            return keyPath1 == keyPath2
            
        case (._aggregate(let function1, let keyPath1, let alias1, let nativeType1),
              ._aggregate(let function2, let keyPath2, let alias2, let nativeType2)):
            return function1 == function2
                && keyPath1 == keyPath2
                && alias1 == alias2
                && nativeType1 == nativeType2
            
        case (._identity(let alias1, let nativeType1), ._identity(let alias2, let nativeType2)):
            return alias1 == alias2 && nativeType1 == nativeType2
            
        case (._attribute, _),
             (._aggregate, _),
             (._identity, _):
            return false
        }
    }
    
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        switch self {
            
        case ._attribute(let keyPath):
            hasher.combine(0)
            hasher.combine(keyPath)
            
        case ._aggregate(let function, let keyPath, let alias, let nativeType):
            hasher.combine(1)
            hasher.combine(function)
            hasher.combine(keyPath)
            hasher.combine(alias)
            hasher.combine(nativeType)
            
        case ._identity(let alias, let nativeType):
            hasher.combine(2)
            hasher.combine(alias)
            hasher.combine(nativeType)
        }
    }
    
    
    // MARK: Internal
    
    case _attribute(KeyPathString)

    case _aggregate(
        function: String,
        keyPath: KeyPathString,
        alias: String,
        nativeType: NSAttributeType
    )

    case _identity(
        alias: String,
        nativeType: NSAttributeType
    )

    internal var keyPathString: String {
        
        switch self {
            
        case ._attribute(let keyPath):          return keyPath
        case ._aggregate(_, _, let alias, _):   return alias
        case ._identity(let alias, _):          return alias
        }
    }
}


// MARK: - SelectTerm where O: NSManagedObject

extension SelectTerm where O: NSManagedObject {
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying an entity attribute.
     - parameter keyPath: the attribute name
     - returns: a `SelectTerm` to a `Select` clause for querying an entity attribute
     */
    public static func attribute<V>(
        _ keyPath: KeyPath<O, V>
    ) -> SelectTerm<O> {

        return self.attribute(keyPath._kvcKeyPathString!)
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the average value of an attribute.
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "average(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the average value of an attribute
     */
    public static func average<V>(
        _ keyPath: KeyPath<O, V>,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return self.average(
            keyPath._kvcKeyPathString!,
            as: alias
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for a count query.
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "count(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for a count query
     */
    public static func count<V>(
        _ keyPath: KeyPath<O, V>,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return self.count(
            keyPath._kvcKeyPathString!,
            as: alias
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the maximum value for an attribute.
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "max(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the maximum value for an attribute
     */
    public static func maximum<V>(
        _ keyPath: KeyPath<O, V>,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return self.maximum(
            keyPath._kvcKeyPathString!,
            as: alias
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the minimum value for an attribute.
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "min(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the minimum value for an attribute
     */
    public static func minimum<V>(
        _ keyPath: KeyPath<O, V>,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return self.minimum(
            keyPath._kvcKeyPathString!,
            as: alias
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the sum value for an attribute.
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "sum(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the sum value for an attribute
     */
    public static func sum<V>(
        _ keyPath: KeyPath<O, V>,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> {

        return self.sum(
            keyPath._kvcKeyPathString!,
            as: alias
        )
    }
}


// MARK: - SelectTerm where O: CoreStoreObject

extension SelectTerm where O: CoreStoreObject {

    /**
     Provides a `SelectTerm` to a `Select` clause for querying an entity attribute.
     - parameter keyPath: the attribute name
     - returns: a `SelectTerm` to a `Select` clause for querying an entity attribute
     */
    public static func attribute<K: AttributeKeyPathStringConvertible>(
        _ keyPath: KeyPath<O, K>
    ) -> SelectTerm<O> where K.ObjectType == O {

        return self.attribute(O.meta[keyPath: keyPath].cs_keyPathString)
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the average value of an attribute.
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "average(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the average value of an attribute
     */
    public static func average<K: AttributeKeyPathStringConvertible>(
        _ keyPath: KeyPath<O, K>,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> where K.ObjectType == O{

        return self.average(
            O.meta[keyPath: keyPath].cs_keyPathString,
            as: alias
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for a count query.
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "count(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for a count query
     */
    public static func count<K: AttributeKeyPathStringConvertible>(
        _ keyPath: KeyPath<O, K>,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> where K.ObjectType == O {

        return self.count(
            O.meta[keyPath: keyPath].cs_keyPathString,
            as: alias
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the maximum value for an attribute.
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "max(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the maximum value for an attribute
     */
    public static func maximum<K: AttributeKeyPathStringConvertible>(
        _ keyPath: KeyPath<O, K>,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> where K.ObjectType == O {

        return self.maximum(
            O.meta[keyPath: keyPath].cs_keyPathString,
            as: alias
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the minimum value for an attribute.
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "min(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the minimum value for an attribute
     */
    public static func minimum<K: AttributeKeyPathStringConvertible>(
        _ keyPath: KeyPath<O, K>,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> where K.ObjectType == O {

        return self.minimum(
            O.meta[keyPath: keyPath].cs_keyPathString,
            as: alias
        )
    }
    
    /**
     Provides a `SelectTerm` to a `Select` clause for querying the sum value for an attribute.
     - parameter keyPath: the attribute name
     - parameter alias: the dictionary key to use to access the result. Ignored when the query return value is not an `NSDictionary`. If `nil`, the default key "sum(<attributeName>)" is used
     - returns: a `SelectTerm` to a `Select` clause for querying the sum value for an attribute
     */
    public static func sum<K: AttributeKeyPathStringConvertible>(
        _ keyPath: KeyPath<O, K>,
        as alias: KeyPathString? = nil
    ) -> SelectTerm<O> where K.ObjectType == O {

        return self.sum(
            O.meta[keyPath: keyPath].cs_keyPathString,
            as: alias
        )
    }
}


// MARK: - Select

/**
 The `Select` clause indicates the attribute / aggregate value to be queried. The generic type is a `SelectResultType`, and will be used as the return type for the query.
 
 You can bind the return type by specializing the initializer:
 ```
 let maximumAge = dataStack.queryValue(
     From<MyPersonEntity>(),
     Select<Int>(.maximum("age"))
 )
 ```
 or by casting the type of the return value:
 ```
 let maximumAge: Int = dataStack.queryValue(
     From<MyPersonEntity>(),
     Select(.maximum("age"))
 )
 ```
 Valid return types depend on the query:
 
 - for `queryValue(...)` methods:
     - all types that conform to `QueryableAttributeType` protocol
 - for `queryAttributes(...)` methods:
     - `NSDictionary`
 
 - parameter sortDescriptors: a series of `NSSortDescriptor`s
 */
public struct Select<O: DynamicObject, T: SelectResultType>: SelectClause, Hashable {
    
    /**
     Initializes a `Select` clause with a list of `SelectTerm`s
     
     - parameter selectTerm: a `SelectTerm`
     - parameter selectTerms: a series of `SelectTerm`s
     */
    public init(
        _ selectTerm: SelectTerm<O>,
        _ selectTerms: SelectTerm<O>...
    ) {

        self.selectTerms = [selectTerm] + selectTerms
    }
    
    /**
     Initializes a `Select` clause with a list of `SelectTerm`s
     
     - parameter selectTerms: a series of `SelectTerm`s
     */
    public init(
        _ selectTerms: [SelectTerm<O>]
    ) {

        self.selectTerms = selectTerms
    }
    
    
    // MARK: Equatable
    
    public static func == <T1, T2>(
        lhs: Select<O, T1>,
        rhs: Select<O, T2>
    ) -> Bool {

        return lhs.selectTerms == rhs.selectTerms
    }
    
    
    // MARK: SelectClause
    
    public typealias ObjectType = O
    public typealias ReturnType = T
    
    public let selectTerms: [SelectTerm<O>]
    
    
    // MARK: Hashable

    public func hash(into hasher: inout Hasher) {

        hasher.combine(self.selectTerms)
    }
    
    
    // MARK: Internal
    
    internal func applyToFetchRequest(
        _ fetchRequest: NSFetchRequest<NSDictionary>
    ) {

        fetchRequest.includesPendingChanges = false
        fetchRequest.resultType = .dictionaryResultType
        
        func attributeDescription(for keyPath: String, in entity: NSEntityDescription) -> NSAttributeDescription? {
            
            let components = keyPath.components(separatedBy: ".")
            switch components.count {
                
            case 0:
                return nil
                
            case 1:
                return entity.attributesByName[components[0]]
                
            default:
                guard let relationship = entity.relationshipsByName[components[0]],
                    let destinationEntity = relationship.destinationEntity else {
                        
                        return nil
                }
                return attributeDescription(
                    for: components.dropFirst().joined(separator: "."),
                    in: destinationEntity
                )
            }
        }
        
        var propertiesToFetch = [Any]()
        for term in self.selectTerms {
            
            switch term {
                
            case ._attribute(let keyPath):
                propertiesToFetch.append(keyPath)
                
            case ._aggregate(let function, let keyPath, let alias, let nativeType):
                let entityDescription = fetchRequest.entity!
                if let attributeDescription = attributeDescription(for: keyPath, in: entityDescription) {
                    
                    let expressionDescription = NSExpressionDescription()
                    expressionDescription.name = alias
                    if nativeType == .undefinedAttributeType {
                        
                        expressionDescription.expressionResultType = attributeDescription.attributeType
                    }
                    else {
                        
                        expressionDescription.expressionResultType = nativeType
                    }
                    expressionDescription.expression = NSExpression(
                        forFunction: function,
                        arguments: [NSExpression(forKeyPath: keyPath)]
                    )
                    propertiesToFetch.append(expressionDescription)
                }
                else {
                    
                    Internals.log(
                        .warning,
                        message: "The key path \"\(keyPath)\" could not be resolved in entity \(Internals.typeName(entityDescription.managedObjectClassName)) as an attribute and will be ignored by \(Internals.typeName(self)) query clause."
                    )
                }
                
            case ._identity(let alias, let nativeType):
                let expressionDescription = NSExpressionDescription()
                expressionDescription.name = alias
                if nativeType == .undefinedAttributeType {
                    
                    expressionDescription.expressionResultType = .objectIDAttributeType
                }
                else {
                    
                    expressionDescription.expressionResultType = nativeType
                }
                expressionDescription.expression = NSExpression.expressionForEvaluatedObject()
                
                propertiesToFetch.append(expressionDescription)
            }
        }
        
        fetchRequest.propertiesToFetch = propertiesToFetch
    }
}

extension Select where T: NSManagedObjectID {
    
    /**
     Initializes a `Select` that queries for `NSManagedObjectID` results
     */
    public init() {
        
        self.init(.objectID())
    }
}

extension Select where O: NSManagedObject {
    
    /**
     Initializes a `Select` that queries the value of an attribute pertained by a keyPath
     - parameter keyPath: the keyPath for the attribute
     */
    public init(_ keyPath: KeyPath<O, T>) {
        
        self.init(.attribute(keyPath))
    }
}


// MARK: - SelectClause

/**
 Abstracts the `Select` clause for protocol utilities.
 */
public protocol SelectClause {
    
    /**
     The `DynamicObject` type associated with the clause
     */
    associatedtype ObjectType: DynamicObject
    
    /**
     The `SelectResultType` type associated with the clause
     */
    associatedtype ReturnType: SelectResultType
    
    /**
     The `SelectTerm`s for the query
     */
    var selectTerms: [SelectTerm<ObjectType>] { get }
}


// MARK: - NSDictionary: SelectAttributesResultType

extension NSDictionary: SelectAttributesResultType {
    
    // MARK: SelectAttributesResultType
    
    public static func cs_fromQueryResultsNativeType(
        _ result: [Any]
    ) -> [[String : Any]] {

        return result as! [[String: Any]]
    }
}


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension Select where O: CoreStoreObject, T: ImportableAttributeType {
    
    public init(_ keyPath: KeyPath<O, ValueContainer<O>.Required<T>>) {
        
        self.init(.attribute(keyPath))
    }
    
    public init(_ keyPath: KeyPath<O, ValueContainer<O>.Optional<T>>) {
        
        self.init(.attribute(keyPath))
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension Select where O: CoreStoreObject, T: ImportableAttributeType & NSCoding & NSCopying {
    
    public init(_ keyPath: KeyPath<O, TransformableContainer<O>.Required<T>>) {
        
        self.init(.attribute(keyPath))
    }
    
    public init(_ keyPath: KeyPath<O, TransformableContainer<O>.Optional<T>>) {
        
        self.init(.attribute(keyPath))
    }
}
