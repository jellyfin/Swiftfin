//
//  ImportableAttributeType.swift
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


// MARK: - ImportableAttributeType

/**
 Types supported by CoreStore as `NSManagedObject` and `CoreStoreObject` property types.
 Supported default types:
 - Bool
 - CGFloat
 - Data
 - Date
 - Double
 - Float
 - Int
 - Int8
 - Int16
 - Int32
 - Int64
 - NSData
 - NSDate
 - NSDecimalNumber
 - NSNumber
 - NSString
 - NSURL
 - NSUUID
 - String
 - URL
 - UUID
 
 In addition, `RawRepresentable` types whose `RawValue` already implements `ImportableAttributeType` only need to declare conformance to `ImportableAttributeType`.
 */
public protocol ImportableAttributeType: QueryableAttributeType {}


// MARK: - Bool

extension Bool: ImportableAttributeType {}

// MARK: - CGFloat

extension CGFloat: ImportableAttributeType {}


// MARK: - Data

extension Data: ImportableAttributeType {}


// MARK: - Date

extension Date: ImportableAttributeType {}


// MARK: - Double

extension Double: ImportableAttributeType {}


// MARK: - Float

extension Float: ImportableAttributeType {}


// MARK: - Int

extension Int: ImportableAttributeType {}


// MARK: - Int8

extension Int8: ImportableAttributeType {}


// MARK: - Int16

extension Int16: ImportableAttributeType {}


// MARK: - Int32

extension Int32: ImportableAttributeType {}


// MARK: - Int64

extension Int64: ImportableAttributeType {}


// MARK: - NSData

extension NSData: ImportableAttributeType {}


// MARK: - NSDate

extension NSDate: ImportableAttributeType {}


// MARK: - NSNumber

extension NSNumber: ImportableAttributeType {}


// MARK: - NSString

extension NSString: ImportableAttributeType {}


// MARK: - NSURL

extension NSURL: ImportableAttributeType {}


// MARK: - NSUUID

extension NSUUID: ImportableAttributeType {}


// MARK: - String

extension String: ImportableAttributeType {}


// MARK: - URL

extension URL: ImportableAttributeType {}


// MARK: - UUID

extension UUID: ImportableAttributeType {}


// MARK: - RawRepresentable

extension RawRepresentable where RawValue: ImportableAttributeType {
    
    /**
     Creates an instance of this type from its `QueryableNativeType` value.
     */
    @inline(__always)
    public static func cs_fromQueryableNativeType(_ value: QueryableNativeType) -> Self? {
        
        return RawValue.cs_fromQueryableNativeType(value).flatMap({ self.init(rawValue: $0) })
    }
    
    /**
     Creates `QueryableNativeType` value from this instance.
     */
    @inline(__always)
    public func cs_toQueryableNativeType() -> QueryableNativeType {
        
        return self.rawValue.cs_toQueryableNativeType()
    }
}
