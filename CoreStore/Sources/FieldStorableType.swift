//
//  FieldStorableType.swift
//  CoreStore
//
//  Copyright © 2020 John Rommel Estropia
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
import CoreGraphics


// MARK: - FieldStorableType

/**
 Values to be used for `Field.Stored` properties.
 */
public protocol FieldStorableType {

    /**
     The `NSAttributeType` for this type
     */
    associatedtype FieldStoredNativeType

    /**
     The `NSAttributeType` for this type. Used internally by CoreStore. Do not call directly.
     */
    static var cs_rawAttributeType: NSAttributeType { get }

    /**
     Creates an instance of this type from raw native value. Used internally by CoreStore. Do not call directly.
     */
    @inline(__always)
    static func cs_fromFieldStoredNativeType(_ value: FieldStoredNativeType) -> Self

    /**
     Creates `FieldStoredNativeType` value from this instance. Used internally by CoreStore. Do not call directly.     
     */
    @inline(__always)
    func cs_toFieldStoredNativeType() -> Any?
}


// MARK: - FieldStorableType where Self: ImportableAttributeType, FieldStoredNativeType == QueryableNativeType

extension FieldStorableType where Self: ImportableAttributeType, FieldStoredNativeType == QueryableNativeType {

    @inline(__always)
    public static func cs_fromFieldStoredNativeType(_ value: FieldStoredNativeType) -> Self {

        return self.cs_fromQueryableNativeType(value)!
    }

    @inline(__always)
    public func cs_toFieldStoredNativeType() -> Any? {

        return self.cs_toQueryableNativeType()
    }
}


// MARK: - Bool

extension Bool: FieldStorableType {}


// MARK: - CGFloat

extension CGFloat: FieldStorableType {}


// MARK: - Data

extension Data: FieldStorableType {}


// MARK: - Date

extension Date: FieldStorableType {}


// MARK: - Double

extension Double: FieldStorableType {}


// MARK: - Float

extension Float: FieldStorableType {}


// MARK: - Int

extension Int: FieldStorableType {}


// MARK: - Int8

extension Int8: FieldStorableType {}


// MARK: - Int16

extension Int16: FieldStorableType {}


// MARK: - Int32

extension Int32: FieldStorableType {}


// MARK: - Int64

extension Int64: FieldStorableType {}


// MARK: - NSData

extension NSData: FieldStorableType {

    @nonobjc @inline(__always)
    public class func cs_fromFieldStoredNativeType(_ value: FieldStoredNativeType) -> Self {

        return self.cs_fromQueryableNativeType(value)!
    }
}


// MARK: - NSDate

extension NSDate: FieldStorableType {

    @nonobjc @inline(__always)
    public class func cs_fromFieldStoredNativeType(_ value: FieldStoredNativeType) -> Self {

        return self.cs_fromQueryableNativeType(value)!
    }
}


// MARK: - NSNumber

extension NSNumber: FieldStorableType {

    @nonobjc @inline(__always)
    public class func cs_fromFieldStoredNativeType(_ value: FieldStoredNativeType) -> Self {

        return self.cs_fromQueryableNativeType(value)!
    }
}


// MARK: - NSString

extension NSString: FieldStorableType {

    @nonobjc @inline(__always)
    public class func cs_fromFieldStoredNativeType(_ value: FieldStoredNativeType) -> Self {

        return self.cs_fromQueryableNativeType(value)!
    }
}


// MARK: - NSURL

extension NSURL: FieldStorableType {

    @nonobjc @inline(__always)
    public class func cs_fromFieldStoredNativeType(_ value: FieldStoredNativeType) -> Self {

        return self.cs_fromQueryableNativeType(value)!
    }
}


// MARK: - NSUUID

extension NSUUID: FieldStorableType {

    @nonobjc @inline(__always)
    public class func cs_fromFieldStoredNativeType(_ value: FieldStoredNativeType) -> Self {

        return self.cs_fromQueryableNativeType(value)!
    }
}


// MARK: - String

extension String: FieldStorableType {}


// MARK: - URL

extension URL: FieldStorableType {}


// MARK: - UUID

extension UUID: FieldStorableType {}


// MARK: - Optional<FieldStorableType>

extension Optional: FieldStorableType where Wrapped: FieldStorableType {

    // MARK: FieldStorableType

    public typealias FieldStoredNativeType = Wrapped.FieldStoredNativeType?

    public static var cs_rawAttributeType: NSAttributeType {

        return Wrapped.cs_rawAttributeType
    }

    @inline(__always)
    public static func cs_fromFieldStoredNativeType(_ value: FieldStoredNativeType) -> Self {

        switch value {

        case nil,
             is NSNull:
            return nil

        case let value?:
            return Wrapped.cs_fromFieldStoredNativeType(value)
        }
    }

    @inline(__always)
    public func cs_toFieldStoredNativeType() -> Any? {

        switch self {

        case nil,
             is NSNull:
            return nil

        case let value?:
            return value.cs_toFieldStoredNativeType()
        }
    }
}
