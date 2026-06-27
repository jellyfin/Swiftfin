//
//  FIeldRelationshipType.swift
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


// MARK: - FieldRelationshipType

/**
 Values to be used for `Field.Relationship` properties.
 */
public protocol FieldRelationshipType {

    /**
     The destination object's type
     */
    associatedtype DestinationObjectType: CoreStoreObject

    /**
     The Objective-C native type synthesized by Core Data
     */
    associatedtype NativeValueType: AnyObject

    /**
     The corresponding value for this field returned from `ObjectSnapshot` properties.
     */
    associatedtype SnapshotValueType

    /**
     The corresponding value for this field returned from `ObjectPublisher` properties.
     */
    associatedtype PublishedType

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_toReturnType(
        from value: NativeValueType?
    ) -> Self

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_toPublishedType(
        from value: SnapshotValueType,
        in context: NSManagedObjectContext
    ) -> PublishedType

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_toNativeType(
        from value: Self
    ) -> NativeValueType?

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_toSnapshotType(
        from value: PublishedType
    ) -> SnapshotValueType

    /**
     Used internally by CoreStore. Do not call directly.
     */
    static func cs_valueForSnapshot(
        from objectIDs: [DestinationObjectType.ObjectID]
    ) -> SnapshotValueType
}


// MARK: - FieldRelationshipToOneType: FieldRelationshipType

public protocol FieldRelationshipToOneType: FieldRelationshipType {}


// MARK: - FieldRelationshipToManyType: FieldRelationshipType where Self: Sequence

public protocol FieldRelationshipToManyType: FieldRelationshipType where Self: Sequence {}


// MARK: - FieldRelationshipToManyOrderedType: FieldRelationshipToManyType

public protocol FieldRelationshipToManyOrderedType: FieldRelationshipToManyType {}


// MARK: - FieldRelationshipToManyUnorderedType: FieldRelationshipToManyType

public protocol FieldRelationshipToManyUnorderedType: FieldRelationshipToManyType {}


// MARK: - Optional: FieldRelationshipType, FieldRelationshipToOneType where Wrapped: CoreStoreObject

extension Optional: FieldRelationshipType, FieldRelationshipToOneType where Wrapped: CoreStoreObject {

    // MARK: FieldRelationshipType

    public typealias DestinationObjectType = Wrapped

    public typealias NativeValueType = NSManagedObject

    public typealias SnapshotValueType = NSManagedObjectID?

    public typealias PublishedType = ObjectPublisher<DestinationObjectType>?

    public static func cs_toReturnType(
        from value: NativeValueType?
    ) -> Self {

        return value.map(Wrapped.cs_fromRaw(object:))
    }

    public static func cs_toPublishedType(
        from value: SnapshotValueType,
        in context: NSManagedObjectContext
    ) -> PublishedType {

        return value.map(context.objectPublisher(objectID:))
    }

    public static func cs_toNativeType(
        from value: Self
    ) -> NativeValueType? {

        return value?.cs_toRaw()
    }

    public static func cs_toSnapshotType(
        from value: PublishedType
    ) -> SnapshotValueType {

        return value?.objectID()
    }

    public static func cs_valueForSnapshot(
        from objectIDs: [DestinationObjectType.ObjectID]
    ) -> SnapshotValueType {

        return objectIDs.first
    }
}


// MARK: - Array: FieldRelationshipType, FieldRelationshipToManyType, FieldRelationshipToManyOrderedType where Element: CoreStoreObject

extension Array: FieldRelationshipType, FieldRelationshipToManyType, FieldRelationshipToManyOrderedType where Element: CoreStoreObject {

    // MARK: FieldRelationshipType

    public typealias DestinationObjectType = Element

    public typealias NativeValueType = NSOrderedSet

    public typealias SnapshotValueType = [NSManagedObjectID]

    public typealias PublishedType = [ObjectPublisher<DestinationObjectType>]

    public static func cs_toReturnType(
        from value: NativeValueType?
    ) -> Self {

        guard let value = value else {

            return []
        }
        return value.map({ Element.cs_fromRaw(object: $0 as! NSManagedObject) })
    }

    public static func cs_toPublishedType(
        from value: SnapshotValueType,
        in context: NSManagedObjectContext
    ) -> PublishedType {

        return value.map(context.objectPublisher(objectID:))
    }

    public static func cs_toNativeType(
        from value: Self
    ) -> NativeValueType? {

        return NSOrderedSet(array: value.map({ $0.rawObject! }))
    }

    public static func cs_toSnapshotType(
        from value: PublishedType
    ) -> SnapshotValueType {

        return value.map({ $0.objectID() })
    }

    public static func cs_valueForSnapshot(
        from objectIDs: [DestinationObjectType.ObjectID]
    ) -> SnapshotValueType {

        return objectIDs
    }
}


// MARK: - Set: FieldRelationshipType, FieldRelationshipToManyType, FieldRelationshipToManyUnorderedType where Element: CoreStoreObject

extension Set: FieldRelationshipType, FieldRelationshipToManyType, FieldRelationshipToManyUnorderedType where Element: CoreStoreObject {

    // MARK: FieldRelationshipType

    public typealias DestinationObjectType = Element

    public typealias NativeValueType = NSSet

    public typealias SnapshotValueType = Set<NSManagedObjectID>

    public typealias PublishedType = Set<ObjectPublisher<DestinationObjectType>>

    public static func cs_toReturnType(
        from value: NativeValueType?
    ) -> Self {

        guard let value = value else {

            return []
        }
        return Set(value.map({ Element.cs_fromRaw(object: $0 as! NSManagedObject) }))
    }

    public static func cs_toPublishedType(
        from value: SnapshotValueType,
        in context: NSManagedObjectContext
    ) -> PublishedType {

        return PublishedType(value.map(context.objectPublisher(objectID:)))
    }

    public static func cs_toNativeType(
        from value: Self
    ) -> NativeValueType? {

        return NSSet(array: value.map({ $0.rawObject! }))
    }

    public static func cs_toSnapshotType(
        from value: PublishedType
    ) -> SnapshotValueType {

        return SnapshotValueType(value.map({ $0.objectID() }))
    }

    public static func cs_valueForSnapshot(
        from objectIDs: [DestinationObjectType.ObjectID]
    ) -> SnapshotValueType {

        return .init(objectIDs)
    }
}
