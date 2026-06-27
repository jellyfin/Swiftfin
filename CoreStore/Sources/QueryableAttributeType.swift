//
//  QueryableAttributeType.swift
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
import CoreGraphics


// MARK: - QueryableAttributeType

/**
 Types supported by CoreStore for querying, especially as generic type for `Select` clauses.
 Supported default types:
 - `Bool`
 - `CGFloat`
 - `Data`
 - `Date`
 - `Double`
 - `Float`
 - `Int`
 - `Int8`
 - `Int16`
 - `Int32`
 - `Int64`
 - `NSData`
 - `NSDate`
 - `NSDecimalNumber`
 - `NSManagedObjectID`
 - `NSNull`
 - `NSNumber`
 - `NSString`
 - `NSURL`
 - `NSUUID`
 - `String`
 - `URL`
 - `UUID`
 
 In addition, `RawRepresentable` types whose `RawValue` already implements `QueryableAttributeType` only need to declare conformance to `QueryableAttributeType`.
 */
public protocol QueryableAttributeType: Hashable, SelectResultType {
    
    /**
     The `CoreDataNativeType` for this type when used in `Select` clauses.
     */
    associatedtype QueryableNativeType
    
    /**
     The `NSAttributeType` for this type when used in `Select` clauses.
     */
    static var cs_rawAttributeType: NSAttributeType { get }
    
    /**
     Creates an instance of this type from its `QueryableNativeType` value.
     */
    @inline(__always)
    static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self?
    
    /**
     Creates `QueryableNativeType` value from this instance.
     */
    @inline(__always)
    func cs_toQueryableNativeType() -> QueryableNativeType
}


// MARK: - Bool

extension Bool: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNumber
    
    public static let cs_rawAttributeType: NSAttributeType = .booleanAttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Bool? {
        
        switch value {
            
        case let decimal as NSDecimalNumber:
            // iOS: NSDecimalNumber(string: "0.5").boolValue // true
            // macOS: NSDecimalNumber(string: "0.5").boolValue // false
            return decimal != NSDecimalNumber.zero
            
        default:
            return value.boolValue
        }
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as QueryableNativeType
    }
}


// MARK: - CGFloat

extension CGFloat: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNumber
    
    public static let cs_rawAttributeType: NSAttributeType = .doubleAttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> CGFloat? {
        
        return CGFloat(value.doubleValue)
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as QueryableNativeType
    }
}


// MARK: - Data

extension Data: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSData
    
    public static let cs_rawAttributeType: NSAttributeType = .binaryDataAttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Data? {
        
        return value as Data
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as QueryableNativeType
    }
}


// MARK: - Date

extension Date: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSDate
    
    public static let cs_rawAttributeType: NSAttributeType = .dateAttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Date? {
        
        return value as Date
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as NSDate
    }
}


// MARK: - Double

extension Double: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNumber
    
    public static let cs_rawAttributeType: NSAttributeType = .doubleAttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Double? {
        
        return value.doubleValue
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as NSNumber
    }
}


// MARK: - Float

extension Float: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNumber
    
    public static let cs_rawAttributeType: NSAttributeType = .floatAttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Float? {
        
        return value.floatValue
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as NSNumber
    }
}


// MARK: - Int

extension Int: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNumber
    
    public static let cs_rawAttributeType: NSAttributeType = .integer64AttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Int? {
        
        return value.intValue
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as NSNumber
    }
}


// MARK: - Int8

extension Int8: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNumber
    
    public static let cs_rawAttributeType: NSAttributeType = .integer16AttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Int8? {
        
        return value.int8Value
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as NSNumber
    }
}


// MARK: - Int16

extension Int16: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNumber
    
    public static let cs_rawAttributeType: NSAttributeType = .integer16AttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Int16? {
        
        return value.int16Value
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as NSNumber
    }
}


// MARK: - Int32

extension Int32: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNumber
    
    public static let cs_rawAttributeType: NSAttributeType = .integer32AttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Int32? {
        
        return value.int32Value
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as NSNumber
    }
}


// MARK: - Int64

extension Int64: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNumber
    
    public static let cs_rawAttributeType: NSAttributeType = .integer64AttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Int64? {
        
        return value.int64Value
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as NSNumber
    }
}


// MARK: - NSData

extension NSData: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSData
    
    @nonobjc
    public class var cs_rawAttributeType: NSAttributeType {
        
        return .binaryDataAttributeType
    }
    
    @nonobjc @inline(__always)
    public class func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self? {
        
        func forceCast<T: NSData>(_ value: Any) -> T? {
            
            return value as? T
        }
        return forceCast(value)
    }
    
    @nonobjc @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self
    }
}


// MARK: - NSDate

extension NSDate: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSDate
    
    @nonobjc
    public class var cs_rawAttributeType: NSAttributeType {
        
        return .dateAttributeType
    }
    
    @nonobjc @inline(__always)
    public class func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self? {
        
        func forceCast<T: NSDate>(_ value: Any) -> T? {
            
            return value as? T
        }
        return forceCast(value)
    }
    
    @nonobjc @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self
    }
}


// MARK: - NSDecimalNumber

extension NSDecimalNumber /*: QueryableAttributeType */ {
    
    public override class var cs_rawAttributeType: NSAttributeType {
        
        return .decimalAttributeType
    }
}


// MARK: - NSManagedObjectID

extension NSManagedObjectID: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSManagedObjectID
    
    @nonobjc
    public class var cs_rawAttributeType: NSAttributeType {
        
        return .objectIDAttributeType
    }
    
    @nonobjc @inline(__always)
    public class func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self? {
        
        func forceCast<T: NSManagedObjectID>(_ value: Any) -> T? {
            
            return value as? T
        }
        return forceCast(value)
    }
    
    @nonobjc @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self
    }
}


// MARK: - NSNull

extension NSNull: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNull
    
    @nonobjc
    public class var cs_rawAttributeType: NSAttributeType {
        
        return .undefinedAttributeType
    }
    
    @nonobjc @inline(__always)
    public class func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self? {
        
        func forceCast<T: NSNull>(_ value: Any) -> T? {
            
            return value as? T
        }
        return forceCast(value)
    }
    
    @nonobjc @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self
    }
}


// MARK: - NSNumber

extension NSNumber: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSNumber
    
    @objc
    public class var cs_rawAttributeType: NSAttributeType {
        
        return .integer64AttributeType
    }
    
    @nonobjc @inline(__always)
    public class func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self? {
        
        func forceCast<T: NSNumber>(_ value: Any) -> T? {
            
            return value as? T
        }
        return forceCast(value)
    }
    
    @nonobjc @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self
    }
}


// MARK: - NSString

extension NSString: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSString
    
    @nonobjc
    public class var cs_rawAttributeType: NSAttributeType {
        
        return .stringAttributeType
    }
    
    @nonobjc @inline(__always)
    public class func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self? {
        
        func forceCast<T: NSString>(_ value: Any) -> T? {
            
            return value as? T
        }
        return forceCast(value)
    }
    
    @nonobjc @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self
    }
}


// MARK: - NSURL

extension NSURL: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSString
    
    @nonobjc
    public class var cs_rawAttributeType: NSAttributeType {
        
        return .stringAttributeType
    }
    
    @nonobjc @inline(__always)
    public class func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self? {
        
        return self.init(string: value as String)
    }
    
    @nonobjc @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return (self as URL).absoluteString as QueryableNativeType
    }
}


// MARK: - NSUUID

extension NSUUID: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSString
    
    @nonobjc
    public class var cs_rawAttributeType: NSAttributeType {
        
        return .stringAttributeType
    }
    
    @nonobjc @inline(__always)
    public class func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self? {
        
        return self.init(uuidString: value.lowercased)
    }
    
    @nonobjc @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self.uuidString.lowercased() as QueryableNativeType
    }
}


// MARK: - String

extension String: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSString
    
    public static let cs_rawAttributeType: NSAttributeType = .stringAttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> String? {
        
        return value as String
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self as QueryableNativeType
    }
}


// MARK: - URL

extension URL: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSString
    
    public static let cs_rawAttributeType: NSAttributeType = .stringAttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> URL? {
        
        return self.init(string: value as String)
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self.absoluteString as QueryableNativeType
    }
}


// MARK: - UUID

extension UUID: QueryableAttributeType {
    
    public typealias QueryableNativeType = NSString
    
    public static let cs_rawAttributeType: NSAttributeType = .stringAttributeType
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> UUID? {
        
        return self.init(uuidString: value.lowercased)
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self.uuidString.lowercased() as QueryableNativeType
    }
}


// MARK: - RawRepresentable

extension RawRepresentable where RawValue: QueryableAttributeType {
    
    public typealias QueryableNativeType = RawValue.QueryableNativeType
    
    public static var cs_rawAttributeType: NSAttributeType {
        
        return RawValue.cs_rawAttributeType
    }
    
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self? {
        
        return RawValue.cs_fromQueryableNativeType(value).flatMap({ self.init(rawValue: $0) })
    }
    
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self.rawValue.cs_toQueryableNativeType()
    }
}
