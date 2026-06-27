//
//  Field.ToOne.swift
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


// MARK: - FieldContainer

extension FieldContainer {

    // MARK: - Relationship

    /**
     The containing type for relationships. Any `CoreStoreObject` subclass can be a destination type. Inverse relationships should be declared from the destination type as well, using the `inverse:` argument for the relationship.
     ```
     class Dog: CoreStoreObject {

         @Field.Relationship("master")
         var master: Person?
     }

     class Person: CoreStoreObject {

         @Field.Relationship("pets", inverse: \.$master)
         var pets: Set<Dog>
     }
     ```
     - Important: `Field` properties are required to be used as `@propertyWrapper`s. Any other declaration not using the `@Field.Relationship(...) var` syntax will be ignored.
     */
    @propertyWrapper
    public struct Relationship<V: FieldRelationshipType>: RelationshipKeyPathStringConvertible, FieldRelationshipProtocol {

        /**
         Overload for compiler error message only
         */
        @available(*, unavailable, message: "Field.Relationship properties are not allowed to have initial values, including `nil`.")
        public init(
            wrappedValue initial: @autoclosure @escaping () -> V,
            _ keyPath: KeyPathString,
            minCount: Int = 0,
            maxCount: Int = 0,
            deleteRule: DeleteRule = .nullify,
            versionHashModifier: @autoclosure @escaping () -> String? = nil,
            previousVersionKeyPath: @autoclosure @escaping () -> String? = nil
        ) {

            fatalError()
        }

        /**
         Overload for compiler error message only
         */
        @available(*, unavailable, message: "Field.Relationship properties are not allowed to have initial values, including `nil`.")
        public init<D>(
            wrappedValue initial: @autoclosure @escaping () -> V,
            _ keyPath: KeyPathString,
            minCount: Int = 0,
            maxCount: Int = 0,
            inverse: KeyPath<V.DestinationObjectType, FieldContainer<V.DestinationObjectType>.Relationship<D>>,
            deleteRule: DeleteRule = .nullify,
            versionHashModifier: @autoclosure @escaping () -> String? = nil,
            previousVersionKeyPath: @autoclosure @escaping () -> String? = nil
        ) {

            fatalError()
        }


        // MARK: @propertyWrapper

        @available(*, unavailable)
        public var wrappedValue: V {

            get { fatalError() }
            set { fatalError() }
        }

        public var projectedValue: Self {

            return self
        }

        public static subscript(
            _enclosingInstance instance: O,
            wrapped wrappedKeyPath: ReferenceWritableKeyPath<O, V>,
            storage storageKeyPath: ReferenceWritableKeyPath<O, Self>
        ) -> V {

            get {

                Internals.assert(
                    instance.rawObject != nil,
                    "Attempted to access values from a \(Internals.typeName(O.self)) meta object. Meta objects are only used for querying keyPaths and infering types."
                )
                Internals.assert(
                    instance.rawObject?.isRunningInAllowedQueue() == true,
                    "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
                )
                return self.read(field: instance[keyPath: storageKeyPath], for: instance.rawObject!) as! V
            }
            set {

                Internals.assert(
                    instance.rawObject != nil,
                    "Attempted to access values from a \(Internals.typeName(O.self)) meta object. Meta objects are only used for querying keyPaths and infering types."
                )
                Internals.assert(
                    instance.rawObject?.isRunningInAllowedQueue() == true,
                    "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
                )
                return self.modify(field: instance[keyPath: storageKeyPath], for: instance.rawObject!, newValue: newValue)
            }
        }


        // MARK: AnyKeyPathStringConvertible

        public var cs_keyPathString: String {

            return self.keyPath
        }


        // MARK: KeyPathStringConvertible

        public typealias ObjectType = O
        public typealias DestinationValueType = V.DestinationObjectType


        // MARK: RelationshipKeyPathStringConvertible

        public typealias ReturnValueType = V


        // MARK: PropertyProtocol

        internal let keyPath: KeyPathString


        // MARK: FieldProtocol

        internal static var dynamicObjectType: CoreStoreObject.Type {

            return ObjectType.self
        }

        internal static func read(
            field: FieldProtocol,
            for rawObject: CoreStoreManagedObject
        ) -> Any? {

            let field = field as! Self
            let keyPath = field.keyPath
            return V.cs_toReturnType(
                from: rawObject.value(forKey: keyPath) as! V.NativeValueType?
            )
        }

        internal static func modify(
            field: FieldProtocol,
            for rawObject: CoreStoreManagedObject,
            newValue: Any?
        ) {

            Internals.assert(
                rawObject.isEditableInContext() == true,
                "Attempted to update a \(Internals.typeName(O.self))'s value from outside a transaction."
            )
            let newValue = newValue as! V
            let field = field as! Self
            let keyPath = field.keyPath
            return rawObject.setValue(
                V.cs_toNativeType(from: newValue),
                forKey: keyPath
            )
        }


        // MARK: FieldRelationshipProtocol

        internal let entityDescriptionValues: () -> FieldRelationshipProtocol.EntityDescriptionValues

        internal static func valueForSnapshot(
            field: FieldProtocol,
            for rawObject: CoreStoreManagedObject
        ) -> Any? {

            Internals.assert(
                rawObject.isRunningInAllowedQueue() == true,
                "Attempted to access \(Internals.typeName(O.self))'s value outside it's designated queue."
            )
            let field = field as! Self
            return V.cs_valueForSnapshot(from: rawObject.objectIDs(forRelationshipNamed: field.keyPath))
        }


        // MARK: FilePrivate

        fileprivate init(
            keyPath: KeyPathString,
            isToMany: Bool,
            isOrdered: Bool,
            deleteRule: DeleteRule,
            inverseKeyPath: @escaping () -> KeyPathString?,
            versionHashModifier: @escaping () -> String?,
            renamingIdentifier: @escaping () -> String?,
            affectedByKeyPaths: @escaping () -> Set<KeyPathString>,
            minCount: Int,
            maxCount: Int
        ) {

            self.keyPath = keyPath
            self.entityDescriptionValues = {

                let range = (Swift.max(0, minCount) ... maxCount)
                return (
                    isToMany: isToMany,
                    isOrdered: isOrdered,
                    deleteRule: deleteRule.nativeValue,
                    inverse: (type: V.DestinationObjectType.self, keyPath: inverseKeyPath()),
                    versionHashModifier: versionHashModifier(),
                    renamingIdentifier: renamingIdentifier(),
                    affectedByKeyPaths: affectedByKeyPaths(),
                    minCount: range.lowerBound,
                    maxCount: range.upperBound
                )
            }
        }


        // MARK: - DeleteRule

        /**
         These constants define what happens to relationships when an object is deleted.
         */
        public enum DeleteRule {

            // MARK: Public

            /**
             If the object is deleted, back pointers from the objects to which it is related are nullified.
             */
            case nullify

            /**
             If the object is deleted, the destination object or objects of this relationship are also deleted.
             */
            case cascade

            /**
             If the destination of this relationship is not nil, the delete creates a validation error.
             */
            case deny


            // MARK: Internal

            internal var nativeValue: NSDeleteRule {

                switch self {

                case .nullify:  return .nullifyDeleteRule
                case .cascade:  return .cascadeDeleteRule
                case .deny:     return .denyDeleteRule
                }
            }
        }
    }
}


// MARK: - FieldContainer.Relationship where V: FieldRelationshipToOneType

extension FieldContainer.Relationship where V: FieldRelationshipToOneType {

    /**
    Initializes the metadata for the relationship. All relationships require an "inverse", so updates to to this object's relationship are also reflected on its destination object. Make sure to declare this relationship's inverse relationship on its destination object. Due to Swift's compiler limitation, only one of the relationship and its inverse can declare an `inverse:` argument.
     ```
     class Dog: CoreStoreObject {

         @Field.Relationship("master")
         var master: Person?
     }

     class Person: CoreStoreObject {

         @Field.Relationship("pets", inverse: \.$master)
         var pets: Set<Dog>
     }
     ```
     - parameter keyPath: the permanent name for this relationship.
     - parameter deleteRule: defines what happens to relationship when an object is deleted. Valid values are `.nullify`, `.cascade`, and `.delete`. Defaults to `.nullify`.
     - parameter versionHashModifier: used to mark or denote a property as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where the properties are unchanged but the format or content of its data are changed.)
     - parameter previousVersionKeyPath: used to resolve naming conflicts between models. When creating an entity mapping between entities in two managed object models, a source entity property's `keyPath` with a matching destination entity property's `previousVersionKeyPath` indicate that a property mapping should be configured to migrate from the source to the destination. If unset, the identifier will be the property's `keyPath`.
     - parameter affectedByKeyPaths: a set of key paths for properties whose values affect the value of the receiver. This is similar to `NSManagedObject.keyPathsForValuesAffectingValue(forKey:)`.
     */
    public init(
        _ keyPath: KeyPathString,
        deleteRule: DeleteRule = .nullify,
        versionHashModifier: @autoclosure @escaping () -> String? = nil,
        previousVersionKeyPath: @autoclosure @escaping () -> String? = nil,
        affectedByKeyPaths: @autoclosure @escaping () -> Set<KeyPathString> = []
    ) {

        self.init(
            keyPath: keyPath,
            isToMany: false,
            isOrdered: false,
            deleteRule: deleteRule,
            inverseKeyPath: { nil },
            versionHashModifier: versionHashModifier,
            renamingIdentifier: previousVersionKeyPath,
            affectedByKeyPaths: affectedByKeyPaths,
            minCount: 0,
            maxCount: 1
        )
    }

    /**
    Initializes the metadata for the relationship. All relationships require an "inverse", so updates to to this object's relationship are also reflected on its destination object. Make sure to declare this relationship's inverse relationship on its destination object. Due to Swift's compiler limitation, only one of the relationship and its inverse can declare an `inverse:` argument.
     ```
     class Dog: CoreStoreObject {

         @Field.Relationship("master")
         var master: Person?
     }

     class Person: CoreStoreObject {

         @Field.Relationship("pets", inverse: \.$master)
         var pets: Set<Dog>
     }
     ```
     - parameter keyPath: the permanent name for this relationship.
     - parameter inverse: the inverse relationship that is declared for the destination object. All relationships require an "inverse", so updates to to this object's relationship are also reflected on its destination object.
     - parameter deleteRule: defines what happens to relationship when an object is deleted. Valid values are `.nullify`, `.cascade`, and `.delete`. Defaults to `.nullify`.
     - parameter versionHashModifier: used to mark or denote a property as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where the properties are unchanged but the format or content of its data are changed.)
     - parameter previousVersionKeyPath: used to resolve naming conflicts between models. When creating an entity mapping between entities in two managed object models, a source entity property's `keyPath` with a matching destination entity property's `previousVersionKeyPath` indicate that a property mapping should be configured to migrate from the source to the destination. If unset, the identifier will be the property's `keyPath`.
     - parameter affectedByKeyPaths: a set of key paths for properties whose values affect the value of the receiver. This is similar to `NSManagedObject.keyPathsForValuesAffectingValue(forKey:)`.
     */
    public init<D>(
        _ keyPath: KeyPathString,
        inverse: KeyPath<V.DestinationObjectType, FieldContainer<V.DestinationObjectType>.Relationship<D>>,
        deleteRule: DeleteRule = .nullify,
        versionHashModifier: @autoclosure @escaping () -> String? = nil,
        previousVersionKeyPath: @autoclosure @escaping () -> String? = nil,
        affectedByKeyPaths: @autoclosure @escaping () -> Set<KeyPathString> = []
    ) where D: FieldRelationshipType {

        self.init(
            keyPath: keyPath,
            isToMany: false,
            isOrdered: false,
            deleteRule: deleteRule,
            inverseKeyPath: { V.DestinationObjectType.meta[keyPath: inverse].keyPath },
            versionHashModifier: versionHashModifier,
            renamingIdentifier: previousVersionKeyPath,
            affectedByKeyPaths: affectedByKeyPaths,
            minCount: 0,
            maxCount: 1
        )
    }
}


// MARK: - FieldContainer.Relationship: ToManyRelationshipKeyPathStringConvertible where V: FieldRelationshipToManyType

extension FieldContainer.Relationship: ToManyRelationshipKeyPathStringConvertible where V: FieldRelationshipToManyType {}


// MARK: - FieldContainer.Relationship where V: FieldRelationshipToManyOrderedType

extension FieldContainer.Relationship where V: FieldRelationshipToManyOrderedType {

    /**
    Initializes the metadata for the relationship. All relationships require an "inverse", so updates to to this object's relationship are also reflected on its destination object. Make sure to declare this relationship's inverse relationship on its destination object. Due to Swift's compiler limitation, only one of the relationship and its inverse can declare an `inverse:` argument.
     ```
     class Dog: CoreStoreObject {

         @Field.Relationship("master")
         var master: Person?
     }

     class Person: CoreStoreObject {

         @Field.Relationship("pets", inverse: \.$master)
         var pets: Array<Dog>
     }
     ```
     - parameter keyPath: the permanent name for this relationship.
     - parameter minCount: the minimum number of objects in this relationship UNLESS THE RELATIONSHIP IS EMPTY. This means there might be zero objects in the relationship, which might be less than `minCount`. If the number of objects in the relationship do not satisfy `minCount` and `maxCount`, the transaction's commit (or auto-commit) would fail with a validation error.
     - parameter maxCount: the maximum number of objects in this relationship. If the number of objects in the relationship do not satisfy `minCount` and `maxCount`, the transaction's commit (or auto-commit) would fail with a validation error.
     - parameter deleteRule: defines what happens to relationship when an object is deleted. Valid values are `.nullify`, `.cascade`, and `.delete`. Defaults to `.nullify`.
     - parameter versionHashModifier: used to mark or denote a property as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where the properties are unchanged but the format or content of its data are changed.)
     - parameter previousVersionKeyPath: used to resolve naming conflicts between models. When creating an entity mapping between entities in two managed object models, a source entity property's `keyPath` with a matching destination entity property's `previousVersionKeyPath` indicate that a property mapping should be configured to migrate from the source to the destination. If unset, the identifier will be the property's `keyPath`.
     - parameter affectedByKeyPaths: a set of key paths for properties whose values affect the value of the receiver. This is similar to `NSManagedObject.keyPathsForValuesAffectingValue(forKey:)`.
     */
    public init(
        _ keyPath: KeyPathString,
        minCount: Int = 0,
        maxCount: Int = 0,
        deleteRule: DeleteRule = .nullify,
        versionHashModifier: @autoclosure @escaping () -> String? = nil,
        previousVersionKeyPath: @autoclosure @escaping () -> String? = nil,
        affectedByKeyPaths: @autoclosure @escaping () -> Set<KeyPathString> = []
    ) {

        self.init(
            keyPath: keyPath,
            isToMany: true,
            isOrdered: true,
            deleteRule: deleteRule,
            inverseKeyPath: { nil },
            versionHashModifier: versionHashModifier,
            renamingIdentifier: previousVersionKeyPath,
            affectedByKeyPaths: affectedByKeyPaths,
            minCount: minCount,
            maxCount: maxCount
        )
    }

    /**
    Initializes the metadata for the relationship. All relationships require an "inverse", so updates to to this object's relationship are also reflected on its destination object. Make sure to declare this relationship's inverse relationship on its destination object. Due to Swift's compiler limitation, only one of the relationship and its inverse can declare an `inverse:` argument.
     ```
     class Dog: CoreStoreObject {

         @Field.Relationship("master")
         var master: Person?
     }

     class Person: CoreStoreObject {

         @Field.Relationship("pets", inverse: \.$master)
         var pets: Array<Dog>
     }
     ```
     - parameter keyPath: the permanent name for this relationship.
     - parameter minCount: the minimum number of objects in this relationship UNLESS THE RELATIONSHIP IS EMPTY. This means there might be zero objects in the relationship, which might be less than `minCount`. If the number of objects in the relationship do not satisfy `minCount` and `maxCount`, the transaction's commit (or auto-commit) would fail with a validation error.
     - parameter maxCount: the maximum number of objects in this relationship. If the number of objects in the relationship do not satisfy `minCount` and `maxCount`, the transaction's commit (or auto-commit) would fail with a validation error.
     - parameter inverse: the inverse relationship that is declared for the destination object. All relationships require an "inverse", so updates to to this object's relationship are also reflected on its destination object.
     - parameter deleteRule: defines what happens to relationship when an object is deleted. Valid values are `.nullify`, `.cascade`, and `.delete`. Defaults to `.nullify`.
     - parameter versionHashModifier: used to mark or denote a property as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where the properties are unchanged but the format or content of its data are changed.)
     - parameter previousVersionKeyPath: used to resolve naming conflicts between models. When creating an entity mapping between entities in two managed object models, a source entity property's `keyPath` with a matching destination entity property's `previousVersionKeyPath` indicate that a property mapping should be configured to migrate from the source to the destination. If unset, the identifier will be the property's `keyPath`.
     - parameter affectedByKeyPaths: a set of key paths for properties whose values affect the value of the receiver. This is similar to `NSManagedObject.keyPathsForValuesAffectingValue(forKey:)`.
     */
    public init<D>(
        _ keyPath: KeyPathString,
        minCount: Int = 0,
        maxCount: Int = 0,
        inverse: KeyPath<V.DestinationObjectType, FieldContainer<V.DestinationObjectType>.Relationship<D>>,
        deleteRule: DeleteRule = .nullify,
        versionHashModifier: @autoclosure @escaping () -> String? = nil,
        previousVersionKeyPath: @autoclosure @escaping () -> String? = nil,
        affectedByKeyPaths: @autoclosure @escaping () -> Set<KeyPathString> = []
    ) where D: FieldRelationshipType {

        self.init(
            keyPath: keyPath,
            isToMany: true,
            isOrdered: true,
            deleteRule: deleteRule,
            inverseKeyPath: { V.DestinationObjectType.meta[keyPath: inverse].keyPath },
            versionHashModifier: versionHashModifier,
            renamingIdentifier: previousVersionKeyPath,
            affectedByKeyPaths: affectedByKeyPaths,
            minCount: minCount,
            maxCount: maxCount
        )
    }
}


// MARK: - FieldContainer.Relationship where V: FieldRelationshipToManyUnorderedType

extension FieldContainer.Relationship where V: FieldRelationshipToManyUnorderedType {

    /**
    Initializes the metadata for the relationship. All relationships require an "inverse", so updates to to this object's relationship are also reflected on its destination object. Make sure to declare this relationship's inverse relationship on its destination object. Due to Swift's compiler limitation, only one of the relationship and its inverse can declare an `inverse:` argument.
     ```
     class Dog: CoreStoreObject {

         @Field.Relationship("master")
         var master: Person?
     }

     class Person: CoreStoreObject {

         @Field.Relationship("pets", inverse: \.$master)
         var pets: Set<Dog>
     }
     ```
     - parameter keyPath: the permanent name for this relationship.
     - parameter minCount: the minimum number of objects in this relationship UNLESS THE RELATIONSHIP IS EMPTY. This means there might be zero objects in the relationship, which might be less than `minCount`. If the number of objects in the relationship do not satisfy `minCount` and `maxCount`, the transaction's commit (or auto-commit) would fail with a validation error.
     - parameter maxCount: the maximum number of objects in this relationship. If the number of objects in the relationship do not satisfy `minCount` and `maxCount`, the transaction's commit (or auto-commit) would fail with a validation error.
     - parameter deleteRule: defines what happens to relationship when an object is deleted. Valid values are `.nullify`, `.cascade`, and `.delete`. Defaults to `.nullify`.
     - parameter versionHashModifier: used to mark or denote a property as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where the properties are unchanged but the format or content of its data are changed.)
     - parameter previousVersionKeyPath: used to resolve naming conflicts between models. When creating an entity mapping between entities in two managed object models, a source entity property's `keyPath` with a matching destination entity property's `previousVersionKeyPath` indicate that a property mapping should be configured to migrate from the source to the destination. If unset, the identifier will be the property's `keyPath`.
     - parameter affectedByKeyPaths: a set of key paths for properties whose values affect the value of the receiver. This is similar to `NSManagedObject.keyPathsForValuesAffectingValue(forKey:)`.
     */
    public init(
        _ keyPath: KeyPathString,
        minCount: Int = 0,
        maxCount: Int = 0,
        deleteRule: DeleteRule = .nullify,
        versionHashModifier: @autoclosure @escaping () -> String? = nil,
        previousVersionKeyPath: @autoclosure @escaping () -> String? = nil,
        affectedByKeyPaths: @autoclosure @escaping () -> Set<KeyPathString> = []
    ) {

        self.init(
            keyPath: keyPath,
            isToMany: true,
            isOrdered: false,
            deleteRule: deleteRule,
            inverseKeyPath: { nil },
            versionHashModifier: versionHashModifier,
            renamingIdentifier: previousVersionKeyPath,
            affectedByKeyPaths: affectedByKeyPaths,
            minCount: minCount,
            maxCount: maxCount
        )
    }

    /**
    Initializes the metadata for the relationship. All relationships require an "inverse", so updates to to this object's relationship are also reflected on its destination object. Make sure to declare this relationship's inverse relationship on its destination object. Due to Swift's compiler limitation, only one of the relationship and its inverse can declare an `inverse:` argument.
     ```
     class Dog: CoreStoreObject {

         @Field.Relationship("master")
         var master: Person?
     }

     class Person: CoreStoreObject {

         @Field.Relationship("pets", inverse: \.$master)
         var pets: Set<Dog>
     }
     ```
     - parameter keyPath: the permanent name for this relationship.
     - parameter minCount: the minimum number of objects in this relationship UNLESS THE RELATIONSHIP IS EMPTY. This means there might be zero objects in the relationship, which might be less than `minCount`. If the number of objects in the relationship do not satisfy `minCount` and `maxCount`, the transaction's commit (or auto-commit) would fail with a validation error.
     - parameter maxCount: the maximum number of objects in this relationship. If the number of objects in the relationship do not satisfy `minCount` and `maxCount`, the transaction's commit (or auto-commit) would fail with a validation error.
     - parameter inverse: the inverse relationship that is declared for the destination object. All relationships require an "inverse", so updates to to this object's relationship are also reflected on its destination object.
     - parameter deleteRule: defines what happens to relationship when an object is deleted. Valid values are `.nullify`, `.cascade`, and `.delete`. Defaults to `.nullify`.
     - parameter versionHashModifier: used to mark or denote a property as being a different "version" than another even if all of the values which affect persistence are equal. (Such a difference is important in cases where the properties are unchanged but the format or content of its data are changed.)
     - parameter previousVersionKeyPath: used to resolve naming conflicts between models. When creating an entity mapping between entities in two managed object models, a source entity property's `keyPath` with a matching destination entity property's `previousVersionKeyPath` indicate that a property mapping should be configured to migrate from the source to the destination. If unset, the identifier will be the property's `keyPath`.
     - parameter affectedByKeyPaths: a set of key paths for properties whose values affect the value of the receiver. This is similar to `NSManagedObject.keyPathsForValuesAffectingValue(forKey:)`.
     */
    public init<D>(
        _ keyPath: KeyPathString,
        minCount: Int = 0,
        maxCount: Int = 0,
        inverse: KeyPath<V.DestinationObjectType, FieldContainer<V.DestinationObjectType>.Relationship<D>>,
        deleteRule: DeleteRule = .nullify,
        versionHashModifier: @autoclosure @escaping () -> String? = nil,
        previousVersionKeyPath: @autoclosure @escaping () -> String? = nil,
        affectedByKeyPaths: @autoclosure @escaping () -> Set<KeyPathString> = []
    ) where D: FieldRelationshipType {

        self.init(
            keyPath: keyPath,
            isToMany: true,
            isOrdered: false,
            deleteRule: deleteRule,
            inverseKeyPath: { V.DestinationObjectType.meta[keyPath: inverse].keyPath },
            versionHashModifier: versionHashModifier,
            renamingIdentifier: previousVersionKeyPath,
            affectedByKeyPaths: affectedByKeyPaths,
            minCount: minCount,
            maxCount: maxCount
        )
    }
}
