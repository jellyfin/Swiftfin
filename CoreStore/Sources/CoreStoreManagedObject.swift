//
//  CoreStoreManagedObject.swift
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

import CoreData
import Foundation


// MARK: - CoreStoreManagedObject

@objc internal class CoreStoreManagedObject: NSManagedObject {
    
    internal typealias CustomGetter = @convention(block) (_ rawObject: Any) -> Any?
    internal typealias CustomSetter = @convention(block) (_ rawObject: Any, _ newValue: Any?) -> Void
    internal typealias CustomInitializer = @convention(block) (_ rawObject: Any) -> Void
    internal typealias CustomGetterSetter = (getter: CustomGetter?, setter: CustomSetter?)
    
    @nonobjc @inline(__always)
    internal static func cs_subclassName(for entity: DynamicEntity, in modelVersion: ModelVersion) -> String {
        
        return "_\(NSStringFromClass(CoreStoreManagedObject.self))__\(modelVersion)__\(NSStringFromClass(entity.type))__\(entity.entityName)"
    }
}


// MARK: - Private

private enum Static {
    
    static let queue = DispatchQueue.concurrent("com.coreStore.coreStoreManagerObjectBarrierQueue", qos: .userInteractive)
    static var cache: [ObjectIdentifier: [KeyPathString: Set<KeyPathString>]] = [:]
}
