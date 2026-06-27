//
//  NSManagedObjectContext+Transaction.swift
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
    internal weak var parentTransaction: BaseDataTransaction? {
        
        get {
            
            return Internals.getAssociatedObjectForKey(
                &PropertyKeys.parentTransaction,
                inObject: self
            )
        }
        set {
            
            Internals.setAssociatedWeakObject(
                newValue,
                forKey: &PropertyKeys.parentTransaction,
                inObject: self
            )
        }
    }
    
    @nonobjc
    internal var saveMetadata: SaveMetadata? {
        
        get {
            
            let value: SaveMetadata? = Internals.getAssociatedObjectForKey(
                &PropertyKeys.saveMetadata,
                inObject: self
            )
            return value
        }
        set {
            
            Internals.setAssociatedRetainedObject(
                newValue,
                forKey: &PropertyKeys.saveMetadata,
                inObject: self
            )
        }
    }
    
    @nonobjc
    internal var isTransactionContext: Bool {
        
        get {
            
            let value: NSNumber? = Internals.getAssociatedObjectForKey(
                &PropertyKeys.isTransactionContext,
                inObject: self
            )
            return value?.boolValue == true
        }
        set {
            
            Internals.setAssociatedCopiedObject(
                NSNumber(value: newValue),
                forKey: &PropertyKeys.isTransactionContext,
                inObject: self
            )
        }
    }
    
    @nonobjc
    internal var isDataStackContext: Bool {
        
        get {
            
            let value: NSNumber? = Internals.getAssociatedObjectForKey(
                &PropertyKeys.isDataStackContext,
                inObject: self
            )
            return value?.boolValue == true
        }
        set {
            
            Internals.setAssociatedCopiedObject(
                NSNumber(value: newValue),
                forKey: &PropertyKeys.isDataStackContext,
                inObject: self
            )
        }
    }
    
    @nonobjc
    internal func isRunningInAllowedQueue() -> Bool {
        
        guard let parentTransaction = self.parentTransaction else {
            
            return false
        }
        return parentTransaction.isRunningInAllowedQueue()
    }
    
    @nonobjc
    internal func temporaryContextInTransactionWithConcurrencyType(_ concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        
        let context = NSManagedObjectContext(concurrencyType: concurrencyType)
        context.parent = self
        context.parentStack = self.parentStack
        context.setupForCoreStoreWithContextName("com.corestore.temporarycontext")
        context.shouldCascadeSavesToParent = (self.parentStack?.rootSavingContext == self)
        context.retainsRegisteredObjects = true
        
        return context
    }
    
    @nonobjc
    internal func saveSynchronously(
        waitForMerge: Bool,
        sourceIdentifier: Any?
    ) -> (hasChanges: Bool, error: CoreStoreError?) {
      
        var result: (hasChanges: Bool, error: CoreStoreError?) = (false, nil)
        self.performAndWait {
            
            guard self.hasChanges else {
                
                return
            }
            do {
                
                self.saveMetadata = .init(
                    isSavingSynchronously: waitForMerge,
                    sourceIdentifier: sourceIdentifier
                )
                try self.save()
                self.saveMetadata = nil
            }
            catch {
                
                let saveError = CoreStoreError(error)
                Internals.log(
                    saveError,
                    "Failed to save \(Internals.typeName(NSManagedObjectContext.self))."
                )
                result = (true, saveError)
                return
            }
            if let parentContext = self.parent, self.shouldCascadeSavesToParent {
                
                let (_, error) = parentContext.saveSynchronously(
                    waitForMerge: waitForMerge,
                    sourceIdentifier: sourceIdentifier
                )
                result = (true, error)
            }
            else {
                
                result = (true, nil)
            }
        }
        return result
    }
    
    @nonobjc
    internal func saveAsynchronously(
        sourceIdentifier: Any?,
        completion: @escaping (_ hasChanges: Bool, _ error: CoreStoreError?) -> Void = { (_, _) in }
    ) {
        
        self.perform {
            
            guard self.hasChanges else {
                
                DispatchQueue.main.async {
                    
                    completion(false, nil)
                }
                return
            }
            do {
                
                self.saveMetadata = .init(
                    isSavingSynchronously: false,
                    sourceIdentifier: sourceIdentifier
                )
                try self.save()
                self.saveMetadata = nil
            }
            catch {
                
                let saveError = CoreStoreError(error)
                Internals.log(
                    saveError,
                    "Failed to save \(Internals.typeName(NSManagedObjectContext.self))."
                )
                DispatchQueue.main.async {
    
                    completion(true, saveError)
                }
                return
            }
            if self.shouldCascadeSavesToParent, let parentContext = self.parent {
                
                parentContext.saveAsynchronously(
                    sourceIdentifier: sourceIdentifier,
                    completion: { (_, error) in
                        
                        completion(true, error)
                    }
                )
            }
            else {
                
                DispatchQueue.main.async {
    
                    completion(true, nil)
                }
            }
        }
    }
    
    @nonobjc
    internal func refreshAndMergeAllObjects() {
        
        self.refreshAllObjects()
    }
    
    
    // MARK: - SaveMetadata
    
    internal final class SaveMetadata {
        
        // MARK: Internal
        
        internal let isSavingSynchronously: Bool
        internal let sourceIdentifier: Any?
        
        internal init(
            isSavingSynchronously: Bool,
            sourceIdentifier: Any?
        ) {
            
            self.isSavingSynchronously = isSavingSynchronously
            self.sourceIdentifier = sourceIdentifier
        }
    }
    
    
    // MARK: Private
    
    private struct PropertyKeys {
        
        static var parentTransaction: Void?
        static var saveMetadata: Void?
        static var isTransactionContext: Void?
        static var isDataStackContext: Void?
    }
}
