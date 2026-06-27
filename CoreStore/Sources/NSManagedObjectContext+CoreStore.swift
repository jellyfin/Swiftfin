//
//  NSManagedObjectContext+CoreStore.swift
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


// MARK: - NSManagedObjectContext

extension NSManagedObjectContext {
    
    // MARK: Internal
    
    @nonobjc
    internal var shouldCascadeSavesToParent: Bool {
        
        get {
            
            let number: NSNumber? = Internals.getAssociatedObjectForKey(
                &PropertyKeys.shouldCascadeSavesToParent,
                inObject: self
            )
            return number?.boolValue ?? false
        }
        set {
            
            Internals.setAssociatedCopiedObject(
                NSNumber(value: newValue),
                forKey: &PropertyKeys.shouldCascadeSavesToParent,
                inObject: self
            )
        }
    }
    
    @nonobjc
    internal func setupForCoreStoreWithContextName(_ contextName: String) {
        
        self.name = contextName
        self.observerForWillSaveNotification = Internals.NotificationObserver(
            notificationName: NSNotification.Name.NSManagedObjectContextWillSave,
            object: self,
            closure: { (note) -> Void in
                
                let context = note.object as! NSManagedObjectContext
                let insertedObjects = context.insertedObjects
                let numberOfInsertedObjects = insertedObjects.count
                guard numberOfInsertedObjects > 0 else {
                    
                    return
                }
                
                do {
                    
                    try context.obtainPermanentIDs(for: Array(insertedObjects))
                }
                catch {
                    
                    Internals.log(
                        CoreStoreError(error),
                        "Failed to obtain permanent ID(s) for \(numberOfInsertedObjects) inserted object(s)."
                    )
                }
            }
        )
    }

    @nonobjc
    internal func objectPublisher<O: DynamicObject>(objectID: NSManagedObjectID) -> ObjectPublisher<O> {

        let cache: NSMapTable<NSManagedObjectID, ObjectPublisher<O>> = self.userInfo(for: .objectPublishersCache(O.self)) {

            return .strongToWeakObjects()
        }
        return Internals.with {

            if let objectPublisher = cache.object(forKey: objectID) {

                return objectPublisher
            }
            let objectPublisher = ObjectPublisher<O>.createUncached(objectID: objectID, context: self)
            cache.setObject(objectPublisher, forKey: objectID)
            return objectPublisher
        }
    }

    @nonobjc
    internal func objectsDidChangeObserver<U: AnyObject>(for observer: U) -> Internals.SharedNotificationObserver<(updated: Set<NSManagedObjectID>, deleted: Set<NSManagedObjectID>)> {

        return self.userInfo(for: .objectsChangeObserver(U.self)) {

            return .init(
                notificationName: .NSManagedObjectContextObjectsDidChange,
                object: self,
                queue: .main,
                sharedValue: { (notification) -> (updated: Set<NSManagedObjectID>, deleted: Set<NSManagedObjectID>) in

                    guard let userInfo = notification.userInfo else {

                        return (updated: [], deleted: [])
                    }
                    if userInfo[NSInvalidatedAllObjectsKey] != nil {

                        let context = notification.object as! NSManagedObjectContext
                        return (updated: Set(context.registeredObjects.map({ $0.objectID })), deleted: [])
                    }

                    var updatedObjectIDs: Set<NSManagedObjectID> = []
                    if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {

                        updatedObjectIDs.formUnion(updatedObjects.map({ $0.objectID }))
                    }
                    if let mergedObjects = userInfo[NSRefreshedObjectsKey] as? Set<NSManagedObject> {

                        updatedObjectIDs.formUnion(mergedObjects.map({ $0.objectID }))
                    }
                    if let mergedObjects = userInfo[NSInvalidatedObjectsKey] as? Set<NSManagedObject> {

                        updatedObjectIDs.formUnion(mergedObjects.map({ $0.objectID }))
                    }
                    let deletedObjectIDs: Set<NSManagedObject> = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>) ?? []
                    return (updated: updatedObjectIDs, deleted: Set(deletedObjectIDs.map({ $0.objectID })))
                }
            )
        }
    }

    @nonobjc
    internal func objectsDidChangeObserver<U: AnyObject>(remove: U) {

        _ = self.userInfo(for: .objectsChangeObserver(U.self), initialize: { nil as Any? })
    }
    
    
    // MARK: Private
    
    @nonobjc
    private var observerForWillSaveNotification: Internals.NotificationObserver? {
        
        get {
            
            return Internals.getAssociatedObjectForKey(
                &PropertyKeys.observerForWillSaveNotification,
                inObject: self
            )
        }
        set {
            
            Internals.setAssociatedRetainedObject(
                newValue,
                forKey: &PropertyKeys.observerForWillSaveNotification,
                inObject: self
            )
        }
    }

    private func userInfo<T>(for key: UserInfoKeys, initialize: () -> T) -> T {

        let keyString = key.keyString
        if let value = self.userInfo[keyString] as? T {

            return value
        }
        let value = initialize()
        self.userInfo[keyString] = value
        return value
    }


    // MARK: - PropertyKeys

    private struct PropertyKeys {

        static var observerForWillSaveNotification: Void?
        static var shouldCascadeSavesToParent: Void?
    }


    // MARK: - UserInfoKeys

    private enum UserInfoKeys {

        case objectPublishersCache(DynamicObject.Type)
        case objectsChangeObserver(AnyObject.Type)

        var keyString: String {

            switch self {

            case .objectPublishersCache(let objectType):
                return "CoreStore.objectPublishersCache(\(Internals.typeName(objectType)))"

            case .objectsChangeObserver:
                return "CoreStore.objectsChangeObserver"
            }
        }
    }
}

