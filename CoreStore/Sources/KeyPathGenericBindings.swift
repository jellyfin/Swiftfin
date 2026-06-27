//
//  KeyPathGenericBindings.swift
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


// MARK: - AllowedObjectiveCKeyPathValue

/**
 Used only for utility methods. Types allowed as `Value` generic type to `KeyPath` utilities.
 */
public protocol AllowedObjectiveCKeyPathValue {

    /**
     The destination value type
     */
    associatedtype DestinationValueType
}


// MARK: - AllowedOptionalObjectiveCKeyPathValue

/**
 Used only for utility methods. Types allowed as `Value` generic type to `KeyPath` utilities.
 */
public protocol AllowedOptionalObjectiveCKeyPathValue: AllowedObjectiveCKeyPathValue {}

extension Bool: AllowedObjectiveCKeyPathValue {

    public typealias DestinationValueType = Bool
}

extension CGFloat: AllowedObjectiveCKeyPathValue {

    public typealias DestinationValueType = CGFloat
}

extension Data: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = Data
}

extension Date: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = Date
}

extension Double: AllowedObjectiveCKeyPathValue {

    public typealias DestinationValueType = Double
}

extension Float: AllowedObjectiveCKeyPathValue {

    public typealias DestinationValueType = Float
}

extension Int: AllowedObjectiveCKeyPathValue {

    public typealias DestinationValueType = Int
}

extension Int8: AllowedObjectiveCKeyPathValue {

    public typealias DestinationValueType = Int8
}

extension Int16: AllowedObjectiveCKeyPathValue {

    public typealias DestinationValueType = Int16
}

extension Int32: AllowedObjectiveCKeyPathValue {

    public typealias DestinationValueType = Int32
}

extension Int64: AllowedObjectiveCKeyPathValue {

    public typealias DestinationValueType = Int64
}

extension NSData: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = NSData
}

extension NSDate: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = NSDate
}

extension NSManagedObject: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = NSManagedObject
}

extension NSNumber: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = NSNumber
}

extension NSString: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = NSString
}

extension NSSet: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = NSSet
}

extension NSOrderedSet: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = NSOrderedSet
}

extension NSURL: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = NSURL
}

extension NSUUID: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = NSUUID
}

extension String: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = String
}

extension URL: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = URL
}

extension UUID: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = UUID
}

extension Optional: AllowedObjectiveCKeyPathValue where Wrapped: AllowedOptionalObjectiveCKeyPathValue {

    public typealias DestinationValueType = Wrapped.DestinationValueType
}


// MARK: - AllowedObjectiveCAttributeKeyPathValue

/**
 Used only for utility methods. Types allowed as `Value` generic type to `KeyPath` utilities.
 */
public protocol AllowedObjectiveCAttributeKeyPathValue: AllowedObjectiveCKeyPathValue {

    /**
     The attribute value type
     */
    associatedtype ReturnValueType
}

extension Bool: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = Bool
}

extension CGFloat: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = CGFloat
}

extension Data: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = Data
}

extension Date: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = Date
}

extension Double: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = Double
}

extension Float: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = Float
}

extension Int: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = Int
}

extension Int8: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = Int8
}

extension Int16: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = Int16
}

extension Int32: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = Int32
}

extension Int64: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = Int64
}

extension NSData: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = NSData
}

extension NSDate: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = NSDate
}

extension NSNumber: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = NSNumber
}

extension NSString: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = NSString
}

extension NSURL: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = NSURL
}

extension NSUUID: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = NSUUID
}

extension String: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = String
}

extension URL: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = URL
}

extension UUID: AllowedObjectiveCAttributeKeyPathValue {

    public typealias ReturnValueType = UUID
}

extension Optional: AllowedObjectiveCAttributeKeyPathValue where Wrapped: AllowedObjectiveCAttributeKeyPathValue, Wrapped: AllowedOptionalObjectiveCKeyPathValue {

    public typealias ReturnValueType = Optional
}


// MARK: - AllowedObjectiveCRelationshipKeyPathValue

/**
 Used only for utility methods. Types allowed as `Value` generic type to `KeyPath` utilities.
 */
public protocol AllowedObjectiveCRelationshipKeyPathValue: AllowedOptionalObjectiveCKeyPathValue {}

extension NSManagedObject: AllowedObjectiveCRelationshipKeyPathValue {}

extension NSSet: AllowedObjectiveCRelationshipKeyPathValue {}

extension NSOrderedSet: AllowedObjectiveCRelationshipKeyPathValue {}

extension Optional: AllowedOptionalObjectiveCKeyPathValue, AllowedObjectiveCRelationshipKeyPathValue where Wrapped: AllowedObjectiveCRelationshipKeyPathValue {}


// MARK: - AllowedObjectiveCToManyRelationshipKeyPathValue

/**
 Used only for utility methods. Types allowed as `Value` generic type to `KeyPath` utilities.
 */
public protocol AllowedObjectiveCToManyRelationshipKeyPathValue: AllowedOptionalObjectiveCKeyPathValue {}

extension NSSet: AllowedObjectiveCToManyRelationshipKeyPathValue {}

extension NSOrderedSet: AllowedObjectiveCToManyRelationshipKeyPathValue {}

extension Optional: AllowedObjectiveCToManyRelationshipKeyPathValue where Wrapped: AllowedObjectiveCToManyRelationshipKeyPathValue, Wrapped: AllowedObjectiveCRelationshipKeyPathValue {}
