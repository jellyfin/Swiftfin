//
//  CoreStoreObject+Observing.swift
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


// MARK: - DynamicObject where Self: CoreStoreObject

extension DynamicObject where Self: CoreStoreObject {

    // MARK: Public

    public func observe<O, V>(
        _ keyPath: KeyPath<Self, FieldContainer<O>.Stored<V>>,
        options: NSKeyValueObservingOptions = [],
        changeHandler: @escaping (Self, CoreStoreObjectValueDiff<V>) -> Void
    ) -> CoreStoreObjectKeyValueObservation {

        let result = _CoreStoreObjectKeyValueObservation(
            object: self.rawObject!,
            keyPath: self[keyPath: keyPath].keyPath,
            callback: { (object, kind, newValue, oldValue, _, isPrior) in

                let notification = CoreStoreObjectValueDiff<V>(
                    kind: kind,
                    newNativeValue: newValue as? V.QueryableNativeType,
                    oldNativeValue: oldValue as? V.QueryableNativeType,
                    isPrior: isPrior
                )
                changeHandler(
                    Self.cs_fromRaw(object: object),
                    notification
                )
            }
        )
        result.start(options)
        return result
    }
}


// MARK: CoreStoreObjectKeyValueObservation

/**
 Observation token for `CoreStoreObject` properties. Make sure to retain this instance to keep observing notifications.

 `invalidate()` will be called automatically when an `CoreStoreObjectKeyValueObservation` is deinited.
 */
public protocol CoreStoreObjectKeyValueObservation: AnyObject {

    /**
     `invalidate()` will be called automatically when an `CoreStoreObjectKeyValueObservation` is deinited.
     */
    func invalidate()
}


// MARK: - CoreStoreObjectValueDiff

/**
 The object containing the changeset for an observed `ValueContainer.Required` and `ValueContainer.Optional` property.
 */
public final class CoreStoreObjectValueDiff<V: ImportableAttributeType> {

    /**
     Indicates the kind of change. See the comments for `NSObject.observeValue(forKeyPath:of:change:context:)` for more information.
     */
    public let kind: NSKeyValueChange

    /**
     `newValue` and `oldValue` will only be non-nil if `.new`/`.old` is passed to `observe()`. `newValue` will be `nil` if `isPrior` is `true`.
     */
    public private(set) lazy var newValue: V? = self.newNativeValue.flatMap(V.cs_fromQueryableNativeType)

    /**
     `newValue` and `oldValue` will only be non-nil if `.new`/`.old` is passed to `observe()`.
     */
    public private(set) lazy var oldValue: V? = self.oldNativeValue.flatMap(V.cs_fromQueryableNativeType)

    /**
     'isPrior' will be `true` if this change observation is being sent before the change happens, due to `.prior` being passed to `observe()`
     */
    public let isPrior: Bool


    // MARK: FilePrivate

    fileprivate init(kind: NSKeyValueChange, newNativeValue: V.QueryableNativeType?, oldNativeValue: V.QueryableNativeType?, isPrior: Bool) {

        self.kind = kind
        self.newNativeValue = newNativeValue
        self.oldNativeValue = oldNativeValue
        self.isPrior = isPrior
    }


    // MARK: Private

    private let newNativeValue: V.QueryableNativeType?
    private let oldNativeValue: V.QueryableNativeType?
}


// MARK: - CoreStoreObjectValueDiff

/**
 The object containing the changeset for an observed `TransformableContainer.Required` or `TransformableContainer.Optional` property.
 */
public final class CoreStoreObjectTransformableDiff<V: NSCoding & NSCopying> {

    /**
     Indicates the kind of change. See the comments for `NSObject.observeValue(forKeyPath:of:change:context:)` for more information.
     */
    public let kind: NSKeyValueChange

    /**
     `newValue` and `oldValue` will only be non-nil if `.new`/`.old` is passed to `observe()`. In general, get the most up to date value by accessing it directly on the observed object instead.
     */
    public let newValue: V?

    /**
     `newValue` and `oldValue` will only be non-nil if `.new`/`.old` is passed to `observe()`. In general, get the most up to date value by accessing it directly on the observed object instead.
     */
    public let oldValue: V?

    /**
     'isPrior' will be `true` if this change observation is being sent before the change happens, due to `.prior` being passed to `observe()`
     */
    public let isPrior: Bool


    // MARK: FilePrivate

    fileprivate init(kind: NSKeyValueChange, newValue: V?, oldValue: V?, isPrior: Bool) {

        self.kind = kind
        self.newValue = newValue
        self.oldValue = oldValue
        self.isPrior = isPrior
    }
}


// MARK: - CoreStoreObjectObjectDiff

/**
 The object containing the changeset for an observed `RelationshipContainer.ToOne` property.
 */
public final class CoreStoreObjectObjectDiff<D: CoreStoreObject> {

    /**
     Indicates the kind of change. See the comments for `NSObject.observeValue(forKeyPath:of:change:context:)` for more information.
     */
    public let kind: NSKeyValueChange

    /**
     `newValue` and `oldValue` will only be non-nil if `.new`/`.old` is passed to `observe()`. In general, get the most up to date value by accessing it directly on the observed object instead.
     */
    public private(set) lazy var newValue: D? = self.newNativeValue.flatMap(D.cs_fromRaw(object:))

    /**
     `newValue` and `oldValue` will only be non-nil if `.new`/`.old` is passed to `observe()`. In general, get the most up to date value by accessing it directly on the observed object instead.
     */
    public private(set) lazy var oldValue: D? = self.oldNativeValue.flatMap(D.cs_fromRaw(object:))

    /**
     'isPrior' will be `true` if this change observation is being sent before the change happens, due to `.prior` being passed to `observe()`
     */
    public let isPrior: Bool


    // MARK: FilePrivate

    fileprivate init(
        kind: NSKeyValueChange,
        newNativeValue: CoreStoreManagedObject?,
        oldNativeValue: CoreStoreManagedObject?,
        isPrior: Bool
    ) {

        self.kind = kind
        self.newNativeValue = newNativeValue
        self.oldNativeValue = oldNativeValue
        self.isPrior = isPrior
    }


    // MARK: Private

    private let newNativeValue: CoreStoreManagedObject?
    private let oldNativeValue: CoreStoreManagedObject?
}


// MARK: - CoreStoreObjectUnorderedDiff

/**
 The object containing the changeset for an observed `RelationshipContainer.ToManyUnordered` property.
 */
public final class CoreStoreObjectUnorderedDiff<D: CoreStoreObject> {

    /**
     Indicates the kind of change. See the comments for `NSObject.observeValue(forKeyPath:of:change:context:)` for more information.
     */
    public let kind: NSKeyValueChange

    /**
     `newValue` and `oldValue` will only be non-nil if `.new`/`.old` is passed to `observe()`. In general, get the most up to date value by accessing it directly on the observed object instead.
     */
    public private(set) lazy var newValue: Set<D> = Set(self.newNativeValue.map({ D.cs_fromRaw(object: $0 as! NSManagedObject) }))

    /**
     `newValue` and `oldValue` will only be non-nil if `.new`/`.old` is passed to `observe()`. In general, get the most up to date value by accessing it directly on the observed object instead.
     */
    public private(set) lazy var oldValue: Set<D> = Set(self.oldNativeValue.map({ D.cs_fromRaw(object: $0 as! NSManagedObject) }))

    /**
     'isPrior' will be `true` if this change observation is being sent before the change happens, due to `.prior` being passed to `observe()`
     */
    public let isPrior: Bool


    // MARK: FilePrivate

    fileprivate init(
        kind: NSKeyValueChange,
        newNativeValue: NSOrderedSet?,
        oldNativeValue: NSOrderedSet?,
        isPrior: Bool
    ) {

        self.kind = kind
        self.newNativeValue = newNativeValue ?? []
        self.oldNativeValue = oldNativeValue ?? []
        self.isPrior = isPrior
    }


    // MARK: Private

    private let newNativeValue: NSOrderedSet
    private let oldNativeValue: NSOrderedSet
}


// MARK: - CoreStoreObjectOrderedDiff

/**
 The object containing the changeset for an observed `RelationshipContainer.Ordered` property.
 */
public final class CoreStoreObjectOrderedDiff<D: CoreStoreObject> {

    /**
     Indicates the kind of change. See the comments for `NSObject.observeValue(forKeyPath:of:change:context:)` for more information.
     */
    public let kind: NSKeyValueChange

    /**
     `newValue` and `oldValue` will only be non-nil if `.new`/`.old` is passed to `observe()`. In general, get the most up to date value by accessing it directly on the observed object instead.
     */
    public private(set) lazy var newValue: [D] = self.newNativeValue.map({ D.cs_fromRaw(object: $0 as! NSManagedObject) })

    /**
     `newValue` and `oldValue` will only be non-nil if `.new`/`.old` is passed to `observe()`. In general, get the most up to date value by accessing it directly on the observed object instead.
     */
    public private(set) lazy var oldValue: [D] = self.oldNativeValue.map({ D.cs_fromRaw(object: $0 as! NSManagedObject) })

    /**
     `indexes` will be `nil` unless the observed KeyPath refers to an ordered to-many property
     */
    public let indexes: IndexSet

    /**
     'isPrior' will be `true` if this change observation is being sent before the change happens, due to `.prior` being passed to `observe()`
     */
    public let isPrior: Bool


    // MARK: FilePrivate

    fileprivate init(
        kind: NSKeyValueChange,
        newNativeValue: NSArray?,
        oldNativeValue: NSArray?,
        indexes: IndexSet,
        isPrior: Bool
    ) {

        self.kind = kind
        self.newNativeValue = newNativeValue ?? []
        self.oldNativeValue = oldNativeValue ?? []
        self.indexes = indexes
        self.isPrior = isPrior
    }


    // MARK: Private

    private let newNativeValue: NSArray
    private let oldNativeValue: NSArray
}


// MARK: - AttributeProtocol

extension AttributeProtocol {

    // MARK: FilePrivate

    fileprivate func observe<O: CoreStoreObject, V: ImportableAttributeType>(with options: NSKeyValueObservingOptions = [], changeHandler: @escaping (O, CoreStoreObjectValueDiff<V>) -> Void) -> CoreStoreObjectKeyValueObservation {

        let result = _CoreStoreObjectKeyValueObservation(
            object: self.rawObject!,
            keyPath: self.keyPath,
            callback: { (object, kind, newValue, oldValue, _, isPrior) in

                let notification = CoreStoreObjectValueDiff<V>(
                    kind: kind,
                    newNativeValue: newValue as? V.QueryableNativeType,
                    oldNativeValue: oldValue as? V.QueryableNativeType,
                    isPrior: isPrior
                )
                changeHandler(
                    O.cs_fromRaw(object: object),
                    notification
                )
            }
        )
        result.start(options)
        return result
    }

    fileprivate func observe<O: CoreStoreObject, V: NSCoding & NSCopying>(with options: NSKeyValueObservingOptions = [], changeHandler: @escaping (O, CoreStoreObjectTransformableDiff<V>) -> Void) -> CoreStoreObjectKeyValueObservation {

        let result = _CoreStoreObjectKeyValueObservation(
            object: self.rawObject!,
            keyPath: self.keyPath,
            callback: { (object, kind, newValue, oldValue, _, isPrior) in

                let notification = CoreStoreObjectTransformableDiff<V>(
                    kind: kind,
                    newValue: newValue as? V,
                    oldValue: oldValue as? V,
                    isPrior: isPrior
                )
                changeHandler(
                    O.cs_fromRaw(object: object),
                    notification
                )
            }
        )
        result.start(options)
        return result
    }
}


// MARK: - _CoreStoreObjectKeyValueObservation

// Mirrored implementation from https://github.com/apple/swift/blob/6e7051eb1e38e743a514555d09256d12d3fec750/stdlib/public/Darwin/Foundation/NSObject.swift#L141
fileprivate final class _CoreStoreObjectKeyValueObservation: NSObject, CoreStoreObjectKeyValueObservation {

    // MARK: FilePrivate

    @nonobjc
    fileprivate init(
        object: CoreStoreManagedObject,
        keyPath: KeyPathString,
        callback: @escaping (
            _ object: CoreStoreManagedObject,
            _ kind: NSKeyValueChange,
            _ newValue: Any?,
            _ oldValue: Any?,
            _ indexes: IndexSet?,
            _ isPrior: Bool
        ) -> Void
    ) {

        let _ = _CoreStoreObjectKeyValueObservation.swizzler
        self.keyPath = keyPath
        self.object = object
        self.callback = callback
    }

    @nonobjc
    fileprivate func start(_ options: NSKeyValueObservingOptions) {
        
        self.object?
            .addObserver(
                self,
                forKeyPath: self.keyPath,
                options: options,
                context: nil
            )
    }

    deinit {

        self.object?
            .removeObserver(self, forKeyPath: self.keyPath, context: nil)
    }


    // MARK: DynamicObjectKeyValueObservation

    @nonobjc
    public func invalidate() {

        self.object?
            .removeObserver(self, forKeyPath: self.keyPath, context: nil)
        self.object = nil
    }


    // MARK: Private

    // workaround for <rdar://problem/31640524> Erroneous (?) error when using bridging in the Foundation overlay
    @nonobjc
    static var swizzler: Any? = Internals.with {

        let bridgeClass: AnyClass = _CoreStoreObjectKeyValueObservation.self
        let rootObserveImpl = class_getInstanceMethod(
            bridgeClass,
            #selector(
                _CoreStoreObjectKeyValueObservation
                    .observeValue(forKeyPath:of:change:context:)
            )
        )!
        let swapObserveImpl = class_getInstanceMethod(
            bridgeClass,
            #selector(
                _CoreStoreObjectKeyValueObservation
                    ._cs_swizzle_me_observeValue(forKeyPath:of:change:context:)
            )
        )!
        method_exchangeImplementations(rootObserveImpl, swapObserveImpl)
        return nil
    }

    @nonobjc
    private weak var object: CoreStoreManagedObject?

    @nonobjc
    private let callback: (
        _ object: CoreStoreManagedObject,
        _ kind: NSKeyValueChange,
        _ newValue: Any?,
        _ oldValue: Any?,
        _ indexes: IndexSet?,
        _ isPrior: Bool
    ) -> Void

    @nonobjc
    private let keyPath: KeyPathString

    @objc
    private dynamic func _cs_swizzle_me_observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSString: Any]?,
        context: UnsafeMutableRawPointer?
    ) {

        guard
            let object = object as? CoreStoreManagedObject,
            object == self.object,
            let change = change
        else {

            return
        }
        let rawKind: UInt = change[NSKeyValueChangeKey.kindKey.rawValue as NSString] as! UInt
        self.callback(
            object,
            NSKeyValueChange(rawValue: rawKind)!,
            change[NSKeyValueChangeKey.newKey.rawValue as NSString],
            change[NSKeyValueChangeKey.oldKey.rawValue as NSString],
            change[NSKeyValueChangeKey.indexesKey.rawValue as NSString] as! IndexSet?,
            change[NSKeyValueChangeKey.notificationIsPriorKey.rawValue as NSString] as! Bool? ?? false
        )
    }
}


// MARK: - Deprecated

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension ValueContainer.Required {

    public func observe(options: NSKeyValueObservingOptions = [], changeHandler: @escaping (O, CoreStoreObjectValueDiff<V>) -> Void) -> CoreStoreObjectKeyValueObservation {

        return self.observe(with: options, changeHandler: changeHandler)
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension ValueContainer.Optional {

    public func observe(options: NSKeyValueObservingOptions = [], changeHandler: @escaping (O, CoreStoreObjectValueDiff<V>) -> Void) -> CoreStoreObjectKeyValueObservation {

        return self.observe(with: options, changeHandler: changeHandler)
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension TransformableContainer.Required {

    public func observe(options: NSKeyValueObservingOptions = [], changeHandler: @escaping (O, CoreStoreObjectTransformableDiff<V>) -> Void) -> CoreStoreObjectKeyValueObservation {

        return self.observe(with: options, changeHandler: changeHandler)
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension TransformableContainer.Optional {

    public func observe(options: NSKeyValueObservingOptions = [], changeHandler: @escaping (O, CoreStoreObjectTransformableDiff<V>) -> Void) -> CoreStoreObjectKeyValueObservation {

        return self.observe(with: options, changeHandler: changeHandler)
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension RelationshipContainer.ToOne {

    public func observe(options: NSKeyValueObservingOptions = [], changeHandler: @escaping (O, CoreStoreObjectObjectDiff<D>) -> Void) -> CoreStoreObjectKeyValueObservation {

        let result = _CoreStoreObjectKeyValueObservation(
            object: self.rawObject!,
            keyPath: self.keyPath,
            callback: { (object, kind, newValue, oldValue, _, isPrior) in

                let notification = CoreStoreObjectObjectDiff<D>(
                    kind: kind,
                    newNativeValue: newValue as! CoreStoreManagedObject?,
                    oldNativeValue: oldValue as! CoreStoreManagedObject?,
                    isPrior: isPrior
                )
                changeHandler(
                    O.cs_fromRaw(object: object),
                    notification
                )
            }
        )
        result.start(options)
        return result
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension RelationshipContainer.ToManyUnordered {

    public func observe(options: NSKeyValueObservingOptions = [], changeHandler: @escaping (O, CoreStoreObjectUnorderedDiff<D>) -> Void) -> CoreStoreObjectKeyValueObservation {

        let result = _CoreStoreObjectKeyValueObservation(
            object: self.rawObject!,
            keyPath: self.keyPath,
            callback: { (object, kind, newValue, oldValue, _, isPrior) in

                let notification = CoreStoreObjectUnorderedDiff<D>(
                    kind: kind,
                    newNativeValue: newValue as! NSOrderedSet?,
                    oldNativeValue: oldValue as! NSOrderedSet?,
                    isPrior: isPrior
                )
                changeHandler(
                    O.cs_fromRaw(object: object),
                    notification
                )
            }
        )
        result.start(options)
        return result
    }
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
extension RelationshipContainer.ToManyOrdered {

    public func observe(options: NSKeyValueObservingOptions = [], changeHandler: @escaping (O, CoreStoreObjectOrderedDiff<D>) -> Void) -> CoreStoreObjectKeyValueObservation {

        let result = _CoreStoreObjectKeyValueObservation(
            object: self.rawObject!,
            keyPath: self.keyPath,
            callback: { (object, kind, newValue, oldValue, indexes, isPrior) in

                let notification = CoreStoreObjectOrderedDiff<D>(
                    kind: kind,
                    newNativeValue: newValue as! NSArray?,
                    oldNativeValue: oldValue as! NSArray?,
                    indexes: indexes ?? IndexSet(),
                    isPrior: isPrior
                )
                changeHandler(
                    O.cs_fromRaw(object: object),
                    notification
                )
            }
        )
        result.start(options)
        return result
    }
}
