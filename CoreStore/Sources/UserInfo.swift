//
//  UserInfo.swift
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


// MARK: UserInfo

/**
 The `UserInfo` class is provided by several CoreStore types such as `DataStack`, `ListMonitor`, `ObjectMonitor` and transactions to allow external libraries or user apps to store their own custom data.
 ```
 enum Static {
     static var myDataKey: Void?
 }
 CoreStoreDefaults.dataStack.userInfo[&Static.myDataKey] = myObject
 ```
 - Important: Do not use this class to store thread-sensitive data.
 */
public final class UserInfo {
    
    /**
     Allows external libraries to store custom data. App code should rarely have a need for this.
     ```
     enum Static {
        static var myDataKey: Void?
     }
     CoreStoreDefaults.dataStack.userInfo[&Static.myDataKey] = myObject
     ```
     - Important: Do not use this method to store thread-sensitive data.
     - parameter key: the key for custom data. Make sure this is a static pointer that will never be changed.
     */
    public subscript(key: UnsafeRawPointer) -> Any? {
        
        get {
            
            self.lock.lock()
            defer {
                
                self.lock.unlock()
            }
            return self.data[key]
        }
        set {
            
            self.lock.lock()
            defer {
                
                self.lock.unlock()
            }
            self.data[key] = newValue
        }
    }
    
    /**
     Allows external libraries to store custom data in the `DataStack`. App code should rarely have a need for this.
     ```
     enum Static {
         static var myDataKey: Void?
     }
     CoreStoreDefaults.dataStack.userInfo[&Static.myDataKey, lazyInit: { MyObject() }] = myObject
     ```
     - Important: Do not use this method to store thread-sensitive data.
     - parameter key: the key for custom data. Make sure this is a static pointer that will never be changed.
     - parameter lazyInit: a closure to use to lazily-initialize the data
     - returns: A custom data identified by `key`
     */
    public subscript(key: UnsafeRawPointer, lazyInit closure: () -> Any) -> Any {
        
        self.lock.lock()
        defer {
            
            self.lock.unlock()
        }
        if let value = self.data[key] {
            
            return value
        }
        let value = closure()
        self.data[key] = value
        return value
    }
    
    
    // MARK: Internal
    
    internal init() {}
    
    
    // MARK: Private
    
    private var data: [UnsafeRawPointer: Any] = [:]
    private let lock = NSRecursiveLock()
}
