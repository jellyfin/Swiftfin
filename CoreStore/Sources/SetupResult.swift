//
//  SetupResult.swift
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


// MARK: - SetupResult

/**
 The `SetupResult` indicates the result of an asynchronous initialization of a persistent store.
 `SetupResult.success` indicates that the storage setup succeeded. The associated object for this `enum` value is the related `StorageInterface` instance.
 `SetupResult.failure` indicates that the storage setup failed. The associated object for this value is the related `CoreStoreError` enum value.
 ```
 try! dataStack.addStorage(
     SQLiteStore(),
     completion: { (result: SetupResult) -> Void in
         switch result {
         case .success(let storage):
             // storage is the related StorageInterface instance
         case .failure(let error):
             // error is the CoreStoreError enum value for the failure
         }
     }
 )
 ```
 */
public typealias SetupResult<StorageInterfaceType> = Swift.Result<StorageInterfaceType, CoreStoreError> where StorageInterfaceType: StorageInterface
